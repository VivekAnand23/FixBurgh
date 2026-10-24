import 'package:fixburgh/app/providers.dart';
import 'package:fixburgh/app/router.dart';
import 'package:fixburgh/features/onboarding/onboarding_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

OnboardingState s({
  bool welcome = true,
  bool age = true,
  bool blocked = false,
}) => OnboardingState(
  welcomeSeen: welcome,
  ageConfirmed: age,
  ageBlocked: blocked,
);

void main() {
  test('new users see the welcome screen first', () {
    expect(
      onboardingRedirect(s(welcome: false, age: false), Routes.map),
      Routes.welcome,
    );
  });

  test('after welcome, the age screen is required', () {
    expect(onboardingRedirect(s(age: false), Routes.map), Routes.age);
    expect(onboardingRedirect(s(age: false), Routes.age), isNull);
  });

  test('blocked users cannot leave the blocked screen', () {
    expect(
      onboardingRedirect(s(age: false, blocked: true), Routes.map),
      Routes.ageBlocked,
    );
    expect(
      onboardingRedirect(s(age: false, blocked: true), Routes.age),
      Routes.ageBlocked,
    );
  });

  test('finished onboarding goes to the map and stays out of onboarding', () {
    expect(onboardingRedirect(s(), Routes.welcome), Routes.map);
    expect(onboardingRedirect(s(), Routes.profile), isNull);
  });

  test('finished onboarding can open every tab', () {
    for (final tab in [Routes.society, Routes.activity]) {
      expect(onboardingRedirect(s(), tab), isNull);
    }
  });

  test('the bottom bar is Map, Society, Report, Activity, Profile', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    final shell = container
        .read(routerProvider)
        .configuration
        .routes
        .whereType<StatefulShellRoute>()
        .single;
    expect(
      [for (final b in shell.branches) (b.routes.single as GoRoute).path],
      [
        Routes.map,
        Routes.society,
        Routes.report,
        Routes.activity,
        Routes.profile,
      ],
    );
  });
}
