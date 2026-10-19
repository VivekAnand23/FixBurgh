import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Remote Config defaults. Phase 2 features are on unless the project's
/// template switches them off (BRD section 10.6), so a first launch offline
/// still gets them.
const remoteConfigDefaults = <String, Object>{
  'safety_keywords': '',
  'feature_offline_outbox': true,
  'feature_push': true,
  'feature_saved_places': true,
};

/// Remote Config, fetched once per app run. Null without Firebase (tests).
final remoteConfigProvider = FutureProvider<FirebaseRemoteConfig?>((ref) async {
  try {
    final rc = FirebaseRemoteConfig.instance;
    await rc.setDefaults(remoteConfigDefaults);
    await rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 12),
      ),
    );
    try {
      await rc.fetchAndActivate();
    } on Object {
      // Offline: the last activated values (or the defaults) apply.
    }
    return rc;
  } on Object {
    return null;
  }
});

/// Phase 2 feature switches.
typedef FeatureFlags = ({bool offlineOutbox, bool push, bool savedPlaces});

final featureFlagsProvider = Provider<FeatureFlags>((ref) {
  final rc = ref.watch(remoteConfigProvider).value;
  bool flag(String key) =>
      rc?.getBool(key) ?? remoteConfigDefaults[key]! as bool;
  return (
    offlineOutbox: flag('feature_offline_outbox'),
    push: flag('feature_push'),
    savedPlaces: flag('feature_saved_places'),
  );
});
