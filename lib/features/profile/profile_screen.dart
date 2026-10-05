import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/auth/sign_in_screen.dart';
import 'package:fixburgh/features/moderation/blocked_users.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAccountTitle),
        content: Text(l10n.deleteAccountBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      messenger.showSnackBar(SnackBar(content: Text(l10n.accountDeleted)));
    } on AuthException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(authFailureMessage(l10n, e.failure))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final user = ref.watch(authUserProvider).value;
    final isGuest = user == null || user.isAnonymous;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isGuest
                        ? l10n.profileGuest
                        : l10n.profileSignedInAs(
                            user.email ?? user.displayName ?? '',
                          ),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (isGuest) Text(l10n.profileGuestBody),
                  if (!isGuest && user.email != null && !user.emailVerified)
                    Text(l10n.profileEmailUnverified),
                  const SizedBox(height: 16),
                  if (isGuest)
                    FilledButton(
                      onPressed: () => context.push('/sign-in'),
                      child: Text(l10n.signIn),
                    )
                  else
                    OutlinedButton(
                      onPressed: () =>
                          ref.read(authRepositoryProvider).signOut(),
                      child: Text(l10n.signOut),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.emergency_outlined),
            title: Text(l10n.notForEmergencies),
          ),
          if (ref.watch(blockedUsersProvider).isNotEmpty)
            ListTile(
              leading: const Icon(Icons.block),
              title: Text(
                l10n.blockedCount(ref.watch(blockedUsersProvider).length),
              ),
              trailing: TextButton(
                onPressed: () =>
                    ref.read(blockedUsersProvider.notifier).unblockAll(),
                child: Text(l10n.unblockAll),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: Text(l10n.dataSources),
            subtitle: Text(l10n.dataSourcesBody),
          ),
          if (!isGuest)
            ListTile(
              leading: Icon(
                Icons.delete_forever_outlined,
                color: theme.colorScheme.error,
              ),
              title: Text(
                l10n.deleteAccount,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () => _confirmDelete(context, ref),
            ),
        ],
      ),
    );
  }
}
