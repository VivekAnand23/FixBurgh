import 'package:fixburgh/app/widgets/placeholder_view.dart';
import 'package:fixburgh/features/report/data/report_repository.dart';
import 'package:fixburgh/features/report/domain/report.dart';
import 'package:fixburgh/features/report/presentation/report_detail_sheet.dart';
import 'package:fixburgh/features/report/presentation/report_labels.dart';
import 'package:fixburgh/features/report/presentation/steps/review_step.dart';
import 'package:fixburgh/features/routing/data/routing_providers.dart';
import 'package:fixburgh/features/routing/presentation/office_card.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reports = ref.watch(myReportsProvider);
    return reports.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.myReportsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => PlaceholderView(
        icon: Icons.cloud_off,
        title: l10n.myReportsTitle,
        message: l10n.errorGeneric,
      ),
      data: (list) => list.isEmpty
          ? PlaceholderView(
              icon: Icons.list_alt,
              title: l10n.myReportsTitle,
              message: l10n.myReportsEmpty,
            )
          : Scaffold(
              appBar: AppBar(title: Text(l10n.myReportsTitle)),
              body: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _ReportCard(report: list[i]),
              ),
            ),
    );
  }
}

class _ReportCard extends ConsumerWidget {
  const _ReportCard({required this.report});

  final Report report;

  Future<void> _contact(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final r = report;
    final routing = await ref.read(
      reportRoutingProvider((
        lat: r.location.lat,
        lng: r.location.lng,
        category: r.category,
      )).future,
    );
    if (routing == null || !context.mounted) return;
    await showContactSheet(
      context,
      routing: routing,
      summary: reportSummary(
        l10n,
        category: r.category,
        severity: r.severity,
        location: r.location,
        address: r.address,
        description: r.description,
      ),
      subject: l10n.emailSubject(
        r.category.label(l10n),
        r.severity.label(l10n),
        r.address ?? r.municipalityName,
      ),
      onContacted: (c) =>
          ref.read(reportRepositoryProvider).markSent(r.id, c.name),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final r = report;
    final date = DateFormat.MMMd(
      Localizations.localeOf(context).toString(),
    ).format(r.createdAt);
    final (chipBg, chipFg) = switch (r.status) {
      ReportStatus.reported => (
        theme.colorScheme.secondary,
        theme.colorScheme.onSecondary,
      ),
      ReportStatus.sent => (
        theme.colorScheme.primary,
        theme.colorScheme.onPrimary,
      ),
      ReportStatus.resolved => (
        theme.colorScheme.tertiary,
        theme.colorScheme.onTertiary,
      ),
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showReportSheet(context, r.id),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox.square(
                  dimension: 72,
                  child: r.thumbUrl == null
                      ? ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(r.category.icon),
                        )
                      : Image.network(
                          r.thumbUrl!,
                          fit: BoxFit.cover,
                          excludeFromSemantics: true,
                          errorBuilder: (_, _, _) => Icon(r.category.icon),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.category.label(l10n),
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      [r.address ?? r.municipalityName, date].join(' · '),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Chip(
                          label: Text(r.status.label(l10n)),
                          backgroundColor: chipBg,
                          labelStyle: TextStyle(color: chipFg),
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                        ),
                        const Spacer(),
                        if (r.status != ReportStatus.resolved)
                          TextButton(
                            onPressed: () => ref
                                .read(reportRepositoryProvider)
                                .markResolved(r.id),
                            child: Text(l10n.markFixed),
                          ),
                      ],
                    ),
                    if (r.status != ReportStatus.resolved)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => _contact(context, ref),
                          icon: const Icon(Icons.support_agent, size: 18),
                          label: Text(l10n.contactOffice),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
