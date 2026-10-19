import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fixburgh/app/flavor.dart';
import 'package:fixburgh/features/report/data/outbox.dart';
import 'package:fixburgh/features/report/data/report_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

/// The flavor the app last ran as; background tasks start without one.
const flavorPrefsKey = 'app.flavor';

/// Entry point for background work (Android WorkManager, iOS
/// BGTaskScheduler). Sends the outbox (BRD FR-OFF-02).
@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((task, _) async {
    WidgetsFlutterBinding.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    final flavor = Flavor.values
        .where((f) => f.name == prefs.getString(flavorPrefsKey))
        .firstOrNull;
    if (flavor == null) return true; // Never opened; nothing queued.
    return backgroundOutboxTask(flavor);
  });
}

/// Sends what it can. False asks WorkManager to retry with backoff.
Future<bool> backgroundOutboxTask(Flavor flavor) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: flavor.firebaseOptions);
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
        providerApple: kDebugMode
            ? const AppleDebugProvider()
            : const AppleAppAttestWithDeviceCheckFallbackProvider(),
      );
    }
    final auth = FirebaseAuth.instance;
    // The saved session loads asynchronously in a fresh engine.
    var user = await auth.authStateChanges().first;
    user ??= (await auth.signInAnonymously()).user;
    final me = user!;
    final run = await OutboxSender(
      outbox: Outbox(),
      repo: ReportRepository(
        FirebaseFirestore.instance,
        FirebaseStorage.instance,
      ),
      sender: () async => (uid: me.uid, isGuest: me.isAnonymous),
    ).sendDue();
    return run.waiting == 0;
  } on Object {
    return false;
  }
}
