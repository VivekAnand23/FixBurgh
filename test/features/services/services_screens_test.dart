import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixburgh/app/providers.dart';
import 'package:fixburgh/app/remote_config.dart';
import 'package:fixburgh/app/theme/app_theme.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/providers/data/provider_repository.dart';
import 'package:fixburgh/features/providers/domain/provider.dart';
import 'package:fixburgh/features/providers/presentation/become_provider_screen.dart';
import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:fixburgh/features/services/data/request_outbox.dart';
import 'package:fixburgh/features/services/data/service_request_repository.dart';
import 'package:fixburgh/features/services/domain/service_category.dart';
import 'package:fixburgh/features/services/domain/service_request.dart';
import 'package:fixburgh/features/services/presentation/report_fork.dart';
import 'package:fixburgh/features/services/presentation/request_detail_screen.dart';
import 'package:fixburgh/features/services/presentation/request_form_screen.dart';
import 'package:fixburgh/features/services/presentation/services_tab.dart';
import 'package:fixburgh/features/society/data/society_repository.dart';
import 'package:fixburgh/features/society/domain/society.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _User extends Mock implements User {}

class _Requests extends Mock implements ServiceRequestRepository {}

class _Providers extends Mock implements ProviderRepository {}

const _maple = Society(
  id: 's1',
  name: 'Maple Court HOA',
  address: '1200 Maple Ct, Pittsburgh, PA',
  location: GeoPoint(40.44, -79.99),
  units: 84,
  adminUids: ['admin'],
);

const FeatureFlags _flags = (
  offlineOutbox: true,
  push: true,
  savedPlaces: true,
  society: true,
  channels: true,
  services: true,
  monetisation: false,
);

ServiceProvider _provider(
  String id, {
  double avg = 4.8,
  int count = 20,
  bool checked = false,
}) => ServiceProvider(
  id: id,
  businessName: 'Pro $id',
  categories: const ['plumbing'],
  status: ProviderStatus.approved,
  ratingAvg: avg,
  ratingCount: count,
  rankScore: rankScore(avg, count),
  backgroundChecked: checked,
);

ServiceRequest _request(RequestStatus status, {bool rated = false}) =>
    ServiceRequest(
      id: 'r1',
      posterUid: 'poster',
      posterName: 'Ann',
      title: 'Kitchen tap leaking',
      category: 'plumbing',
      group: 'home_repair',
      status: status,
      providerId: 'pro',
      rated: rated,
    );

void main() {
  late _Requests requests;
  late _Providers providers;
  final queries = <ProviderQuery>[];

  setUp(() {
    requests = _Requests();
    providers = _Providers();
    queries.clear();
    when(() => requests.confirm(any())).thenAnswer((_) async {});
    when(() => requests.accept(any())).thenAnswer((_) async {});
    when(
      () => providers.review(
        providerId: any(named: 'providerId'),
        requestId: any(named: 'requestId'),
        uid: any(named: 'uid'),
        authorName: any(named: 'authorName'),
        stars: any(named: 'stars'),
        comment: any(named: 'comment'),
        category: any(named: 'category'),
      ),
    ).thenAnswer((_) async {});
  });

  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    String uid = 'poster',
    String? society = 's1',
    Membership? me,
    ServiceRequest? request,
    List<ProviderResult> results = const [],
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final user = _User();
    when(() => user.isAnonymous).thenReturn(false);
    when(() => user.uid).thenReturn(uid);
    when(() => user.displayName).thenReturn('Ann');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          featureFlagsProvider.overrideWithValue(_flags),
          serviceCategoriesProvider.overrideWithValue(
            parseServiceCategories(serviceCategoriesDefault),
          ),
          authUserProvider.overrideWith((ref) => Stream.value(user)),
          currentSocietyIdProvider.overrideWithValue(society),
          societyProvider.overrideWith((ref, id) => Stream.value(_maple)),
          myMembershipProvider.overrideWith((ref, id) => Stream.value(me)),
          serviceRequestRepositoryProvider.overrideWithValue(requests),
          providerRepositoryProvider.overrideWithValue(providers),
          serviceRequestProvider.overrideWith(
            (ref, id) => Stream.value(request),
          ),
          requestEventsProvider.overrideWith(
            (ref, id) => Stream.value(const []),
          ),
          providerProvider.overrideWith(
            (ref, id) => Stream.value(_provider(id)),
          ),
          recommendedProvider.overrideWith(
            (ref, id) => Stream.value(const {'b'}),
          ),
          commonRequestsProvider.overrideWith(
            (ref, id) => Stream.value(const []),
          ),
          myProviderProvider.overrideWith((ref) => Stream.value(null)),
          requestOutboxProvider.overrideWith(_NoOutbox.new),
          providerSearchProvider.overrideWith((ref, q) async {
            queries.add(q);
            return results;
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Where is the problem?', () {
    testWidgets('offers street, home and the society common areas', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, const ReportEntry());
      expect(find.text('Where is the problem?'), findsOneWidget);
      expect(find.byKey(const Key('fork-street')), findsOneWidget);
      expect(find.byKey(const Key('fork-home')), findsOneWidget);
      expect(find.byKey(const Key('fork-common')), findsOneWidget);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('no common areas without a society', (tester) async {
      await pump(tester, const ReportEntry(), society: null);
      expect(find.byKey(const Key('fork-home')), findsOneWidget);
      expect(find.byKey(const Key('fork-common')), findsNothing);
    });
  });

  group('Services tab', () {
    final results = sortResults([
      (provider: _provider('a'), distanceMiles: 1.2, recommended: false),
      (
        provider: _provider('b', avg: 4.2, count: 5, checked: true),
        distanceMiles: 3.4,
        recommended: true,
      ),
    ]);

    testWidgets('describing the problem searches by the detected category', (
      tester,
    ) async {
      await pump(
        tester,
        const Scaffold(
          body: ServicesTab(
            societyId: 's1',
            me: Membership(
              uid: 'poster',
              role: MemberRole.member,
              status: MemberStatus.approved,
            ),
          ),
        ),
        results: results,
      );
      await tester.enterText(
        find.byKey(const Key('services-search')),
        'kitchen tap leaking',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('detected-plumbing')), findsOneWidget);
      expect(queries.last.categories, ['plumbing']);
      expect(queries.last.text, 'kitchen tap leaking');
      expect(queries.last.miles, 10);
      expect(queries.last.near?.lat, 40.44);

      // The recommended provider is first, with both badges.
      final first = tester.getTopLeft(find.byKey(const Key('provider-b')));
      final second = tester.getTopLeft(find.byKey(const Key('provider-a')));
      expect(first.dy, lessThan(second.dy));
      expect(find.text('Recommended by your society'), findsOneWidget);
      expect(find.text('Background checked'), findsOneWidget);

      await tester.tap(find.byKey(const Key('miles-25')));
      await tester.pumpAndSettle();
      expect(queries.last.miles, 25);
    });

    testWidgets('admins see the common-area requests', (tester) async {
      await pump(
        tester,
        const Scaffold(
          body: ServicesTab(
            societyId: 's1',
            me: Membership(
              uid: 'admin',
              role: MemberRole.admin,
              status: MemberStatus.approved,
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('services-common')), findsOneWidget);
    });
  });

  testWidgets('the request form suggests a category and asks what fits', (
    tester,
  ) async {
    // Tall enough that the lazy list builds every field.
    tester.view.physicalSize = const Size(1080, 6000);
    addTearDown(tester.view.reset);
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      const RequestFormScreen(
        args: RequestFormArgs(scope: RequestScope.home, societyId: 's1'),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('request-title')),
      'Kitchen tap leaking',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('detected-plumbing')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('request-category')), findsOneWidget);
    expect(find.text('How urgent?'), findsOneWidget);
    expect(find.text('Access'), findsOneWidget);
    expect(find.text('Photos (0 of 6)'), findsOneWidget);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  testWidgets('becoming a provider asks for the documents the services need', (
    tester,
  ) async {
    // Tall enough that the lazy list builds every field.
    tester.view.physicalSize = const Size(1080, 6000);
    addTearDown(tester.view.reset);
    await pump(tester, const BecomeProviderScreen());
    expect(find.byKey(const Key('doc-license')), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const Key('cat-plumbing')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('cat-plumbing')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('doc-license'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('doc-insurance'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('doc-background'), skipOffstage: false),
      findsNothing,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('cat-babysitting')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('cat-babysitting')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('doc-background'), skipOffstage: false),
      findsOneWidget,
    );
  });

  group('request detail', () {
    testWidgets('the poster confirms finished work', (tester) async {
      await pump(
        tester,
        const RequestDetailScreen(requestId: 'r1'),
        request: _request(RequestStatus.completed),
      );
      expect(find.byKey(const Key('not-fixed')), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm-done')));
      await tester.pumpAndSettle();
      verify(() => requests.confirm('r1')).called(1);
    });

    testWidgets('the provider accepts or declines a new job', (tester) async {
      await pump(
        tester,
        const RequestDetailScreen(requestId: 'r1'),
        uid: 'pro',
        request: _request(RequestStatus.assigned),
      );
      expect(find.byKey(const Key('decline-job')), findsOneWidget);
      expect(find.byKey(const Key('confirm-done')), findsNothing);
      await tester.tap(find.byKey(const Key('accept-job')));
      await tester.pumpAndSettle();
      verify(() => requests.accept('r1')).called(1);
    });

    testWidgets('after confirming, the poster rates the provider', (
      tester,
    ) async {
      await pump(
        tester,
        const RequestDetailScreen(requestId: 'r1'),
        request: _request(RequestStatus.confirmed),
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('send-review')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byTooltip('5 stars'));
      await tester.enterText(
        find.byKey(const Key('review-comment')),
        'Quick and tidy',
      );
      await tester.tap(find.byKey(const Key('send-review')));
      await tester.pumpAndSettle();
      verify(
        () => providers.review(
          providerId: 'pro',
          requestId: 'r1',
          uid: 'poster',
          authorName: 'Ann',
          stars: 5,
          comment: 'Quick and tidy',
          category: 'plumbing',
        ),
      ).called(1);
    });

    testWidgets('no review form once rated', (tester) async {
      await pump(
        tester,
        const RequestDetailScreen(requestId: 'r1'),
        request: _request(RequestStatus.confirmed, rated: true),
      );
      expect(find.byKey(const Key('send-review')), findsNothing);
    });
  });
}

class _NoOutbox extends RequestOutboxController {
  @override
  List<QueuedRequest> build() => const [];
}
