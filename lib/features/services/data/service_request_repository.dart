import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart' hide GeoPoint;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fixburgh/app/analytics.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/moderation/text_filter.dart';
import 'package:fixburgh/features/report/domain/geohash.dart';
import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:fixburgh/features/services/domain/service_request.dart';
import 'package:fixburgh/features/society/data/society_repository.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Largest completion video, as the Storage rules allow.
const int maxVideoBytes = 30 * 1024 * 1024;

final serviceRequestRepositoryProvider = Provider<ServiceRequestRepository>(
  (ref) => ServiceRequestRepository(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
    analytics: ref.watch(analyticsProvider),
  ),
);

/// Requests the signed-in person posted, newest first.
final StreamProvider<List<ServiceRequest>> myServiceRequestsProvider =
    StreamProvider.autoDispose<List<ServiceRequest>>((ref) {
      final uid = ref.watch(authUserProvider).value?.uid;
      if (uid == null) return Stream.value(const []);
      return ref.watch(serviceRequestRepositoryProvider).watchPosted(uid);
    });

/// Jobs sent to the signed-in provider, newest first.
final StreamProvider<List<ServiceRequest>> myJobsProvider =
    StreamProvider.autoDispose<List<ServiceRequest>>((ref) {
      final uid = ref.watch(authUserProvider).value?.uid;
      if (uid == null) return Stream.value(const []);
      return ref.watch(serviceRequestRepositoryProvider).watchJobs(uid);
    });

/// A society's common-area requests, for its admins.
// ignore: specify_nonobvious_property_types, family type isn't exported.
final commonRequestsProvider = StreamProvider.autoDispose
    .family<List<ServiceRequest>, String>(
      (ref, sid) =>
          ref.watch(serviceRequestRepositoryProvider).watchCommon(sid),
    );

// ignore: specify_nonobvious_property_types, family type isn't exported.
final serviceRequestProvider = StreamProvider.autoDispose
    .family<ServiceRequest?, String>(
      (ref, id) => ref.watch(serviceRequestRepositoryProvider).watch(id),
    );

// ignore: specify_nonobvious_property_types, family type isn't exported.
final requestEventsProvider = StreamProvider.autoDispose
    .family<List<RequestEvent>, String>(
      (ref, id) => ref.watch(serviceRequestRepositoryProvider).watchEvents(id),
    );

/// What someone fills in to post a request.
typedef RequestDraft = ({
  RequestScope scope,
  String? societyId,
  String title,
  String description,
  String category,
  String group,
  Map<String, String> details,
  List<File> photos,
  GeoPoint? location,
  String? providerId,
});

/// Service requests at `serviceRequests/{id}`. Status pushes and the
/// timeline come from Cloud Functions (functions/src/services.ts).
class ServiceRequestRepository {
  ServiceRequestRepository(
    this._db,
    this._storage, {
    Analytics analytics = const NoAnalytics(),
  }) : _analytics = analytics;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final Analytics _analytics;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('serviceRequests');

  Stream<List<ServiceRequest>> _list(Query<Map<String, dynamic>> q) => q
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs) ServiceRequest.fromDoc(d.id, plain(d.data())),
        ],
      );

  Stream<List<ServiceRequest>> watchPosted(String uid) =>
      _list(_requests.where('posterUid', isEqualTo: uid));

  Stream<List<ServiceRequest>> watchJobs(String uid) =>
      _list(_requests.where('providerId', isEqualTo: uid));

  Stream<List<ServiceRequest>> watchCommon(String sid) => _list(
    _requests
        .where('societyId', isEqualTo: sid)
        .where('scope', isEqualTo: 'common'),
  );

  Stream<ServiceRequest?> watch(String id) => _requests
      .doc(id)
      .snapshots()
      .map(
        (d) => d.exists ? ServiceRequest.fromDoc(d.id, plain(d.data()!)) : null,
      );

  Stream<List<RequestEvent>> watchEvents(String id) => _requests
      .doc(id)
      .collection('events')
      .orderBy('at')
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs)
            (
              status: RequestStatus.parse(d.data()['status']),
              note: d.data()['note'] as String? ?? '',
              at: (d.data()['at'] as Timestamp?)?.toDate(),
            ),
        ],
      );

  /// A new id, so a retry after a dropped connection reuses it.
  String newId() => _requests.doc().id;

  Future<bool> existsOnServer(String id) async {
    try {
      final doc = await _requests
          .doc(id)
          .get(const GetOptions(source: Source.server));
      return doc.exists;
    } on FirebaseException catch (e) {
      // Reading one that doesn't exist yet is denied by the read rule.
      if (e.code == 'permission-denied') return false;
      rethrow;
    }
  }

  /// Uploads the photos (compressed, without location data), then posts.
  /// With [id] from an earlier attempt, it continues that request.
  Future<String> post(
    RequestDraft draft, {
    required String uid,
    required String posterName,
    String? id,
  }) async {
    final rid = id ?? newId();
    final photos = <Map<String, String>>[];
    for (final (i, f) in draft.photos.take(6).indexed) {
      photos.add(await _uploadPhoto(f, 'serviceRequests/$rid', '$i'));
    }
    final loc = draft.location;
    await _requests.doc(rid).set({
      'posterUid': uid,
      'posterName': posterName.length > 60
          ? posterName.substring(0, 60)
          : posterName,
      'scope': draft.scope.name,
      'societyId': draft.societyId,
      'title': cleanUserText(draft.title.trim()),
      'description': cleanUserText(draft.description.trim()),
      'category': draft.category,
      'group': draft.group,
      'details': draft.details,
      'photos': photos,
      'location': loc == null
          ? null
          : {
              'lat': loc.lat,
              'lng': loc.lng,
              'geohash': encodeGeohash(loc.lat, loc.lng),
            },
      'providerId': draft.providerId,
      'status': draft.providerId == null ? 'posted' : 'assigned',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _analytics.serviceRequestPosted(
      category: draft.category,
      scope: draft.scope.name,
      hasProvider: draft.providerId != null,
    );
    return rid;
  }

  Future<void> _step(String id, Map<String, Object?> data) async {
    await _requests.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _analytics.serviceRequestStep(data['status']! as String);
  }

  Future<void> assign(String id, String providerId) =>
      _step(id, {'providerId': providerId, 'status': 'assigned'});

  Future<void> cancel(String id) => _step(id, {'status': 'cancelled'});

  Future<void> accept(String id) => _step(id, {'status': 'accepted'});

  Future<void> decline(String id, String reason) =>
      _step(id, {'status': 'declined', 'declineReason': reason.trim()});

  Future<void> start(String id) => _step(id, {'status': 'in_progress'});

  /// The provider marks the job done, with a note and before/after photos
  /// or a short video.
  Future<void> complete(
    String id, {
    required String note,
    List<File> photos = const [],
    File? video,
  }) async {
    final folder = 'serviceRequests/$id/completion';
    final uploaded = <Map<String, String>>[];
    for (final f in photos.take(6)) {
      uploaded.add(await _uploadPhoto(f, folder, const Uuid().v4()));
    }
    Map<String, String>? clip;
    if (video != null) {
      final path = '$folder/${const Uuid().v4()}.mp4';
      await _storage
          .ref(path)
          .putFile(video, SettableMetadata(contentType: 'video/mp4'));
      clip = {'path': path};
    }
    await _step(id, {
      'status': 'completed',
      'completion': {
        'note': cleanUserText(note.trim()),
        'photos': uploaded,
        'video': clip,
      },
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> confirm(String id) => _step(id, {
    'status': 'confirmed',
    'confirmedAt': FieldValue.serverTimestamp(),
  });

  Future<void> notFixed(String id, String note) =>
      _step(id, {'status': 'not_fixed', 'notFixedNote': note.trim()});

  /// A link to a request photo or the completion video.
  Future<String> fileUrl(String path) => _storage.ref(path).getDownloadURL();

  Future<Map<String, String>> _uploadPhoto(
    File f,
    String folder,
    String name,
  ) async {
    final meta = SettableMetadata(contentType: 'image/jpeg');
    final full = _storage.ref('$folder/$name.jpg');
    final thumb = _storage.ref('$folder/${name}_thumb.jpg');
    await full.putData(await _compress(f, 1600, 80), meta);
    await thumb.putData(await _compress(f, 480, 70), meta);
    return {
      'path': full.fullPath,
      'thumbPath': thumb.fullPath,
      'thumbUrl': await thumb.getDownloadURL(),
    };
  }

  static Future<Uint8List> _compress(File f, int size, int quality) async =>
      await FlutterImageCompress.compressWithFile(
        f.path,
        minWidth: size,
        minHeight: size,
        quality: quality,
      ) ??
      await f.readAsBytes();
}
