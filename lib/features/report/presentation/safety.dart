import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:fixburgh/app/providers.dart';
import 'package:fixburgh/features/report/domain/report.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The full safety screen is shown for a person's first reports; after
/// that it is a compact row that is still always shown (BRD FR-SAF-01).
const fullSafetyCheckReports = 3;

const _filedKey = 'safety.reportsFiled';

/// Words in an urgent description that mean someone may be in danger
/// (BRD FR-SAF-03). Matched at the start of words, so "spark" also
/// matches "sparking". Overridden by the Remote Config `safety_keywords`
/// parameter (comma-separated).
const defaultSafetyKeywords = [
  'wire',
  'power line',
  'spark',
  'electric',
  'gas',
  'smoke',
  'fire',
  'trapped',
  'stuck',
  'injur',
  'hurt',
  'bleeding',
];

/// Categories where an urgent report may really be an emergency.
const Set<ReportCategory> _recheckCategories = {
  ReportCategory.fallenTree,
  ReportCategory.flooding,
  ReportCategory.streetlight,
};

/// Whether to ask "Is anyone in danger?" again before continuing.
bool needsSafetyRecheck({
  required ReportCategory? category,
  required Severity severity,
  required String description,
  List<String> keywords = defaultSafetyKeywords,
}) {
  if (severity != Severity.urgent || !_recheckCategories.contains(category)) {
    return false;
  }
  final text = description.toLowerCase();
  return keywords.any(
    (k) =>
        k.trim().isNotEmpty &&
        RegExp(r'\b' + RegExp.escape(k.trim().toLowerCase())).hasMatch(text),
  );
}

/// Parses the Remote Config value; falls back to the defaults when empty.
List<String> parseKeywords(String raw) {
  final list = [
    for (final k in raw.split(','))
      if (k.trim().isNotEmpty) k.trim(),
  ];
  return list.isEmpty ? defaultSafetyKeywords : list;
}

/// Safety keywords from Remote Config (free), with the built-in list as
/// default and fallback.
final safetyKeywordsProvider = FutureProvider<List<String>>((ref) async {
  try {
    final rc = FirebaseRemoteConfig.instance;
    await rc.setDefaults({'safety_keywords': defaultSafetyKeywords.join(',')});
    await rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 12),
      ),
    );
    await rc.fetchAndActivate();
    return parseKeywords(rc.getString('safety_keywords'));
  } on Object {
    return defaultSafetyKeywords;
  }
});

/// Reports this person has filed on this device, for [fullSafetyCheckReports].
final reportsFiledProvider = NotifierProvider<ReportsFiled, int>(
  ReportsFiled.new,
);

class ReportsFiled extends Notifier<int> {
  @override
  int build() => ref.watch(sharedPreferencesProvider).getInt(_filedKey) ?? 0;

  Future<void> increment() async {
    state++;
    await ref.read(sharedPreferencesProvider).setInt(_filedKey, state);
  }
}
