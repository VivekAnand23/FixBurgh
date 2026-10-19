import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/report/data/outbox.dart';
import 'package:fixburgh/features/report/data/report_repository.dart';
import 'package:fixburgh/features/report/domain/report.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

final outboxStoreProvider = Provider<Outbox>((ref) => Outbox());

/// Starts the background send (BRD FR-OFF-02): Android WorkManager with a
/// network constraint and exponential backoff; iOS BGTaskScheduler. Both
/// run `backgroundOutboxTask` in `lib/app/background.dart`.
final outboxSchedulerProvider = Provider<Future<void> Function()>(
  (ref) => scheduleOutboxSend,
);

const outboxTaskName = 'com.fixburgh.outbox';

Future<void> scheduleOutboxSend() async {
  try {
    final constraints = Constraints(networkType: NetworkType.connected);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await Workmanager().registerProcessingTask(
        outboxTaskName,
        outboxTaskName,
        constraints: constraints,
      );
    } else {
      await Workmanager().registerOneOffTask(
        outboxTaskName,
        outboxTaskName,
        constraints: constraints,
        existingWorkPolicy: ExistingWorkPolicy.replace,
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 1),
      );
    }
  } on Object {
    // Background work unavailable (tests, simulator quirks): the app still
    // sends when it is open and the connection returns.
  }
}

/// Reports waiting on this device, for My Reports (BRD FR-OFF-03).
final outboxProvider = NotifierProvider<OutboxController, List<OutboxItem>>(
  OutboxController.new,
);

class OutboxController extends Notifier<List<OutboxItem>> {
  bool _sending = false;

  Outbox get _store => ref.read(outboxStoreProvider);

  @override
  List<OutboxItem> build() {
    unawaited(refresh());
    return const [];
  }

  Future<void> refresh() async {
    final items = await _store.load();
    if (ref.mounted) state = items;
  }

  /// Saves a report that couldn't be sent now, and schedules sending it.
  Future<void> enqueue({
    required String id,
    required ReportDraft draft,
    required List<String> photoIds,
    Map<String, Object?>? routing,
  }) async {
    await _store.add(
      id: id,
      draft: draft,
      photoIds: photoIds,
      routing: routing,
    );
    await refresh();
    await ref.read(outboxSchedulerProvider)();
  }

  /// Tries to send now. [force] also retries items that gave up.
  Future<OutboxRun?> sendNow({bool force = false}) async {
    if (_sending) return null;
    _sending = true;
    try {
      final auth = ref.read(authRepositoryProvider);
      final run = await OutboxSender(
        outbox: _store,
        repo: ref.read(reportRepositoryProvider),
        sender: () async {
          await auth.ensureGuest();
          final user = auth.currentUser!;
          return (uid: user.uid, isGuest: user.isAnonymous);
        },
      ).sendDue(force: force);
      if (run.waiting > 0) await ref.read(outboxSchedulerProvider)();
      return run;
    } finally {
      _sending = false;
      await refresh();
    }
  }

  /// Cancels a waiting report and deletes its saved photos.
  Future<void> cancel(String id) async {
    await _store.remove(id);
    await refresh();
  }

  /// "Send anyway" after a duplicate was found.
  Future<void> sendAnyway(String id) async {
    final item = state.firstWhere((i) => i.id == id);
    await _store.update(
      item.copyWith(sendAnyway: true, status: OutboxStatus.waiting),
    );
    await sendNow();
  }

  /// "Me too" on the existing report instead of sending this one.
  Future<void> meTooInstead(String id) async {
    final item = state.firstWhere((i) => i.id == id);
    final auth = ref.read(authRepositoryProvider);
    await auth.ensureGuest();
    await ref
        .read(reportRepositoryProvider)
        .setUpvote(item.duplicateOfId!, auth.currentUser!.uid, on: true);
    await cancel(id);
  }
}

/// Sends the outbox while the app is open: on launch, when the connection
/// comes back, when the app returns to the foreground, and on a timer while
/// items are backing off.
class OutboxRunner extends ConsumerStatefulWidget {
  const OutboxRunner({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<OutboxRunner> createState() => _OutboxRunnerState();
}

class _OutboxRunnerState extends ConsumerState<OutboxRunner>
    with WidgetsBindingObserver {
  StreamSubscription<List<ConnectivityResult>>? _connectivity;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    try {
      _connectivity = Connectivity().onConnectivityChanged.listen((r) {
        if (!r.contains(ConnectivityResult.none)) _send();
      });
    } on Object {
      // No connectivity plugin (tests).
    }
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (ref.read(outboxProvider).isNotEmpty) _send();
    });
    _send();
  }

  void _send() => unawaited(
    ref.read(outboxProvider.notifier).sendNow().catchError((_) {
      return null;
    }),
  );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _send();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_connectivity?.cancel());
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Whether the device has any network right now. True when unknown.
Future<bool> isOnline() async {
  try {
    final r = await Connectivity().checkConnectivity();
    return !r.contains(ConnectivityResult.none);
  } on Object {
    return true;
  }
}
