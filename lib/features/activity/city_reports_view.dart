import 'dart:io';

import 'package:fixburgh/app/widgets/placeholder_view.dart';
import 'package:fixburgh/features/report/data/outbox.dart';
import 'package:fixburgh/features/report/data/report_repository.dart';
import 'package:fixburgh/features/report/domain/report.dart';
import 'package:fixburgh/features/report/presentation/mark_fixed.dart';
import 'package:fixburgh/features/report/presentation/outbox_controller.dart';
import 'package:fixburgh/features/report/presentation/report_detail_sheet.dart';
import 'package:fixburgh/features/report/presentation/report_labels.dart';
import 'package:fixburgh/features/report/presentation/steps/review_step.dart';
import 'package:fixburgh/features/routing/data/routing_providers.dart';
import 'package:fixburgh/features/routing/presentation/office_card.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// The City reports segment of Activity: the reports this person made,
/// with any still waiting in the outbox.
class CityReportsView extends ConsumerWidget {
  const CityReportsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reports = ref.watch(myReportsProvider);
    final waiting = ref.watch(outboxProvider);
    return reports.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          PlaceholderBody(icon: Icons.cloud_off, message: l10n.errorGeneric),
      data: (list) => list.isEmpty && waiting.isEmpty
          ? PlaceholderBody(icon: Icons.list_alt, message: l10n.myReportsEmpty)
          : DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(text: l10n.tabAll(list.length + waiting.length)),
                      Tab(
                        text: l10n.tabOpen(
                          list.where(_open).length + waiting.length,
                        ),
                      ),
                      Tab(text: l10n.tabFixed(list.where(_fixed).length)),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _ReportList(reports: list, waiting: waiting),
                        _ReportList(
                          reports: list.where(_open).toList(),
                          waiting: waiting,
                        ),
                        _ReportList(reports: list.where(_fixed).toList()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  static bool _open(Report r) => r.isOpen;
  static bool _fixed(Report r) => !r.isOpen;
}

/// Newest first, as [myReportsProvider] returns them (BRD FR-MYR-01), after
/// any reports still waiting to send.
class _ReportList extends StatelessWidget {
  const _ReportList({required this.reports, this.waiting = const []});

  final List<Report> reports;
  final List<OutboxItem> waiting;

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty && waiting.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            AppLocalizations.of(context).noReportsInTab,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: waiting.length + reports.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => i < waiting.length
          ? OutboxCard(item: waiting[i])
          : _ReportCard(report: reports[i - waiting.length]),
    );
  }
}

/// A report saved on the device that hasn't reached the server yet
/// (BRD FR-OFF-03, FR-OFF-05).
class OutboxCard extends ConsumerWidget {
  const OutboxCard({required this.item, super.key});

  final OutboxItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ctl = ref.read(outboxProvider.notifier);
    final d = item.draft;
    final messenger = ScaffoldMessenger.of(context);
    Future<void> guard(Future<void> Function() action) async {
      try {
        await action();
      } on Exception {
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      }
    }

    final status = switch (item.status) {
      OutboxStatus.waiting => l10n.outboxWaiting,
      OutboxStatus.limitReached => l10n.outboxLimit,
      OutboxStatus.failed => l10n.outboxFailed,
      OutboxStatus.duplicate => l10n.outboxDuplicate,
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox.square(
                    dimension: 72,
                    child: d.photoPaths.isEmpty
                        ? Icon(d.category?.icon ?? Icons.photo)
                        : Image.file(
                            File(d.photoPaths.first),
                            fit: BoxFit.cover,
                            excludeFromSemantics: true,
                            errorBuilder: (_, _, _) =>
                                Icon(d.category?.icon ?? Icons.photo),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.category?.label(l10n) ?? '',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        d.address ?? d.municipality?.name ?? '',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            item.status == OutboxStatus.waiting
                                ? Icons.cloud_upload_outlined
                                : Icons.info_outline,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              status,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (item.status == OutboxStatus.duplicate) ...[
                  FilledButton.tonal(
                    onPressed: () => guard(() => ctl.meTooInstead(item.id)),
                    child: Text(l10n.meTooShort),
                  ),
                  TextButton(
                    onPressed: () => guard(() => ctl.sendAnyway(item.id)),
                    child: Text(l10n.sendAnyway),
                  ),
                ] else
                  TextButton(
                    onPressed: () => guard(() async {
                      final run = await ctl.sendNow(force: true);
                      if ((run?.sent ?? 0) == 0) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(l10n.stillOffline)),
                        );
                      }
                    }),
                    child: Text(l10n.retryNow),
                  ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  onPressed: () => ctl.cancel(item.id),
                  child: Text(l10n.cancelReport),
                ),
              ],
            ),
          ],
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
    final messenger = ScaffoldMessenger.of(context);
    final routing = await routeReport(ref, (
      lat: r.location.lat,
      lng: r.location.lng,
      category: r.category,
    )).catchError((Object _) => null);
    if (!context.mounted) return;
    if (routing == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.routingUnavailable)));
      return;
    }
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
                            onPressed: () => markFixedFlow(context, ref, r),
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
