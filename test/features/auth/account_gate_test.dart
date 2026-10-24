import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixburgh/features/auth/account_gate.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';

class _Auth extends Mock implements FirebaseAuth {}

class _User extends Mock implements User {}

class _Google extends Mock implements GoogleSignIn {}

void main() {
  late _Auth auth;
  late User? current;
  late _User guest;
  late _User member;

  setUp(() {
    auth = _Auth();
    guest = _User();
    member = _User();
    when(() => guest.isAnonymous).thenReturn(true);
    when(() => member.isAnonymous).thenReturn(false);
    when(() => auth.currentUser).thenAnswer((_) => current);
  });

  test('only non-anonymous users have a full account', () {
    expect(hasFullAccount(null), isFalse);
    expect(hasFullAccount(guest), isFalse);
    expect(hasFullAccount(member), isTrue);
  });

  /// Pumps a button that runs [requireFullAccount] and stores its result.
  Future<List<bool>> pumpGate(
    WidgetTester tester, {
    required Future<void> Function() signIn,
  }) async {
    final results = <bool>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            AuthRepository(
              auth,
              _Google(),
              googleServerClientId: 'id',
              claimGuestReports: (_) async {},
              deleteAccountData: (_) async {},
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () async => results.add(
                  await requireFullAccount(context, ref, signIn: signIn),
                ),
                child: const Text('Join'),
              ),
            ),
          ),
        ),
      ),
    );
    return results;
  }

  testWidgets('lets signed-in people straight through', (tester) async {
    current = member;
    var signIns = 0;
    final results = await pumpGate(tester, signIn: () async => signIns++);
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();
    expect(find.byType(AccountGateSheet), findsNothing);
    expect(results, [true]);
    expect(signIns, 0);
  });

  testWidgets('asks guests to sign in and stops on Not now', (tester) async {
    current = guest;
    var signIns = 0;
    final results = await pumpGate(tester, signIn: () async => signIns++);
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in to continue'), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(results, [false]);
    expect(signIns, 0);
  });

  testWidgets('continues once the guest signs in', (tester) async {
    current = guest;
    final results = await pumpGate(
      tester,
      signIn: () async => current = member,
    );
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.byType(AccountGateSheet), findsNothing);
    expect(results, [true]);
  });

  testWidgets('stays closed when sign-in is abandoned', (tester) async {
    current = guest;
    final results = await pumpGate(tester, signIn: () async {});
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(results, [false]);
  });
}
