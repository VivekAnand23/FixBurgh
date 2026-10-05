import 'dart:async';

import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/moderation/blocked_users.dart';
import 'package:fixburgh/features/moderation/text_filter.dart';
import 'package:fixburgh/features/report/data/report_repository.dart';
import 'package:fixburgh/features/report/domain/report.dart';
import 'package:fixburgh/features/report/presentation/report_labels.dart';
import 'package:fixburgh/features/report/presentation/steps/review_step.dart';
import 'package:fixburgh/features/routing/data/routing_providers.dart';
import 'package:fixburgh/features/routing/presentation/office_card.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Opens the report detail sheet (map pin tap, list tap, My Reports).
Future<void> showReportSheet(BuildContext context, String reportId) =>
    showModalBottomSheet<void>(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => ReportDetailSheet(reportId: reportId),
    );

class ReportDetailSheet extends ConsumerWidget {
  const ReportDetailSheet({required this.reportId, super.key});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final report = ref.watch(reportProvider(reportId));
    return switch (report) {
      AsyncData(:final value?) => _Body(report: value),
      AsyncData() => Padding(
        padding: const EdgeInsets.all(32),
        child: Text(l10n.reportGone, textAlign: TextAlign.center),
      ),
      AsyncError() => Padding(
        padding: const EdgeInsets.all(32),
        child: Text(l10n.errorGeneric, textAlign: TextAlign.center),
      ),
      _ => const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.report});

  final Report report;

  Future<void> _guard(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await action();
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }

  Future<String> _uid(WidgetRef ref) async {
    final auth = ref.read(authRepositoryProvider);
    await auth.ensureGuest();
    return auth.currentUser!.uid;
  }

  Future<void> _flag(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final reasons = {
      'wrong_routing': l10n.flagWrongOffice,
      'wrong_location': l10n.flagWrongLocation,
      'wrong_category': l10n.flagWrongCategory,
      'spam': l10n.flagSpam,
      'offensive': l10n.flagOffensive,
      'private_info': l10n.flagPrivate,
    };
    final reason = await showModalBottomSheet<String>(
      useRootNavigator: true,
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                l10n.flagTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final e in reasons.entries)
              ListTile(
                title: Text(e.value),
                onTap: () => Navigator.pop(context, e.key),
              ),
          ],
        ),
      ),
    );
    if (reason == null) return;
    if (!context.mounted) return;
    await _guard(context, () async {
      await ref
          .read(reportRepositoryProvider)
          .flag(reportId: report.id, uid: await _uid(ref), reason: reason);
      messenger.showSnackBar(SnackBar(content: Text(l10n.flagThanks)));
    });
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final nav = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteReportTitle),
        content: Text(l10n.deleteReportBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    nav.pop();
    await ref.read(reportRepositoryProvider).delete(report);
  }

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
    final isAuthor = ref.read(authUserProvider).value?.uid == r.authorUid;
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
      onContacted: (c) {
        // Only the reporter's own contact moves the status.
        if (isAuthor && r.status == ReportStatus.reported) {
          unawaited(ref.read(reportRepositoryProvider).markSent(r.id, c.name));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final r = report;
    final uid = ref.watch(authUserProvider).value?.uid;
    final isAuthor = uid != null && uid == r.authorUid;
    final repo = ref.read(reportRepositoryProvider);
    final upvoted =
        ref
            .watch(myVoteProvider((reportId: r.id, collection: 'upvotes')))
            .value ??
        false;
    final votedFixed =
        ref
            .watch(myVoteProvider((reportId: r.id, collection: 'fixedVotes')))
            .value ??
        false;
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.yMMMd(locale).format(r.createdAt);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (r.thumbUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  r.thumbUrl!,
                  fit: BoxFit.cover,
                  semanticLabel: l10n.photoOf(r.category.label(l10n)),
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(r.category.icon),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  r.category.label(l10n),
                  style: theme.textTheme.titleLarge,
                ),
              ),
              Chip(label: Text(r.status.label(l10n))),
            ],
          ),
          Text(
            [
              r.severity.label(l10n),
              r.address ?? r.municipalityName,
              date,
            ].join(' · '),
            style: theme.textTheme.bodyMedium,
          ),
          if (r.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              cleanUserText(r.description),
              style: theme.textTheme.bodyLarge,
            ),
          ],
          if (r.agencyName != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.routedTo(r.agencyName!),
              style: theme.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 16),
          if (!isAuthor && r.isOpen) ...[
            FilledButton.icon(
              onPressed: () => _guard(
                context,
                () async => repo.setUpvote(r.id, await _uid(ref), on: !upvoted),
              ),
              icon: Icon(upvoted ? Icons.check : Icons.front_hand_outlined),
              label: Text(
                upvoted
                    ? l10n.meTooDone(r.upvoteCount)
                    : l10n.meToo(r.upvoteCount),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: votedFixed
                  ? null
                  : () => _guard(
                      context,
                      () async => repo.voteFixed(r.id, await _uid(ref)),
                    ),
              icon: const Icon(Icons.task_alt),
              label: Text(
                l10n.looksFixed(r.fixedVoteCount, communityResolveVotes),
              ),
            ),
          ] else if (!isAuthor)
            Text(l10n.alreadyFixed, style: theme.textTheme.bodyMedium),
          if (isAuthor) ...[
            Text(
              l10n.yourReportStats(r.upvoteCount),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            if (r.isOpen)
              FilledButton.icon(
                onPressed: () => _guard(context, () => repo.markResolved(r.id)),
                icon: const Icon(Icons.task_alt),
                label: Text(l10n.markFixed),
              )
            else
              OutlinedButton.icon(
                onPressed: () => _guard(context, () => repo.reopen(r.id)),
                icon: const Icon(Icons.replay),
                label: Text(l10n.reopen),
              ),
          ],
          const SizedBox(height: 8),
          if (r.isOpen)
            TextButton.icon(
              onPressed: () => _contact(context, ref),
              icon: const Icon(Icons.support_agent),
              label: Text(l10n.contactOffice),
            ),
          TextButton.icon(
            onPressed: () => _flag(context, ref),
            icon: const Icon(Icons.flag_outlined),
            label: Text(l10n.flagReport),
          ),
          if (!isAuthor && r.authorUid.isNotEmpty)
            TextButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();
                await ref
                    .read(blockedUsersProvider.notifier)
                    .block(r.authorUid);
                messenger.showSnackBar(SnackBar(content: Text(l10n.blocked)));
              },
              icon: const Icon(Icons.block),
              label: Text(l10n.blockReporter),
            ),
          if (isAuthor)
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              onPressed: () => _delete(context, ref),
              icon: const Icon(Icons.delete_outline),
              label: Text(l10n.deleteReport),
            ),
        ],
      ),
    );
  }
}
