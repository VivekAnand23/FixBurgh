import 'dart:convert';

/// A WGS84 coordinate.
class GeoPoint {
  const GeoPoint(this.lat, this.lng);

  final double lat;
  final double lng;

  @override
  String toString() => 'GeoPoint($lat, $lng)';
}

/// One of the 130 municipalities in Allegheny County.
class Municipality {
  const Municipality({
    required this.id,
    required this.name,
    required this.type,
  });

  /// Allegheny County municipal code (`MUNICODE`), e.g. `100` for Pittsburgh.
  final String id;
  final String name;

  /// `city`, `borough`, `township`, `town` or `municipality`.
  final String type;

  @override
  String toString() => 'Municipality($id, $name)';
}

/// Finds which municipality contains a point, using the boundaries bundled in
/// `assets/gis/municipalities.geojson`. Pure Dart so it can be unit tested and
/// reused by the web dashboard.
class MunicipalityLocator {
  MunicipalityLocator._(this._entries);

  /// Parses a GeoJSON FeatureCollection of (Multi)Polygons.
  factory MunicipalityLocator.fromGeoJson(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final features = (json['features'] as List).cast<Map<String, dynamic>>();
    return MunicipalityLocator._([
      for (final f in features) _Entry.fromFeature(f),
    ]);
  }

  final List<_Entry> _entries;

  int get count => _entries.length;

  /// Returns the municipality containing [p], or `null` when [p] is outside
  /// Allegheny County.
  Municipality? locate(GeoPoint p) {
    for (final e in _entries) {
      if (e.contains(p)) return e.municipality;
    }
    return null;
  }
}

typedef _Ring = List<List<double>>; // [[lng, lat], ...]

class _Entry {
  _Entry(this.municipality, this.polygons)
    : minLng = _min(polygons, 0),
      maxLng = _max(polygons, 0),
      minLat = _min(polygons, 1),
      maxLat = _max(polygons, 1);

  factory _Entry.fromFeature(Map<String, dynamic> f) {
    final props = f['properties'] as Map<String, dynamic>;
    final geom = f['geometry'] as Map<String, dynamic>;
    final raw = geom['type'] == 'Polygon'
        ? [geom['coordinates'] as List]
        : (geom['coordinates'] as List).cast<List<dynamic>>();
    final polygons = [
      for (final poly in raw)
        [
          for (final ring in poly)
            [
              for (final pt in ring as List)
                [
                  ((pt as List)[0] as num).toDouble(),
                  (pt[1] as num).toDouble(),
                ],
            ],
        ],
    ];
    return _Entry(
      Municipality(
        id: props['id'] as String,
        name: props['name'] as String,
        type: props['type'] as String,
      ),
      polygons,
    );
  }

  final Municipality municipality;

  /// Each polygon is an outer ring followed by optional holes.
  final List<List<_Ring>> polygons;
  final double minLng;
  final double maxLng;
  final double minLat;
  final double maxLat;

  bool contains(GeoPoint p) {
    if (p.lng < minLng || p.lng > maxLng || p.lat < minLat || p.lat > maxLat) {
      return false;
    }
    for (final poly in polygons) {
      if (_inRing(p, poly.first) && !poly.skip(1).any((h) => _inRing(p, h))) {
        return true;
      }
    }
    return false;
  }

  /// Ray casting point-in-polygon test.
  static bool _inRing(GeoPoint p, _Ring ring) {
    var inside = false;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final xi = ring[i][0];
      final yi = ring[i][1];
      final xj = ring[j][0];
      final yj = ring[j][1];
      if ((yi > p.lat) != (yj > p.lat) &&
          p.lng < (xj - xi) * (p.lat - yi) / (yj - yi) + xi) {
        inside = !inside;
      }
    }
    return inside;
  }

  static double _min(List<List<_Ring>> polys, int axis) => polys
      .expand((p) => p.first)
      .map((pt) => pt[axis])
      .reduce((a, b) => a < b ? a : b);

  static double _max(List<List<_Ring>> polys, int axis) => polys
      .expand((p) => p.first)
      .map((pt) => pt[axis])
      .reduce((a, b) => a > b ? a : b);
}
