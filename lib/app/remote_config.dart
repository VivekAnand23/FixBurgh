import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Remote Config defaults. Phase 2 features are on unless the project's
/// template switches them off (BRD section 10.6), so a first launch offline
/// still gets them. Burghood features stay off until their phase ships.
const remoteConfigDefaults = <String, Object>{
  'safety_keywords': '',
  'feature_offline_outbox': true,
  'feature_push': true,
  'feature_saved_places': true,
  'feature_society': false,
  'feature_channels': false,
  'feature_services': false,
  'feature_monetisation': false,
  'service_categories': serviceCategoriesDefault,
};

/// The service category groups, kept in step with
/// `firebase/remoteconfig.template.json` (checked by a test).
const serviceCategoriesDefault = '''
[
  {
    "id": "home_repair",
    "label": "Home repair",
    "approvalCheck": "Pennsylvania contractor registration (HIC) and insurance",
    "categories": [
      {"id": "plumbing", "label": "Plumbing"},
      {"id": "electrical", "label": "Electrical"},
      {"id": "hvac", "label": "HVAC"},
      {"id": "appliance_repair", "label": "Appliance repair"},
      {"id": "carpentry", "label": "Carpentry"},
      {"id": "painting", "label": "Painting"},
      {"id": "roofing_and_gutters", "label": "Roofing and gutters"},
      {"id": "locksmith", "label": "Locksmith"},
      {"id": "handyman", "label": "Handyman"}
    ]
  },
  {
    "id": "home_care",
    "label": "Home care",
    "approvalCheck": "Insurance",
    "categories": [
      {"id": "house_cleaning", "label": "House cleaning"},
      {"id": "pest_control", "label": "Pest control"},
      {"id": "lawn_and_garden", "label": "Lawn and garden"},
      {"id": "snow_removal", "label": "Snow removal"},
      {"id": "moving_help", "label": "Moving help"},
      {"id": "junk_removal", "label": "Junk removal"}
    ]
  },
  {
    "id": "personal_care",
    "label": "Personal care",
    "approvalCheck": "Background check, plus Pennsylvania child abuse clearances for anyone caring for children",
    "categories": [
      {"id": "babysitting", "label": "Babysitting"},
      {"id": "nanny", "label": "Nanny"},
      {"id": "elder_care_and_companionship", "label": "Elder care and companionship"},
      {"id": "pet_sitting", "label": "Pet sitting"},
      {"id": "dog_walking", "label": "Dog walking"},
      {"id": "pet_grooming", "label": "Pet grooming"},
      {"id": "tutoring", "label": "Tutoring"}
    ]
  },
  {
    "id": "everyday_help",
    "label": "Everyday help",
    "approvalCheck": "None beyond ID",
    "categories": [
      {"id": "errands_and_grocery_runs", "label": "Errands and grocery runs"},
      {"id": "meal_prep", "label": "Meal prep"},
      {"id": "tech_help", "label": "Tech help"},
      {"id": "car_wash_and_detailing", "label": "Car wash and detailing"}
    ]
  }
]
''';

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

/// Phase 2 and Burghood feature switches.
typedef FeatureFlags = ({
  bool offlineOutbox,
  bool push,
  bool savedPlaces,
  bool society,
  bool channels,
  bool services,
  bool monetisation,
});

final featureFlagsProvider = Provider<FeatureFlags>((ref) {
  final rc = ref.watch(remoteConfigProvider).value;
  bool flag(String key) =>
      rc?.getBool(key) ?? remoteConfigDefaults[key]! as bool;
  return (
    offlineOutbox: flag('feature_offline_outbox'),
    push: flag('feature_push'),
    savedPlaces: flag('feature_saved_places'),
    society: flag('feature_society'),
    channels: flag('feature_channels'),
    services: flag('feature_services'),
    monetisation: flag('feature_monetisation'),
  );
});
