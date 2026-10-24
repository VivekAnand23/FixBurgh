import 'package:fixburgh/app/router.dart';
import 'package:fixburgh/app/theme/app_colors.dart';
import 'package:fixburgh/features/society/data/society_repository.dart';
import 'package:fixburgh/features/society/domain/society.dart';
import 'package:fixburgh/features/society/presentation/society_widgets.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// One of the person's claims on Find your society.
class ClaimCard extends StatelessWidget {
  const ClaimCard({required this.claim, super.key});

  final SocietyClaim claim;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (icon, color, title) = _status(context, claim);
    return SocietyCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(
          switch (claim.status) {
            ClaimStatus.pending => l10n.claimPendingBody,
            ClaimStatus.approved => l10n.claimApprovedBody,
            ClaimStatus.rejected => l10n.claimRejectedBody,
          },
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(Routes.claim(claim.id)),
      ),
    );
  }
}

(IconData, Color, String) _status(BuildContext context, SocietyClaim c) {
  final l10n = AppLocalizations.of(context);
  final scheme = Theme.of(context).colorScheme;
  return switch (c.status) {
    ClaimStatus.pending => (
      Icons.hourglass_top,
      scheme.primary,
      l10n.claimPendingTitle(c.societyName),
    ),
    ClaimStatus.approved => (
      Icons.verified,
      AppColors.teal700,
      l10n.claimApprovedTitle(c.societyName),
    ),
    ClaimStatus.rejected => (
      Icons.error_outline,
      scheme.error,
      l10n.claimRejectedTitle(c.societyName),
    ),
  };
}

/// A claim's progress: submitted, under review, decided (with the reason
/// when rejected, and a way to resubmit).
class ClaimStatusScreen extends ConsumerWidget {
  const ClaimStatusScreen({required this.claimId, super.key});

  final String claimId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final claim = ref
        .watch(myClaimsProvider)
        .value
        ?.where((c) => c.id == claimId)
        .firstOrNull;
    if (claim == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.claimTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final date = DateFormat.yMMMd();
    final (icon, color, title) = _status(context, claim);
    final decided = claim.status != ClaimStatus.pending;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.claimTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
            ],
          ),
          const SizedBox(height: 4),
          Text(claim.address, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          _Step(
            done: true,
            title: l10n.claimStepSubmitted,
            detail: claim.createdAt == null
                ? ''
                : date.format(claim.createdAt!),
          ),
          _Step(
            done: decided,
            current: !decided,
            title: l10n.claimStepReview,
            detail: decided ? '' : l10n.claimStepReviewBody,
          ),
          _Step(
            done: decided,
            last: true,
            title: switch (claim.status) {
              ClaimStatus.approved => l10n.claimStepApproved,
              ClaimStatus.rejected => l10n.claimStepRejected,
              ClaimStatus.pending => l10n.claimStepDecision,
            },
            detail: claim.decidedAt == null
                ? ''
                : date.format(claim.decidedAt!),
          ),
          if (claim.status == ClaimStatus.rejected) ...[
            const SizedBox(height: 16),
            SocietyCard(
              borderColor: theme.colorScheme.error,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.claimReason,
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(claim.reason),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.push(Routes.createSociety, extra: claim),
              child: Text(l10n.resubmit),
            ),
          ],
          if (claim.status == ClaimStatus.approved &&
              claim.societyId != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                ref
                    .read(selectedSocietyProvider.notifier)
                    .select(claim.societyId!);
                context.go(Routes.society);
              },
              child: Text(l10n.openSociety),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            l10n.claimFilesNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.done,
    required this.title,
    required this.detail,
    this.current = false,
    this.last = false,
  });

  final bool done;
  final bool current;
  final bool last;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = done || current ? scheme.primary : scheme.outline;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: color,
              ),
              if (!last)
                Expanded(
                  child: Container(width: 2, color: scheme.outlineVariant),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (detail.isNotEmpty) Text(detail),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
