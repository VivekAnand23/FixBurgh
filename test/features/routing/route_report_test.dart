import 'dart:io';

import 'package:fixburgh/app/providers.dart';
import 'package:fixburgh/features/report/domain/report.dart';
import 'package:fixburgh/features/routing/data/routing_providers.dart';
import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:fixburgh/features/routing/domain/road_owner_locator.dart';
import 'package:fixburgh/features/routing/domain/routing_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // "Contact office" did nothing when the bundled GIS data loaded slowly:
  // the auto-disposing lookup was dropped before it finished.
  testWidgets('Contact office lookup finishes while data loads slowly', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    String asset(String path) => File(path).readAsStringSync();
    // Each bundled file takes a while to load, as on a slow phone.
    Future<T> slowly<T>(T Function() load) =>
        Future.delayed(const Duration(seconds: 2), load);
    RoutingResult? result;
    Object? error;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          municipalityLocatorProvider.overrideWith(
            (ref) => slowly(
              () => MunicipalityLocator.fromGeoJson(
                asset('assets/gis/municipalities.geojson'),
              ),
            ),
          ),
          roadOwnerLocatorProvider.overrideWith(
            (ref) => slowly(
              () => RoadOwnerLocator.fromGeoJson(
                stateRoads: asset('assets/gis/state_roads.geojson'),
                countyRoads: asset('assets/gis/county_roads.geojson'),
              ),
            ),
          ),
          routingEngineProvider.overrideWith(
            (ref) => slowly(
              () => RoutingEngine.fromJson(
                asset('assets/directory/agencies.json'),
              ),
            ),
          ),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () async {
                try {
                  result = await routeReport(ref, (
                    lat: 40.4406,
                    lng: -79.9959,
                    category: ReportCategory.pothole,
                  ));
                } on Object catch (e) {
                  error = e;
                }
              },
              child: const Text('contact'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('contact'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(error, isNull);
    expect(result, isNotNull);
    expect(result!.municipality.name, 'City of Pittsburgh');
  });
}
