import 'dart:async';

import 'package:fixburgh/app/links.dart';
import 'package:fixburgh/app/providers.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/auth/sign_in_screen.dart';
import 'package:fixburgh/features/moderation/blocked_users.dart';
import 'package:fixburgh/features/profile/settings_controller.dart';
import 'package:fixburgh/features/report/data/draft_store.dart';
import 'package:fixburgh/features/report/data/report_repository.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Profile: account, settings and About (BRD FR-PRF-01 to 04).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  /// Personal data kept on the device goes when the person signs out or
  /// deletes their account (BRD FR-AUTH-04).
  static Future<void> _clearLocalData(WidgetRef ref) async {
    await ref.read(draftStoreProvider).clear();
    await ref.read(blockedUsersProvider.notifier).unblockAll();
  }

  Future<void> _signOut(WidgetRef ref) async {
    await ref.read(authRepositoryProvider).signOut();
    await _clearLocalData(ref);
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final choice = await showDialog<ReportsOnDelete>(
      context: context,
      builder: (_) => const DeleteAccountDialog(),
    );
    if (choice == null || !context.mounted) return;
    final repo = ref.read(authRepositoryProvider);
    final nav = Navigator.of(context, rootNavigator: true);
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 24),
                Expanded(child: Text(l10n.deletingAccount)),
              ],
            ),
          ),
        ),
      ),
    );
    var progressShown = true;
    void closeProgress() {
      if (progressShown) nav.pop();
      progressShown = false;
    }

    try {
      try {
        await repo.deleteAccount(choice);
      } on AuthException catch (e) {
        if (e.failure != AuthFailure.requiresRecentLogin) rethrow;
        // Confirm who they are, then try once more (BRD FR-AUTH-05).
        closeProgress();
        if (!context.mounted) return;
        String? password;
        if (repo.signInMethod == 'password') {
          password = await _askPassword(context);
          if (password == null) return;
        }
        await repo.reauthenticate(password: password);
        await repo.deleteAccount(choice);
      }
      closeProgress();
      await _clearLocalData(ref);
      messenger.showSnackBar(SnackBar(content: Text(l10n.accountDeleted)));
    } on AuthException catch (e) {
      closeProgress();
      final message = authFailureMessage(l10n, e.failure);
      if (message.isNotEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  static Future<String?> _askPassword(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmPasswordTitle),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(labelText: l10n.password),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.continueLabel),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  static Future<void> _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);

  static String _methodLabel(AppLocalizations l10n, String method) =>
      switch (method) {
        'google.com' => l10n.methodGoogle,
        'apple.com' => l10n.methodApple,
        _ => l10n.methodEmail,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final user = ref.watch(authUserProvider).value;
    final isGuest = user == null || user.isAnonymous;
    final mine = ref.watch(myReportsProvider).value ?? const [];
    final open = mine.where((r) => r.isOpen).length;
    final settings = ref.watch(settingsProvider);
    final settingsCtl = ref.read(settingsProvider.notifier);
    final blocked = ref.watch(blockedUsersProvider);
    final links = AppLinks(ref.watch(flavorProvider));
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
                  if (!isGuest)
                    Text(
                      l10n.signedInWith(
                        _methodLabel(
                          l10n,
                          ref.read(authRepositoryProvider).signInMethod,
                        ),
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.reportCounts(mine.length, open, mine.length - open),
                  ),
                  if (isGuest) ...[
                    const SizedBox(height: 8),
                    Text(l10n.profileGuestBody),
                  ],
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
                      onPressed: () => _signOut(ref),
                      child: Text(l10n.signOut),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Heading(l10n.settingsTitle),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: Text(l10n.themeTitle),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(l10n.themeSystem),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(l10n.themeLight),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(l10n.themeDark),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => settingsCtl.setThemeMode(s.first),
              showSelectedIcon: false,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.format_size),
            title: Text(l10n.textSizeTitle),
            subtitle: Text(l10n.textSizeBody),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<TextSize>(
              segments: [
                ButtonSegment(
                  value: TextSize.system,
                  label: Text(l10n.textSizeSystem),
                ),
                ButtonSegment(
                  value: TextSize.large,
                  label: Text(l10n.textSizeLarge),
                ),
                ButtonSegment(
                  value: TextSize.larger,
                  label: Text(l10n.textSizeLarger),
                ),
              ],
              selected: {settings.textSize},
              onSelectionChanged: (s) => settingsCtl.setTextSize(s.first),
              showSelectedIcon: false,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              color: theme.colorScheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  l10n.textSizePreview,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
          ),
          if (blocked.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.block),
              title: Text(l10n.blockedCount(blocked.length)),
              trailing: TextButton(
                onPressed: () =>
                    ref.read(blockedUsersProvider.notifier).unblockAll(),
                child: Text(l10n.unblockAll),
              ),
            ),
          const SizedBox(height: 16),
          _Heading(l10n.aboutTitle),
          ListTile(
            leading: Icon(
              Icons.emergency_outlined,
              color: theme.colorScheme.error,
            ),
            title: Text(l10n.notForEmergencies),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.privacyPolicy),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _open(links.privacy),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: Text(l10n.termsOfUse),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _open(links.terms),
          ),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: Text(l10n.dataSources),
            subtitle: Text(l10n.dataSourcesShort),
            onTap: () => context.push('/data-sources'),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: Text(l10n.openSourceLicenses),
            onTap: () => showLicensePage(
              context: context,
              applicationName: l10n.appTitle,
              applicationLegalese: l10n.notForEmergencies,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: Text(l10n.contactSupport),
            subtitle: const Text(AppLinks.supportEmail),
            onTap: () => launchUrl(
              Uri(
                scheme: 'mailto',
                path: AppLinks.supportEmail,
                query: 'subject=${Uri.encodeComponent(l10n.appTitle)}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: theme.colorScheme.error,
            ),
            title: Text(
              l10n.deleteAccount,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () => _deleteAccount(context, ref),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ),
  );
}

/// Confirms deletion and asks what to do with the reports (BRD journey
/// 6.5; default: keep them on the map without the account).
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  ReportsOnDelete _choice = ReportsOnDelete.anonymize;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(l10n.deleteAccountTitle),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.deleteAccountBody),
          const SizedBox(height: 16),
          Text(
            l10n.deleteAccountReportsQuestion,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          RadioGroup<ReportsOnDelete>(
            groupValue: _choice,
            onChanged: (v) => setState(() => _choice = v ?? _choice),
            child: Column(
              children: [
                RadioListTile(
                  contentPadding: EdgeInsets.zero,
                  value: ReportsOnDelete.anonymize,
                  title: Text(l10n.deleteKeepReports),
                  subtitle: Text(l10n.deleteKeepReportsBody),
                ),
                RadioListTile(
                  contentPadding: EdgeInsets.zero,
                  value: ReportsOnDelete.delete,
                  title: Text(l10n.deleteRemoveReports),
                  subtitle: Text(l10n.deleteRemoveReportsBody),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        // Filled so the red keeps 4.5:1 on the dialog's tinted surface.
        FilledButton(
          onPressed: () => Navigator.pop(context, _choice),
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          child: Text(l10n.delete),
        ),
      ],
    );
  }
}
