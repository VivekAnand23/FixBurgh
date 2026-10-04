import 'package:fixburgh/features/onboarding/onboarding_controller.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Neutral age screen (COPPA): no default values and no hint about the
/// required age. Only the pass/fail outcome is stored.
class AgeGateScreen extends ConsumerStatefulWidget {
  const AgeGateScreen({super.key});

  @override
  ConsumerState<AgeGateScreen> createState() => _AgeGateScreenState();
}

class _AgeGateScreenState extends ConsumerState<AgeGateScreen> {
  int? _month;
  int? _year;
  bool _busy = false;

  Future<void> _submit() async {
    setState(() => _busy = true);
    await ref
        .read(onboardingProvider.notifier)
        .submitBirthDate(year: _year!, month: _month!);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final months = DateFormat.MMMM(Localizations.localeOf(context).toString());
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 48),
            Text(
              l10n.ageTitle,
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.ageBody,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            DropdownButtonFormField<int>(
              initialValue: _month,
              decoration: InputDecoration(labelText: l10n.ageMonth),
              items: [
                for (var m = 1; m <= 12; m++)
                  DropdownMenuItem(
                    value: m,
                    child: Text(months.format(DateTime(2000, m))),
                  ),
              ],
              onChanged: (v) => setState(() => _month = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _year,
              decoration: InputDecoration(labelText: l10n.ageYear),
              menuMaxHeight: 320,
              items: [
                for (var y = now.year; y >= now.year - 110; y--)
                  DropdownMenuItem(value: y, child: Text('$y')),
              ],
              onChanged: (v) => setState(() => _year = v),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _month == null || _year == null || _busy
                  ? null
                  : _submit,
              child: Text(l10n.ageContinue),
            ),
          ],
        ),
      ),
    );
  }
}

class AgeBlockedScreen extends StatelessWidget {
  const AgeBlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.family_restroom,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.ageBlockedTitle,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.ageBlockedBody,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
