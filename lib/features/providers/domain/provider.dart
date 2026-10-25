import 'package:fixburgh/features/report/domain/report.dart' show distanceM;
import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:fixburgh/features/services/domain/service_category.dart';
import 'package:flutter/foundation.dart';

enum ProviderStatus {
  applied,
  approved,

  /// Approved, but listed only once the listing fee is recorded (Phase 4,
  /// while `feature_monetisation` is on), or after the listing ran out.
  awaitingFee,
  rejected,
  suspended;

  /// As stored, e.g. `awaiting_fee`.
  String get id => this == awaitingFee ? 'awaiting_fee' : name;

  static ProviderStatus parse(Object? v) =>
      values.firstWhere((s) => s.id == v, orElse: () => applied);
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
    this.listingPaidThrough,
    this.paymentRequest,
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
      listingPaidThrough: DateTime.tryParse(
        (d['listing'] as Map?)?['paidThrough'] as String? ?? '',
      ),
      paymentRequest: parsePaymentRequest(d['paymentRequest']),
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

  /// The last day of the paid listing, when fees apply (Phase 4).
  final DateTime? listingPaidThrough;

  /// The listing fee the Burghood team asked for, until it's recorded.
  final PaymentRequest? paymentRequest;

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

/// Fees and sponsorship settings (`config/monetisation`), placeholders until
/// the amounts are decided. Platform admins change them in the console.
typedef MonetisationSettings = ({
  double listingFeeUsd,
  int listingMonths,
  int maxSponsored,
});

const MonetisationSettings defaultMonetisation = (
  listingFeeUsd: 150,
  listingMonths: 12,
  maxSponsored: 2,
);

MonetisationSettings parseMonetisation(Map<String, dynamic>? d) => (
  listingFeeUsd:
      (d?['listingFeeUsd'] as num?)?.toDouble() ??
      defaultMonetisation.listingFeeUsd,
  listingMonths:
      (d?['listingMonths'] as num?)?.toInt() ??
      defaultMonetisation.listingMonths,
  maxSponsored:
      ((d?['maxSponsored'] as num?)?.toInt() ??
              defaultMonetisation.maxSponsored)
          .clamp(0, 2),
);

/// A sponsored listing that is paid for and showing now (Phase 4).
@immutable
class Sponsorship {
  const Sponsorship({
    required this.id,
    required this.providerId,
    required this.categories,
    required this.center,
    required this.radiusMiles,
  });

  factory Sponsorship.fromDoc(String id, Map<String, dynamic> d) {
    final a = (d['area'] as Map?)?.cast<String, dynamic>() ?? const {};
    return Sponsorship(
      id: id,
      providerId: d['providerId'] as String? ?? '',
      categories: [
        ...(d['categories'] as List? ?? const []).whereType<String>(),
      ],
      center: GeoPoint(
        (a['lat'] as num?)?.toDouble() ?? 0,
        (a['lng'] as num?)?.toDouble() ?? 0,
      ),
      radiusMiles: (a['radiusMiles'] as num?)?.toDouble() ?? 10,
    );
  }

  final String id;
  final String providerId;
  final List<String> categories;
  final GeoPoint center;
  final double radiusMiles;
}

const _metresPerMile = 1609.344;

/// Up to [max] sponsorships for a search: those for one of [categories]
/// whose area takes in [near] (any area when it's unknown), in a stable
/// order so they don't jump around between searches.
List<Sponsorship> pickSponsored(
  List<Sponsorship> all, {
  required List<String> categories,
  required GeoPoint? near,
  required int max,
}) {
  final matching = [
    for (final s in all)
      if (s.categories.any(categories.contains) &&
          (near == null ||
              distanceM(near, s.center) / _metresPerMile <= s.radiusMiles))
        s,
  ]..sort((a, b) => a.id.compareTo(b.id));
  return matching.take(max).toList();
}

/// A sponsored search result: shown above the others with a Sponsored
/// badge and an orange border.
typedef SponsoredResult = ({String sponsorshipId, ServiceProvider provider});

/// A listing fee the Burghood team asked a provider for: how much, for how
/// long, how to pay (and an optional https payment link) and by when.
typedef PaymentRequest = ({
  double amountUsd,
  int periodMonths,
  String instructions,
  String? payLink,
  DateTime? dueDate,
});

PaymentRequest? parsePaymentRequest(Object? v) {
  if (v is! Map) return null;
  final amount = (v['amountUsd'] as num?)?.toDouble();
  if (amount == null || amount <= 0) return null;
  final link = v['payLink'] as String? ?? '';
  return (
    amountUsd: amount,
    periodMonths: (v['periodMonths'] as num?)?.toInt() ?? 12,
    instructions: v['instructions'] as String? ?? '',
    // Only https links open from the app.
    payLink: link.startsWith('https://') ? link : null,
    dueDate: DateTime.tryParse(v['dueDate'] as String? ?? ''),
  );
}
