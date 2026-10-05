import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/report/domain/geohash.dart';
import 'package:fixburgh/features/report/domain/report.dart';
import 'package:fixburgh/features/routing/domain/municipality_locator.dart'
    as geo;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

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
    void Function(double progress)? onProgress,
  }) async {
    final location = draft.location!;
    final reportId = const Uuid().v4();
    final photos = <Map<String, dynamic>>[];
    final steps = draft.photoPaths.length * 2;
    var done = 0;

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

    final description = draft.description.trim();
    await _reports.doc(reportId).set({
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
      'status': ReportStatus.reported.name,
      'upvoteCount': 0,
      'flagCount': 0,
      'moderation': 'visible',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return reportId;
  }

  Stream<List<Report>> watchMine(String uid) => _reports
      .where('authorUid', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(_fromDoc).toList());

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

  static Report _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    final g = (m['geo'] as Map?)?.cast<String, dynamic>() ?? const {};
    final photos = (m['photos'] as List?)?.cast<Map<String, dynamic>>();
    return Report(
      id: d.id,
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
