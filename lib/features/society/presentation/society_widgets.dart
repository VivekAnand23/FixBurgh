import 'package:fixburgh/app/theme/app_colors.dart';
import 'package:fixburgh/features/society/data/society_repository.dart';
import 'package:fixburgh/features/society/domain/society.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

bool _dark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

/// White card with a thin border and 16 px corners, as in the mocks.
class SocietyCard extends StatelessWidget {
  const SocietyCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color:
            color ?? (_dark(context) ? scheme.surfaceContainer : Colors.white),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(
          color:
              borderColor ??
              (_dark(context) ? scheme.outlineVariant : AppColors.cardBorder),
        ),
      ),
      child: child,
    );
  }
}

/// Teal-tinted box for what someone needs before they start.
class InfoBox extends StatelessWidget {
  const InfoBox({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = _dark(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? scheme.tertiaryContainer : AppColors.tealTint,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: dark ? scheme.tertiary : AppColors.teal),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: dark ? scheme.onTertiaryContainer : AppColors.teal700,
        ),
      ),
    );
  }
}

/// Round avatar with a society's initials.
class SocietyAvatar extends StatelessWidget {
  const SocietyAvatar({
    required this.society,
    this.highlight = false,
    super.key,
  });

  final Society society;

  /// Teal for the best match, navy otherwise.
  final bool highlight;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 22,
    backgroundColor: highlight ? AppColors.teal700 : AppColors.navy,
    foregroundColor: Colors.white,
    child: Text(
      society.initials,
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
  );
}

/// "✓ Verified" in teal.
class VerifiedLabel extends StatelessWidget {
  const VerifiedLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final color = _dark(context)
        ? Theme.of(context).colorScheme.tertiary
        : AppColors.teal700;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          AppLocalizations.of(context).verified,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// "1200 Maple Ct · 84 homes · 60 m away".
String societySummary(AppLocalizations l10n, Society s, {double? distanceM}) =>
    [
      if (s.address.isNotEmpty) s.address.split(',').first,
      l10n.homesCount(s.units),
      if (distanceM != null) l10n.distanceAway(formatDistance(distanceM)),
    ].join(' · ');

/// Metres under 1 km ("60 m"), else kilometres ("1.2 km").
String formatDistance(double m) => m < 1000
    ? '${(m / 10).round() * 10} m'
    : '${(m / 1000).toStringAsFixed(1)} km';

/// Opens a member-only file (a document or notice attachment) in the
/// in-app browser.
Future<void> openSocietyFile(
  BuildContext context,
  WidgetRef ref,
  String path,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  try {
    final url = await ref.read(societyRepositoryProvider).fileUrl(path);
    await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
  } on Exception {
    messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
  }
}

/// Opens an HOA link in the in-app browser.
Future<void> openLink(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final ok = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.inAppBrowserView,
  ).catchError((_) => false);
  if (!ok) messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
}

/// Display labels for enums.
extension SocietyLabels on AppLocalizations {
  String position(ClaimPosition p) => switch (p) {
    ClaimPosition.president => positionPresident,
    ClaimPosition.secretary => positionSecretary,
    ClaimPosition.boardMember => positionBoardMember,
    ClaimPosition.manager => positionManager,
  };

  String role(MemberRole r) => switch (r) {
    MemberRole.member => roleMember,
    MemberRole.committee => roleCommittee,
    MemberRole.admin => roleAdmin,
  };

  String docCategory(DocumentCategory c) => switch (c) {
    DocumentCategory.bylaws => docBylaws,
    DocumentCategory.minutes => docMinutes,
    DocumentCategory.budget => docBudget,
    DocumentCategory.rules => docRules,
    DocumentCategory.other => docOther,
  };
}
