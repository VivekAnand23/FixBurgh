import 'dart:async';

import 'package:fixburgh/app/remote_config.dart';
import 'package:fixburgh/app/router.dart';
import 'package:fixburgh/features/auth/account_gate.dart';
import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/report/report_screen.dart';
import 'package:fixburgh/features/services/domain/service_request.dart';
import 'package:fixburgh/features/services/presentation/request_form_screen.dart';
import 'package:fixburgh/features/society/data/society_repository.dart';
import 'package:fixburgh/features/society/presentation/society_widgets.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The Report tab. With `feature_services` on, it first asks "Where is the
/// problem?": on the street is today's city report, unchanged; at home or
/// in the society's common areas becomes a service request.
class ReportEntry extends ConsumerStatefulWidget {
  const ReportEntry({super.key});

  @override
  ConsumerState<ReportEntry> createState() => _ReportEntryState();
}

class _ReportEntryState extends ConsumerState<ReportEntry> {
  bool _street = false;

  @override
  Widget build(BuildContext context) {
    if (_street || !ref.watch(featureFlagsProvider).services) {
      return const ReportScreen();
    }
    final l10n = AppLocalizations.of(context);
    final sid = ref.watch(currentSocietyIdProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.whereIsProblem)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Choice(
            key: const Key('fork-street'),
            icon: Icons.add_road,
            title: l10n.forkStreet,
            body: l10n.forkStreetBody,
            onTap: () => setState(() => _street = true),
          ),
          const SizedBox(height: 12),
          _Choice(
            key: const Key('fork-home'),
            icon: Icons.home_outlined,
            title: l10n.forkHome,
            body: l10n.forkHomeBody,
            onTap: () => unawaited(_request(RequestScope.home, sid)),
          ),
          if (sid != null) ...[
            const SizedBox(height: 12),
            _Choice(
              key: const Key('fork-common'),
              icon: Icons.apartment,
              title: l10n.forkCommon,
              body: l10n.forkCommonBody,
              onTap: () => unawaited(_request(RequestScope.common, sid)),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _request(RequestScope scope, String? sid) async {
    if (!hasFullAccount(ref.read(authUserProvider).value) &&
        !await requireFullAccount(context, ref)) {
      return;
    }
    if (!mounted) return;
    await context.push(
      Routes.newServiceRequest,
      extra: RequestFormArgs(scope: scope, societyId: sid),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SocietyCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(body),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
