import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixburgh/app/router.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Whether [user] has a full account rather than a guest session.
bool hasFullAccount(User? user) => user != null && !user.isAnonymous;

/// Lets a feature that needs an account (societies, channels, services)
/// go ahead. Guests get a "Sign in to continue" sheet; signing in there
/// upgrades the guest through [AuthRepository], so their reports carry over.
/// Completes with true once the person has a full account.
///
/// [signIn] opens the sign-in flow and completes when it closes; it
/// defaults to the sign-in screen.
Future<bool> requireFullAccount(
  BuildContext context,
  WidgetRef ref, {
  Future<void> Function()? signIn,
}) async {
  final repo = ref.read(authRepositoryProvider);
  if (hasFullAccount(repo.currentUser)) return true;
  final go = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (_) => const AccountGateSheet(),
  );
  if (go != true || !context.mounted) return false;
  await (signIn ?? () => context.push<void>(Routes.signIn))();
  return hasFullAccount(repo.currentUser);
}

/// The "Sign in to continue" sheet. Pops true when the person chooses to
/// sign in.
class AccountGateSheet extends StatelessWidget {
  const AccountGateSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.accountGateTitle,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.accountGateBody,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.accountGateSignIn),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.accountGateNotNow),
            ),
          ],
        ),
      ),
    );
  }
}
