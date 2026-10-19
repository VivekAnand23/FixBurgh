import 'package:fixburgh/app/providers.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/profile/profile_screen.dart';
import 'package:fixburgh/features/profile/settings_controller.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('theme and text size are saved on the device', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    ProviderContainer make() => ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    final c = make();
    expect(c.read(settingsProvider).themeMode, ThemeMode.system);
    await c.read(settingsProvider.notifier).setThemeMode(ThemeMode.dark);
    await c.read(settingsProvider.notifier).setTextSize(TextSize.larger);
    c.dispose();

    final again = make();
    expect(again.read(settingsProvider).themeMode, ThemeMode.dark);
    expect(again.read(settingsProvider).textSize, TextSize.larger);
    again.dispose();
  });

  testWidgets('text size multiplies the system scale', (tester) async {
    late double scale;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.2)),
        child: AppTextScale(
          size: TextSize.large,
          child: Builder(
            builder: (context) {
              scale = MediaQuery.textScalerOf(context).scale(1);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(scale, closeTo(1.2 * 1.15, 1e-9));
  });

  testWidgets('delete dialog defaults to keeping reports anonymously', (
    tester,
  ) async {
    ReportsOnDelete? result;
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<ReportsOnDelete>(
                context: context,
                builder: (_) => const DeleteAccountDialog(),
              );
              closed = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    Future<void> open() async {
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    await open();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(result, ReportsOnDelete.anonymize);

    await open();
    await tester.tap(find.text('Delete them and their photos'));
    await tester.pump();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(result, ReportsOnDelete.delete);

    closed = false;
    await open();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(result, isNull);
  });
}
