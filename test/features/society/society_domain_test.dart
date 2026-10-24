import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:fixburgh/features/society/data/society_repository.dart';
import 'package:fixburgh/features/society/domain/society.dart';
import 'package:fixburgh/features/society/presentation/society_home.dart';
import 'package:fixburgh/features/society/presentation/society_widgets.dart';
import 'package:fixburgh/l10n/gen/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

Society society(String name) => Society(
  id: 's',
  name: name,
  address: '',
  location: const GeoPoint(0, 0),
  units: 1,
);

void main() {
  test('society initials skip symbols and keep two letters', () {
    expect(society('Maple Court HOA').initials, 'MC');
    expect(society('The Heights').initials, 'TH');
    expect(society('1200 Maple & Co').initials, 'MC');
    expect(society('Liberty').initials, 'L');
  });

  test('reads a society document', () {
    final s = Society.fromDoc('abc', {
      'name': 'Maple Court HOA',
      'address': '1200 Maple Ct, Pittsburgh, PA',
      'lat': 40.44,
      'lng': -79.99,
      'units': 84,
      'verified': true,
      'pendingCount': 2,
      'adminUids': ['ann', 7],
    });
    expect(s.units, 84);
    expect(s.verified, isTrue);
    expect(s.pendingCount, 2);
    expect(s.adminUids, ['ann']);
  });

  test('memberships know who manages and who posts notices', () {
    Membership m(String role, String status) =>
        Membership.fromDoc('u', {'role': role, 'status': status});
    expect(m('admin', 'approved').isAdmin, isTrue);
    expect(m('admin', 'pending').isAdmin, isFalse);
    expect(m('committee', 'approved').canPostNotices, isTrue);
    expect(m('member', 'approved').canPostNotices, isFalse);
    expect(m('owner', 'weird').role, MemberRole.member);
    expect(m('owner', 'weird').status, MemberStatus.pending);
  });

  test('pinned notices come first, then newest, expired last', () {
    final now = DateTime(2026, 10, 24, 12);
    SocietyNotice n(
      String id, {
      bool pinned = false,
      int hoursAgo = 0,
      DateTime? expires,
    }) => SocietyNotice(
      id: id,
      title: id,
      body: '',
      authorUid: 'a',
      pinned: pinned,
      createdAt: now.subtract(Duration(hours: hoursAgo)),
      expiresAt: expires,
    );
    final sorted = sortNotices([
      n('old', hoursAgo: 48),
      n('expiredPin', pinned: true, expires: now),
      n('new', hoursAgo: 1),
      n('pin', pinned: true, hoursAgo: 72),
    ], now);
    expect(sorted.map((x) => x.id), ['pin', 'new', 'old', 'expiredPin']);
  });

  test('only https links are accepted, and bare domains get https', () {
    expect(isValidHttpsUrl(''), isTrue);
    expect(isValidHttpsUrl('https://acme.example.com/account'), isTrue);
    expect(isValidHttpsUrl('http://acme.example.com'), isFalse);
    expect(isValidHttpsUrl('javascript:alert(1)'), isFalse);
    expect(isValidHttpsUrl('https://localhost'), isFalse);
    expect(normalizeUrl(' acme.example.com '), 'https://acme.example.com');
    expect(normalizeUrl('http://x.com'), 'http://x.com');
  });

  test('invite codes ignore case, spaces and dashes', () {
    expect(normalizeInviteCode('abcd-23 45'), 'ABCD2345');
  });

  test('claim files are stored as jpg, png or pdf', () {
    expect(claimFileExtension('/tmp/IMG_1.JPEG'), 'jpg');
    expect(claimFileExtension('/tmp/scan.png'), 'png');
    expect(claimFileExtension('/tmp/minutes.pdf'), 'pdf');
    expect(claimFileExtension('/tmp/photo.heic'), 'jpg');
  });

  test('claim positions are stored with underscores', () {
    expect(ClaimPosition.boardMember.id, 'board_member');
    expect(ClaimPosition.president.id, 'president');
  });

  test('distances and times read naturally', () {
    final l10n = AppLocalizationsEn();
    expect(formatDistance(57), '60 m');
    expect(formatDistance(1234), '1.2 km');
    final now = DateTime(2026, 10, 24, 12);
    expect(timeAgo(l10n, now, now: now), 'just now');
    expect(timeAgo(l10n, DateTime(2026, 10, 24, 10), now: now), '2h ago');
    expect(timeAgo(l10n, DateTime(2026, 10, 21), now: now), '3d ago');
    expect(
      societySummary(
        l10n,
        Society(
          id: 's',
          name: 'Maple',
          address: '1200 Maple Ct, Pittsburgh, PA',
          location: const GeoPoint(0, 0),
          units: 84,
        ),
        distanceM: 60,
      ),
      '1200 Maple Ct · 84 homes · 60 m away',
    );
  });
}
