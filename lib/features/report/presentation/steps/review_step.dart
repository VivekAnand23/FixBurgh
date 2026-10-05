import 'dart:io';

import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/moderation/text_filter.dart';
import 'package:fixburgh/features/report/data/report_repository.dart';
import 'package:fixburgh/features/report/domain/report.dart';
import 'package:fixburgh/features/report/presentation/report_draft_controller.dart';
import 'package:fixburgh/features/report/presentation/report_labels.dart';
import 'package:fixburgh/features/routing/data/routing_providers.dart';
import 'package:fixburgh/features/routing/domain/routing_engine.dart';
import 'package:fixburgh/features/routing/presentation/office_card.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Step indexes used by the Edit links.
const _photoStep = 1;
const _locationStep = 2;
const _detailsStep = 3;

class ReviewStep extends ConsumerStatefulWidget {
  const ReviewStep({
    required this.onEditStep,
    required this.onSubmitted,
    super.key,
  });

  final ValueChanged<int> onEditStep;
  final VoidCallback onSubmitted;

  @override
  ConsumerState<ReviewStep> createState() => _ReviewStepState();
}

class _ReviewStepState extends ConsumerState<ReviewStep> {
  double? _progress;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final auth = ref.read(authRepositoryProvider);
    setState(() => _progress = 0);
    try {
      await auth.ensureGuest();
      final user = auth.currentUser!;
      final draft = ref.read(reportDraftProvider);
      final repo = ref.read(reportRepositoryProvider);

      // Offer "Me too" instead of a duplicate (BRD FR-MAP-08).
      final dupes = await repo
          .nearbyDuplicates(draft.location!, draft.category!)
          .catchError((Object _) => <Report>[]);
      final others = dupes.where((r) => r.authorUid != user.uid).toList();
      if (others.isNotEmpty && mounted) {
        final existing = others.first;
        final choice = await _askDuplicate(existing, draft);
        if (choice == null) return; // Dismissed: stay on review.
        if (choice) {
          await repo.setUpvote(existing.id, user.uid, on: true);
          ref.invalidate(reportDraftProvider);
          widget.onSubmitted();
          messenger.showSnackBar(SnackBar(content: Text(l10n.meTooAdded)));
          router.go('/map');
          return;
        }
      }

      final routing = await ref.read(draftRoutingProvider.future);
      final reportId = await repo.submit(
        draft: draft,
        uid: user.uid,
        isGuest: user.isAnonymous,
        routing: routing,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (routing != null && mounted) {
        await showContactSheet(
          context,
          routing: routing,
          summary: _summary(l10n, draft),
          subject: _subject(l10n, draft),
          onContacted: (c) => repo.markSent(reportId, c.name),
        );
      }
      ref.invalidate(reportDraftProvider);
      widget.onSubmitted();
      messenger.showSnackBar(SnackBar(content: Text(l10n.reportSubmitted)));
      router.go('/my-reports');
    } on DailyLimitReached catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.isGuest
                ? l10n.guestLimitReached(guestDailyLimit)
                : l10n.userLimitReached(userDailyLimit),
          ),
        ),
      );
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l10n.submitFailed)));
    } finally {
      if (mounted) setState(() => _progress = null);
    }
  }

  /// True = "Me too", false = "This is different", null = dismissed.
  Future<bool?> _askDuplicate(Report existing, ReportDraft draft) {
    final l10n = AppLocalizations.of(context);
    final meters = distanceM(draft.location!, existing.location).round();
    final days = DateTime.now().difference(existing.createdAt).inDays;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.groups_outlined),
        title: Text(l10n.duplicateTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.duplicateBody(
                existing.category.label(l10n),
                meters,
                days,
                existing.upvoteCount,
              ),
            ),
            if (existing.thumbUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  existing.thumbUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.thisIsDifferent),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.meTooShort),
          ),
        ],
      ),
    );
  }

  static String _summary(AppLocalizations l10n, ReportDraft d) => reportSummary(
    l10n,
    category: d.category!,
    severity: d.severity,
    location: d.location!,
    address: d.address,
    description: d.description,
  );

  static String _subject(AppLocalizations l10n, ReportDraft d) =>
      l10n.emailSubject(
        d.category!.label(l10n),
        d.severity.label(l10n),
        d.address ?? d.municipality?.name ?? '',
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final d = ref.watch(reportDraftProvider);
    final routing = ref.watch(draftRoutingProvider);
    final busy = _progress != null;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(l10n.reviewTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        _Section(
          title: l10n.photos,
          onEdit: busy ? null : () => widget.onEditStep(_photoStep),
          child: Wrap(
            spacing: 8,
            children: [
              for (final p in d.photoPaths)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(p),
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                ),
            ],
          ),
        ),
        _Section(
          title: l10n.location,
          onEdit: busy ? null : () => widget.onEditStep(_locationStep),
          child: Text(
            [
              if (d.address != null) d.address!,
              if (d.municipality != null)
                l10n.inMunicipality(d.municipality!.name),
            ].join('\n'),
          ),
        ),
        _Section(
          title: l10n.details,
          onEdit: busy ? null : () => widget.onEditStep(_detailsStep),
          child: Text(
            [
              '${d.category?.label(l10n) ?? ''} · ${d.severity.label(l10n)}',
              if (d.description.trim().isNotEmpty)
                cleanUserText(d.description.trim()),
            ].join('\n'),
          ),
        ),
        Text(l10n.whoFixesThis, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        switch (routing) {
          AsyncData(:final value?) => OfficeCard(
            result: value,
            summary: _summary(l10n, d),
            showActions: false,
          ),
          AsyncLoading() => const Center(child: CircularProgressIndicator()),
          _ => Text(l10n.routingUnavailable),
        },
        const SizedBox(height: 8),
        Card(
          color: theme.colorScheme.secondaryContainer,
          child: ListTile(
            leading: const Icon(Icons.groups_outlined),
            title: Text(l10n.reviewPublicNote),
          ),
        ),
        const SizedBox(height: 24),
        if (busy) ...[
          LinearProgressIndicator(value: _progress),
          const SizedBox(height: 12),
        ],
        FilledButton(
          onPressed: busy || !d.isComplete ? null : _submit,
          child: Text(busy ? l10n.submitting : l10n.submitReport),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.onEdit});

  final String title;
  final Widget child;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: onEdit,
                child: Text(l10n.edit, semanticsLabel: l10n.editSection(title)),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}

/// After submitting: "Now tell them" with the office's contact buttons.
Future<void> showContactSheet(
  BuildContext context, {
  required RoutingResult routing,
  required String summary,
  required ValueChanged<ContactChannel> onContacted,
  String? subject,
}) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<void>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.nowTellThem,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(l10n.nowTellThemBody),
            const SizedBox(height: 12),
            OfficeCard(
              result: routing,
              summary: summary,
              subject: subject,
              onContacted: (c) {
                onContacted(c);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.later),
            ),
          ],
        ),
      ),
    ),
  );
}
