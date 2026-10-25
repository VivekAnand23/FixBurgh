import 'dart:async';

import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:fixburgh/features/services/data/google_places_repository.dart';
import 'package:fixburgh/features/society/presentation/society_widgets.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// When no listed provider matches: businesses from Google Maps (while the
/// `feature_google_places` flag is on), clearly marked as not checked by
/// Burghood, and always a link to the same search in Google Maps.
class GoogleResults extends ConsumerWidget {
  const GoogleResults({
    required this.query,
    required this.near,
    required this.miles,
    super.key,
  });

  final String query;
  final GeoPoint near;
  final int miles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final q = GoogleQuery(query: query, near: near, miles: miles);
    final enabled = ref.watch(googlePlacesEnabledProvider);
    final found = enabled ? ref.watch(googlePlacesProvider(q)) : null;
    final places = found?.value?.results ?? const <GooglePlace>[];
    final mapsUrl = found?.value?.mapsUrl ?? mapsSearchUrl(query, near);
    return Column(
      key: const Key('google-results'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (found?.isLoading ?? false)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (places.isNotEmpty) ...[
          Semantics(
            header: true,
            child: Text(
              l10n.googleResultsTitle,
              style: theme.textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 4),
          Text(l10n.googleResultsNote, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          for (final p in places)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GooglePlaceCard(place: p),
            ),
          // Google's terms ask for attribution next to Places results.
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              l10n.googleAttribution,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          key: const Key('search-google-maps'),
          icon: const Icon(Icons.map_outlined),
          label: Text(l10n.searchGoogleMaps(query)),
          onPressed: () => unawaited(openLink(context, mapsUrl)),
        ),
      ],
    );
  }
}

class GooglePlaceCard extends StatelessWidget {
  const GooglePlaceCard({required this.place, super.key});

  final GooglePlace place;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = place;
    return SocietyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (p.rating != null) ...[
                Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 2),
              ],
              Flexible(
                child: Text(
                  [
                    if (p.rating != null)
                      l10n.googleRating(
                        p.rating!.toStringAsFixed(1),
                        p.ratingCount,
                      ),
                    l10n.milesAway(p.distanceMiles.toStringAsFixed(1)),
                  ].join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          if (p.address.isNotEmpty)
            Text(
              p.address,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              if (p.phone != null)
                TextButton.icon(
                  icon: const Icon(Icons.phone_outlined),
                  label: Text(l10n.call),
                  onPressed: () => unawaited(
                    openLink(
                      context,
                      'tel:${p.phone!.replaceAll(RegExp('[^0-9+]'), '')}',
                    ),
                  ),
                ),
              if (p.website != null)
                TextButton.icon(
                  icon: const Icon(Icons.language),
                  label: Text(l10n.website),
                  onPressed: () => unawaited(openLink(context, p.website!)),
                ),
              TextButton.icon(
                icon: const Icon(Icons.map_outlined),
                label: Text(l10n.openInGoogleMaps),
                onPressed: () => unawaited(openLink(context, p.mapsUrl)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
