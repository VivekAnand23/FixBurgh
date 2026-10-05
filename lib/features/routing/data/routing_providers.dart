import 'package:fixburgh/features/report/domain/report.dart';
import 'package:fixburgh/features/report/presentation/report_draft_controller.dart';
import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:fixburgh/features/routing/domain/road_owner_locator.dart';
import 'package:fixburgh/features/routing/domain/routing_engine.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads the bundled municipal boundaries once per app run.
final municipalityLocatorProvider = FutureProvider<MunicipalityLocator>((
  ref,
) async {
  final source = await rootBundle.loadString(
    'assets/gis/municipalities.geojson',
  );
  return MunicipalityLocator.fromGeoJson(source);
});

/// Loads bundled PennDOT and County road ownership once per app run.
final roadOwnerLocatorProvider = FutureProvider<RoadOwnerLocator>((ref) async {
  final results = await Future.wait([
    rootBundle.loadString('assets/gis/state_roads.geojson'),
    rootBundle.loadString('assets/gis/county_roads.geojson'),
  ]);
  return RoadOwnerLocator.fromGeoJson(
    stateRoads: results[0],
    countyRoads: results[1],
  );
});

/// Office directory bundled with the app (tools/directory).
final routingEngineProvider = FutureProvider<RoutingEngine>((ref) async {
  final source = await rootBundle.loadString(
    'assets/directory/agencies.json',
  );
  return RoutingEngine.fromJson(source);
});

/// Routes a point and category to the responsible office, fully offline.
Future<RoutingResult?> routeIssue(
  Ref ref, {
  required GeoPoint location,
  required ReportCategory category,
}) async {
  final munis = await ref.watch(municipalityLocatorProvider.future);
  final muni = munis.locate(location);
  if (muni == null) return null;
  final roads = await ref.watch(roadOwnerLocatorProvider.future);
  final engine = await ref.watch(routingEngineProvider.future);
  return engine.route(
    municipality: muni,
    road: roads.nearest(location),
    category: category,
  );
}

/// Routing for the report being drafted; null until location and category
/// are set or when the pin is outside the county.
final FutureProvider<RoutingResult?> draftRoutingProvider =
    FutureProvider.autoDispose<RoutingResult?>((ref) {
      final (loc, cat) = ref.watch(
        reportDraftProvider.select((d) => (d.location, d.category)),
      );
      if (loc == null || cat == null) return Future.value();
      return routeIssue(ref, location: loc, category: cat);
    });

typedef RouteKey = ({double lat, double lng, ReportCategory category});

/// Routing for a submitted report (My Reports "Contact office"). Keyed by a
/// record so equal locations share one lookup.
// ignore: specify_nonobvious_property_types, family type isn't exported.
final reportRoutingProvider = FutureProvider.autoDispose
    .family<RoutingResult?, RouteKey>(
      (ref, k) => routeIssue(
        ref,
        location: GeoPoint(k.lat, k.lng),
        category: k.category,
      ),
    );
