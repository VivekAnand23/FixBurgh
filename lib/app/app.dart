import 'package:fixburgh/app/providers.dart';
import 'package:fixburgh/app/router.dart';
import 'package:fixburgh/app/theme/app_theme.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FixBurghApp extends ConsumerWidget {
  const FixBurghApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flavor = ref.watch(flavorProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      // Hidden for store screenshots: --dart-define=SCREENSHOTS=true
      debugShowCheckedModeBanner:
          flavor.isDev && !const bool.fromEnvironment('SCREENSHOTS'),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
