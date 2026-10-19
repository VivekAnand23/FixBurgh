import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The office directory: bundled with the app, corrected from Firestore
/// without an app release (BRD FR-RTE-10).
///
/// Launches read one document, `config/directory`. Only when its `version`
/// changed (the onAgencyWritten function bumps it on every agency edit)
/// does the app fetch the `agencies` collection and cache it on the device.
class AgencyDirectory {
  AgencyDirectory(
    this._prefs, {
    required this.loadBundled,
    required this.firestore,
  });

  static const _cacheKey = 'directory.agencies';
  static const _versionKey = 'directory.version';

  final SharedPreferences _prefs;

  /// The bundled `assets/directory/agencies.json`.
  final Future<String> Function() loadBundled;

  /// Resolved lazily so the directory still works when Firebase isn't set up.
  final FirebaseFirestore Function() firestore;

  /// Bundled records with any cached Firestore records laid over them.
  Future<List<Map<String, dynamic>>> load() async {
    final bundled =
        ((jsonDecode(await loadBundled()) as Map<String, dynamic>)['agencies']
                as List)
            .cast<Map<String, dynamic>>();
    final cached = _prefs.getString(_cacheKey);
    if (cached == null) return bundled;
    try {
      final remote = (jsonDecode(cached) as List).cast<Map<String, dynamic>>();
      return mergeAgencies(bundled, remote);
    } on FormatException {
      return bundled;
    }
  }

  /// Fetches the directory if it changed. True when the cache was updated.
  /// Failures (offline, no Firebase) keep the current data.
  Future<bool> refresh() async {
    try {
      final db = firestore();
      final config = await db.collection('config').doc('directory').get();
      final version = config.data()?['version'];
      final stamp = version is Timestamp
          ? version.millisecondsSinceEpoch
          : null;
      if (stamp == null || stamp == _prefs.getInt(_versionKey)) return false;
      final snap = await db.collection('agencies').get();
      final records = [
        for (final d in snap.docs) {'id': d.id, ...jsonSafe(d.data())},
      ];
      await _prefs.setString(_cacheKey, jsonEncode(records));
      await _prefs.setInt(_versionKey, stamp);
      return true;
    } on Object {
      return false;
    }
  }
}

/// [bundled] with [remote] records replacing or adding by `id`.
List<Map<String, dynamic>> mergeAgencies(
  List<Map<String, dynamic>> bundled,
  List<Map<String, dynamic>> remote,
) {
  final byId = {for (final a in bundled) a['id']: a};
  for (final r in remote) {
    if (r['id'] is String) byId[r['id']] = r;
  }
  return byId.values.toList();
}

/// Firestore values as plain JSON (timestamps become ISO dates).
Map<String, dynamic> jsonSafe(Map<String, dynamic> data) {
  Object? convert(Object? v) => switch (v) {
    Timestamp() => v.toDate().toUtc().toIso8601String().substring(0, 10),
    final List<Object?> l => l.map(convert).toList(),
    final Map<String, dynamic> m => jsonSafe(m),
    String() || num() || bool() || null => v,
    _ => null,
  };
  return {for (final e in data.entries) e.key: convert(e.value)};
}
