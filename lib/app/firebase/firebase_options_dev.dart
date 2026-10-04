// Firebase configuration for the `dev` flavor.
//
// Generated from `firebase apps:sdkconfig` for project `fixburgh-dev`.
// These values identify the Firebase project and are safe to commit; access is
// protected by Security Rules, App Check and API key restrictions.
// ignore_for_file: lines_longer_than_80_chars

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

abstract final class FirebaseOptionsDev {
  static FirebaseOptions get currentPlatform => switch (defaultTargetPlatform) {
    TargetPlatform.android => android,
    TargetPlatform.iOS => ios,
    _ => throw UnsupportedError('FixBurgh supports only Android and iOS.'),
  };

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyA5XwUEA0l3zN_LJnaq0y7m8so2XH2ZAl8',
    appId: '1:306263131093:android:9397be409d1821b4b9335c',
    messagingSenderId: '306263131093',
    projectId: 'fixburgh-dev',
    storageBucket: 'fixburgh-dev.firebasestorage.app',
  );

  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyCVNnNZI6k9M7l_K9VdlsXXDQEp1EbwodM',
    appId: '1:306263131093:ios:3a0fc279c6ca3261b9335c',
    messagingSenderId: '306263131093',
    projectId: 'fixburgh-dev',
    storageBucket: 'fixburgh-dev.firebasestorage.app',
    iosClientId:
        '306263131093-sa90o5tgohc1qpioo51mfffntabk4cpb.apps.googleusercontent.com',
    iosBundleId: 'com.fixburgh.app.dev',
  );

  /// OAuth web client ID, used as Google Sign-In's server client ID.
  static const googleServerClientId =
      '306263131093-6ln5iacuvi0dcognbeim5kbf3567618n.apps.googleusercontent.com';
}
