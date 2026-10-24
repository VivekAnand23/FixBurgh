import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fixburgh/app/remote_config.dart';
import 'package:fixburgh/app/router.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/notifications/push_service.dart';
import 'package:fixburgh/features/report/presentation/outbox_controller.dart';
import 'package:fixburgh/features/report/presentation/report_detail_sheet.dart';
import 'package:fixburgh/features/society/data/society_repository.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Bottom navigation: Map, Society, Report, Activity, Profile. The order
/// matches the shell branches in `router.dart`.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  final _subs = <StreamSubscription<Object?>>[];

  @override
  void initState() {
    super.initState();
    // Onboarding is done by the time the shell shows, so start a guest
    // session if there isn't one. Failures (e.g. offline) retry next launch.
    unawaited(
      ref.read(authRepositoryProvider).ensureGuest().catchError((_) {}),
    );
    unawaited(_initPush());
  }

  @override
  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    super.dispose();
  }

  /// Keeps this device's push token registered for whoever is signed in,
  /// and opens the report a notification is about (BRD FR-NTF-02).
  Future<void> _initPush() async {
    await ref.read(remoteConfigProvider.future);
    if (!mounted || !ref.read(featureFlagsProvider).push) return;
    try {
      final push = ref.read(pushServiceProvider);
      ref.listenManual(authUserProvider, (prev, next) {
        final uid = next.value?.uid;
        if (uid != null && uid != prev?.value?.uid) {
          unawaited(push.register(uid).catchError((_) {}));
        }
      }, fireImmediately: true);
      _subs
        ..add(FirebaseMessaging.onMessage.listen(_showInApp))
        ..add(FirebaseMessaging.onMessageOpenedApp.listen(_open));
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _open(initial);
    } on Object catch (e) {
      // No Firebase Messaging (tests) or no Google Play services.
      debugPrint('Push: unavailable ($e)');
    }
  }

  void _open(RemoteMessage m) {
    if (!mounted) return;
    final id = m.data['reportId'];
    final society = m.data['societyId'];
    final notice = m.data['noticeId'];
    if (id is String && id.isNotEmpty) {
      unawaited(showReportSheet(context, id));
    } else if (society is String && society.isNotEmpty) {
      // A notice, a join decision or a request for admins.
      ref.read(selectedSocietyProvider.notifier).select(society);
      final router = GoRouter.of(context)..go(Routes.society);
      if (notice is String && notice.isNotEmpty) {
        unawaited(router.push(Routes.notice(society, notice)));
      }
    }
  }

  /// The system doesn't show notifications while the app is open.
  void _showInApp(RemoteMessage m) {
    final n = m.notification;
    if (n == null || !mounted) return;
    final id = m.data['reportId'] ?? m.data['societyId'];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text([n.title, n.body].whereType<String>().join('\n')),
        action: id is String && id.isNotEmpty
            ? SnackBarAction(
                label: AppLocalizations.of(context).view,
                onPressed: () => _open(m),
              )
            : null,
      ),
    );
  }

  /// Join requests waiting for this admin, shown on the Society tab.
  int _pendingRequests() {
    if (!ref.watch(featureFlagsProvider).society) return 0;
    final sid = ref.watch(currentSocietyIdProvider);
    final uid = ref.watch(authUserProvider).value?.uid;
    if (sid == null || uid == null) return 0;
    final s = ref.watch(societyProvider(sid)).value;
    return s != null && s.adminUids.contains(uid) ? s.pendingCount : 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shell = widget.navigationShell;
    final requests = _pendingRequests();
    return Scaffold(
      body: OutboxRunner(child: shell),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: l10n.navMap,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: requests > 0,
              label: Text('$requests'),
              child: const Icon(Icons.apartment_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: requests > 0,
              label: Text('$requests'),
              child: const Icon(Icons.apartment),
            ),
            label: l10n.navSociety,
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_circle_outline),
            selectedIcon: const Icon(Icons.add_circle),
            label: l10n.navReport,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: l10n.navActivity,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}
