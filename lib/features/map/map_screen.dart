import 'package:fixburgh/features/moderation/blocked_users.dart';
import 'package:fixburgh/features/report/data/report_repository.dart';
import 'package:fixburgh/features/report/domain/report.dart';
import 'package:fixburgh/features/report/presentation/report_detail_sheet.dart';
import 'package:fixburgh/features/report/presentation/report_labels.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

/// Downtown Pittsburgh.
const _start = CameraPosition(target: LatLng(40.4406, -79.9959), zoom: 12);

/// Fixed reports stay on the map (when shown) for this long (FR-MAP-10).
const _resolvedVisibleFor = Duration(days: 30);

const _cluster = ClusterManagerId('reports');

/// Community map: grouped pins, category and status filters, list view, and
/// a detail sheet with "Me too" (BRD FR-MAP-01 to 11).
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final Set<ReportCategory> _categories = {};
  bool _showFixed = false;
  bool _list = false;

  static double _hue(ReportCategory c) => switch (c) {
    ReportCategory.pothole => BitmapDescriptor.hueOrange,
    ReportCategory.landslide => 30,
    ReportCategory.flooding => BitmapDescriptor.hueAzure,
    ReportCategory.streetlight => BitmapDescriptor.hueYellow,
    ReportCategory.dumping => BitmapDescriptor.hueViolet,
    ReportCategory.fallenTree => BitmapDescriptor.hueGreen,
    ReportCategory.sidewalk => BitmapDescriptor.hueBlue,
    ReportCategory.other => BitmapDescriptor.hueRose,
  };

  List<Report> _filter(List<Report> all, Set<String> blocked) {
    final cutoff = DateTime.now().subtract(_resolvedVisibleFor);
    return [
      for (final r in all)
        if (!blocked.contains(r.authorUid) &&
            (_categories.isEmpty || _categories.contains(r.category)) &&
            (r.isOpen ||
                (_showFixed && (r.resolvedAt ?? r.createdAt).isAfter(cutoff))))
          r,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final all = ref.watch(mapReportsProvider).value ?? const <Report>[];
    final reports = _filter(all, ref.watch(blockedUsersProvider));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mapTitle),
        actions: [
          IconButton(
            tooltip: _list ? l10n.showMapView : l10n.showListView,
            icon: Icon(_list ? Icons.map_outlined : Icons.view_list),
            onPressed: () => setState(() => _list = !_list),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                FilterChip(
                  label: Text(l10n.showFixed),
                  selected: _showFixed,
                  onSelected: (v) => setState(() => _showFixed = v),
                ),
                const SizedBox(width: 8),
                for (final c in ReportCategory.values) ...[
                  FilterChip(
                    avatar: Icon(c.icon, size: 18),
                    label: Text(c.label(l10n)),
                    selected: _categories.contains(c),
                    onSelected: (v) => setState(
                      () => v ? _categories.add(c) : _categories.remove(c),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: _list
                ? _ReportList(reports: reports)
                : Semantics(
                    label: l10n.mapReportsSemantics(reports.length),
                    child: GoogleMap(
                      initialCameraPosition: _start,
                      myLocationEnabled: true,
                      clusterManagers: {
                        const ClusterManager(clusterManagerId: _cluster),
                      },
                      markers: {
                        for (final r in reports)
                          Marker(
                            markerId: MarkerId(r.id),
                            clusterManagerId: _cluster,
                            position: LatLng(r.location.lat, r.location.lng),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              _hue(r.category),
                            ),
                            alpha: r.isOpen ? 1 : 0.55,
                            onTap: () => showReportSheet(context, r.id),
                          ),
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Screen-reader-friendly alternative to the map (NFR-A11Y-06).
class _ReportList extends StatelessWidget {
  const _ReportList({required this.reports});

  final List<Report> reports;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (reports.isEmpty) {
      return Center(child: Text(l10n.noReportsMatch));
    }
    final fmt = DateFormat.MMMd(Localizations.localeOf(context).toString());
    return ListView.separated(
      itemCount: reports.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final r = reports[i];
        return ListTile(
          leading: Icon(r.category.icon),
          title: Text(r.category.label(l10n)),
          subtitle: Text(
            [
              r.address ?? r.municipalityName,
              r.status.label(l10n),
              fmt.format(r.createdAt),
            ].join(' · '),
          ),
          trailing: r.upvoteCount > 0
              ? Text(l10n.meTooCount(r.upvoteCount))
              : null,
          onTap: () => showReportSheet(context, r.id),
        );
      },
    );
  }
}
