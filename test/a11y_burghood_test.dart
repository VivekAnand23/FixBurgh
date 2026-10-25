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
import 'package:fixburgh/features/services/data/request_outbox.dart';
import 'package:fixburgh/features/services/data/service_request_repository.dart';
import 'package:fixburgh/features/services/domain/service_category.dart';
import 'package:fixburgh/features/services/domain/service_request.dart';
import 'package:fixburgh/features/services/presentation/report_fork.dart';
import 'package:fixburgh/features/services/presentation/request_detail_screen.dart';
import 'package:fixburgh/features/services/presentation/request_form_screen.dart';
import 'package:fixburgh/features/services/presentation/service_requests_view.dart';
import 'package:fixburgh/features/society/data/channel_repository.dart';
import 'package:fixburgh/features/society/data/society_repository.dart';
import 'package:fixburgh/features/society/domain/channel.dart';
import 'package:fixburgh/features/society/domain/society.dart';
import 'package:fixburgh/features/society/presentation/channel_screen.dart';
import 'package:fixburgh/features/society/presentation/post_screen.dart';
import 'package:fixburgh/features/society/presentation/society_home.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Accessibility on every Burghood screen (Phase 5): on a small phone with
/// text at 200%, in light and dark, nothing overflows, tap targets are at
/// least 48 px, every control has a label, and text meets contrast.
class _User extends Mock implements User {}

const _society = Society(
  id: 's1',
  name: 'Maple Court Homeowners Association of Upper St. Clair',
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

final _post = Post(
  id: 'p1',
  authorUid: 'cal',
  authorName: 'Cal Rivera-Montgomery',
  authorUnit: '12C',
  text:
      'Snow removal starts at 6 tomorrow morning. Please move cars off '
      'the north lot by then so the plough can get through.',
  reactionCounts: const {'👍': 4, '🙏': 2},
  commentCount: 2,
  createdAt: _now,
);

final _comment = Comment(
  id: 'c1',
  authorUid: 'meg',
  authorName: 'Meg',
  text: 'Thanks! Will the side lot be done too?',
  createdAt: _now,
);

ServiceProvider _provider(String id, {bool checked = false}) => ServiceProvider(
  id: id,
  businessName: 'Steel City Plumbing and Drain Cleaning $id',
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
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final user = _User();
    when(() => user.isAnonymous).thenReturn(false);
    when(() => user.uid).thenReturn(uid);
    when(() => user.displayName).thenReturn('Ann Lee');
    tester.view
      ..physicalSize = const Size(375 * 3, 667 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          featureFlagsProvider.overrideWithValue((
            offlineOutbox: true,
            push: true,
            savedPlaces: true,
            society: true,
            channels: true,
            services: true,
            monetisation: true,
          )),
          serviceCategoriesProvider.overrideWithValue(groups),
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
          channelsProvider.overrideWith((ref, id) => Stream.value([_channel])),
          channelProvider.overrideWith((ref, k) => Stream.value(_channel)),
          postsProvider.overrideWith((ref, k) => Stream.value([_post])),
          postProvider.overrideWith((ref, k) => Stream.value(_post)),
          commentsProvider.overrideWith((ref, k) => Stream.value([_comment])),
          myReactionProvider.overrideWith((ref, path) => Stream.value('👍')),
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
          providerSearchProvider.overrideWith((ref, q) async => results),
          sponsoredSearchProvider.overrideWith(
            (ref, q) async => [
              (sponsorshipId: 'sp1', provider: _provider('z')),
            ],
          ),
        ],
        child: MaterialApp(
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // The largest text size people set: 200%.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final screens =
      <
        String,
        ({
          Widget screen,
          String uid,
          ServiceRequest? request,
          ServiceProvider? mine,
        })
      >{
        'society home': (
          screen: const SocietyHome(societyId: 's1'),
          uid: 'me',
          request: null,
          mine: null,
        ),
        'channel': (
          screen: const ChannelScreen(societyId: 's1', channelId: 'general'),
          uid: 'me',
          request: null,
          mine: null,
        ),
        'post and comments': (
          screen: const PostScreen(
            societyId: 's1',
            channelId: 'general',
            postId: 'p1',
          ),
          uid: 'me',
          request: null,
          mine: null,
        ),
        'where is the problem': (
          screen: const ReportEntry(),
          uid: 'me',
          request: null,
          mine: null,
        ),
        'request form': (
          screen: const RequestFormScreen(
            args: RequestFormArgs(
              scope: RequestScope.home,
              societyId: 's1',
              category: 'plumbing',
              providerId: 'a',
              providerName: 'Steel City Plumbing',
            ),
          ),
          uid: 'me',
          request: null,
          mine: null,
        ),
        'request detail, poster': (
          screen: const RequestDetailScreen(requestId: 'r1'),
          uid: 'me',
          request: _request(RequestStatus.completed),
          mine: null,
        ),
        'request detail, provider': (
          screen: const RequestDetailScreen(requestId: 'r1'),
          uid: 'pro',
          request: _request(RequestStatus.assigned),
          mine: null,
        ),
        'request detail, review': (
          screen: const RequestDetailScreen(requestId: 'r1'),
          uid: 'me',
          request: _request(RequestStatus.confirmed),
          mine: null,
        ),
        'provider profile': (
          screen: const ProviderProfileScreen(providerId: 'a', societyId: 's1'),
          uid: 'me',
          request: null,
          mine: null,
        ),
        'become a provider': (
          screen: const BecomeProviderScreen(),
          uid: 'me',
          request: null,
          mine: null,
        ),
        'provider waiting for the fee': (
          screen: const BecomeProviderScreen(),
          uid: 'me',
          request: null,
          mine: _provider('me').copyWithStatus(ProviderStatus.awaitingFee),
        ),
        'activity': (
          screen: const ActivityScreen(),
          uid: 'me',
          request: null,
          mine: _provider('me'),
        ),
        'common-area requests': (
          screen: const CommonRequestsScreen(societyId: 's1'),
          uid: 'me',
          request: null,
          mine: null,
        ),
      };

  for (final dark in [false, true]) {
    for (final MapEntry(key: name, value: s) in screens.entries) {
      testWidgets('$name works at 200% text (${dark ? 'dark' : 'light'})', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await pump(
          tester,
          s.screen,
          dark: dark,
          uid: s.uid,
          request: s.request,
          mine: s.mine,
        );
        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  }

  testWidgets('the Services tab works at 200% text', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const SocietyHome(societyId: 's1'), dark: false);
    await tester.tap(find.text('Services'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('services-search')),
      'kitchen tap leaking',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Sponsored'), findsWidgets);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}

class _NoRequestOutbox extends RequestOutboxController {
  @override
  List<QueuedRequest> build() => const [];
}

class _NoOutbox extends OutboxController {
  @override
  List<OutboxItem> build() => const [];
}

extension on ServiceProvider {
  ServiceProvider copyWithStatus(ProviderStatus s) => ServiceProvider(
    id: id,
    businessName: businessName,
    categories: categories,
    status: s,
  );
}
