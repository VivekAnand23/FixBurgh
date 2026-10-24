import 'dart:async';

import 'package:fixburgh/app/remote_config.dart';
import 'package:fixburgh/app/widgets/placeholder_view.dart';
import 'package:fixburgh/features/auth/account_gate.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Society tab. Shows "Coming soon" until the `feature_society` Remote
/// Config flag turns on (Burghood Phase 1).
class SocietyScreen extends ConsumerWidget {
  const SocietyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final enabled = ref.watch(featureFlagsProvider).society;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.societyTitle)),
      body: enabled
          // Phase 1 replaces this with society search and the society home.
          ? PlaceholderBody(
              icon: Icons.apartment,
              message: l10n.societyFindBody,
            )
          : const _ComingSoon(),
    );
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
