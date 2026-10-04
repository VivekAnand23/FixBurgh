// Firebase configuration for the `prod` flavor.
//
// Generated from `firebase apps:sdkconfig` for project `fixburgh-prod`.
// These values identify the Firebase project and are safe to commit; access is
// protected by Security Rules, App Check and API key restrictions.
// ignore_for_file: lines_longer_than_80_chars

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

abstract final class FirebaseOptionsProd {
  static FirebaseOptions get currentPlatform => switch (defaultTargetPlatform) {
    TargetPlatform.android => android,
    TargetPlatform.iOS => ios,
    _ => throw UnsupportedError('FixBurgh supports only Android and iOS.'),
  };

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyD9p41sB5RPZpjU4LYdJWdV_bgp-NFeIOw',
    appId: '1:993895991827:android:389b042a04a75aec5c8de6',
    messagingSenderId: '993895991827',
    projectId: 'fixburgh-prod',
    storageBucket: 'fixburgh-prod.firebasestorage.app',
  );

  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyD8YQy13GKhadVgvnU9RTJxEKNff8bW9L8',
    appId: '1:993895991827:ios:7635aaaa83d601935c8de6',
    messagingSenderId: '993895991827',
    projectId: 'fixburgh-prod',
    storageBucket: 'fixburgh-prod.firebasestorage.app',
    iosClientId:
        '993895991827-kfuirn0lifs3e61gt05f41bvogn3pg6t.apps.googleusercontent.com',
    iosBundleId: 'com.fixburgh.app',
  );

  /// OAuth web client ID, used as Google Sign-In's server client ID.
  static const googleServerClientId =
      '993895991827-kktbkqa09bb3lt5pmg5cq06n1mgjec9k.apps.googleusercontent.com';
}
