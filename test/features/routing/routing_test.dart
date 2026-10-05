import 'dart:io';

import 'package:fixburgh/features/report/domain/report.dart';
import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:fixburgh/features/routing/domain/road_owner_locator.dart';
import 'package:fixburgh/features/routing/domain/routing_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RoadOwnerLocator roads;
  late MunicipalityLocator munis;
  late RoutingEngine engine;

  setUpAll(() {
    roads = RoadOwnerLocator.fromGeoJson(
      stateRoads: File('assets/gis/state_roads.geojson').readAsStringSync(),
      countyRoads: File('assets/gis/county_roads.geojson').readAsStringSync(),
    );
    munis = MunicipalityLocator.fromGeoJson(
      File('assets/gis/municipalities.geojson').readAsStringSync(),
    );
    engine = RoutingEngine.fromJson(
      File('assets/directory/agencies.json').readAsStringSync(),
    );
  });

  RoutingResult route(
    GeoPoint p, [
    ReportCategory c = ReportCategory.pothole,
  ]) => engine.route(
    municipality: munis.locate(p)!,
    road: roads.nearest(p),
    category: c,
  );

  group('road owner', () {
    test('Saw Mill Run Blvd (US 19) is a PennDOT road', () {
      final m = roads.nearest(const GeoPoint(40.43277, -80.02794));
      expect(m.owner, RoadOwner.penndot);
      expect(m.name, 'Saw Mill Run Blvd');
      expect(m.route, '19');
    });

    test('Mon Valley Expressway is a Turnpike road', () {
      expect(
        roads.nearest(const GeoPoint(40.2789, -79.93602)).owner,
        RoadOwner.turnpike,
      );
    });

    test('Babcock Blvd is a County road', () {
      final m = roads.nearest(const GeoPoint(40.61353, -79.99425));
      expect(m.owner, RoadOwner.county);
      expect(m.name, contains('Babcock'));
    });

    test('a point 10 m off a state road still matches it', () {
      // ~10 m north of the Saw Mill Run Blvd vertex.
      final m = roads.nearest(const GeoPoint(40.43286, -80.02794));
      expect(m.owner, RoadOwner.penndot);
      expect(m.distanceM, lessThan(25));
    });

    test('a quiet residential street is local', () {
      // Beverly Rd, Mt. Lebanon.
      expect(
        roads.nearest(const GeoPoint(40.37325, -80.04426)).owner,
        RoadOwner.local,
      );
    });
  });

  group('routing', () {
    test('every municipality has an office with a phone number', () {
      for (final id in munis.allIds) {
        final office = engine.municipalOffice(munis.byId(id)!);
        expect(office.phone, isNotNull, reason: office.name);
      }
    });

    test(
      'a pothole on a state road goes to PennDOT, with the city as backup',
      () {
        final r = route(const GeoPoint(40.43277, -80.02794));
        expect(r.agency.id, RoutingEngine.penndotId);
        expect(r.reason, RoutingReason.stateRoad);
        expect(r.alternate, isNotNull);
      },
    );

    test('a local street in Pittsburgh goes to Pittsburgh 311', () {
      // Grant St, downtown (a city street).
      final r = route(const GeoPoint(40.4406, -79.9959));
      expect(r.agency.id, 'pittsburgh-311');
      expect(r.reason, RoutingReason.localRoad);
    });

    test('a County road goes to Allegheny County Public Works', () {
      final r = route(const GeoPoint(40.61353, -79.99425));
      expect(r.agency.id, RoutingEngine.countyId);
    });

    test('sidewalks go to the municipality even next to a state road', () {
      final r = route(
        const GeoPoint(40.43277, -80.02794),
        ReportCategory.sidewalk,
      );
      expect(r.agency.type, anyOf('municipal', '311'));
      expect(r.reason, RoutingReason.municipalService);
    });
  });
}
