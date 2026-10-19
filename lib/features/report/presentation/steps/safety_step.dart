import 'dart:async';

import 'package:fixburgh/features/routing/data/routing_providers.dart';
import 'package:fixburgh/features/routing/domain/routing_engine.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      return EmergencyCard(onBack: () => setState(() => _emergency = false));
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

/// After a person's first reports the safety check is this one row, still
/// always shown above the photo step (BRD FR-SAF-01).
class CompactSafetyRow extends StatelessWidget {
  const CompactSafetyRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: ListTile(
        leading: Icon(Icons.emergency, color: scheme.error),
        title: Text(
          l10n.safetyCompact,
          style: TextStyle(color: scheme.onErrorContainer),
        ),
        trailing: TextButton(
          style: TextButton.styleFrom(foregroundColor: scheme.error),
          onPressed: () => showEmergencyScreen(context),
          child: Text(l10n.safetyCompactYes),
        ),
      ),
    );
  }
}

/// The emergency card as its own full screen, e.g. when the safety check
/// is asked again from the details step (BRD FR-SAF-03).
Future<void> showEmergencyScreen(BuildContext context) =>
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          body: SafeArea(
            child: EmergencyCard(onBack: () => Navigator.of(context).pop()),
          ),
        ),
      ),
    );

/// "Call 911 now", plus the utilities' emergency lines for downed wires
/// and gas (BRD FR-SAF-02). No report is created.
class EmergencyCard extends ConsumerWidget {
  const EmergencyCard({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final onCard = theme.colorScheme.onErrorContainer;
    final engine = ref.watch(routingEngineProvider).value;
    final sections = [
      (Icons.electrical_services, l10n.utilityWires, 'wires'),
      (Icons.local_fire_department_outlined, l10n.utilityGas, 'gas'),
    ];
    return ColoredBox(
      color: theme.colorScheme.errorContainer,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.emergency, size: 72, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                l10n.emergencyTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: onCard,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.emergencyBody,
                style: theme.textTheme.bodyLarge?.copyWith(color: onCard),
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
              if (engine != null)
                for (final (icon, title, hazard) in sections)
                  if (engine.emergencyLines(hazard).isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Icon(icon, color: onCard),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: onCard,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (final a in engine.emergencyLines(hazard)) ...[
                      _UtilityButton(agency: a),
                      const SizedBox(height: 8),
                    ],
                  ],
              const SizedBox(height: 12),
              TextButton(onPressed: onBack, child: Text(l10n.notAnEmergency)),
            ],
          ),
        ),
      ),
    );
  }
}

class _UtilityButton extends StatelessWidget {
  const _UtilityButton({required this.agency});

  final Agency agency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onErrorContainer,
        side: BorderSide(color: scheme.onErrorContainer),
        alignment: Alignment.centerLeft,
      ),
      onPressed: () => unawaited(
        launchUrl(
          Uri(
            scheme: 'tel',
            path: agency.phone!.replaceAll(RegExp('[^0-9+]'), ''),
          ),
        ),
      ),
      icon: const Icon(Icons.call_outlined),
      label: Text(
        l10n.callUtility(agency.name, agency.phoneLabel ?? agency.phone!),
      ),
    );
  }
}
