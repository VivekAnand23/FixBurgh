import 'package:fixburgh/app/theme/app_colors.dart';
import 'package:fixburgh/features/providers/domain/provider.dart';
import 'package:fixburgh/features/services/domain/service_category.dart';
import 'package:fixburgh/features/services/domain/service_request.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

String requestStatusLabel(AppLocalizations l10n, RequestStatus s) =>
    switch (s) {
      RequestStatus.posted => l10n.srPosted,
      RequestStatus.assigned => l10n.srAssigned,
      RequestStatus.accepted => l10n.srAccepted,
      RequestStatus.declined => l10n.srDeclined,
      RequestStatus.inProgress => l10n.srInProgress,
      RequestStatus.completed => l10n.srCompleted,
      RequestStatus.notFixed => l10n.srNotFixed,
      RequestStatus.confirmed => l10n.srConfirmed,
      RequestStatus.closed => l10n.srClosed,
      RequestStatus.cancelled => l10n.srCancelled,
    };

/// A request's status as a small coloured chip.
class RequestStatusChip extends StatelessWidget {
  const RequestStatusChip({required this.status, super.key});

  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      RequestStatus.confirmed || RequestStatus.closed => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      RequestStatus.cancelled || RequestStatus.declined => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      RequestStatus.notFixed => (
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      _ => (scheme.primaryContainer, scheme.onPrimaryContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
      ),
      child: Text(
        requestStatusLabel(AppLocalizations.of(context), status),
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

/// Stars with the average and count, e.g. ★ 4.8 (200).
class RatingLine extends StatelessWidget {
  const RatingLine({required this.provider, super.key});

  final ServiceProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = provider;
    final label = p.ratingCount == 0
        ? l10n.noReviewsYet
        : l10n.ratingSummary(p.ratingAvg.toStringAsFixed(1), p.ratingCount);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 18, color: Colors.amber.shade700),
          const SizedBox(width: 2),
          Text(
            p.ratingCount == 0
                ? l10n.noReviewsYet
                : '${p.ratingAvg.toStringAsFixed(1)} (${p.ratingCount})',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// "Recommended by your society" and "Background checked".
class ProviderBadges extends StatelessWidget {
  const ProviderBadges({
    required this.provider,
    this.recommended = false,
    super.key,
  });

  final ServiceProvider provider;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!recommended && !provider.backgroundChecked) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (recommended)
          _Badge(
            icon: Icons.thumb_up_alt_outlined,
            text: l10n.recommendedBySociety,
            color: AppColors.teal,
          ),
        if (provider.backgroundChecked)
          _Badge(
            icon: Icons.verified_user_outlined,
            text: l10n.backgroundChecked,
            color: Colors.green.shade700,
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      border: Border.all(color: color),
      borderRadius: const BorderRadius.all(Radius.circular(999)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Labels of a provider's categories, e.g. "Plumbing · Handyman".
String categoryLabels(
  Iterable<String> ids,
  List<ServiceCategoryGroup> groups,
) => [for (final id in ids) groups.category(id)?.label ?? id].join(' · ');

/// Picks 1 to 5 stars.
class StarPicker extends StatelessWidget {
  const StarPicker({required this.value, required this.onChanged, super.key});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            tooltip: l10n.starsLabel(i),
            iconSize: 36,
            isSelected: i <= value,
            icon: const Icon(Icons.star_outline_rounded),
            selectedIcon: Icon(
              Icons.star_rounded,
              color: Colors.amber.shade700,
            ),
            onPressed: () => onChanged(i),
          ),
      ],
    );
  }
}
