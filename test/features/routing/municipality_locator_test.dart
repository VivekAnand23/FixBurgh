import 'dart:io';

import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MunicipalityLocator locator;

  setUpAll(() {
    locator = MunicipalityLocator.fromGeoJson(
      File('assets/gis/municipalities.geojson').readAsStringSync(),
    );
  });

  test('bundles all 130 Allegheny County municipalities', () {
    expect(locator.count, 130);
  });

  const cases = {
    'Downtown Pittsburgh': (GeoPoint(40.4406, -79.9959), 'City of Pittsburgh'),
    'Mt. Lebanon': (GeoPoint(40.3754, -80.0495), 'Mount Lebanon Township'),
    'Bethel Park': (GeoPoint(40.3276, -80.0395), 'Bethel Park Municipality'),
    'Sewickley': (GeoPoint(40.5365, -80.1845), 'Sewickley Borough'),
    'Monroeville': (GeoPoint(40.4212, -79.7881), 'Monroeville Municipality'),
  };

  for (final MapEntry(key: place, value: (point, expected)) in cases.entries) {
    test('$place resolves to $expected', () {
      expect(locator.locate(point)?.name, expected);
    });
  }

  test('points outside the county return null', () {
    expect(
      locator.locate(const GeoPoint(40.1740, -80.2462)),
      isNull,
    ); // Washington, PA
    expect(
      locator.locate(const GeoPoint(40.8612, -79.8953)),
      isNull,
    ); // Butler, PA
  });
}
