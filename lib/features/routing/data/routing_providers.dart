import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
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
