import 'package:firebase_core/firebase_core.dart';
import 'package:fixburgh/app/firebase/firebase_options_dev.dart';
import 'package:fixburgh/app/firebase/firebase_options_prod.dart';

/// Build flavor. Each flavor talks to its own Firebase project.
enum Flavor {
  dev,
  prod;

  FirebaseOptions get firebaseOptions => switch (this) {
    Flavor.dev => FirebaseOptionsDev.currentPlatform,
    Flavor.prod => FirebaseOptionsProd.currentPlatform,
  };

  String get googleServerClientId => switch (this) {
    Flavor.dev => FirebaseOptionsDev.googleServerClientId,
    Flavor.prod => FirebaseOptionsProd.googleServerClientId,
  };

  bool get isDev => this == Flavor.dev;
}
