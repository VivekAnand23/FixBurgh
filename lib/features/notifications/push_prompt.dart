import 'package:fixburgh/app/remote_config.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/notifications/push_service.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// After someone's first report (never at first launch), explains what
/// notifications are for before the system asks (BRD FR-NTF-01).
Future<void> maybeAskForNotifications(
  BuildContext context,
  WidgetRef ref,
) async {
  if (!ref.read(featureFlagsProvider).push) return;
  final push = ref.read(pushServiceProvider);
  try {
    if (push.rationaleShown || await push.isAllowed) return;
  } on Object {
    return; // No Firebase Messaging (tests).
  }
  await push.markRationaleShown();
  if (!context.mounted) return;
  final allow = await showModalBottomSheet<bool>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const NotificationRationale(),
  );
  if (allow != true) return;
  await enableNotifications(ref);
}

/// Shows the system prompt and, if allowed, registers this device.
Future<bool> enableNotifications(WidgetRef ref) async {
  final push = ref.read(pushServiceProvider);
  if (!await push.requestPermission()) return false;
  final uid = ref.read(authRepositoryProvider).currentUser?.uid;
  if (uid != null) await push.register(uid);
  return true;
}

class NotificationRationale extends StatelessWidget {
  const NotificationRationale({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.notifications_active_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.pushRationaleTitle,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(l10n.pushRationaleBody, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.pushRationaleAllow),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.notNow),
            ),
          ],
        ),
      ),
    );
  }
}
