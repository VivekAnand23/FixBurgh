import 'package:fixburgh/app/remote_config.dart';
import 'package:fixburgh/features/activity/city_reports_view.dart';
import 'package:fixburgh/features/providers/data/provider_repository.dart';
import 'package:fixburgh/features/providers/domain/provider.dart';
import 'package:fixburgh/features/services/presentation/service_requests_view.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the Activity tab can show: city reports, plus service requests and
/// (for providers) jobs behind `feature_services`.
enum ActivitySegment { cityReports, serviceRequests, jobs }

/// The Activity tab (formerly My Reports).
class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  ActivitySegment _segment = ActivitySegment.cityReports;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = ref.watch(featureFlagsProvider).services;
    final provider = services ? ref.watch(myProviderProvider).value : null;
    final isProvider =
        provider != null && provider.status != ProviderStatus.applied;
    final available = {
      ActivitySegment.cityReports,
      if (services) ActivitySegment.serviceRequests,
      if (isProvider) ActivitySegment.jobs,
    };
    final segment = available.contains(_segment)
        ? _segment
        : ActivitySegment.cityReports;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.activityTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<ActivitySegment>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: ActivitySegment.cityReports,
                    icon: const Icon(Icons.location_city),
                    label: Text(l10n.activityCityReports),
                  ),
                  if (services)
                    ButtonSegment(
                      value: ActivitySegment.serviceRequests,
                      icon: const Icon(Icons.handyman_outlined),
                      label: Text(l10n.activityServiceRequests),
                    ),
                  if (isProvider)
                    ButtonSegment(
                      value: ActivitySegment.jobs,
                      icon: const Icon(Icons.work_outline),
                      label: Text(l10n.activityJobs),
                    ),
                ],
                selected: {segment},
                onSelectionChanged: (s) => setState(() => _segment = s.first),
              ),
            ),
          ),
        ),
      ),
      body: switch (segment) {
        ActivitySegment.cityReports => const CityReportsView(),
        ActivitySegment.serviceRequests => const ServiceRequestsView(),
        ActivitySegment.jobs => const JobsView(),
      },
    );
  }
}
