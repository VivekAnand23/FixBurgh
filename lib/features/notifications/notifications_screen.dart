import 'dart:async';

import 'package:fixburgh/app/remote_config.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/notifications/notification_settings.dart';
import 'package:fixburgh/features/notifications/push_prompt.dart';
import 'package:fixburgh/features/notifications/push_service.dart';
import 'package:fixburgh/features/society/presentation/muted_channels.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Profile > Notifications: what to hear about, quiet hours and saved
/// places (BRD FR-NTF-03, 05).
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool? _allowed;

  @override
  void initState() {
    super.initState();
    unawaited(_checkPermission());
  }

  Future<void> _checkPermission() async {
    bool allowed;
    try {
      allowed = await ref.read(pushServiceProvider).isAllowed;
    } on Object {
      allowed = false;
    }
    if (mounted) setState(() => _allowed = allowed);
  }

  Future<void> _save(NotifySettings s) async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return;
    await ref.read(notificationsRepositoryProvider).saveSettings(uid, s);
  }

  Future<void> _pickTime(NotifySettings s, {required bool start}) async {
    final minutes = start ? s.quietStart : s.quietEnd;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (picked == null) return;
    final m = picked.hour * 60 + picked.minute;
    await _save(start ? s.copyWith(quietStart: m) : s.copyWith(quietEnd: m));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final flags = ref.watch(featureFlagsProvider);
    final s = ref.watch(notifySettingsProvider).value ?? const NotifySettings();
    final messenger = ScaffoldMessenger.of(context);
    String time(int m) =>
        TimeOfDay(hour: m ~/ 60, minute: m % 60).format(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (_allowed == false)
            Card(
              margin: const EdgeInsets.all(16),
              color: theme.colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.pushOffBody),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () async {
                        final ok = await enableNotifications(ref);
                        if (!ok) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(l10n.pushBlocked)),
                          );
                        }
                        await _checkPermission();
                      },
                      child: Text(l10n.pushRationaleAllow),
                    ),
                  ],
                ),
              ),
            ),
          SwitchListTile(
            secondary: const Icon(Icons.update),
            title: Text(l10n.notifyStatus),
            subtitle: Text(l10n.notifyStatusBody),
            value: s.status,
            onChanged: (v) => _save(s.copyWith(status: v)),
          ),
          if (flags.savedPlaces) ...[
            SwitchListTile(
              secondary: const Icon(Icons.warning_amber_rounded),
              title: Text(l10n.notifyNearby),
              subtitle: Text(l10n.notifyNearbyBody),
              value: s.nearby,
              onChanged: (v) => _save(s.copyWith(nearby: v)),
            ),
            ListTile(
              leading: const Icon(Icons.place_outlined),
              title: Text(l10n.savedPlacesTitle),
              subtitle: Text(l10n.savedPlacesBody),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/saved-places'),
            ),
          ],
          if (flags.society && flags.channels) ...[
            const Divider(),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.primaryContainer,
              child: SwitchListTile(
                secondary: const Icon(Icons.forum_outlined),
                title: Text(
                  l10n.notifyInteractions,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(l10n.notifyInteractionsBody),
                value: s.interactions,
                onChanged: (v) => _save(s.copyWith(interactions: v)),
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.alternate_email),
              title: Text(l10n.notifyMentions),
              subtitle: Text(l10n.notifyMentionsBody),
              value: s.interactions && s.mentions,
              onChanged: s.interactions
                  ? (v) => _save(s.copyWith(mentions: v))
                  : null,
            ),
          ],
          if (flags.society)
            SwitchListTile(
              secondary: const Icon(Icons.campaign_outlined),
              title: Text(l10n.notifyNotices),
              subtitle: Text(l10n.notifyNoticesBody),
              value: s.notices,
              onChanged: (v) => _save(s.copyWith(notices: v)),
            ),
          if (flags.society && flags.channels) const MutedChannelsList(),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.bedtime_outlined),
            title: Text(l10n.quietHours),
            subtitle: Text(l10n.quietHoursBody),
            value: s.quietEnabled,
            onChanged: (v) => _save(s.copyWith(quietEnabled: v)),
          ),
          if (s.quietEnabled) ...[
            ListTile(
              contentPadding: const EdgeInsetsDirectional.only(
                start: 72,
                end: 24,
              ),
              title: Text(l10n.quietFrom),
              trailing: Text(time(s.quietStart)),
              onTap: () => _pickTime(s, start: true),
            ),
            ListTile(
              contentPadding: const EdgeInsetsDirectional.only(
                start: 72,
                end: 24,
              ),
              title: Text(l10n.quietUntil),
              trailing: Text(time(s.quietEnd)),
              onTap: () => _pickTime(s, start: false),
            ),
          ],
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              l10n.notifyLimitNote,
              style: theme.textTheme.bodySmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: _allowed != true
                  ? null
                  : () async {
                      try {
                        final uid = ref
                            .read(authRepositoryProvider)
                            .currentUser
                            ?.uid;
                        if (uid != null) {
                          await ref.read(pushServiceProvider).register(uid);
                        }
                        await ref
                            .read(notificationsRepositoryProvider)
                            .sendTest();
                        messenger.showSnackBar(
                          SnackBar(content: Text(l10n.testSent)),
                        );
                      } on Exception {
                        messenger.showSnackBar(
                          SnackBar(content: Text(l10n.errorGeneric)),
                        );
                      }
                    },
              icon: const Icon(Icons.send_outlined),
              label: Text(l10n.sendTestNotification),
            ),
          ),
        ],
      ),
    );
  }
}
