import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:geocoding/geocoding.dart';

/// Finds an address or place with the platform geocoder (free; no paid
/// API calls, BRD FR-MAP-11). Searches inside Allegheny County unless the
/// query already names Pennsylvania. Null when nothing matches.
Future<GeoPoint?> findPlace(String query) async {
  final q = query.trim();
  if (q.isEmpty) return null;
  final hasRegion = RegExp(
    r'\b(PA|Pennsylvania)\b',
    caseSensitive: false,
  ).hasMatch(q);
  try {
    final results = await Geocoding().locationFromAddress(
      hasRegion ? q : '$q, Allegheny County, PA',
    );
    if (results.isEmpty) return null;
    return GeoPoint(results.first.latitude, results.first.longitude);
  } on Exception {
    return null; // Offline, or the geocoder had no match.
  }
}
