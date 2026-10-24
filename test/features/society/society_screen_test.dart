import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixburgh/app/providers.dart';
import 'package:fixburgh/app/remote_config.dart';
import 'package:fixburgh/app/theme/app_theme.dart';
import 'package:fixburgh/features/auth/account_gate.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/notifications/notification_settings.dart';
import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:fixburgh/features/society/data/channel_repository.dart';
import 'package:fixburgh/features/society/data/society_repository.dart';
import 'package:fixburgh/features/society/domain/channel.dart';
import 'package:fixburgh/features/society/domain/society.dart';
import 'package:fixburgh/features/society/presentation/find_society_view.dart';
import 'package:fixburgh/features/society/presentation/manage_screen.dart';
import 'package:fixburgh/features/society/presentation/society_home.dart';
import 'package:fixburgh/features/society/society_screen.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Auth extends Mock implements FirebaseAuth {}

class _User extends Mock implements User {}

class _Google extends Mock implements GoogleSignIn {}

class _Repo extends Mock implements SocietyRepository {}

const _maple = Society(
  id: 's1',
  name: 'Maple Court HOA',
  address: '1200 Maple Ct, Pittsburgh, PA',
  location: GeoPoint(40.44, -79.99),
  units: 84,
  pendingCount: 1,
  adminUids: ['me'],
);

const _admin = {'role': 'admin', 'status': 'approved'};
const _member = {'role': 'member', 'status': 'approved'};

FeatureFlags _flags({bool society = false, bool channels = false}) => (
  offlineOutbox: true,
  push: true,
  savedPlaces: true,
  society: society,
  channels: channels,
  services: false,
  monetisation: false,
);

void main() {
  late _Repo repo;

  setUp(() {
    repo = _Repo();
    when(
      () => repo.updateMember(
        any(),
        any(),
        adminUid: any(named: 'adminUid'),
        status: any(named: 'status'),
        role: any(named: 'role'),
      ),
    ).thenAnswer((_) async {});
  });

  setUpAll(() {
    registerFallbackValue(MemberStatus.pending);
    registerFallbackValue(MemberRole.member);
  });

  Future<void> pump(
    WidgetTester tester, {
    required bool guest,
    bool flag = false,
    List<String> societies = const [],
    Membership? me,
    List<Membership> members = const [],
    List<SocietyNotice> notices = const [],
    Widget home = const SocietyScreen(),
    List<SocietyResult> searchResults = const [],
    bool channels = false,
    List<Channel> channelList = const [],
    Map<String, Unread> unread = const {},
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final user = _User();
    when(() => user.isAnonymous).thenReturn(guest);
    when(() => user.uid).thenReturn('me');
    when(() => user.displayName).thenReturn('Ann');
    final auth = _Auth();
    when(() => auth.currentUser).thenReturn(user);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          featureFlagsProvider.overrideWithValue(
            _flags(society: flag, channels: channels),
          ),
          inboxProvider.overrideWith((ref) => Stream.value(const [])),
          channelsProvider.overrideWith(
            (ref, id) => Stream.value(channelList),
          ),
          unreadProvider.overrideWith(
            (ref, k) async => unread[k.cid] ?? (posts: 0, mentions: 0),
          ),
          authUserProvider.overrideWith((ref) => Stream.value(user)),
          authRepositoryProvider.overrideWithValue(
            AuthRepository(
              auth,
              _Google(),
              googleServerClientId: 'id',
              claimGuestReports: (_) async {},
              deleteAccountData: (_) async {},
            ),
          ),
          societyRepositoryProvider.overrideWithValue(repo),
          mySocietyIdsProvider.overrideWith((ref) => Stream.value(societies)),
          myPendingRequestsProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
          myClaimsProvider.overrideWith((ref) => Stream.value(const [])),
          societyProvider.overrideWith((ref, id) => Stream.value(_maple)),
          myMembershipProvider.overrideWith((ref, id) => Stream.value(me)),
          membersProvider.overrideWith((ref, id) => Stream.value(members)),
          noticesProvider.overrideWith((ref, id) => Stream.value(notices)),
          documentsProvider.overrideWith((ref, id) => Stream.value(const [])),
          hoaProvider.overrideWith(
            (ref, id) => Stream.value(
              const HoaInfo(accountUrl: 'https://acme.example.com/account'),
            ),
          ),
          inviteCodeProvider.overrideWith(
            (ref, id) => Stream.value('ABCD2345'),
          ),
          societySearchProvider.overrideWithValue(
            (_, _) async => searchResults,
          ),
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

  group('while the society flag is off', () {
    testWidgets('shows Coming soon, with sign-in for guests', (tester) async {
      await pump(tester, guest: true);
      expect(find.text('Coming soon'), findsOneWidget);
      await tester.tap(find.text('Sign in to join a society'));
      await tester.pumpAndSettle();
      expect(find.byType(AccountGateSheet), findsOneWidget);
    });

    testWidgets('signed-in people see no sign-in button', (tester) async {
      await pump(tester, guest: false);
      expect(find.text('Coming soon'), findsOneWidget);
      expect(find.text('Sign in to join a society'), findsNothing);
    });
  });

  group('with the society flag on', () {
    testWidgets('guests are asked to sign in first', (tester) async {
      await pump(tester, guest: true, flag: true);
      expect(find.text('Sign in to find your society'), findsOneWidget);
      expect(find.byType(FindSocietyView), findsNothing);
    });

    testWidgets('people in no society can find, join or create one', (
      tester,
    ) async {
      await pump(
        tester,
        guest: false,
        flag: true,
        searchResults: const [(society: _maple, distanceM: 60)],
      );
      expect(find.text('Find your society'), findsOneWidget);
      expect(find.text("I'm the admin, create it"), findsOneWidget);
      expect(find.text('Not the admin? Invite them'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '1200 Maple Ct');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('1 society near this address'), findsOneWidget);
      expect(find.text('Maple Court HOA'), findsOneWidget);
      expect(find.text('1200 Maple Ct · 84 homes · 60 m away'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);

      await tester.tap(find.text('Request to join'));
      await tester.pumpAndSettle();
      expect(find.text('Join Maple Court HOA'), findsOneWidget);
    });

    testWidgets('members see their society with Notices and Docs', (
      tester,
    ) async {
      await pump(
        tester,
        guest: false,
        flag: true,
        societies: ['s1'],
        me: Membership.fromDoc('me', _member),
        notices: [
          SocietyNotice(
            id: 'n1',
            title: 'Water off Tuesday',
            body: '9 to 12',
            authorUid: 'a',
            authorName: 'Ann',
            pinned: true,
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
        ],
      );
      expect(find.byType(SocietyHome), findsOneWidget);
      expect(find.text('Maple Court HOA'), findsOneWidget);
      expect(find.text("84 homes · You're a member"), findsOneWidget);
      expect(find.text('Notices'), findsOneWidget);
      expect(find.text('Docs'), findsOneWidget);
      expect(find.text('Members'), findsNothing);
      expect(find.text('Manage'), findsNothing);
      expect(find.text('HOA account'), findsOneWidget);
      expect(find.text('Water off Tuesday'), findsOneWidget);
      expect(find.text('📌 NOTICE · FROM ANN'), findsOneWidget);
      expect(find.text('New notice'), findsNothing);
    });

    testWidgets('admins get Manage with the request count and Members', (
      tester,
    ) async {
      await pump(
        tester,
        guest: false,
        flag: true,
        societies: ['s1'],
        me: Membership.fromDoc('me', _admin),
      );
      expect(find.text('Manage'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Members'), findsOneWidget);
      expect(find.text('New notice'), findsOneWidget);
    });
  });

  testWidgets('Manage approves a join request', (tester) async {
    await pump(
      tester,
      guest: false,
      flag: true,
      home: const ManageScreen(societyId: 's1'),
      me: Membership.fromDoc('me', _admin),
      members: [
        Membership.fromDoc('pat', const {
          'role': 'member',
          'status': 'pending',
          'unit': '2C',
          'displayName': 'Pat',
        }),
      ],
    );
    expect(find.text('Join requests (1)'), findsOneWidget);
    expect(find.text('Unit 2C'), findsOneWidget);
    expect(find.text('ABCD-2345'), findsOneWidget);
    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    verify(
      () => repo.updateMember(
        's1',
        'pat',
        adminUid: 'me',
        status: MemberStatus.approved,
      ),
    ).called(1);
  });

  for (final (name, societies) in [
    ('Find your society', <String>[]),
    ('Society home', ['s1']),
  ]) {
    testWidgets('$name meets accessibility guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        guest: false,
        flag: true,
        societies: societies,
        me: Membership.fromDoc('me', _admin),
        searchResults: const [(society: _maple, distanceM: 60)],
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  }

  group('channels', () {
    final channelList = [
      Channel(
        id: 'general',
        name: 'General',
        lastPostAt: DateTime.now().subtract(const Duration(minutes: 5)),
        lastPostText: 'Water is back on',
        lastPostAuthor: 'Cal',
      ),
      Channel(
        id: 'events',
        name: 'Events',
        lastPostAt: DateTime.now().subtract(const Duration(hours: 3)),
        lastPostText: 'BBQ on Saturday',
        lastPostAuthor: 'Ann',
      ),
    ];

    testWidgets('show unread, mention and muted badges', (tester) async {
      await pump(
        tester,
        guest: false,
        flag: true,
        channels: true,
        societies: ['s1'],
        me: Membership.fromDoc('me', const {
          'role': 'member',
          'status': 'approved',
          'mutes': {'events': 'always'},
        }),
        channelList: channelList,
        unread: const {
          'general': (posts: 3, mentions: 1),
          'events': (posts: 2, mentions: 0),
        },
      );
      expect(find.text('Channels'), findsOneWidget);
      expect(find.text('General'), findsOneWidget);
      expect(find.text('Cal: Water is back on'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('@ 1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
      expect(find.text('New channel'), findsNothing);
    });

    testWidgets('meet accessibility guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        guest: false,
        flag: true,
        channels: true,
        societies: ['s1'],
        me: Membership.fromDoc('me', _admin),
        channelList: channelList,
        unread: const {'general': (posts: 3, mentions: 1)},
      );
      expect(find.text('New channel'), findsOneWidget);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });
}
