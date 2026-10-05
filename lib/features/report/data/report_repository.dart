import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/moderation/text_filter.dart';
import 'package:fixburgh/features/report/domain/geohash.dart';
import 'package:fixburgh/features/report/domain/report.dart';
import 'package:fixburgh/features/routing/domain/municipality_locator.dart'
    as geo;
import 'package:fixburgh/features/routing/domain/routing_engine.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

const guestDailyLimit = 3;
const userDailyLimit = 10;

/// Thrown before upload when today's report limit is used up.
class DailyLimitReached implements Exception {
  const DailyLimitReached({required this.isGuest});

  final bool isGuest;
}

/// UTC date as the rules compute it, e.g. "2026-10-5".
String _today() {
  final now = DateTime.now().toUtc();
  return '${now.year}-${now.month}-${now.day}';
}

/// Distinct "Looks fixed" votes that resolve a report (BRD FR-MYR-06).
const communityResolveVotes = 3;

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
  ),
);

/// The signed-in user's reports, newest first.
final myReportsProvider = StreamProvider<List<Report>>((ref) {
  final user = ref.watch(authUserProvider).value;
  if (user == null) return Stream.value(const []);
  return ref.watch(reportRepositoryProvider).watchMine(user.uid);
});

/// Recent visible reports for the community map (open and recently fixed).
final mapReportsProvider = StreamProvider<List<Report>>(
  (ref) => ref.watch(reportRepositoryProvider).watchVisible(),
);

/// One report, live.
// ignore: specify_nonobvious_property_types, family type isn't exported.
final reportProvider = StreamProvider.autoDispose.family<Report?, String>(
  (ref, id) => ref.watch(reportRepositoryProvider).watch(id),
);

/// Whether the current user has voted in `upvotes` or `fixedVotes`.
// ignore: specify_nonobvious_property_types, family type isn't exported.
final myVoteProvider = StreamProvider.autoDispose
    .family<bool, ({String reportId, String collection})>((ref, k) {
      final uid = ref.watch(authUserProvider).value?.uid;
      if (uid == null) return Stream.value(false);
      return ref
          .watch(reportRepositoryProvider)
          .watchVote(k.reportId, k.collection, uid);
    });

class ReportRepository {
  ReportRepository(this._db, this._storage);

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('reports');

  /// Compresses and uploads the photos, then creates the report document.
  /// Photos go first so a report never points at missing images.
  Future<String> submit({
    required ReportDraft draft,
    required String uid,
    required bool isGuest,
    RoutingResult? routing,
    void Function(double progress)? onProgress,
  }) async {
    final location = draft.location!;
    final reportId = const Uuid().v4();
    final photos = <Map<String, dynamic>>[];
    final steps = draft.photoPaths.length * 2;
    var done = 0;

    // The report and today's counter are written together; security rules
    // reject the pair when the daily limit is reached.
    final limitRef = _db.collection('rateLimits').doc(uid);
    final limit = await limitRef.get();
    final day = _today();
    final prev = limit.data();
    final count = prev != null && prev['day'] == day
        ? (prev['count'] as num).toInt() + 1
        : 1;
    if (count > (isGuest ? guestDailyLimit : userDailyLimit)) {
      throw DailyLimitReached(isGuest: isGuest);
    }

    for (final path in draft.photoPaths) {
      final photoId = const Uuid().v4();
      final base = 'reports/$uid/$reportId/$photoId';
      final full = await _compress(path, size: 1600, quality: 80);
      final thumb = await _compress(path, size: 320, quality: 70);
      final fullRef = _storage.ref('$base.jpg');
      final thumbRef = _storage.ref('${base}_thumb.jpg');
      final meta = SettableMetadata(contentType: 'image/jpeg');
      await fullRef.putData(full, meta);
      onProgress?.call(++done / steps);
      await thumbRef.putData(thumb, meta);
      onProgress?.call(++done / steps);
      photos.add({
        'path': fullRef.fullPath,
        'thumbPath': thumbRef.fullPath,
        'thumbUrl': await thumbRef.getDownloadURL(),
        'blurred': false,
      });
    }

    final description = cleanUserText(draft.description.trim());
    final batch = _db.batch()
      ..set(limitRef, {'day': day, 'count': count})
      ..set(_reports.doc(reportId), {
        'authorUid': uid,
        'authorIsGuest': isGuest,
        'category': draft.category!.id,
        'severity': draft.severity.name,
        'description': description,
        'geo': {
          'lat': location.lat,
          'lng': location.lng,
          'geohash': encodeGeohash(location.lat, location.lng),
          'accuracyM': draft.accuracyM,
        },
        'address': draft.address,
        'municipalityId': draft.municipality!.id,
        'municipalityName': draft.municipality!.name,
        'photos': photos,
        if (routing != null) ...{
          'agencyId': routing.agency.id,
          'agencyName': routing.agency.name,
          'roadOwner': routing.road.owner.name,
          'roadName': routing.road.name,
          'stateRoute': routing.road.route,
        },
        'status': ReportStatus.reported.name,
        'upvoteCount': 0,
        'flagCount': 0,
        'moderation': 'visible',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    await batch.commit();
    return reportId;
  }

  Stream<List<Report>> watchMine(String uid) => _reports
      .where('authorUid', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(_fromDoc).toList());

  /// Must filter on `moderation` so the query matches the read rule.
  /// Viewport queries come with clustering at scale; 300 recent reports is
  /// plenty for the pilot.
  Stream<List<Report>> watchVisible() => _reports
      .where('moderation', isEqualTo: 'visible')
      .orderBy('createdAt', descending: true)
      .limit(300)
      .snapshots()
      .map((s) => s.docs.map(_fromDoc).toList());

  /// Open reports near [p] with the same category, nearest first. Queries
  /// the geohash cells around the point, then filters by exact distance.
  Future<List<Report>> nearbyDuplicates(
    geo.GeoPoint p,
    ReportCategory category,
  ) async {
    final prefixes = neighborGeohashes(p.lat, p.lng);
    final snaps = await Future.wait([
      for (final prefix in prefixes)
        _reports
            .where('moderation', isEqualTo: 'visible')
            .orderBy('geo.geohash')
            .startAt([prefix])
            .endAt(['$prefix\uf8ff'])
            .limit(50)
            .get(),
    ]);
    final seen = <String>{};
    final out = <Report>[];
    for (final doc in snaps.expand((s) => s.docs)) {
      if (!seen.add(doc.id)) continue;
      final r = _fromDoc(doc);
      if (r.isOpen &&
          r.category == category &&
          distanceM(p, r.location) <= duplicateRadiusM) {
        out.add(r);
      }
    }
    out.sort(
      (a, b) => distanceM(p, a.location).compareTo(distanceM(p, b.location)),
    );
    return out;
  }

  Stream<Report?> watch(String id) =>
      _reports.doc(id).snapshots().map((d) => d.exists ? _fromDoc(d) : null);

  /// Whether [uid] has a vote doc in [collection] for the report.
  Stream<bool> watchVote(String reportId, String collection, String uid) =>
      _reports
          .doc(reportId)
          .collection(collection)
          .doc(uid)
          .snapshots()
          .map((d) => d.exists);

  /// Adds or removes a "Me too" in one batch so rules can pair them.
  Future<void> setUpvote(String reportId, String uid, {required bool on}) {
    final doc = _reports.doc(reportId);
    final vote = doc.collection('upvotes').doc(uid);
    final batch = _db.batch();
    if (on) {
      batch.set(vote, {'createdAt': FieldValue.serverTimestamp()});
    } else {
      batch.delete(vote);
    }
    batch.update(doc, {'upvoteCount': FieldValue.increment(on ? 1 : -1)});
    return batch.commit();
  }

  /// Records a "Looks fixed" vote; the third distinct vote resolves it.
  Future<void> voteFixed(String reportId, String uid) =>
      _db.runTransaction((tx) async {
        final doc = _reports.doc(reportId);
        final vote = doc.collection('fixedVotes').doc(uid);
        if ((await tx.get(vote)).exists) return;
        final snap = await tx.get(doc);
        final count = ((snap.data()?['fixedVoteCount'] as num?) ?? 0) + 1;
        tx
          ..set(vote, {'createdAt': FieldValue.serverTimestamp()})
          ..update(doc, {
            'fixedVoteCount': count,
            if (count >= communityResolveVotes) ...{
              'status': ReportStatus.resolved.name,
              'resolvedBy': 'community',
              'resolvedAt': FieldValue.serverTimestamp(),
            },
          });
      });

  Future<void> reopen(String reportId) => _reports.doc(reportId).update({
    'status': ReportStatus.reported.name,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  /// Deletes the report and its photos.
  Future<void> delete(Report r) async {
    await _reports.doc(r.id).delete();
    await Future.wait([
      for (final path in r.photoPaths)
        _storage.ref(path).delete().catchError((Object _) {}),
    ]);
  }

  Future<void> flag({
    required String reportId,
    required String uid,
    required String reason,
    String note = '',
  }) async {
    try {
      await _db.collection('flags').doc('${reportId}_$uid').set({
        'reportId': reportId,
        'reporterUid': uid,
        'reason': reason,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      // Flagging twice is rejected by the rules; the first flag stands.
      if (e.code != 'permission-denied') rethrow;
    }
  }

  /// The reporter contacted the office through the app (BRD section 8.5).
  Future<void> markSent(String reportId, String channel) =>
      _reports.doc(reportId).update({
        'status': ReportStatus.sent.name,
        'contactChannel': channel,
        'sentAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> markResolved(String reportId) => _reports.doc(reportId).update({
    'status': ReportStatus.resolved.name,
    'resolvedAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  /// Resizes to [size] px on the long edge and re-encodes as JPEG, which
  /// drops EXIF metadata (GPS, device) from the uploaded file.
  static Future<Uint8List> _compress(
    String path, {
    required int size,
    required int quality,
  }) async {
    final out = await FlutterImageCompress.compressWithFile(
      path,
      minWidth: size,
      minHeight: size,
      quality: quality,
    );
    return out ?? await File(path).readAsBytes();
  }

  static Report _fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    final g = (m['geo'] as Map?)?.cast<String, dynamic>() ?? const {};
    final photos = (m['photos'] as List?)?.cast<Map<String, dynamic>>();
    return Report(
      id: d.id,
      authorUid: m['authorUid'] as String? ?? '',
      photoPaths: [
        for (final p in photos ?? const <Map<String, dynamic>>[]) ...[
          if (p['path'] is String) p['path'] as String,
          if (p['thumbPath'] is String) p['thumbPath'] as String,
        ],
      ],
      upvoteCount: (m['upvoteCount'] as num?)?.toInt() ?? 0,
      fixedVoteCount: (m['fixedVoteCount'] as num?)?.toInt() ?? 0,
      agencyName: m['agencyName'] as String?,
      resolvedAt: (m['resolvedAt'] as Timestamp?)?.toDate(),
      category: ReportCategory.fromId(m['category'] as String? ?? ''),
      severity: Severity.fromId(m['severity'] as String? ?? ''),
      status: ReportStatus.fromId(m['status'] as String? ?? ''),
      location: geo.GeoPoint(
        (g['lat'] as num?)?.toDouble() ?? 0,
        (g['lng'] as num?)?.toDouble() ?? 0,
      ),
      municipalityName: m['municipalityName'] as String? ?? '',
      address: m['address'] as String?,
      description: m['description'] as String? ?? '',
      thumbUrl: photos?.isNotEmpty ?? false
          ? photos!.first['thumbUrl'] as String?
          : null,
      // Pending server timestamps read as null until the write lands.
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
