import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixburgh/app/flavor.dart';
import 'package:fixburgh/app/providers.dart';
import 'package:fixburgh/app/remote_config.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/profile/profile_screen.dart';
import 'package:fixburgh/features/providers/data/provider_repository.dart';
import 'package:fixburgh/features/report/data/report_repository.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _User extends Mock implements User {}

class _Auth extends Mock implements AuthRepository {}

/// Anyone signed in can apply as a provider from Profile, without joining a
/// society first.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required bool guest,
    bool services = true,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final user = _User();
    when(() => user.isAnonymous).thenReturn(guest);
    when(() => user.uid).thenReturn('pro');
    when(() => user.email).thenReturn(guest ? null : 'pro@example.com');
    when(() => user.displayName).thenReturn(null);
    when(() => user.emailVerified).thenReturn(true);
    final auth = _Auth();
    when(() => auth.signInMethod).thenReturn('password');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          flavorProvider.overrideWithValue(Flavor.dev),
          authUserProvider.overrideWith((ref) => Stream.value(user)),
          authRepositoryProvider.overrideWithValue(auth),
          myReportsProvider.overrideWith((ref) => Stream.value(const [])),
          myProviderProvider.overrideWith((ref) => Stream.value(null)),
          featureFlagsProvider.overrideWithValue((
            offlineOutbox: true,
            push: false,
            savedPlaces: true,
            society: true,
            channels: true,
            services: services,
            monetisation: false,
          )),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('signed in: Offer your services opens the application', (
    tester,
  ) async {
    await pump(tester, guest: false);
    expect(find.byKey(const Key('become-provider')), findsOneWidget);
    expect(find.text('Offer your services'), findsOneWidget);
  });

  testWidgets('guests are asked to sign in first', (tester) async {
    await pump(tester, guest: true);
    expect(find.byKey(const Key('become-provider')), findsNothing);
    expect(find.byKey(const Key('profile-become-provider')), findsOneWidget);
    expect(
      find.text('Sign in to apply as a service provider.'),
      findsOneWidget,
    );
  });

  testWidgets('hidden while services are off', (tester) async {
    await pump(tester, guest: false, services: false);
    expect(find.text('Offer your services'), findsNothing);
  });
}
