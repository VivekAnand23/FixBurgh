import 'dart:async';

import 'package:fixburgh/features/report/domain/report.dart';
import 'package:fixburgh/features/report/presentation/report_labels.dart';
import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:fixburgh/features/routing/domain/road_owner_locator.dart';
import 'package:fixburgh/features/routing/domain/routing_engine.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// How the user contacted the office; stored on the report.
enum ContactChannel { call, web, email }

/// Plain-language reason, e.g. "Saw Mill Run Blvd is a state road...".
String routingExplanation(AppLocalizations l10n, RoutingResult r) {
  final road = r.road.name.isEmpty ? l10n.thisRoad : r.road.name;
  return switch (r.reason) {
    RoutingReason.stateRoad => l10n.whyStateRoad(road),
    RoutingReason.turnpike => l10n.whyTurnpike(road),
    RoutingReason.countyRoad => l10n.whyCountyRoad(road),
    RoutingReason.localRoad => l10n.whyLocalRoad(r.municipality.name),
    RoutingReason.municipalService => l10n.whyMunicipalService(
      r.municipality.name,
    ),
  };
}

String roadBadge(AppLocalizations l10n, RoadMatch road) => switch (road.owner) {
  RoadOwner.penndot =>
    road.route.isEmpty ? l10n.badgeStateRoad : l10n.badgeStateRoute(road.route),
  RoadOwner.turnpike => l10n.badgeTurnpike,
  RoadOwner.county => l10n.badgeCountyRoad,
  RoadOwner.local => l10n.badgeLocalRoad,
};

/// Text the user can paste into a web form or email.
String reportSummary(
  AppLocalizations l10n, {
  required ReportCategory category,
  required Severity severity,
  required GeoPoint location,
  String? address,
  String description = '',
}) {
  final lat = location.lat.toStringAsFixed(6);
  final lng = location.lng.toStringAsFixed(6);
  return [
    '${l10n.summaryIssue}: ${category.label(l10n)} (${severity.label(l10n)})',
    if (address != null && address.isNotEmpty)
      '${l10n.summaryLocation}: $address',
    '${l10n.summaryCoordinates}: $lat, $lng',
    '${l10n.summaryMap}: https://maps.google.com/?q=$lat,$lng',
    if (description.trim().isNotEmpty)
      '${l10n.summaryDescription}: ${description.trim()}',
    '',
    l10n.summaryFooter,
  ].join('\n');
}

/// "Who fixes this?" card (BRD FR-RTE-05 to 08).
class OfficeCard extends StatelessWidget {
  const OfficeCard({
    required this.result,
    required this.summary,
    this.subject,
    this.onContacted,
    this.showActions = true,
    super.key,
  });

  final RoutingResult result;

  /// Report details for email bodies and "Copy details".
  final String summary;
  final String? subject;
  final ValueChanged<ContactChannel>? onContacted;
  final bool showActions;

  Future<void> _open(Uri uri, ContactChannel channel) async {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      onContacted?.call(channel);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final a = result.agency;
    final web = a.webFormUrl ?? a.website;
    return Card(
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              roadBadge(l10n, result.road).toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              a.name,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              routingExplanation(l10n, result),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            if (a.phone != null)
              _InfoRow(
                icon: Icons.call_outlined,
                text: a.phoneLabel ?? a.phone!,
              ),
            if (a.hours != null) _InfoRow(icon: Icons.schedule, text: a.hours!),
            if (a.address != null)
              _InfoRow(icon: Icons.place_outlined, text: a.address!),
            if (web != null)
              _InfoRow(
                icon: Icons.language,
                text: Uri.tryParse(web)?.host ?? web,
              ),
            if (showActions) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (a.phone != null)
                    FilledButton.icon(
                      onPressed: () => _open(
                        Uri(
                          scheme: 'tel',
                          path: a.phone!.replaceAll(RegExp('[^0-9+]'), ''),
                        ),
                        ContactChannel.call,
                      ),
                      icon: const Icon(Icons.call),
                      label: Text(l10n.callOffice),
                    ),
                  if (a.email != null)
                    OutlinedButton.icon(
                      onPressed: () => _open(
                        Uri(
                          scheme: 'mailto',
                          path: a.email,
                          query: _query({
                            'subject': subject ?? l10n.appTitle,
                            'body': summary,
                          }),
                        ),
                        ContactChannel.email,
                      ),
                      icon: const Icon(Icons.mail_outline),
                      label: Text(l10n.emailOffice),
                    ),
                  if (web != null)
                    OutlinedButton.icon(
                      onPressed: () async {
                        // Most forms need the details pasted in.
                        await Clipboard.setData(ClipboardData(text: summary));
                        await _open(Uri.parse(web), ContactChannel.web);
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: Text(
                        a.webFormUrl != null ? l10n.openWebForm : l10n.website,
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () {
                      unawaited(
                        Clipboard.setData(ClipboardData(text: summary)),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.detailsCopied)),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: Text(l10n.copyDetails),
                  ),
                ],
              ),
            ],
            if (result.alternate != null) ...[
              const SizedBox(height: 12),
              Text(
                l10n.notTheirs(result.alternate!.name),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _query(Map<String, String> params) => params.entries
      .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
      .join('&');
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onTertiaryContainer;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}
