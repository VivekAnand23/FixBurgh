import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:flutter/foundation.dart';

/// A verified society: an HOA, condo association or apartment community.
/// Created by the decideClaim function once a platform admin has checked
/// its first admin's documents.
@immutable
class Society {
  const Society({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.units,
    this.municipalityName = '',
    this.verified = true,
    this.memberCount = 0,
    this.pendingCount = 0,
    this.adminUids = const [],
  });

  factory Society.fromDoc(String id, Map<String, dynamic> d) => Society(
    id: id,
    name: d['name'] as String? ?? '',
    address: d['address'] as String? ?? '',
    location: GeoPoint(
      (d['lat'] as num?)?.toDouble() ?? 0,
      (d['lng'] as num?)?.toDouble() ?? 0,
    ),
    units: (d['units'] as num?)?.toInt() ?? 0,
    municipalityName: d['municipalityName'] as String? ?? '',
    verified: d['verified'] as bool? ?? false,
    memberCount: (d['memberCount'] as num?)?.toInt() ?? 0,
    pendingCount: (d['pendingCount'] as num?)?.toInt() ?? 0,
    adminUids: [...(d['adminUids'] as List? ?? const []).whereType<String>()],
  );

  final String id;
  final String name;
  final String address;
  final GeoPoint location;

  /// Homes in the society, as its admin gave them.
  final int units;
  final String municipalityName;
  final bool verified;
  final int memberCount;

  /// Join requests waiting for an admin.
  final int pendingCount;
  final List<String> adminUids;

  /// Up to two initials for the avatar, e.g. "MC" for Maple Court HOA.
  String get initials {
    final words = name
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && w[0].toUpperCase() != w[0].toLowerCase())
        .toList();
    return words.take(2).map((w) => w[0].toUpperCase()).join();
  }
}

/// A society found by search, with how far it is from the searched spot.
typedef SocietyResult = ({Society society, double? distanceM});

enum MemberRole {
  member,
  committee,
  admin;

  static MemberRole parse(Object? v) =>
      values.firstWhere((r) => r.name == v, orElse: () => member);

  /// Admins and committee members post notices.
  bool get canPostNotices => this != member;
}

enum MemberStatus {
  pending,
  approved,
  declined,
  removed;

  static MemberStatus parse(Object? v) =>
      values.firstWhere((s) => s.name == v, orElse: () => pending);
}

/// Someone's membership of a society, at `societies/{sid}/members/{uid}`.
@immutable
class Membership {
  const Membership({
    required this.uid,
    required this.role,
    required this.status,
    this.unit = '',
    this.displayName = '',
    this.requestedAt,
  });

  factory Membership.fromDoc(String uid, Map<String, dynamic> d) => Membership(
    uid: uid,
    role: MemberRole.parse(d['role']),
    status: MemberStatus.parse(d['status']),
    unit: d['unit'] as String? ?? '',
    displayName: d['displayName'] as String? ?? '',
    requestedAt: _date(d['requestedAt']),
  );

  final String uid;
  final MemberRole role;
  final MemberStatus status;
  final String unit;
  final String displayName;
  final DateTime? requestedAt;

  bool get isApproved => status == MemberStatus.approved;
  bool get isAdmin => isApproved && role == MemberRole.admin;
  bool get canPostNotices => isApproved && role.canPostNotices;
}

/// An announcement from a society's admins or committee.
@immutable
class SocietyNotice {
  const SocietyNotice({
    required this.id,
    required this.title,
    required this.body,
    required this.authorUid,
    this.authorName = '',
    this.pinned = false,
    this.createdAt,
    this.expiresAt,
    this.attachment,
  });

  factory SocietyNotice.fromDoc(String id, Map<String, dynamic> d) {
    final a = (d['attachment'] as Map?)?.cast<String, dynamic>();
    return SocietyNotice(
      id: id,
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      authorUid: d['authorUid'] as String? ?? '',
      authorName: d['authorName'] as String? ?? '',
      pinned: d['pinned'] as bool? ?? false,
      createdAt: _date(d['createdAt']),
      expiresAt: _date(d['expiresAt']),
      attachment: a == null
          ? null
          : (
              path: a['path'] as String? ?? '',
              name: a['name'] as String? ?? '',
              contentType: a['contentType'] as String? ?? '',
            ),
    );
  }

  final String id;
  final String title;
  final String body;
  final String authorUid;
  final String authorName;
  final bool pinned;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final NoticeAttachment? attachment;

  bool isExpired(DateTime now) => expiresAt != null && !expiresAt!.isAfter(now);
}

typedef NoticeAttachment = ({String path, String name, String contentType});

/// Pinned notices first, then newest; expired ones last.
List<SocietyNotice> sortNotices(List<SocietyNotice> notices, DateTime now) {
  int rank(SocietyNotice n) => n.isExpired(now) ? 2 : (n.pinned ? 0 : 1);
  final epoch = DateTime.fromMillisecondsSinceEpoch(0);
  return [...notices]..sort((a, b) {
    final r = rank(a).compareTo(rank(b));
    return r != 0 ? r : (b.createdAt ?? epoch).compareTo(a.createdAt ?? epoch);
  });
}

enum DocumentCategory { bylaws, minutes, budget, rules, other }

/// A PDF shared with a society's members.
@immutable
class SocietyDocument {
  const SocietyDocument({
    required this.id,
    required this.title,
    required this.category,
    required this.path,
    this.fileName = '',
    this.sizeBytes = 0,
    this.createdAt,
  });

  factory SocietyDocument.fromDoc(String id, Map<String, dynamic> d) =>
      SocietyDocument(
        id: id,
        title: d['title'] as String? ?? '',
        category: DocumentCategory.values.firstWhere(
          (c) => c.name == d['category'],
          orElse: () => DocumentCategory.other,
        ),
        path: d['path'] as String? ?? '',
        fileName: d['fileName'] as String? ?? '',
        sizeBytes: (d['sizeBytes'] as num?)?.toInt() ?? 0,
        createdAt: _date(d['createdAt']),
      );

  final String id;
  final String title;
  final DocumentCategory category;
  final String path;
  final String fileName;
  final int sizeBytes;
  final DateTime? createdAt;
}

/// The HOA management company and the one link to its account section.
/// Burghood stores links only, never balances or payment details.
@immutable
class HoaInfo {
  const HoaInfo({this.company = '', this.website = '', this.accountUrl = ''});

  factory HoaInfo.fromDoc(Map<String, dynamic>? d) => HoaInfo(
    company: d?['company'] as String? ?? '',
    website: d?['website'] as String? ?? '',
    accountUrl: d?['accountUrl'] as String? ?? '',
  );

  final String company;
  final String website;
  final String accountUrl;
}

/// The claimant's role in the society.
enum ClaimPosition { president, secretary, boardMember, manager }

extension ClaimPositionId on ClaimPosition {
  /// As stored, e.g. `board_member`.
  String get id => this == ClaimPosition.boardMember ? 'board_member' : name;
}

enum ClaimStatus { pending, approved, rejected }

/// A request to become a society's first admin, checked by a platform
/// admin in the web console.
@immutable
class SocietyClaim {
  const SocietyClaim({
    required this.id,
    required this.societyName,
    required this.address,
    required this.status,
    this.reason = '',
    this.societyId,
    this.createdAt,
    this.decidedAt,
    this.data = const {},
  });

  factory SocietyClaim.fromDoc(String id, Map<String, dynamic> d) {
    final s = (d['society'] as Map?)?.cast<String, dynamic>() ?? const {};
    return SocietyClaim(
      id: id,
      societyName: s['name'] as String? ?? '',
      address: s['address'] as String? ?? '',
      status: ClaimStatus.values.firstWhere(
        (c) => c.name == d['status'],
        orElse: () => ClaimStatus.pending,
      ),
      reason: d['reason'] as String? ?? '',
      societyId: d['societyId'] as String?,
      createdAt: _date(d['createdAt']),
      decidedAt: _date(d['decidedAt']),
      data: d,
    );
  }

  final String id;
  final String societyName;
  final String address;
  final ClaimStatus status;

  /// Why it was rejected, from the platform admin.
  final String reason;

  /// The new society, once approved.
  final String? societyId;
  final DateTime? createdAt;
  final DateTime? decidedAt;

  /// The claim as stored, to prefill a resubmission.
  final Map<String, dynamic> data;
}

/// What someone fills in to claim a new society.
@immutable
class ClaimDraft {
  const ClaimDraft({
    required this.name,
    required this.address,
    required this.location,
    required this.municipality,
    required this.units,
    required this.position,
    this.applicantName = '',
    this.hoa = const HoaInfo(),
    this.previousClaimId = '',
  });

  final String name;
  final String address;
  final GeoPoint location;
  final Municipality municipality;
  final int units;
  final ClaimPosition position;
  final String applicantName;
  final HoaInfo hoa;

  /// The rejected claim this one resubmits, if any.
  final String previousClaimId;
}

/// A possible duplicate near a new society's address.
typedef NearbySociety = ({
  String name,
  bool pending,
  int distanceM,
  String? societyId,
});

/// Most homes a society can list, as the rules allow.
const maxSocietyUnits = 5000;

/// `https://` links only (or none), as the rules allow.
bool isValidHttpsUrl(String url) {
  if (url.isEmpty) return true;
  final uri = Uri.tryParse(url);
  return url.length <= 500 &&
      uri != null &&
      uri.scheme == 'https' &&
      uri.host.contains('.');
}

/// Adds `https://` when someone types a bare domain.
String normalizeUrl(String input) {
  final t = input.trim();
  if (t.isEmpty || t.contains('://')) return t;
  return 'https://$t';
}

/// Invite codes as the joinWithCode function reads them.
String normalizeInviteCode(String input) =>
    input.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

/// Dates arrive as [DateTime]; the repository converts Firestore
/// timestamps before building these models.
DateTime? _date(Object? v) => v is DateTime ? v : null;
