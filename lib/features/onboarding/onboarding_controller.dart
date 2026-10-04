import 'package:fixburgh/app/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where the user is in first-run onboarding.
class OnboardingState {
  const OnboardingState({
    required this.welcomeSeen,
    required this.ageConfirmed,
    required this.ageBlocked,
  });

  final bool welcomeSeen;
  final bool ageConfirmed;

  /// The user entered an age under 13. Kept so they can't simply retry.
  final bool ageBlocked;

  bool get isComplete => welcomeSeen && ageConfirmed && !ageBlocked;
}

/// Returns true when someone born in [birthYear]/[birthMonth] is definitely
/// 13 or older on [today]. If today is in their birth month we can't know
/// whether the birthday has passed, so we assume it hasn't.
bool isAtLeast13({
  required int birthYear,
  required int birthMonth,
  required DateTime today,
}) {
  var age = today.year - birthYear;
  if (today.month <= birthMonth) age -= 1;
  return age >= 13;
}

final onboardingProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );

class OnboardingController extends Notifier<OnboardingState> {
  static const _welcomeKey = 'onboarding.welcomeSeen';
  static const _ageKey = 'onboarding.ageConfirmed13';
  static const _blockedKey = 'onboarding.ageBlocked';

  @override
  OnboardingState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return OnboardingState(
      welcomeSeen: prefs.getBool(_welcomeKey) ?? false,
      ageConfirmed: prefs.getBool(_ageKey) ?? false,
      ageBlocked: prefs.getBool(_blockedKey) ?? false,
    );
  }

  Future<void> markWelcomeSeen() async {
    await ref.read(sharedPreferencesProvider).setBool(_welcomeKey, true);
    state = OnboardingState(
      welcomeSeen: true,
      ageConfirmed: state.ageConfirmed,
      ageBlocked: state.ageBlocked,
    );
  }

  /// Records only the outcome; the birth date itself is never stored.
  Future<bool> submitBirthDate({
    required int year,
    required int month,
    DateTime? today,
  }) async {
    final ok = isAtLeast13(
      birthYear: year,
      birthMonth: month,
      today: today ?? DateTime.now(),
    );
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(ok ? _ageKey : _blockedKey, true);
    state = OnboardingState(
      welcomeSeen: state.welcomeSeen,
      ageConfirmed: ok,
      ageBlocked: !ok,
    );
    return ok;
  }
}
