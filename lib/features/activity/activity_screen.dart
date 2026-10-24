import 'package:fixburgh/features/activity/city_reports_view.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// What the Activity tab can show. Service requests and provider jobs join
/// in Burghood Phase 3.
enum ActivitySegment { cityReports }

/// The Activity tab (formerly My Reports).
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  ActivitySegment _segment = ActivitySegment.cityReports;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                ],
                selected: {_segment},
                onSelectionChanged: (s) => setState(() => _segment = s.first),
              ),
            ),
          ),
        ),
      ),
      body: switch (_segment) {
        ActivitySegment.cityReports => const CityReportsView(),
      },
    );
  }
}
