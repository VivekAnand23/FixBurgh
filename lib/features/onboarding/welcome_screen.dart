import 'package:fixburgh/features/onboarding/onboarding_controller.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 32),
            Semantics(
              label: 'FixBurgh logo',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'Images/Logo.jpeg',
                  height: 120,
                  excludeFromSemantics: true,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.welcomeTitle,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.welcomeBody,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text(l10n.welcomePrivacy),
              ),
            ),
            Card(
              color: theme.colorScheme.errorContainer,
              child: ListTile(
                leading: Icon(
                  Icons.emergency_outlined,
                  color: theme.colorScheme.onErrorContainer,
                ),
                title: Text(
                  l10n.notForEmergencies,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () =>
                  ref.read(onboardingProvider.notifier).markWelcomeSeen(),
              child: Text(l10n.welcomeContinue),
            ),
          ],
        ),
      ),
    );
  }
}
