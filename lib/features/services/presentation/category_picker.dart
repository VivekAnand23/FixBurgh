import 'package:fixburgh/features/services/domain/service_category.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// A sheet listing every category under its group. Returns the id picked.
Future<String?> pickServiceCategory(
  BuildContext context,
  List<ServiceCategoryGroup> groups,
) => showModalBottomSheet<String>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (sheet) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.7,
    builder: (_, scroll) => ListView(
      controller: scroll,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            AppLocalizations.of(sheet).chooseCategory,
            style: Theme.of(sheet).textTheme.titleLarge,
          ),
        ),
        for (final g in groups) ...[
          _GroupHeader(label: g.label),
          for (final c in g.categories)
            ListTile(
              title: Text(c.label),
              onTap: () => Navigator.pop(sheet, c.id),
            ),
        ],
      ],
    ),
  ),
);

/// Checkboxes for every category under its group, for a provider's
/// application.
class CategoryChecklist extends StatelessWidget {
  const CategoryChecklist({
    required this.groups,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<ServiceCategoryGroup> groups;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final g in groups) ...[
        _GroupHeader(label: g.label, note: g.approvalCheck, inset: 0),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final c in g.categories)
              FilterChip(
                key: Key('cat-${c.id}'),
                label: Text(c.label),
                selected: selected.contains(c.id),
                onSelected: (on) => onChanged(
                  on ? {...selected, c.id} : ({...selected}..remove(c.id)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    ],
  );
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label, this.note, this.inset = 16});

  final String label;
  final String? note;
  final double inset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(inset, 16, inset, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (note != null)
            Text(
              note!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
