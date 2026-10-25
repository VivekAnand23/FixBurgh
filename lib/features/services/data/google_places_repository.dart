import 'package:cloud_functions/cloud_functions.dart';
import 'package:fixburgh/app/analytics.dart';
import 'package:fixburgh/app/remote_config.dart';
import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A business from Google Maps, shown when no listed provider matches.
/// Burghood hasn't checked it.
typedef GooglePlace = ({
  String name,
  String address,
  double? rating,
  int ratingCount,
  String? phone,
  String? website,
  String mapsUrl,
  double distanceMiles,
});

/// What a Google search returned. `available` is false when the in-app
/// search is off or failed; `mapsUrl` always opens the same search in
/// Google Maps instead.
typedef GoogleResults = ({
  bool available,
  bool limited,
  List<GooglePlace> results,
  String mapsUrl,
});

/// A search for Google results: what to look for, near where.
@immutable
class GoogleQuery {
  const GoogleQuery({
    required this.query,
    required this.near,
    required this.miles,
  });

  final String query;
  final GeoPoint near;
  final int miles;

  @override
  bool operator ==(Object other) =>
      other is GoogleQuery &&
      other.query == query &&
      other.near.lat == near.lat &&
      other.near.lng == near.lng &&
      other.miles == miles;

  @override
  int get hashCode => Object.hash(query, near.lat, near.lng, miles);
}

/// Google Maps searching for [query] around [near]: free, no API call.
/// Kept in step with `mapsSearchUrl` in functions/src/placesQuery.ts.
String mapsSearchUrl(String query, GeoPoint near) =>
    'https://www.google.com/maps/search/${Uri.encodeComponent(query)}'
    '/@${near.lat.toStringAsFixed(5)},${near.lng.toStringAsFixed(5)},13z';

/// The `feature_google_places` Remote Config flag: show Google results in
/// the app (Places API, billed per search). When off, only the link to
/// Google Maps shows.
final Provider<bool> googlePlacesEnabledProvider = Provider<bool>((ref) {
  ref.watch(featureFlagsProvider); // Re-reads when Remote Config loads.
  final rc = ref.watch(remoteConfigProvider).value;
  return rc?.getBool('feature_google_places') ??
      remoteConfigDefaults['feature_google_places']! as bool;
});

final googlePlacesRepositoryProvider = Provider<GooglePlacesRepository>(
  (ref) => GooglePlacesRepository(
    FirebaseFunctions.instanceFor(region: 'us-east1'),
  ),
);

/// Google results for a search with no listed provider.
// ignore: specify_nonobvious_property_types, family type isn't exported.
final googlePlacesProvider = FutureProvider.autoDispose
    .family<GoogleResults, GoogleQuery>(
      (ref, q) async {
        final fallback = (
          available: false,
          limited: false,
          results: const <GooglePlace>[],
          mapsUrl: mapsSearchUrl(q.query, q.near),
        );
        if (!ref.watch(googlePlacesEnabledProvider)) return fallback;
        final results = await ref
            .watch(googlePlacesRepositoryProvider)
            .search(q)
            .catchError((Object _) => fallback);
        await ref
            .read(analyticsProvider)
            .googleResultsShown(
              available: results.available,
              results: results.results.length,
            );
        return results;
      },
      retry: (_, _) => null,
    );

class GooglePlacesRepository {
  GooglePlacesRepository(this._functions);

  final FirebaseFunctions _functions;

  Future<GoogleResults> search(GoogleQuery q) async {
    final res = await _functions
        .httpsCallable('searchGooglePlaces')
        .call<Map<String, dynamic>>({
          'query': q.query,
          'lat': q.near.lat,
          'lng': q.near.lng,
          'miles': q.miles,
        });
    return parseGoogleResults(res.data, q);
  }
}

@visibleForTesting
GoogleResults parseGoogleResults(Map<String, dynamic> d, GoogleQuery q) => (
  available: d['available'] == true,
  limited: d['limited'] == true,
  mapsUrl: d['mapsUrl'] as String? ?? mapsSearchUrl(q.query, q.near),
  results: [
    for (final r
        in (d['results'] as List? ?? const [])
            .whereType<Map<Object?, Object?>>())
      if (r['name'] case final String name)
        (
          name: name,
          address: r['address'] as String? ?? '',
          rating: (r['rating'] as num?)?.toDouble(),
          ratingCount: (r['ratingCount'] as num?)?.toInt() ?? 0,
          phone: r['phone'] as String?,
          website: r['website'] as String?,
          mapsUrl: r['mapsUrl'] as String? ?? mapsSearchUrl(name, q.near),
          distanceMiles: (r['distanceMiles'] as num?)?.toDouble() ?? 0,
        ),
  ],
);
