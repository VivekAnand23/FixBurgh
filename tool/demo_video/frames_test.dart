// A dev tool, not a test: it uses the same fakes as the widget tests.
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixburgh/app/providers.dart';
import 'package:fixburgh/app/remote_config.dart';
import 'package:fixburgh/app/theme/app_theme.dart';
import 'package:fixburgh/features/activity/activity_screen.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/notifications/notification_settings.dart';
import 'package:fixburgh/features/providers/data/provider_repository.dart';
import 'package:fixburgh/features/providers/domain/provider.dart';
import 'package:fixburgh/features/providers/presentation/become_provider_screen.dart';
import 'package:fixburgh/features/providers/presentation/provider_profile_screen.dart';
import 'package:fixburgh/features/report/data/outbox.dart';
import 'package:fixburgh/features/report/data/report_repository.dart';
import 'package:fixburgh/features/report/presentation/outbox_controller.dart';
import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:fixburgh/features/services/data/google_places_repository.dart';
import 'package:fixburgh/features/services/data/request_outbox.dart';
import 'package:fixburgh/features/services/data/service_request_repository.dart';
import 'package:fixburgh/features/services/domain/service_category.dart';
import 'package:fixburgh/features/services/domain/service_request.dart';
import 'package:fixburgh/features/services/presentation/report_fork.dart';
import 'package:fixburgh/features/services/presentation/request_detail_screen.dart';
import 'package:fixburgh/features/services/presentation/request_form_screen.dart';
import 'package:fixburgh/features/society/data/channel_repository.dart';
import 'package:fixburgh/features/society/data/society_repository.dart';
import 'package:fixburgh/features/society/domain/channel.dart';
import 'package:fixburgh/features/society/domain/society.dart';
import 'package:fixburgh/features/society/presentation/channel_screen.dart';
import 'package:fixburgh/features/society/presentation/society_home.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Frames for the Burghood demo video (docs/marketing/demo-video-script.md):
/// every Burghood screen the script walks through, at 1320 x 2868, with
/// sample data. Not part of `flutter test`; run:
///
///   flutter test tool/demo_video --update-goldens
///
/// and the PNGs land in Images/demo-video/frames/. Then run
/// `python3 tool/demo_video/make_video.py` to build the video.
class _User extends Mock implements User {}

class _Channels extends Mock implements ChannelRepository {}

class _Requests extends Mock implements ServiceRequestRepository {}

class _Providers extends Mock implements ProviderRepository {}

class _Societies extends Mock implements SocietyRepository {}

const _society = Society(
  id: 's1',
  name: 'Maple Court HOA',
  address: '1200 Maple Ct, Pittsburgh, PA',
  location: GeoPoint(40.44, -79.99),
  units: 84,
  pendingCount: 2,
  adminUids: ['me'],
);

const _admin = Membership(
  uid: 'me',
  role: MemberRole.admin,
  status: MemberStatus.approved,
  displayName: 'Ann Lee',
  unit: '4B',
);

final _now = DateTime(2026, 10, 24, 18, 30);

final _channel = Channel(
  id: 'general',
  name: 'General',
  postCount: 3,
  lastPostAt: _now,
  lastPostText: 'Snow removal starts at 6 tomorrow morning, please move cars',
  lastPostAuthor: 'Ann Lee',
);

final _channels = <Channel>[
  _channel,
  Channel(
    id: 'parking',
    name: 'Parking and snow',
    postCount: 8,
    lastPostAt: _now.subtract(const Duration(hours: 3)),
    lastPostText: 'North lot is plowed, thanks everyone for moving cars',
    lastPostAuthor: 'Cal Rivera',
  ),
  Channel(
    id: 'lost',
    name: 'Lost and found',
    postCount: 2,
    lastPostAt: _now.subtract(const Duration(days: 1)),
    lastPostText: 'Found a set of keys by the mailboxes',
    lastPostAuthor: 'Meg Park',
  ),
  Channel(
    id: 'events',
    name: 'Events',
    postCount: 5,
    lastPostAt: _now.subtract(const Duration(days: 2)),
    lastPostText: 'Fall cleanup day is Saturday at 10, coffee on us',
    lastPostAuthor: 'Ann Lee',
  ),
];

final _post = Post(
  id: 'p1',
  authorUid: 'cal',
  authorName: 'Cal Rivera',
  authorUnit: '12C',
  text:
      'Snow removal starts at 6 tomorrow morning. Please move cars off '
      'the north lot by then so the plough can get through.',
  commentCount: 2,
  createdAt: _now,
);

final _posts = <Post>[
  Post(
    id: 'p3',
    authorUid: 'meg',
    authorName: 'Meg Park',
    authorUnit: '7A',
    text:
        'Does anyone have a ladder I could borrow this weekend? '
        'Happy to swap for fresh cookies.',
    commentCount: 3,
    createdAt: _now,
  ),
  Post(
    id: 'p2',
    authorUid: 'me',
    authorName: 'Ann Lee',
    authorUnit: '4B',
    text:
        'Reminder: the pool closes for the season on Sunday. '
        'Thanks for a great summer, everyone!',
    commentCount: 5,
    createdAt: _now.subtract(const Duration(hours: 5)),
  ),
  _post,
];

final _comment = Comment(
  id: 'c1',
  authorUid: 'meg',
  authorName: 'Meg',
  text: 'Thanks! Will the side lot be done too?',
  createdAt: _now,
);

const _names = {
  'a': 'Steel City Plumbing',
  'b': 'Mon Valley Handyman',
  'z': 'Three Rivers Drain Co.',
};

ServiceProvider _provider(String id, {bool checked = false}) => ServiceProvider(
  id: id,
  businessName: _names[id] ?? 'Steel City Plumbing',
  description: 'Leaks, drains and water heaters fixed fast, 7 days a week.',
  categories: const ['plumbing', 'handyman'],
  status: ProviderStatus.approved,
  areaLabel: 'Upper St. Clair',
  ratingAvg: 4.8,
  ratingCount: 212,
  rankScore: rankScore(4.8, 212),
  backgroundChecked: checked,
  phone: '412-555-0100',
);

ServiceRequest _request(RequestStatus s) => ServiceRequest(
  id: 'r1',
  posterUid: 'me',
  posterName: 'Ann Lee',
  title: 'Kitchen tap leaking under the sink, water on the floor',
  description: 'Started Monday. It drips constantly and the cabinet is wet.',
  category: 'plumbing',
  group: 'home_repair',
  details: const {
    'urgency': 'soon',
    'timeWindow': 'evening',
    'access': 'Key with the front desk',
  },
  status: s,
  providerId: 'pro',
  scope: RequestScope.common,
  societyId: 's1',
  createdAt: _now,
  completion: s == RequestStatus.completed
      ? (
          note: 'Replaced the washer and the cartridge.',
          photos: const [],
          videoPath: 'v.mp4',
        )
      : null,
);

final _events = <RequestEvent>[
  (status: RequestStatus.posted, note: '', at: _now),
  (status: RequestStatus.assigned, note: '', at: _now),
  (status: RequestStatus.notFixed, note: 'Still drips at night', at: _now),
];

void main() {
  final groups = parseServiceCategories(serviceCategoriesDefault);
  final results = <ProviderResult>[
    (
      provider: _provider('a', checked: true),
      distanceMiles: 1.2,
      recommended: true,
    ),
    (provider: _provider('b'), distanceMiles: 3.4, recommended: false),
  ];

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    required bool dark,
    String uid = 'me',
    ServiceRequest? request,
    ServiceProvider? mine,
    List<ProviderResult>? found,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final user = _User();
    when(() => user.isAnonymous).thenReturn(false);
    when(() => user.uid).thenReturn(uid);
    when(() => user.displayName).thenReturn('Ann Lee');
    tester.view
      ..physicalSize = const Size(1320, 2868)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    debugDisableShadows = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          serviceCategoriesProvider.overrideWithValue(groups),
          channelRepositoryProvider.overrideWithValue(_Channels()),
          serviceRequestRepositoryProvider.overrideWithValue(_Requests()),
          providerRepositoryProvider.overrideWithValue(_Providers()),
          societyRepositoryProvider.overrideWithValue(_Societies()),
          authUserProvider.overrideWith((ref) => Stream.value(user)),
          currentSocietyIdProvider.overrideWithValue('s1'),
          mySocietyIdsProvider.overrideWith(
            (ref) => Stream.value(const ['s1']),
          ),
          societyProvider.overrideWith((ref, id) => Stream.value(_society)),
          myMembershipProvider.overrideWith((ref, id) => Stream.value(_admin)),
          membersProvider.overrideWith(
            (ref, id) => Stream.value(const [_admin]),
          ),
          noticesProvider.overrideWith((ref, id) => Stream.value(const [])),
          documentsProvider.overrideWith((ref, id) => Stream.value(const [])),
          hoaProvider.overrideWith(
            (ref, id) => Stream.value(
              const HoaInfo(accountUrl: 'https://acme.example.com/account'),
            ),
          ),
          inboxProvider.overrideWith((ref) => Stream.value(const [])),
          channelsProvider.overrideWith((ref, id) => Stream.value(_channels)),
          channelProvider.overrideWith((ref, k) => Stream.value(_channel)),
          postsProvider.overrideWith((ref, k) => Stream.value(_posts)),
          postProvider.overrideWith((ref, k) => Stream.value(_post)),
          commentsProvider.overrideWith((ref, k) => Stream.value([_comment])),
          myReactionProvider.overrideWith((ref, path) => Stream.value(null)),
          unreadProvider.overrideWith(
            (ref, k) async => (posts: 12, mentions: 1),
          ),
          serviceRequestProvider.overrideWith(
            (ref, id) => Stream.value(request),
          ),
          requestEventsProvider.overrideWith(
            (ref, id) => Stream.value(_events),
          ),
          myServiceRequestsProvider.overrideWith(
            (ref) => Stream.value([
              _request(RequestStatus.inProgress),
              _request(RequestStatus.confirmed),
            ]),
          ),
          myJobsProvider.overrideWith(
            (ref) => Stream.value([_request(RequestStatus.assigned)]),
          ),
          commonRequestsProvider.overrideWith(
            (ref, id) => Stream.value([_request(RequestStatus.posted)]),
          ),
          requestOutboxProvider.overrideWith(_NoRequestOutbox.new),
          outboxProvider.overrideWith(_NoOutbox.new),
          myReportsProvider.overrideWith((ref) => Stream.value(const [])),
          providerProvider.overrideWith(
            (ref, id) => Stream.value(_provider(id, checked: true)),
          ),
          myProviderProvider.overrideWith((ref) => Stream.value(mine)),
          reviewsProvider.overrideWith(
            (ref, id) => Stream.value([
              Review(
                id: 'r1',
                stars: 5,
                comment:
                    'Came back the same day and fixed it properly. '
                    'Tidy and on time.',
                authorName: 'Ann Lee',
                reply: 'Thanks Ann, glad it is sorted!',
                createdAt: _now,
              ),
            ]),
          ),
          recommendedProvider.overrideWith(
            (ref, id) => Stream.value(const {'a'}),
          ),
          monetisationSettingsProvider.overrideWith(
            (ref) => Stream.value(defaultMonetisation),
          ),
          featureFlagsProvider.overrideWithValue((
            offlineOutbox: true,
            push: true,
            savedPlaces: true,
            society: true,
            channels: true,
            services: true,
            monetisation: true,
          )),
          googlePlacesEnabledProvider.overrideWithValue(true),
          googlePlacesProvider.overrideWith(
            (ref, q) async => (
              available: true,
              limited: false,
              mapsUrl: mapsSearchUrl(q.query, q.near),
              results: const <GooglePlace>[
                (
                  name: 'Allegheny Lawn Care',
                  address: '410 Washington Rd, Mt Lebanon, PA',
                  rating: 4.7,
                  ratingCount: 128,
                  phone: '(412) 555-0142',
                  website: 'https://example.com',
                  mapsUrl: 'https://maps.google.com',
                  distanceMiles: 2.1,
                ),
                (
                  name: 'Green Hollow Gardens',
                  address: '88 Bower Hill Rd, Pittsburgh, PA',
                  rating: 4.5,
                  ratingCount: 64,
                  phone: '(412) 555-0177',
                  website: null,
                  mapsUrl: 'https://maps.google.com',
                  distanceMiles: 3.4,
                ),
              ],
            ),
          ),
          providerSearchProvider.overrideWith(
            (ref, q) async => found ?? results,
          ),
          sponsoredSearchProvider.overrideWith(
            // No sponsored plumber above a lawn-mowing search.
            (ref, q) async => found != null
                ? const <SponsoredResult>[]
                : [(sponsorshipId: 'sp1', provider: _provider('z'))],
          ),
        ],
        child: MaterialApp(
          theme: _withRoboto(dark ? AppTheme.dark() : AppTheme.light()),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          debugShowCheckedModeBanner: false,
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUpAll(() async {
    await _loadFonts();
    // Touch screens show no keyboard focus rings.
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTouch;
  });

  final shots =
      <
        String,
        ({
          Widget screen,
          String uid,
          ServiceRequest? request,
          ServiceProvider? mine,
        })
      >{
        '03-society-home': (
          screen: const SocietyHome(societyId: 's1'),
          uid: 'me',
          request: null,
          mine: null,
        ),
        '04-channel': (
          screen: const ChannelScreen(societyId: 's1', channelId: 'general'),
          uid: 'me',
          request: null,
          mine: null,
        ),
        '05-report-fork': (
          screen: const ReportEntry(),
          uid: 'me',
          request: null,
          mine: null,
        ),
        '07-provider-profile': (
          screen: const ProviderProfileScreen(providerId: 'a', societyId: 's1'),
          uid: 'me',
          request: null,
          mine: null,
        ),
        '08-request-form': (
          screen: const RequestFormScreen(
            args: RequestFormArgs(
              scope: RequestScope.home,
              societyId: 's1',
              providerId: 'a',
              providerName: 'Steel City Plumbing',
              category: 'plumbing',
            ),
          ),
          uid: 'me',
          request: null,
          mine: null,
        ),
        '09-job-for-provider': (
          screen: const RequestDetailScreen(requestId: 'r1'),
          uid: 'pro',
          request: _request(RequestStatus.assigned),
          mine: null,
        ),
        '10-request-timeline': (
          screen: const RequestDetailScreen(requestId: 'r1'),
          uid: 'me',
          request: _request(RequestStatus.completed),
          mine: null,
        ),
        '12-become-provider': (
          screen: const BecomeProviderScreen(),
          uid: 'me',
          request: null,
          mine: null,
        ),
        '13-listing-fee': (
          screen: const BecomeProviderScreen(),
          uid: 'me',
          request: null,
          mine: ServiceProvider(
            id: 'me',
            businessName: 'Steel City Plumbing',
            categories: const ['plumbing'],
            status: ProviderStatus.awaitingFee,
            areaLabel: 'Upper St. Clair',
            paymentRequest: (
              amountUsd: 150,
              periodMonths: 12,
              instructions:
                  'Pay by check to FixBurgh, or by bank transfer. Put your '
                  'business name in the memo.',
              payLink: 'https://pay.example.com/burghood',
              dueDate: DateTime(2026, 11, 8),
            ),
          ),
        ),
      };

  for (final MapEntry(key: name, value: s) in shots.entries) {
    testWidgets(name, (tester) async {
      await pump(
        tester,
        s.screen,
        dark: false,
        uid: s.uid,
        request: s.request,
        mine: s.mine,
      );
      await _shot(tester, name);
    });
  }

  Future<void> search(WidgetTester tester, String text) async {
    await tester.tap(find.text('Services'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('services-search')), text);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  testWidgets('06-services-search', (tester) async {
    await pump(tester, const SocietyHome(societyId: 's1'), dark: false);
    await search(tester, 'kitchen tap leaking');
    await _shot(tester, '06-services-search');
  });

  testWidgets('11-google-fallback', (tester) async {
    await pump(
      tester,
      const SocietyHome(societyId: 's1'),
      dark: false,
      found: const [],
    );
    await search(tester, 'lawn mowing');
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await _shot(tester, '11-google-fallback');
  });

  testWidgets('14-jobs', (tester) async {
    await pump(
      tester,
      const ActivityScreen(),
      dark: false,
      mine: _provider('me'),
    );
    await tester.tap(find.text('Jobs'));
    await tester.pumpAndSettle();
    await _shot(tester, '14-jobs');
  });
}

/// Saves the screen as `Images/demo-video/frames/<name>.png`. `pump` turned real shadows on (tests
/// draw outlines instead); they go back off before the test ends.
Future<void> _shot(WidgetTester tester, String name) async {
  try {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../Images/demo-video/frames/$name.png'),
    );
  } finally {
    debugDisableShadows = true;
  }
}

/// The app's button labels set no font family, which in tests means the
/// test font; on a phone it's the system font, so name Roboto for them.
ThemeData _withRoboto(ThemeData t) {
  const label = WidgetStatePropertyAll(
    TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w600),
  );
  return t.copyWith(
    filledButtonTheme: FilledButtonThemeData(
      style: t.filledButtonTheme.style?.copyWith(textStyle: label),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: t.outlinedButtonTheme.style?.copyWith(textStyle: label),
    ),
  );
}

/// Real fonts instead of the test font's boxes: Roboto and the Material
/// icons that ship with the Flutter SDK.
Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT']!;
  final fonts = Directory('$root/bin/cache/artifacts/material_fonts');
  Future<ByteData> read(String f) async =>
      ByteData.sublistView(await File('${fonts.path}/$f').readAsBytes());
  final roboto = FontLoader('Roboto');
  for (final f in ['Regular', 'Medium', 'Bold', 'Italic']) {
    roboto.addFont(read('Roboto-$f.ttf'));
  }
  await roboto.load();

  await (FontLoader(
    'MaterialIcons',
  )..addFont(read('MaterialIcons-Regular.otf'))).load();
}

class _NoRequestOutbox extends RequestOutboxController {
  @override
  List<QueuedRequest> build() => const [];
}

class _NoOutbox extends OutboxController {
  @override
  List<OutboxItem> build() => const [];
}
