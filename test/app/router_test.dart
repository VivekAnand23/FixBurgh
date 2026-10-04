import 'package:fixburgh/app/router.dart';
import 'package:fixburgh/features/onboarding/onboarding_controller.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
