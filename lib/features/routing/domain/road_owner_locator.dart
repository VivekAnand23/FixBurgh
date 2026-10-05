import 'dart:convert';
import 'dart:math' as math;

import 'package:fixburgh/features/routing/domain/municipality_locator.dart';

/// Who maintains a road.
enum RoadOwner { penndot, turnpike, county, local }

/// The nearest owned road to a point, if any is close enough.
class RoadMatch {
  const RoadMatch({
    required this.owner,
    required this.distanceM,
    this.name = '',
    this.route = '',
  });

  final RoadOwner owner;
  final double distanceM;

  /// Street name, e.g. "Saw Mill Run Blvd".
  final String name;

  /// Signed route number for state roads (e.g. "51"), or County route id.
  final String route;
}

/// Finds whether a point is on a PennDOT, Turnpike or County-maintained road
/// using the bundled `state_roads.geojson` and `county_roads.geojson`.
/// Anything else is a local (municipal) road. Pure Dart; works offline.
class RoadOwnerLocator {
  RoadOwnerLocator._(this._segments, this._grid);

  factory RoadOwnerLocator.fromGeoJson({
    required String stateRoads,
    required String countyRoads,
  }) {
    final segments = <_Segment>[];
    void add(String source, RoadOwner Function(Map<String, dynamic>) owner) {
      final json = jsonDecode(source) as Map<String, dynamic>;
      for (final f in (json['features'] as List).cast<Map<String, dynamic>>()) {
        final props = f['properties'] as Map<String, dynamic>;
        final geom = f['geometry'] as Map<String, dynamic>;
        final lines = geom['type'] == 'LineString'
            ? [geom['coordinates'] as List]
            : (geom['coordinates'] as List).cast<List<dynamic>>();
        final road = (
          owner: owner(props),
          name: props['name'] as String? ?? '',
          route: props['route'] as String? ?? '',
        );
        for (final line in lines) {
          for (var i = 0; i + 1 < line.length; i++) {
            final a = line[i] as List;
            final b = line[i + 1] as List;
            segments.add(
              _Segment(
                (a[0] as num).toDouble(),
                (a[1] as num).toDouble(),
                (b[0] as num).toDouble(),
                (b[1] as num).toDouble(),
                road.owner,
                road.name,
                road.route,
              ),
            );
          }
        }
      }
    }

    add(
      stateRoads,
      (p) => p['owner'] == 'turnpike' ? RoadOwner.turnpike : RoadOwner.penndot,
    );
    add(countyRoads, (_) => RoadOwner.county);

    final grid = <int, List<int>>{};
    for (var i = 0; i < segments.length; i++) {
      final s = segments[i];
      for (
        var x = _cell(math.min(s.x1, s.x2));
        x <= _cell(math.max(s.x1, s.x2));
        x++
      ) {
        for (
          var y = _cell(math.min(s.y1, s.y2));
          y <= _cell(math.max(s.y1, s.y2));
          y++
        ) {
          (grid[_key(x, y)] ??= []).add(i);
        }
      }
    }
    return RoadOwnerLocator._(segments, grid);
  }

  /// Grid cell size in degrees (~250 m), larger than any search radius.
  static const _cellDeg = 0.0025;

  final List<_Segment> _segments;
  final Map<int, List<int>> _grid;

  int get segmentCount => _segments.length;

  /// Nearest PennDOT/Turnpike/County road within [radiusM] of [p], or a
  /// [RoadOwner.local] match when none is that close.
  RoadMatch nearest(GeoPoint p, {double radiusM = 25}) {
    final cx = _cell(p.lng);
    final cy = _cell(p.lat);
    _Segment? best;
    var bestD = double.infinity;
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        for (final i in _grid[_key(cx + dx, cy + dy)] ?? const <int>[]) {
          final d = _segments[i].distanceM(p);
          if (d < bestD) {
            bestD = d;
            best = _segments[i];
          }
        }
      }
    }
    if (best == null || bestD > radiusM) {
      return RoadMatch(owner: RoadOwner.local, distanceM: bestD);
    }
    return RoadMatch(
      owner: best.owner,
      distanceM: bestD,
      name: best.name,
      route: best.route,
    );
  }

  static int _cell(double deg) => (deg / _cellDeg).floor();

  static int _key(int x, int y) => x * 1000003 + y;
}

class _Segment {
  _Segment(
    this.x1,
    this.y1,
    this.x2,
    this.y2,
    this.owner,
    this.name,
    this.route,
  );

  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final RoadOwner owner;
  final String name;
  final String route;

  /// Point-to-segment distance using a local equirectangular projection,
  /// accurate to well under a metre at these distances.
  double distanceM(GeoPoint p) {
    const mPerDegLat = 111320.0;
    final mPerDegLng = mPerDegLat * math.cos(p.lat * math.pi / 180);
    final ax = (x1 - p.lng) * mPerDegLng;
    final ay = (y1 - p.lat) * mPerDegLat;
    final bx = (x2 - p.lng) * mPerDegLng;
    final by = (y2 - p.lat) * mPerDegLat;
    final dx = bx - ax;
    final dy = by - ay;
    final len2 = dx * dx + dy * dy;
    final t = len2 == 0 ? 0.0 : (-(ax * dx + ay * dy) / len2).clamp(0.0, 1.0);
    final cx = ax + t * dx;
    final cy = ay + t * dy;
    return math.sqrt(cx * cx + cy * cy);
  }
}
