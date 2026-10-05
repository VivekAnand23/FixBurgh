import 'package:fixburgh/features/report/domain/report.dart';
import 'package:fixburgh/features/report/presentation/report_draft_controller.dart';
import 'package:fixburgh/features/report/presentation/report_labels.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DetailsStep extends ConsumerStatefulWidget {
  const DetailsStep({required this.onNext, super.key});

  final VoidCallback onNext;

  @override
  ConsumerState<DetailsStep> createState() => _DetailsStepState();
}

class _DetailsStepState extends ConsumerState<DetailsStep> {
  late final _description = TextEditingController(
    text: ref.read(reportDraftProvider).description,
  );

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final draft = ref.watch(reportDraftProvider);
    final notifier = ref.read(reportDraftProvider.notifier);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(l10n.whatIsIt, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.85,
          children: [
            for (final c in ReportCategory.values)
              _CategoryTile(
                category: c,
                selected: draft.category == c,
                onTap: () => notifier.setCategory(c),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text(l10n.howBad, style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        SegmentedButton<Severity>(
          segments: [
            for (final s in Severity.values)
              ButtonSegment(value: s, label: Text(s.label(l10n))),
          ],
          selected: {draft.severity},
          onSelectionChanged: (s) => notifier.setSeverity(s.first),
          showSelectedIcon: false,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _description,
          maxLength: maxDescriptionLength,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.describeIt,
            hintText: l10n.describeHint,
          ),
          onChanged: notifier.setDescription,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: draft.category != null ? widget.onNext : null,
          child: Text(l10n.next),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final ReportCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? scheme.secondaryContainer
            : scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? scheme.secondary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(category.icon, size: 28),
                const SizedBox(height: 4),
                Text(
                  category.label(l10n),
                  style: Theme.of(context).textTheme.labelSmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
