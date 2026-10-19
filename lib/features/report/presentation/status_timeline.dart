import 'package:fixburgh/features/report/data/report_repository.dart';
import 'package:fixburgh/features/report/domain/report.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Timestamped status history on the report detail (BRD FR-MAP-09).
class StatusTimeline extends ConsumerWidget {
  const StatusTimeline({required this.report, super.key});

  final Report report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(reportEventsProvider(report.id)).value;
    return StatusTimelineView(
      events: reportTimeline(report, events ?? const []),
    );
  }
}

/// The timeline itself, without data loading (also used in tests).
class StatusTimelineView extends StatelessWidget {
  const StatusTimelineView({required this.events, super.key});

  final List<ReportEvent> events;

  static String label(AppLocalizations l10n, ReportEvent e) => switch (e.type) {
    ReportEventType.reported => l10n.eventReported,
    ReportEventType.sent => switch (e.channel) {
      'call' => l10n.eventSentCall,
      'email' => l10n.eventSentEmail,
      'web' => l10n.eventSentWeb,
      _ => l10n.statusSent,
    },
    ReportEventType.resolved =>
      e.by == 'community'
          ? l10n.eventResolvedCommunity
          : l10n.eventResolvedReporter,
    ReportEventType.reopened => l10n.eventReopened,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final fmt = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).add_jm();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.historyTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final (i, e) in events.indexed)
          MergeSemantics(
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 32,
                    child: Column(
                      children: [
                        Icon(
                          _icon(e.type),
                          size: 20,
                          color: e.type == ReportEventType.resolved
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.primary,
                        ),
                        if (i < events.length - 1)
                          Expanded(
                            child: Center(
                              child: Container(
                                width: 2,
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label(l10n, e),
                            style: theme.textTheme.bodyLarge,
                          ),
                          Text(
                            fmt.format(e.at),
                            style: theme.textTheme.bodySmall,
                          ),
                          if (e.photoUrl != null) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                e.photoUrl!,
                                height: 96,
                                fit: BoxFit.cover,
                                semanticLabel: l10n.afterPhoto,
                                errorBuilder: (_, _, _) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static IconData _icon(ReportEventType t) => switch (t) {
    ReportEventType.reported => Icons.flag_outlined,
    ReportEventType.sent => Icons.outgoing_mail,
    ReportEventType.resolved => Icons.task_alt,
    ReportEventType.reopened => Icons.replay,
  };
}
