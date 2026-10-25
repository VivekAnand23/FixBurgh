import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:flutter/foundation.dart';

/// Where a service request stands. The poster and the provider each move it
/// through their own steps; see firestore.rules.
enum RequestStatus {
  posted,
  assigned,
  accepted,
  declined,
  inProgress,
  completed,
  notFixed,
  confirmed,
  closed,
  cancelled;

  /// As stored, e.g. `in_progress`.
  String get id => switch (this) {
    inProgress => 'in_progress',
    notFixed => 'not_fixed',
    _ => name,
  };

  static RequestStatus parse(Object? v) =>
      values.firstWhere((s) => s.id == v, orElse: () => posted);

  /// Still needs someone to act.
  bool get isOpen => !{confirmed, closed, cancelled}.contains(this);
}

/// Where the problem is: in the person's home, or their society's common
/// areas (the society admin picks the provider).
enum RequestScope { home, common }

typedef RequestPhoto = ({String path, String thumbPath, String thumbUrl});

/// What the provider left when marking the job done.
typedef Completion = ({
  String note,
  List<RequestPhoto> photos,
  String? videoPath,
});

@immutable
class ServiceRequest {
  const ServiceRequest({
    required this.id,
    required this.posterUid,
    required this.title,
    required this.category,
    required this.status,
    this.posterName = '',
    this.scope = RequestScope.home,
    this.societyId,
    this.description = '',
    this.group = '',
    this.details = const {},
    this.photos = const [],
    this.location,
    this.providerId,
    this.completion,
    this.declineReason = '',
    this.notFixedNote = '',
    this.createdAt,
    this.completedAt,
    this.rated = false,
  });

  factory ServiceRequest.fromDoc(String id, Map<String, dynamic> d) {
    final c = (d['completion'] as Map?)?.cast<String, dynamic>();
    final loc = (d['location'] as Map?)?.cast<String, dynamic>();
    return ServiceRequest(
      id: id,
      posterUid: d['posterUid'] as String? ?? '',
      posterName: d['posterName'] as String? ?? '',
      scope: d['scope'] == 'common' ? RequestScope.common : RequestScope.home,
      societyId: d['societyId'] as String?,
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      category: d['category'] as String? ?? '',
      group: d['group'] as String? ?? '',
      details: {
        for (final MapEntry(:key, :value)
            in ((d['details'] as Map<Object?, Object?>?) ?? const {}).entries)
          if ((key, value) case (final String k, final String v)) k: v,
      },
      photos: _photos(d['photos']),
      location: loc == null
          ? null
          : GeoPoint(
              (loc['lat'] as num?)?.toDouble() ?? 0,
              (loc['lng'] as num?)?.toDouble() ?? 0,
            ),
      providerId: d['providerId'] as String?,
      status: RequestStatus.parse(d['status']),
      completion: c == null
          ? null
          : (
              note: c['note'] as String? ?? '',
              photos: _photos(c['photos']),
              videoPath: (c['video'] as Map?)?['path'] as String?,
            ),
      declineReason: d['declineReason'] as String? ?? '',
      notFixedNote: d['notFixedNote'] as String? ?? '',
      createdAt: d['createdAt'] as DateTime?,
      completedAt: d['completedAt'] as DateTime?,
      rated: d['rated'] as bool? ?? false,
    );
  }

  final String id;
  final String posterUid;
  final String posterName;
  final RequestScope scope;
  final String? societyId;
  final String title;
  final String description;
  final String category;
  final String group;

  /// Fields that depend on the category: urgency and access for repairs,
  /// date and hours for babysitting, pet type and size for pet care.
  final Map<String, String> details;
  final List<RequestPhoto> photos;
  final GeoPoint? location;
  final String? providerId;
  final RequestStatus status;
  final Completion? completion;
  final String declineReason;
  final String notFixedNote;
  final DateTime? createdAt;
  final DateTime? completedAt;

  /// The poster has reviewed the provider.
  final bool rated;

  bool get canReview =>
      status == RequestStatus.confirmed && !rated && providerId != null;
}

/// One step in a request's timeline, written by Cloud Functions.
typedef RequestEvent = ({RequestStatus status, String note, DateTime? at});

List<RequestPhoto> _photos(Object? v) => [
  for (final p in (v as List? ?? const []).whereType<Map<Object?, Object?>>())
    (
      path: p['path'] as String? ?? '',
      thumbPath: p['thumbPath'] as String? ?? '',
      thumbUrl: p['thumbUrl'] as String? ?? '',
    ),
];

/// The extra fields a request form asks for, by category group.
enum DetailField {
  urgency,
  access,
  timeWindow,
  date,
  hours,
  childrenAges,
  petType,
  petSize,
  budget,
}

List<DetailField> detailFieldsFor(String group, String category) {
  if (category == 'babysitting' || category == 'nanny') {
    return const [
      DetailField.date,
      DetailField.hours,
      DetailField.childrenAges,
      DetailField.budget,
    ];
  }
  if (category.startsWith('pet_') || category == 'dog_walking') {
    return const [
      DetailField.date,
      DetailField.petType,
      DetailField.petSize,
      DetailField.budget,
    ];
  }
  return switch (group) {
    'home_repair' || 'home_care' => const [
      DetailField.urgency,
      DetailField.timeWindow,
      DetailField.access,
      DetailField.budget,
    ],
    _ => const [DetailField.date, DetailField.timeWindow, DetailField.budget],
  };
}
