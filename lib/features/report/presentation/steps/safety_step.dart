import 'dart:async';

import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Always the first step (BRD FR-SAF-01): emergencies go to 911, not a report.
class SafetyStep extends StatefulWidget {
  const SafetyStep({required this.onContinue, super.key});

  final VoidCallback onContinue;

  @override
  State<SafetyStep> createState() => _SafetyStepState();
}

class _SafetyStepState extends State<SafetyStep> {
  bool _emergency = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (_emergency) {
      return _EmergencyCard(onBack: () => setState(() => _emergency = false));
    }
    final examples = [
      (Icons.electrical_services, l10n.dangerWires),
      (Icons.local_fire_department_outlined, l10n.dangerGasFire),
      (Icons.car_crash_outlined, l10n.dangerCrash),
      (Icons.personal_injury_outlined, l10n.dangerTrapped),
      (Icons.flood_outlined, l10n.dangerWater),
    ];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(l10n.safetyTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        for (final (icon, text) in examples)
          ListTile(
            leading: Icon(icon, color: theme.colorScheme.error),
            title: Text(text),
            contentPadding: EdgeInsets.zero,
          ),
        const SizedBox(height: 24),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: () => setState(() => _emergency = true),
          child: Text(l10n.safetyYes),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: widget.onContinue,
          child: Text(l10n.safetyNo),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.safetyPhotoTip,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.errorContainer,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.emergency, size: 72, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            l10n.emergencyTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.emergencyBody,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
              minimumSize: const Size.fromHeight(64),
            ),
            onPressed: () =>
                unawaited(launchUrl(Uri(scheme: 'tel', path: '911'))),
            icon: const Icon(Icons.call),
            label: Text(l10n.call911),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onBack, child: Text(l10n.notAnEmergency)),
        ],
      ),
    );
  }
}
