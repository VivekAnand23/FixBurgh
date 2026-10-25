import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart' hide GeoPoint;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fixburgh/app/analytics.dart';
import 'package:fixburgh/app/providers.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/moderation/text_filter.dart';
import 'package:fixburgh/features/report/domain/geohash.dart';
import 'package:fixburgh/features/report/domain/report.dart' show distanceM;
import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:fixburgh/features/society/domain/society.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Societies within this distance of a searched address are shown, and a
/// new one this close warns about a duplicate.
const double nearbySocietyM = 200;

/// Largest claim file the Storage rules accept.
const int maxClaimFileBytes = 5 * 1024 * 1024;

/// Largest society document the Storage rules accept.
const int maxDocumentBytes = 20 * 1024 * 1024;

/// Thrown when a file is bigger than the rules allow.
class FileTooLarge implements Exception {
  const FileTooLarge(this.maxBytes);

  final int maxBytes;
}

/// Thrown by [SocietyRepository.joinWithCode] for an unknown code.
class InvalidInviteCode implements Exception {
  const InvalidInviteCode();
}

final societyRepositoryProvider = Provider<SocietyRepository>(
  (ref) => SocietyRepository(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
    FirebaseFunctions.instanceFor(region: 'us-east1'),
    analytics: ref.watch(analyticsProvider),
  ),
);

/// Societies the signed-in person is an approved member of.
final mySocietyIdsProvider = StreamProvider<List<String>>((ref) {
  final user = ref.watch(authUserProvider).value;
  if (user == null || user.isAnonymous) return Stream.value(const []);
  return ref.watch(societyRepositoryProvider).watchSocietyIds(user.uid);
});

/// Their join requests still waiting for an admin.
final myPendingRequestsProvider = StreamProvider<List<String>>((ref) {
  final user = ref.watch(authUserProvider).value;
  if (user == null || user.isAnonymous) return Stream.value(const []);
  return ref.watch(societyRepositoryProvider).watchPendingRequests(user.uid);
});

/// Their society claims, newest first.
final myClaimsProvider = StreamProvider<List<SocietyClaim>>((ref) {
  final user = ref.watch(authUserProvider).value;
  if (user == null || user.isAnonymous) return Stream.value(const []);
  return ref.watch(societyRepositoryProvider).watchClaims(user.uid);
});

/// The society shown on the Society tab, for people in more than one.
final selectedSocietyProvider =
    NotifierProvider<SelectedSocietyController, String?>(
      SelectedSocietyController.new,
    );

class SelectedSocietyController extends Notifier<String?> {
  static const _key = 'society.selected';

  @override
  String? build() => ref.watch(sharedPreferencesProvider).getString(_key);

  void select(String id) {
    state = id;
    unawaited(ref.read(sharedPreferencesProvider).setString(_key, id));
  }
}

/// The selected society if they're still in it, else their first one.
final currentSocietyIdProvider = Provider<String?>((ref) {
  final ids = ref.watch(mySocietyIdsProvider).value ?? const [];
  final selected = ref.watch(selectedSocietyProvider);
  return ids.contains(selected) ? selected : ids.firstOrNull;
});

// ignore: specify_nonobvious_property_types, family type isn't exported.
final societyProvider = StreamProvider.autoDispose.family<Society?, String>(
  (ref, sid) => ref.watch(societyRepositoryProvider).watchSociety(sid),
);

/// The signed-in person's membership of a society, if any.
// ignore: specify_nonobvious_property_types, family type isn't exported.
final myMembershipProvider = StreamProvider.autoDispose
    .family<Membership?, String>((ref, sid) {
      final user = ref.watch(authUserProvider).value;
      if (user == null || user.isAnonymous) return Stream.value(null);
      return ref.watch(societyRepositoryProvider).watchMember(sid, user.uid);
    });

// ignore: specify_nonobvious_property_types, family type isn't exported.
final membersProvider = StreamProvider.autoDispose
    .family<List<Membership>, String>(
      (ref, sid) => ref.watch(societyRepositoryProvider).watchMembers(sid),
    );

// ignore: specify_nonobvious_property_types, family type isn't exported.
final noticesProvider = StreamProvider.autoDispose
    .family<List<SocietyNotice>, String>(
      (ref, sid) => ref.watch(societyRepositoryProvider).watchNotices(sid),
    );

// ignore: specify_nonobvious_property_types, family type isn't exported.
final documentsProvider = StreamProvider.autoDispose
    .family<List<SocietyDocument>, String>(
      (ref, sid) => ref.watch(societyRepositoryProvider).watchDocuments(sid),
    );

// ignore: specify_nonobvious_property_types, family type isn't exported.
final hoaProvider = StreamProvider.autoDispose.family<HoaInfo, String>(
  (ref, sid) => ref.watch(societyRepositoryProvider).watchHoa(sid),
);

/// The invite code, for admins.
// ignore: specify_nonobvious_property_types, family type isn't exported.
final inviteCodeProvider = StreamProvider.autoDispose.family<String?, String>(
  (ref, sid) => ref.watch(societyRepositoryProvider).watchInviteCode(sid),
);

/// Reads and writes societies, memberships, notices, documents and claims.
/// Decisions that need the server (claims, invite codes) go through Cloud
/// Functions in `functions/src/society.ts`.
class SocietyRepository {
  SocietyRepository(
    this._db,
    this._storage,
    this._functions, {
    Analytics analytics = const NoAnalytics(),
  }) : _analytics = analytics;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;
  final Analytics _analytics;

  CollectionReference<Map<String, dynamic>> get _societies =>
      _db.collection('societies');

  DocumentReference<Map<String, dynamic>> _society(String sid) =>
      _societies.doc(sid);

  Query<Map<String, dynamic>> get _active =>
      _societies.where('status', isEqualTo: 'active');

  /// Active societies within [nearbySocietyM] of [point], nearest first.
  Future<List<SocietyResult>> searchNearby(GeoPoint point) async {
    // Precision-6 cells (about 1.2 by 0.6 km) and their neighbours cover
    // the radius.
    final cells = neighborGeohashes(point.lat, point.lng, precision: 6);
    final snaps = await Future.wait([
      for (final c in cells)
        _active
            .where('geohash', isGreaterThanOrEqualTo: c)
            .where('geohash', isLessThan: '$c~')
            .get(),
    ]);
    final found = <String, SocietyResult>{};
    for (final d in snaps.expand((s) => s.docs)) {
      final s = Society.fromDoc(d.id, plain(d.data()));
      final m = distanceM(point, s.location);
      if (m <= nearbySocietyM) found[s.id] = (society: s, distanceM: m);
    }
    return found.values.toList()
      ..sort((a, b) => a.distanceM!.compareTo(b.distanceM!));
  }

  /// Active societies whose name starts with [text].
  Future<List<SocietyResult>> searchByName(
    String text, {
    GeoPoint? near,
  }) async {
    final q = text.trim().toLowerCase();
    if (q.length < 2) return const [];
    final snap = await _active
        .where('nameLower', isGreaterThanOrEqualTo: q)
        .where('nameLower', isLessThan: '$q')
        .limit(20)
        .get();
    return [
      for (final d in snap.docs)
        if (Society.fromDoc(d.id, plain(d.data())) case final s)
          (
            society: s,
            distanceM: near == null ? null : distanceM(near, s.location),
          ),
    ];
  }

  Stream<Society?> watchSociety(String sid) => _society(sid).snapshots().map(
    (d) => d.exists ? Society.fromDoc(d.id, plain(d.data()!)) : null,
  );

  Stream<List<String>> watchSocietyIds(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map(
        (d) => [
          ...(d.data()?['societyIds'] as List? ?? const []).whereType<String>(),
        ],
      );

  /// Society ids of [uid]'s pending join requests.
  Stream<List<String>> watchPendingRequests(String uid) => _db
      .collectionGroup('members')
      .where('uid', isEqualTo: uid)
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs)
            if (d.data()['status'] == 'pending') d.reference.parent.parent!.id,
        ],
      );

  Stream<Membership?> watchMember(String sid, String uid) => _society(sid)
      .collection('members')
      .doc(uid)
      .snapshots()
      .map(
        (d) => d.exists ? Membership.fromDoc(d.id, plain(d.data()!)) : null,
      );

  Stream<List<Membership>> watchMembers(String sid) => _society(sid)
      .collection('members')
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs) Membership.fromDoc(d.id, plain(d.data())),
        ],
      );

  Stream<List<SocietyNotice>> watchNotices(String sid) => _society(sid)
      .collection('notices')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs) SocietyNotice.fromDoc(d.id, plain(d.data())),
        ],
      );

  Stream<List<SocietyDocument>> watchDocuments(String sid) => _society(sid)
      .collection('documents')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs)
            SocietyDocument.fromDoc(d.id, plain(d.data())),
        ],
      );

  Stream<HoaInfo> watchHoa(String sid) => _society(sid)
      .collection('hoa')
      .doc('info')
      .snapshots()
      .map((d) => HoaInfo.fromDoc(d.data()));

  Stream<String?> watchInviteCode(String sid) => _society(sid)
      .collection('private')
      .doc('invite')
      .snapshots()
      .map((d) => d.data()?['code'] as String?);

  Stream<List<SocietyClaim>> watchClaims(String uid) => _db
      .collection('societyClaims')
      .where('applicantUid', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs) SocietyClaim.fromDoc(d.id, plain(d.data())),
        ],
      );

  /// Counts a society search for analytics (results only, not the text).
  Future<void> logSearch(int results) =>
      _analytics.societySearch(results: results);

  /// Asks to join; an admin approves or declines.
  Future<void> requestToJoin(
    String sid, {
    required String uid,
    required String unit,
    String displayName = '',
  }) async {
    await _society(sid).collection('members').doc(uid).set({
      'uid': uid,
      'unit': unit.trim(),
      'displayName': _take(displayName.trim(), 60),
      'role': MemberRole.member.name,
      'status': MemberStatus.pending.name,
      'requestedAt': FieldValue.serverTimestamp(),
    });
    await _analytics.societyJoinRequested();
  }

  /// Leaves a society, or withdraws a request.
  Future<void> leave(String sid, String uid) =>
      _society(sid).collection('members').doc(uid).delete();

  /// Joins straight away with an admin's invite code. Returns the society.
  Future<String> joinWithCode(String code, {String unit = ''}) async {
    try {
      final res = await _functions
          .httpsCallable('joinWithCode')
          .call<Map<String, dynamic>>({
            'code': normalizeInviteCode(code),
            'unit': unit.trim(),
          });
      await _analytics.societyJoinedWithCode();
      return res.data['societyId'] as String;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'not-found' || e.code == 'invalid-argument') {
        throw const InvalidInviteCode();
      }
      rethrow;
    }
  }

  /// An admin's decision on someone's membership: approve, decline,
  /// remove, or a new role.
  Future<void> updateMember(
    String sid,
    String uid, {
    required String adminUid,
    MemberStatus? status,
    MemberRole? role,
  }) => _society(sid).collection('members').doc(uid).update({
    'status': ?status?.name,
    'role': ?role?.name,
    'decidedBy': adminUid,
    'decidedAt': FieldValue.serverTimestamp(),
  });

  /// Posts a notice; members get a push from the onNoticeCreated function.
  Future<void> postNotice(
    String sid, {
    required String authorUid,
    required String authorName,
    required String title,
    required String body,
    required bool pinned,
    DateTime? expiresAt,
    File? attachment,
  }) async {
    final ref = _society(sid).collection('notices').doc();
    Map<String, String>? file;
    if (attachment != null) {
      final name = attachment.uri.pathSegments.last;
      final isPdf = name.toLowerCase().endsWith('.pdf');
      final type = isPdf ? 'application/pdf' : 'image/jpeg';
      final path = 'societies/$sid/notices/${ref.id}/${_safeName(name)}';
      await _storage
          .ref(path)
          .putFile(attachment, SettableMetadata(contentType: type));
      file = {'path': path, 'name': name, 'contentType': type};
    }
    await ref.set({
      'title': cleanUserText(title.trim()),
      'body': cleanUserText(body.trim()),
      'pinned': pinned,
      'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt),
      'attachment': file,
      'authorUid': authorUid,
      'authorName': _take(authorName, 60),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteNotice(String sid, SocietyNotice notice) async {
    await _society(sid).collection('notices').doc(notice.id).delete();
    final a = notice.attachment;
    if (a != null) await _storage.ref(a.path).delete().catchError((_) {});
  }

  /// Uploads a PDF for members, then lists it.
  Future<void> uploadDocument(
    String sid, {
    required String uid,
    required String title,
    required DocumentCategory category,
    required File file,
  }) async {
    final size = await file.length();
    if (size >= maxDocumentBytes) throw const FileTooLarge(maxDocumentBytes);
    final ref = _society(sid).collection('documents').doc();
    final path = 'societies/$sid/documents/${ref.id}.pdf';
    await _storage
        .ref(path)
        .putFile(file, SettableMetadata(contentType: 'application/pdf'));
    await ref.set({
      'title': title.trim(),
      'category': category.name,
      'path': path,
      'fileName': file.uri.pathSegments.last,
      'sizeBytes': size,
      'uploadedBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteDocument(String sid, SocietyDocument doc) async {
    await _society(sid).collection('documents').doc(doc.id).delete();
    await _storage.ref(doc.path).delete().catchError((_) {});
  }

  /// A link that opens a member-only file. Fetching it needs the member's
  /// sign-in, so only members get one.
  Future<String> fileUrl(String path) => _storage.ref(path).getDownloadURL();

  Future<void> saveHoa(String sid, HoaInfo hoa) =>
      _society(sid).collection('hoa').doc('info').set({
        'company': hoa.company.trim(),
        'website': normalizeUrl(hoa.website),
        'accountUrl': normalizeUrl(hoa.accountUrl),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Replaces the invite code; the old one stops working.
  Future<String> regenerateInviteCode(String sid) async {
    final res = await _functions
        .httpsCallable('regenerateInviteCode')
        .call<Map<String, dynamic>>({'societyId': sid});
    return res.data['code'] as String;
  }

  /// Live societies and pending claims within [nearbySocietyM].
  Future<List<NearbySociety>> checkDuplicates(GeoPoint point) async {
    final res = await _functions
        .httpsCallable('checkSocietyDuplicates')
        .call<Map<String, dynamic>>({'lat': point.lat, 'lng': point.lng});
    return [
      for (final s in _maps(res.data['societies']))
        (
          name: s['name']! as String,
          pending: s['status'] == 'pending',
          distanceM: (s['distanceM']! as num).toInt(),
          societyId: s['societyId'] as String?,
        ),
    ];
  }

  /// Uploads the photo ID and proof of office, then files the claim.
  /// Files go first so a claim never points at missing files.
  Future<String> submitClaim({
    required String uid,
    required String email,
    required ClaimDraft draft,
    required File idFile,
    required File proofFile,
  }) async {
    for (final f in [idFile, proofFile]) {
      if (await f.length() >= maxClaimFileBytes) {
        throw const FileTooLarge(maxClaimFileBytes);
      }
    }
    final id = const Uuid().v4();
    final folder = 'societyClaims/$uid/$id';
    Future<String> put(String name, File f) async {
      final ext = claimFileExtension(f.path);
      final path = '$folder/$name.$ext';
      await _storage
          .ref(path)
          .putFile(f, SettableMetadata(contentType: _contentType(ext)));
      return path;
    }

    final files = {
      'id': await put('id', idFile),
      'proof': await put('proof', proofFile),
    };
    final p = draft.location;
    await _db.collection('societyClaims').doc(id).set({
      'applicantUid': uid,
      'applicantName': draft.applicantName.trim(),
      'applicantEmail': email,
      'society': {
        'name': draft.name.trim(),
        'address': draft.address.trim(),
        'lat': p.lat,
        'lng': p.lng,
        'geohash': encodeGeohash(p.lat, p.lng),
        'municipalityId': draft.municipality.id,
        'municipalityName': draft.municipality.name,
        'units': draft.units,
      },
      'position': draft.position.id,
      'hoa': {
        'company': draft.hoa.company.trim(),
        'website': normalizeUrl(draft.hoa.website),
        'accountUrl': normalizeUrl(draft.hoa.accountUrl),
      },
      'files': files,
      'status': ClaimStatus.pending.name,
      if (draft.previousClaimId.isNotEmpty)
        'previousClaimId': draft.previousClaimId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _analytics.societyClaimSubmitted();
    return id;
  }
}

List<Map<Object?, Object?>> _maps(Object? list) =>
    (list as List? ?? const []).cast<Map<Object?, Object?>>();

/// `jpg`, `png` or `pdf`, as the Storage rules allow.
String claimFileExtension(String path) {
  final ext = path.split('.').last.toLowerCase();
  return switch (ext) {
    'jpeg' || 'jpg' || 'heic' => 'jpg',
    'png' => 'png',
    _ => 'pdf',
  };
}

String _contentType(String ext) => switch (ext) {
  'jpg' => 'image/jpeg',
  'png' => 'image/png',
  _ => 'application/pdf',
};

String _safeName(String name) =>
    name.replaceAll(RegExp('[^A-Za-z0-9._-]'), '_');

String _take(String s, int n) => s.length <= n ? s : s.substring(0, n);

/// Firestore timestamps as [DateTime], so the models stay plain Dart.
Map<String, dynamic> plain(Map<String, dynamic> d) => {
  for (final MapEntry(:key, :value) in d.entries) key: _plainValue(value),
};

Object? _plainValue(Object? v) => switch (v) {
  final Timestamp t => t.toDate(),
  final Map<String, dynamic> m => plain(m),
  final List<Object?> l => l.map(_plainValue).toList(),
  _ => v,
};
