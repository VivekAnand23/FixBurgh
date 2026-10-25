import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart' hide GeoPoint;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/providers/domain/provider.dart';
import 'package:fixburgh/features/report/domain/geohash.dart';
import 'package:fixburgh/features/report/domain/report.dart' show distanceM;
import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:fixburgh/features/services/domain/service_category.dart';
import 'package:fixburgh/features/society/data/society_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

const _metresPerMile = 1609.344;

final providerRepositoryProvider = Provider<ProviderRepository>(
  (ref) =>
      ProviderRepository(FirebaseFirestore.instance, FirebaseStorage.instance),
);

// ignore: specify_nonobvious_property_types, family type isn't exported.
final providerProvider = StreamProvider.autoDispose
    .family<ServiceProvider?, String>(
      (ref, id) => ref.watch(providerRepositoryProvider).watch(id),
    );

/// The signed-in person's own provider profile, if they applied.
final StreamProvider<ServiceProvider?> myProviderProvider =
    StreamProvider.autoDispose<ServiceProvider?>((ref) {
      final uid = ref.watch(authUserProvider).value?.uid;
      if (uid == null) return Stream.value(null);
      return ref.watch(providerRepositoryProvider).watch(uid);
    });

// ignore: specify_nonobvious_property_types, family type isn't exported.
final reviewsProvider = StreamProvider.autoDispose.family<List<Review>, String>(
  (ref, id) => ref.watch(providerRepositoryProvider).watchReviews(id),
);

/// Providers the society's admins recommend.
// ignore: specify_nonobvious_property_types, family type isn't exported.
final recommendedProvider = StreamProvider.autoDispose
    .family<Set<String>, String>(
      (ref, sid) => ref.watch(providerRepositoryProvider).watchRecommended(sid),
    );

/// A provider search: by the categories picked (or detected in the text),
/// and by the text's words, within `miles` of `near`. Compared by value, so
/// it can key [providerSearchProvider].
@immutable
class ProviderQuery {
  const ProviderQuery({
    required this.text,
    required this.categories,
    required this.miles,
    this.near,
    this.societyId,
  });

  final String text;
  final List<String> categories;
  final GeoPoint? near;
  final int miles;
  final String? societyId;

  @override
  bool operator ==(Object other) =>
      other is ProviderQuery &&
      other.text == text &&
      listEquals(other.categories, categories) &&
      other.near?.lat == near?.lat &&
      other.near?.lng == near?.lng &&
      other.miles == miles &&
      other.societyId == societyId;

  @override
  int get hashCode => Object.hash(
    text,
    Object.hashAll(categories),
    near?.lat,
    near?.lng,
    miles,
    societyId,
  );
}

// ignore: specify_nonobvious_property_types, family type isn't exported.
final providerSearchProvider = FutureProvider.autoDispose
    .family<List<ProviderResult>, ProviderQuery>(
      (ref, q) async {
        final recommended = q.societyId == null
            ? const <String>{}
            : await ref.watch(recommendedProvider(q.societyId!).future);
        return ref
            .watch(providerRepositoryProvider)
            .search(q, recommended: recommended);
      },
      // Show the error (e.g. a missing index) instead of retrying forever.
      retry: (_, _) => null,
    );

/// Provider profiles, reviews and applications. Approval, ratings and
/// keywords are handled by Cloud Functions (functions/src/services.ts).
class ProviderRepository {
  ProviderRepository(this._db, this._storage);

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _providers =>
      _db.collection('providers');

  Stream<ServiceProvider?> watch(String id) => _providers
      .doc(id)
      .snapshots()
      .map(
        (d) =>
            d.exists ? ServiceProvider.fromDoc(d.id, plain(d.data()!)) : null,
      );

  Stream<List<Review>> watchReviews(String id) => _providers
      .doc(id)
      .collection('reviews')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map(
        (s) => [for (final d in s.docs) Review.fromDoc(d.id, plain(d.data()))],
      );

  Stream<Set<String>> watchRecommended(String sid) => _db
      .collection('societies')
      .doc(sid)
      .collection('recommended')
      .snapshots()
      .map((s) => {for (final d in s.docs) d.id});

  Future<List<ProviderResult>> search(
    ProviderQuery q, {
    Set<String> recommended = const {},
  }) async {
    final approved = _providers.where('status', isEqualTo: 'approved');
    final words = searchTokens(q.text).take(10).toList();
    final snaps = await Future.wait([
      if (q.categories.isNotEmpty)
        approved
            .where(
              'categories',
              arrayContainsAny: q.categories.take(10).toList(),
            )
            .orderBy('rankScore', descending: true)
            .limit(50)
            .get(),
      if (words.isNotEmpty)
        approved
            .where('keywords', arrayContainsAny: words)
            .orderBy('rankScore', descending: true)
            .limit(50)
            .get(),
      if (q.categories.isEmpty && words.isEmpty)
        approved.orderBy('rankScore', descending: true).limit(50).get(),
    ]);
    final byId = <String, ProviderResult>{};
    for (final d in snaps.expand((s) => s.docs)) {
      final p = ServiceProvider.fromDoc(d.id, plain(d.data()));
      final miles = q.near == null || p.area == null
          ? null
          : distanceM(q.near!, p.area!) / _metresPerMile;
      if (miles != null && miles > q.miles) continue;
      byId[p.id] = (
        provider: p,
        distanceMiles: miles,
        recommended: recommended.contains(p.id),
      );
    }
    return sortResults(byId.values.toList());
  }

  /// Uploads the documents, then files (or resubmits) the application.
  Future<void> apply({
    required String uid,
    required String businessName,
    required String description,
    required String phone,
    required List<String> categories,
    required GeoPoint area,
    required double radiusMiles,
    required String areaLabel,
    required Map<String, File> documents,
    ServiceProvider? existing,
  }) async {
    final paths = <String, String>{...?existing?.documents};
    for (final MapEntry(key: kind, value: f) in documents.entries) {
      final ext = _ext(f.path);
      final path = 'providerDocs/$uid/$kind.$ext';
      if (paths[kind] == path) continue; // Write-once; already there.
      await _storage
          .ref(path)
          .putFile(f, SettableMetadata(contentType: _type(ext)));
      paths[kind] = path;
    }
    final data = <String, Object?>{
      'ownerUid': uid,
      'businessName': businessName.trim(),
      'description': description.trim(),
      'phone': phone.trim(),
      'categories': categories,
      'serviceArea': {
        'lat': area.lat,
        'lng': area.lng,
        'geohash': encodeGeohash(area.lat, area.lng),
        'radiusMiles': radiusMiles,
        'label': areaLabel,
      },
      'documents': paths,
      'status': 'applied',
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final ref = _providers.doc(uid);
    if (existing == null) {
      await ref.set({
        ...data,
        'portfolio': <Object>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.update(data);
    }
  }

  /// Details a live provider can change any time.
  Future<void> updateDetails(
    String uid, {
    required String businessName,
    required String description,
    required String phone,
  }) => _providers.doc(uid).update({
    'businessName': businessName.trim(),
    'description': description.trim(),
    'phone': phone.trim(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  /// Adds a past-job photo to the public profile.
  Future<void> addPortfolioPhoto(String uid, File photo) async {
    final path = 'providers/$uid/portfolio/${const Uuid().v4()}.jpg';
    final ref = _storage.ref(path);
    final bytes =
        await FlutterImageCompress.compressWithFile(
          photo.path,
          minWidth: 1200,
          minHeight: 1200,
          quality: 80,
        ) ??
        await photo.readAsBytes();
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    await _providers.doc(uid).update({
      'portfolio': FieldValue.arrayUnion([
        {'path': path, 'thumbUrl': await ref.getDownloadURL()},
      ]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// The poster's review of a confirmed job (one per job).
  Future<void> review({
    required String providerId,
    required String requestId,
    required String uid,
    required String authorName,
    required int stars,
    required String comment,
    required String category,
  }) => _providers.doc(providerId).collection('reviews').doc(requestId).set({
    'stars': stars,
    'comment': comment.trim(),
    'authorUid': uid,
    'authorName': authorName,
    'category': category,
    'createdAt': FieldValue.serverTimestamp(),
  });

  Future<void> reply(String providerId, String reviewId, String reply) =>
      _providers.doc(providerId).collection('reviews').doc(reviewId).update({
        'reply': reply.trim(),
        'replyAt': FieldValue.serverTimestamp(),
      });

  Future<void> setRecommended(
    String sid,
    String providerId, {
    required String uid,
    required bool recommended,
  }) {
    final ref = _db
        .collection('societies')
        .doc(sid)
        .collection('recommended')
        .doc(providerId);
    return recommended
        ? ref.set({'by': uid, 'at': FieldValue.serverTimestamp()})
        : ref.delete();
  }
}

String _ext(String path) => switch (path.split('.').last.toLowerCase()) {
  'jpg' || 'jpeg' || 'heic' => 'jpg',
  'png' => 'png',
  _ => 'pdf',
};

String _type(String ext) => switch (ext) {
  'jpg' => 'image/jpeg',
  'png' => 'image/png',
  _ => 'application/pdf',
};
