import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:fixburgh/features/services/domain/service_category.dart';
import 'package:flutter/foundation.dart';

enum ProviderStatus {
  applied,
  approved,
  rejected,
  suspended;

  static ProviderStatus parse(Object? v) =>
      values.firstWhere((s) => s.name == v, orElse: () => applied);
}

/// Bayesian prior, as functions/src/services.ts: a new provider counts as
/// [priorReviews] reviews at [priorMean] stars.
const priorReviews = 10;
const priorMean = 4.0;

double rankScore(double avg, int count) =>
    (priorReviews * priorMean + avg * count) / (priorReviews + count);

/// A provider in the directory: a business or a person offering services.
/// The doc id is the owner's uid.
@immutable
class ServiceProvider {
  const ServiceProvider({
    required this.id,
    required this.businessName,
    required this.categories,
    required this.status,
    this.description = '',
    this.phone = '',
    this.area,
    this.radiusMiles = 10,
    this.areaLabel = '',
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.rankScore = priorMean,
    this.backgroundChecked = false,
    this.portfolio = const [],
    this.rejectReason = '',
    this.documents = const {},
  });

  factory ServiceProvider.fromDoc(String id, Map<String, dynamic> d) {
    final a = (d['serviceArea'] as Map?)?.cast<String, dynamic>();
    final check = (d['backgroundCheck'] as Map?)?.cast<String, dynamic>();
    return ServiceProvider(
      id: id,
      businessName: d['businessName'] as String? ?? '',
      description: d['description'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      categories: [
        ...(d['categories'] as List? ?? const []).whereType<String>(),
      ],
      status: ProviderStatus.parse(d['status']),
      area: a == null
          ? null
          : GeoPoint(
              (a['lat'] as num?)?.toDouble() ?? 0,
              (a['lng'] as num?)?.toDouble() ?? 0,
            ),
      radiusMiles: (a?['radiusMiles'] as num?)?.toDouble() ?? 10,
      areaLabel: a?['label'] as String? ?? '',
      ratingAvg: (d['ratingAvg'] as num?)?.toDouble() ?? 0,
      ratingCount: (d['ratingCount'] as num?)?.toInt() ?? 0,
      rankScore: (d['rankScore'] as num?)?.toDouble() ?? priorMean,
      backgroundChecked: check?['status'] == 'passed',
      portfolio: [
        for (final p
            in (d['portfolio'] as List? ?? const [])
                .whereType<Map<Object?, Object?>>())
          if (p['thumbUrl'] case final String url) url,
      ],
      rejectReason: d['rejectReason'] as String? ?? '',
      documents: {
        for (final MapEntry(:key, :value)
            in ((d['documents'] as Map<Object?, Object?>?) ?? const {}).entries)
          if ((key, value) case (final String k, final String v)) k: v,
      },
    );
  }

  final String id;
  final String businessName;
  final String description;
  final String phone;
  final List<String> categories;
  final ProviderStatus status;
  final GeoPoint? area;
  final double radiusMiles;
  final String areaLabel;
  final double ratingAvg;
  final int ratingCount;
  final double rankScore;
  final bool backgroundChecked;

  /// Thumbnail links of past-job photos.
  final List<String> portfolio;
  final String rejectReason;

  /// Uploaded licence, insurance and background-check paths.
  final Map<String, String> documents;

  bool get offersPersonalCare =>
      categories.any((c) => _personalCare.contains(c));
}

/// Categories in the personal care group, which need background checks.
const _personalCare = {
  'babysitting',
  'nanny',
  'elder_care_and_companionship',
  'pet_sitting',
  'dog_walking',
  'pet_grooming',
  'tutoring',
};

/// Documents an application needs, by the categories chosen: a licence
/// for home repair, insurance for repair and home care, a background check
/// for personal care.
Set<String> requiredDocuments(
  Iterable<String> categories,
  List<ServiceCategoryGroup> groups,
) {
  final g = {for (final c in categories) groups.groupOf(c)?.id};
  return {
    if (g.contains('home_repair')) 'license',
    if (g.contains('home_repair') || g.contains('home_care')) 'insurance',
    if (g.contains(personalCareGroup)) 'background',
  };
}

@immutable
class Review {
  const Review({
    required this.id,
    required this.stars,
    required this.comment,
    this.authorName = '',
    this.reply = '',
    this.createdAt,
  });

  factory Review.fromDoc(String id, Map<String, dynamic> d) => Review(
    id: id,
    stars: (d['stars'] as num?)?.toInt() ?? 0,
    comment: d['comment'] as String? ?? '',
    authorName: d['authorName'] as String? ?? '',
    reply: d['reply'] as String? ?? '',
    createdAt: d['createdAt'] as DateTime?,
  );

  /// The service request it reviews.
  final String id;
  final int stars;
  final String comment;
  final String authorName;
  final String reply;
  final DateTime? createdAt;
}

/// A search result: the provider, how far away, and whether the person's
/// society recommends them.
typedef ProviderResult = ({
  ServiceProvider provider,
  double? distanceMiles,
  bool recommended,
});

/// Best first: recommended by the society, then rank score, then distance.
List<ProviderResult> sortResults(List<ProviderResult> results) =>
    [...results]..sort((a, b) {
      if (a.recommended != b.recommended) return a.recommended ? -1 : 1;
      final r = b.provider.rankScore.compareTo(a.provider.rankScore);
      if (r != 0) return r;
      return (a.distanceMiles ?? 1e9).compareTo(b.distanceMiles ?? 1e9);
    });

/// The distance filter options, in miles.
const distanceOptions = [2, 5, 10, 25];
