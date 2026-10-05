import 'dart:io';

import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/report/data/report_repository.dart';
import 'package:fixburgh/features/report/presentation/report_draft_controller.dart';
import 'package:fixburgh/features/report/presentation/report_labels.dart';
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
      await ref
          .read(reportRepositoryProvider)
          .submit(
            draft: ref.read(reportDraftProvider),
            uid: user.uid,
            isGuest: user.isAnonymous,
            onProgress: (p) {
              if (mounted) setState(() => _progress = p);
            },
          );
      ref.invalidate(reportDraftProvider);
      widget.onSubmitted();
      messenger.showSnackBar(SnackBar(content: Text(l10n.reportSubmitted)));
      router.go('/my-reports');
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l10n.submitFailed)));
    } finally {
      if (mounted) setState(() => _progress = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final d = ref.watch(reportDraftProvider);
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
              if (d.description.trim().isNotEmpty) d.description.trim(),
            ].join('\n'),
          ),
        ),
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
