import 'dart:convert';
import 'dart:io';

import 'package:fixburgh/app/providers.dart';
import 'package:fixburgh/features/report/domain/report.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unfinished drafts older than this are discarded (BRD FR-REP-13).
const draftMaxAge = Duration(hours: 24);

final draftStoreProvider = Provider<DraftStore>(
  (ref) => DraftStore(ref.watch(sharedPreferencesProvider)),
);

/// Keeps the report being drafted on the device, so it survives the app
/// being closed. Photos are copied out of the picker's temporary folder.
///
/// Photo paths are stored relative to the app's support folder because iOS
/// can move the app's container between launches and updates.
class DraftStore {
  DraftStore(
    this._prefs, {
    DateTime Function()? now,
    Future<Directory> Function()? baseDir,
  }) : _now = now ?? DateTime.now,
       _baseDir = baseDir ?? getApplicationSupportDirectory;

  static const _key = 'report.draft';

  final SharedPreferences _prefs;
  final DateTime Function() _now;
  final Future<Directory> Function() _baseDir;

  /// The saved draft, or null if none, it is empty, too old or its photos
  /// are gone.
  Future<ReportDraft?> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, Object?>;
      final savedAt = DateTime.parse(j['savedAt']! as String);
      if (_now().difference(savedAt) > draftMaxAge) return null;
      final draft = ReportDraft.fromJson(
        (j['draft']! as Map).cast<String, Object?>(),
      );
      final base = (await _baseDir()).path;
      final photos = draft.photoPaths
          .map((p) => p.startsWith('/') ? p : '$base/$p')
          .where((p) => File(p).existsSync());
      final kept = draft.copyWith(photoPaths: photos.toList());
      return kept.isEmpty ? null : kept;
    } on Object {
      return null;
    }
  }

  Future<void> save(ReportDraft draft) async {
    if (draft.isEmpty) {
      await _prefs.remove(_key);
      return;
    }
    final base = '${(await _baseDir()).path}/';
    final relative = draft.copyWith(
      photoPaths: [
        for (final p in draft.photoPaths)
          if (p.startsWith(base)) p.substring(base.length) else p,
      ],
    );
    await _prefs.setString(
      _key,
      jsonEncode({
        'savedAt': _now().toIso8601String(),
        'draft': relative.toJson(),
      }),
    );
  }

  /// Forgets the draft and deletes its photo copies.
  Future<void> clear() async {
    await _prefs.remove(_key);
    final dir = await _photoDir();
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  /// Copies a picked photo somewhere the OS won't clean up.
  Future<String> keepPhoto(String path) async {
    final dir = await _photoDir();
    await dir.create(recursive: true);
    final name = '${_now().microsecondsSinceEpoch}_${path.split('/').last}';
    return (await File(path).copy('${dir.path}/$name')).path;
  }

  static Future<Directory> _photoDir() async => Directory(
    '${(await getApplicationSupportDirectory()).path}/draft_photos',
  );
}
