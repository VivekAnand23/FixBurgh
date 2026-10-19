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
  other('other', Icons.more_horiz);

  const ReportCategory(this.id, this.icon);

  final String id;
  final IconData icon;

  static ReportCategory fromId(String id) =>
      values.firstWhere((c) => c.id == id, orElse: () => other);
}

enum Severity {
  low,
  medium,
  urgent;

  static Severity fromId(String id) =>
      values.firstWhere((s) => s.name == id, orElse: () => medium);
}

enum ReportStatus {
  reported,
  sent,
  resolved;

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

  factory ReportDraft.fromJson(Map<String, Object?> j) {
    final m = j['municipality'] as Map<String, Object?>?;
    final cat = j['category'] as String?;
    return ReportDraft(
      photoPaths: (j['photoPaths'] as List?)?.cast<String>() ?? const [],
      location: j['lat'] is num && j['lng'] is num
          ? GeoPoint(
              (j['lat']! as num).toDouble(),
              (j['lng']! as num).toDouble(),
            )
          : null,
      accuracyM: (j['accuracyM'] as num?)?.toDouble(),
      address: j['address'] as String?,
      municipality: m == null
          ? null
          : Municipality(
              id: m['id']! as String,
              name: m['name']! as String,
              type: m['type']! as String,
            ),
      category: cat == null ? null : ReportCategory.fromId(cat),
      severity: Severity.fromId(j['severity'] as String? ?? ''),
      description: j['description'] as String? ?? '',
    );
  }

  final List<String> photoPaths;
  final GeoPoint? location;
  final double? accuracyM;
  final String? address;
  final Municipality? municipality;
  final ReportCategory? category;
  final Severity severity;
  final String description;

  bool get isEmpty =>
      photoPaths.isEmpty && location == null && category == null;

  bool get hasPhoto => photoPaths.isNotEmpty;
  bool get hasLocation => location != null && municipality != null;
  bool get isComplete => hasPhoto && hasLocation && category != null;

  Map<String, Object?> toJson() => {
    'photoPaths': photoPaths,
    if (location != null) 'lat': location!.lat,
    if (location != null) 'lng': location!.lng,
    'accuracyM': accuracyM,
    'address': address,
    if (municipality != null)
      'municipality': {
        'id': municipality!.id,
        'name': municipality!.name,
        'type': municipality!.type,
      },
    'category': category?.id,
    'severity': severity.name,
    'description': description,
  };

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
    this.sentAt,
    this.resolvedAt,
    this.resolvedBy,
    this.afterThumbUrl,
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
  final DateTime? sentAt;
  final DateTime? resolvedAt;

  /// `reporter`, `community` or (Phase 3) `agency`.
  final String? resolvedBy;

  /// Thumbnail of the optional "after" photo added when marked fixed.
  final String? afterThumbUrl;

  bool get isOpen => status != ReportStatus.resolved;

  /// The reporter can reopen a fix that didn't hold, for 30 days
  /// (BRD FR-MYR-03).
  bool canReopen({DateTime? now}) =>
      status == ReportStatus.resolved &&
      (now ?? DateTime.now()).difference(resolvedAt ?? createdAt) <=
          reopenWindow;

  /// The open status a reopened report goes back to.
  ReportStatus get reopenStatus =>
      sentAt != null ? ReportStatus.sent : ReportStatus.reported;
}

const reopenWindow = Duration(days: 30);

/// What happened to a report, for its status timeline (BRD FR-MAP-09).
enum ReportEventType {
  reported,
  sent,
  resolved,
  reopened;

  static ReportEventType fromId(String id) =>
      values.firstWhere((t) => t.name == id, orElse: () => reported);
}

@immutable
class ReportEvent {
  const ReportEvent({
    required this.type,
    required this.at,
    this.by,
    this.channel,
    this.photoUrl,
  });

  final ReportEventType type;
  final DateTime at;

  /// `reporter` or `community`.
  final String? by;

  /// For `sent`: `call`, `email` or `web`.
  final String? channel;

  /// For `resolved`: the "after" photo, if one was added.
  final String? photoUrl;
}

/// The report's history, oldest first. Reports filed before history was
/// recorded have no events (or only the later ones), so the missing early
/// steps are rebuilt from the report's timestamps.
List<ReportEvent> reportTimeline(Report r, List<ReportEvent> events) {
  if (events.isNotEmpty) {
    final types = events.map((e) => e.type).toSet();
    final first = events
        .map((e) => e.at)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    return [
      if (!types.contains(ReportEventType.reported))
        ReportEvent(type: ReportEventType.reported, at: r.createdAt),
      if (!types.contains(ReportEventType.sent) &&
          r.sentAt != null &&
          r.sentAt!.isBefore(first))
        ReportEvent(type: ReportEventType.sent, at: r.sentAt!),
      ...events,
    ]..sort((a, b) => a.at.compareTo(b.at));
  }
  return [
    ReportEvent(type: ReportEventType.reported, at: r.createdAt),
    if (r.sentAt != null)
      ReportEvent(type: ReportEventType.sent, at: r.sentAt!),
    if (r.status == ReportStatus.resolved)
      ReportEvent(
        type: ReportEventType.resolved,
        at: r.resolvedAt ?? r.createdAt,
        by: r.resolvedBy,
        photoUrl: r.afterThumbUrl,
      ),
  ];
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
