import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixburgh/features/auth/account_gate.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/society/society_screen.dart';
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
  Future<void> pump(WidgetTester tester, {required bool guest}) async {
    final user = _User();
    when(() => user.isAnonymous).thenReturn(guest);
    final auth = _Auth();
    when(() => auth.currentUser).thenReturn(user);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SocietyScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows Coming soon while the society flag is off', (
    tester,
  ) async {
    await pump(tester, guest: true);
    expect(find.text('Coming soon'), findsOneWidget);
    expect(find.text('Sign in to join a society'), findsOneWidget);
  });

  testWidgets('asks guests to sign in to join', (tester) async {
    await pump(tester, guest: true);
    await tester.tap(find.text('Sign in to join a society'));
    await tester.pumpAndSettle();
    expect(find.byType(AccountGateSheet), findsOneWidget);
  });

  testWidgets('signed-in people see no sign-in button', (tester) async {
    await pump(tester, guest: false);
    expect(find.text('Coming soon'), findsOneWidget);
    expect(find.text('Sign in to join a society'), findsNothing);
  });
}
