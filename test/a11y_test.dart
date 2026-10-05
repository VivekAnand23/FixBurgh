import 'package:fixburgh/app/providers.dart';
import 'package:fixburgh/app/theme/app_theme.dart';
import 'package:fixburgh/features/auth/sign_in_screen.dart';
import 'package:fixburgh/features/onboarding/age_gate_screen.dart';
import 'package:fixburgh/features/onboarding/welcome_screen.dart';
import 'package:fixburgh/features/report/presentation/steps/details_step.dart';
import 'package:fixburgh/features/report/presentation/steps/photo_step.dart';
import 'package:fixburgh/features/report/presentation/steps/safety_step.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Accessibility guidelines (BRD section 12) for screens that don't need
/// Firebase: tap target sizes, labels and text contrast, in light and dark.
void main() {
  final screens = <String, Widget>{
    'welcome': const WelcomeScreen(),
    'age gate': const AgeGateScreen(),
    'sign in': const SignInScreen(),
    'safety step': Scaffold(body: SafetyStep(onContinue: () {})),
    'photo step': Scaffold(body: PhotoStep(onNext: () {})),
    'details step': Scaffold(body: DetailsStep(onNext: () {})),
  };

  for (final dark in [false, true]) {
    for (final MapEntry(key: name, value: screen) in screens.entries) {
      testWidgets('$name meets accessibility guidelines '
          '(${dark ? 'dark' : 'light'})', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp(
              theme: dark ? AppTheme.dark() : AppTheme.light(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: screen,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  }
}
