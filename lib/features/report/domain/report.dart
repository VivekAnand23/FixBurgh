import 'dart:math' as math;

import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:flutter/material.dart';

/// Issue categories (BRD FR-REP-09). [id] is the value stored in Firestore.
enum ReportCategory {
  pothole('pothole', Icons.warning_amber_rounded),
  landslide('landslide', Icons.landslide_outlined),
  flooding('flooding', Icons.water_drop_outlined),
  streetlight('streetlight', Icons.lightbulb_outline),
  dumping('dumping', Icons.delete_outline),
  fallenTree('fallen_tree', Icons.park_outlined),
  sidewalk('sidewalk', Icons.directions_walk),
  other('other', Icons.more_horiz)
  ;

  const ReportCategory(this.id, this.icon);

  final String id;
  final IconData icon;

  static ReportCategory fromId(String id) =>
      values.firstWhere((c) => c.id == id, orElse: () => other);
}

enum Severity {
  low,
  medium,
  urgent
  ;

  static Severity fromId(String id) =>
      values.firstWhere((s) => s.name == id, orElse: () => medium);
}

enum ReportStatus {
  reported,
  sent,
  resolved
  ;

  static ReportStatus fromId(String id) =>
      values.firstWhere((s) => s.name == id, orElse: () => reported);
}

const maxPhotos = 3;
const maxDescriptionLength = 280;

/// What the user has entered so far in the report flow.
@immutable
class ReportDraft {
  const ReportDraft({
    this.photoPaths = const [],
    this.location,
    this.accuracyM,
    this.address,
    this.municipality,
    this.category,
    this.severity = Severity.medium,
    this.description = '',
  });

  final List<String> photoPaths;
  final GeoPoint? location;
  final double? accuracyM;
  final String? address;
  final Municipality? municipality;
  final ReportCategory? category;
  final Severity severity;
  final String description;

  bool get hasPhoto => photoPaths.isNotEmpty;
  bool get hasLocation => location != null && municipality != null;
  bool get isComplete => hasPhoto && hasLocation && category != null;

  ReportDraft copyWith({
    List<String>? photoPaths,
    GeoPoint? location,
    double? accuracyM,
    bool clearAccuracy = false,
    String? address,
    Municipality? municipality,
    bool clearMunicipality = false,
    ReportCategory? category,
    Severity? severity,
    String? description,
  }) => ReportDraft(
    photoPaths: photoPaths ?? this.photoPaths,
    location: location ?? this.location,
    accuracyM: clearAccuracy ? null : accuracyM ?? this.accuracyM,
    address: address ?? this.address,
    municipality: clearMunicipality ? null : municipality ?? this.municipality,
    category: category ?? this.category,
    severity: severity ?? this.severity,
    description: description ?? this.description,
  );
}

/// A submitted report as stored in Firestore.
@immutable
class Report {
  const Report({
    required this.id,
    required this.category,
    required this.severity,
    required this.status,
    required this.location,
    required this.municipalityName,
    required this.createdAt,
    this.authorUid = '',
    this.address,
    this.description = '',
    this.thumbUrl,
    this.photoPaths = const [],
    this.upvoteCount = 0,
    this.fixedVoteCount = 0,
    this.agencyName,
    this.resolvedAt,
  });

  final String id;
  final String authorUid;
  final ReportCategory category;
  final Severity severity;
  final ReportStatus status;
  final GeoPoint location;
  final String municipalityName;
  final String? address;
  final String description;
  final String? thumbUrl;

  /// Storage paths of every uploaded image (full and thumbnail).
  final List<String> photoPaths;
  final int upvoteCount;
  final int fixedVoteCount;
  final String? agencyName;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  bool get isOpen => status != ReportStatus.resolved;
}

/// Great-circle distance in metres (haversine).
double distanceM(GeoPoint a, GeoPoint b) {
  const r = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(b.lat - a.lat);
  final dLng = rad(b.lng - a.lng);
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.lat)) *
          math.cos(rad(b.lat)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(h));
}

/// Reports closer than this with the same category are likely duplicates.
const duplicateRadiusM = 50.0;
