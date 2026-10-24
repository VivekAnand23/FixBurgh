import 'package:cloud_firestore/cloud_firestore.dart' hide GeoPoint;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/report/domain/geohash.dart';
import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which notifications someone wants and when (BRD FR-NTF-05). Stored on
/// `users/{uid}`; the server reads it before sending.
@immutable
class NotifySettings {
  const NotifySettings({
    this.status = true,
    this.nearby = true,
    this.notices = true,
    this.quietEnabled = false,
    this.quietStart = 22 * 60,
    this.quietEnd = 7 * 60,
  });

  factory NotifySettings.fromDoc(Map<String, dynamic>? d) {
    final n = (d?['notify'] as Map?)?.cast<String, dynamic>() ?? const {};
    final q = (d?['quietHours'] as Map?)?.cast<String, dynamic>() ?? const {};
    return NotifySettings(
      status: n['status'] as bool? ?? true,
      nearby: n['nearby'] as bool? ?? true,
      notices: n['notices'] as bool? ?? true,
      quietEnabled: q['enabled'] as bool? ?? false,
      quietStart: (q['start'] as num?)?.toInt() ?? 22 * 60,
      quietEnd: (q['end'] as num?)?.toInt() ?? 7 * 60,
    );
  }

  /// Updates on reports you made or said "Me too" to.
  final bool status;

  /// New urgent reports near your saved places.
  final bool nearby;

  /// Notices from your society's admins and committee (Burghood).
  final bool notices;
  final bool quietEnabled;

  /// Minutes after local midnight.
  final int quietStart;
  final int quietEnd;

  Map<String, Object> toDoc({required int utcOffsetMinutes}) => {
    'notify': {'status': status, 'nearby': nearby, 'notices': notices},
    'quietHours': {
      'enabled': quietEnabled,
      'start': quietStart,
      'end': quietEnd,
    },
    // Quiet hours are local; the server works in UTC.
    'utcOffsetMinutes': utcOffsetMinutes,
  };

  NotifySettings copyWith({
    bool? status,
    bool? nearby,
    bool? notices,
    bool? quietEnabled,
    int? quietStart,
    int? quietEnd,
  }) => NotifySettings(
    status: status ?? this.status,
    nearby: nearby ?? this.nearby,
    notices: notices ?? this.notices,
    quietEnabled: quietEnabled ?? this.quietEnabled,
    quietStart: quietStart ?? this.quietStart,
    quietEnd: quietEnd ?? this.quietEnd,
  );
}

/// A saved place: home, school, work or other, with an alert radius
/// (BRD FR-NTF-03). Only coordinates and a geohash are stored.
@immutable
class SavedPlace {
  const SavedPlace({
    required this.id,
    required this.kind,
    required this.location,
    required this.radiusMiles,
    this.label = '',
  });

  factory SavedPlace.fromDoc(String id, Map<String, dynamic> d) => SavedPlace(
    id: id,
    kind: d['kind'] as String? ?? 'other',
    label: d['label'] as String? ?? '',
    location: GeoPoint(
      (d['lat'] as num?)?.toDouble() ?? 0,
      (d['lng'] as num?)?.toDouble() ?? 0,
    ),
    radiusMiles: (d['radiusMiles'] as num?)?.toDouble() ?? 0.5,
  );

  /// One of [placeSlots].
  final String id;

  /// `home`, `school`, `work` or `other`.
  final String kind;
  final String label;
  final GeoPoint location;
  final double radiusMiles;

  Map<String, Object> toDoc() => {
    'kind': kind,
    'label': label,
    'lat': location.lat,
    'lng': location.lng,
    'geohash': encodeGeohash(location.lat, location.lng),
    'radiusMiles': radiusMiles,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

/// Document IDs for the 3 places someone can save; rules allow only these.
const placeSlots = ['p1', 'p2', 'p3'];
const minRadiusMiles = 0.25;
const maxRadiusMiles = 2.0;

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(FirebaseFirestore.instance),
);

final StreamProvider<NotifySettings> notifySettingsProvider =
    StreamProvider.autoDispose<NotifySettings>((
      ref,
    ) {
      final uid = ref.watch(authUserProvider).value?.uid;
      if (uid == null) return Stream.value(const NotifySettings());
      return ref.watch(notificationsRepositoryProvider).watchSettings(uid);
    });

final StreamProvider<List<SavedPlace>> savedPlacesProvider =
    StreamProvider.autoDispose<List<SavedPlace>>((
      ref,
    ) {
      final uid = ref.watch(authUserProvider).value?.uid;
      if (uid == null) return Stream.value(const []);
      return ref.watch(notificationsRepositoryProvider).watchPlaces(uid);
    });

class NotificationsRepository {
  NotificationsRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _db.collection('users').doc(uid);

  Stream<NotifySettings> watchSettings(String uid) => _user(
    uid,
  ).snapshots().map((d) => NotifySettings.fromDoc(d.data()));

  Future<void> saveSettings(String uid, NotifySettings s) => _user(uid).set(
    s.toDoc(utcOffsetMinutes: DateTime.now().timeZoneOffset.inMinutes),
    SetOptions(merge: true),
  );

  Stream<List<SavedPlace>> watchPlaces(String uid) => _user(uid)
      .collection('places')
      .snapshots()
      .map(
        (s) =>
            [for (final d in s.docs) SavedPlace.fromDoc(d.id, d.data())]
              ..sort((a, b) => a.id.compareTo(b.id)),
      );

  Future<void> savePlace(String uid, SavedPlace p) =>
      _user(uid).collection('places').doc(p.id).set(p.toDoc());

  Future<void> deletePlace(String uid, String id) =>
      _user(uid).collection('places').doc(id).delete();

  /// Sends a test notification to this person's devices.
  Future<void> sendTest() => FirebaseFunctions.instanceFor(
    region: 'us-east1',
  ).httpsCallable('sendTestNotification').call<void>();
}

/// The first free slot for a new place, or null when all 3 are used.
String? freePlaceSlot(List<SavedPlace> places) {
  final used = places.map((p) => p.id).toSet();
  return placeSlots.where((s) => !used.contains(s)).firstOrNull;
}
