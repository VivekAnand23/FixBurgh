import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Data sources and attributions (BRD FR-PRF-03, section 13.8). Matches
/// docs/data-sources.md.
class DataSourcesScreen extends StatelessWidget {
  const DataSourcesScreen({super.key});

  static const _sources = [
    (
      'Allegheny County Municipal Boundaries',
      'Allegheny County GIS via the Western Pennsylvania Regional Data Center',
      'https://data.wprdc.org/dataset/allegheny-county-municipal-boundaries',
    ),
    (
      'Allegheny County Owned Roads Centerlines',
      'Allegheny County GIS via the Western Pennsylvania Regional Data Center',
      'https://data.wprdc.org/dataset/allegheny-county-owned-roads-centerlines',
    ),
    (
      'PennDOT RMS roadway segments',
      'Pennsylvania Department of Transportation open data',
      'https://gis.penndot.pa.gov/gis/rest/services/opendata/roadwaysegments/MapServer/0',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.dataSources)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.dataSourcesIntro, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 8),
          for (final (name, who, url) in _sources)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(name),
              subtitle: Text(who),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => launchUrl(
                Uri.parse(url),
                mode: LaunchMode.inAppBrowserView,
              ),
            ),
          const SizedBox(height: 8),
          Text(l10n.dataSourcesDirectory, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(l10n.dataSourcesMaps, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(l10n.dataSourcesDisclaimer, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
