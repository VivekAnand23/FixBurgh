import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fixburgh/app/app.dart';
import 'package:fixburgh/app/background.dart';
import 'package:fixburgh/app/flavor.dart';
import 'package:fixburgh/app/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

/// Debug builds can talk to the local emulator suite instead of the
/// flavor's project: `--dart-define=USE_EMULATORS=true`. Start it with
/// `firebase emulators:start --project fixburgh-dev`.
const bool useEmulators =
    !kReleaseMode && bool.fromEnvironment('USE_EMULATORS');

Future<void> _connectEmulators() async {
  // The Android emulator reaches the host at 10.0.2.2.
  final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  await FirebaseStorage.instance.useStorageEmulator(host, 9199);
  FirebaseFunctions.instanceFor(
    region: 'us-east1',
  ).useFunctionsEmulator(host, 5001);
  debugPrint('Using the Firebase emulators on $host');
}

/// Shared startup for every flavor's `main`.
Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: flavor.firebaseOptions);
  if (useEmulators) await _connectEmulators();

  // Debug builds use the App Check debug provider; register the token printed
  // in the device log under App Check > Apps > Manage debug tokens.
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleAppAttestWithDeviceCheckFallbackProvider(),
  );

  final crashlytics = FirebaseCrashlytics.instance;
  await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
  FlutterError.onError = crashlytics.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(crashlytics.recordError(error, stack, fatal: true));
    return true;
  };

  final prefs = await SharedPreferences.getInstance();
  // Background sends need to know which Firebase project to use.
  await prefs.setString(flavorPrefsKey, flavor.name);
  try {
    await Workmanager().initialize(backgroundDispatcher);
  } on Object {
    // Background work unavailable; the outbox still sends while open.
  }

  runApp(
    ProviderScope(
      overrides: [
        flavorProvider.overrideWithValue(flavor),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const FixBurghApp(),
    ),
  );
}
