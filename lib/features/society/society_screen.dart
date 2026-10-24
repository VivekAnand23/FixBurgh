import 'dart:async';

import 'package:fixburgh/app/remote_config.dart';
import 'package:fixburgh/app/widgets/placeholder_view.dart';
import 'package:fixburgh/features/auth/account_gate.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/society/data/society_repository.dart';
import 'package:fixburgh/features/society/presentation/find_society_view.dart';
import 'package:fixburgh/features/society/presentation/society_home.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Society tab. "Coming soon" while the `feature_society` Remote Config
/// flag is off; otherwise the society home for members, or Find your
/// society for everyone else. Societies need a full account.
class SocietyScreen extends ConsumerWidget {
  const SocietyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (!ref.watch(featureFlagsProvider).society) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.societyTitle)),
        body: const _ComingSoon(),
      );
    }
    if (!hasFullAccount(ref.watch(authUserProvider).value)) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.findSocietyTitle)),
        body: PlaceholderBody(
          icon: Icons.apartment,
          title: l10n.societySignInTitle,
          message: l10n.societySignInBody,
          action: FilledButton.icon(
            icon: const Icon(Icons.login),
            label: Text(l10n.societySignInToJoin),
            onPressed: () => unawaited(requireFullAccount(context, ref)),
          ),
        ),
      );
    }
    final ids = ref.watch(mySocietyIdsProvider);
    final current = ref.watch(currentSocietyIdProvider);
    if (ids.isLoading && !ids.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return current == null
        ? const FindSocietyView()
        : SocietyHome(societyId: current);
  }
}

class _ComingSoon extends ConsumerWidget {
  const _ComingSoon();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final signedIn = hasFullAccount(ref.watch(authUserProvider).value);
    return PlaceholderBody(
      icon: Icons.apartment,
      title: l10n.comingSoon,
      message: l10n.societyComingSoonBody,
      action: signedIn
          ? Text(
              l10n.societySignedInNote,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          : FilledButton.icon(
              icon: const Icon(Icons.login),
              label: Text(l10n.societySignInToJoin),
              onPressed: () => unawaited(requireFullAccount(context, ref)),
            ),
    );
  }
}
