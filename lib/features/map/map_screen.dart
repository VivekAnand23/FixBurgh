import 'dart:async';
import 'dart:ui' show ImageByteFormat;

import 'package:fixburgh/features/map/data/place_search.dart';
import 'package:fixburgh/features/map/map_filters.dart';
import 'package:fixburgh/features/moderation/blocked_users.dart';
import 'package:fixburgh/features/report/data/report_repository.dart';
import 'package:fixburgh/features/report/domain/geohash.dart';
import 'package:fixburgh/features/report/domain/report.dart';
import 'package:fixburgh/features/report/presentation/category_style.dart';
import 'package:fixburgh/features/report/presentation/report_detail_sheet.dart';
import 'package:fixburgh/features/report/presentation/report_labels.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

/// Downtown Pittsburgh, used when location permission is denied.
const _start = CameraPosition(target: LatLng(40.4406, -79.9959), zoom: 12);

const _cluster = ClusterManagerId('reports');

/// Marker size in logical pixels.
const _markerSize = 40.0;

/// Geohash cells covering [b], as a provider key.
ViewportKey viewportKey(LatLngBounds b, {required bool includeResolved}) => (
  cells: geohashesCovering(
    south: b.southwest.latitude,
    west: b.southwest.longitude,
    north: b.northeast.latitude,
    east: b.northeast.longitude,
  ).join(','),
  includeResolved: includeResolved,
);

bool _inCounty(double lat, double lng) =>
    lat > 40.18 && lat < 40.68 && lng > -80.37 && lng < -79.68;

/// Community map: category-shaped pins that group when zoomed out, search,
/// filters, legend, list view, and a detail sheet with "Me too"
/// (BRD FR-MAP-01 to 11).
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _map;
  final _search = TextEditingController();
  bool _searching = false;
  bool _list = false;
  bool _locationOn = false;

  /// The visible region; starts as roughly the area around [_start].
  LatLngBounds _bounds = LatLngBounds(
    southwest: const LatLng(40.38, -80.09),
    northeast: const LatLng(40.50, -79.90),
  );

  final Map<(ReportCategory, bool), BitmapDescriptor> _icons = {};
  double? _iconRatio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ratio = MediaQuery.devicePixelRatioOf(context);
    if (ratio != _iconRatio) {
      _iconRatio = ratio;
      unawaited(_loadIcons(ratio));
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _map?.dispose();
    super.dispose();
  }

  Future<void> _loadIcons(double ratio) async {
    for (final c in ReportCategory.values) {
      for (final urgent in [false, true]) {
        final image = await renderMarker(
          c,
          urgent: urgent,
          logicalSize: _markerSize,
          pixelRatio: ratio,
        );
        final png = await image.toByteData(format: ImageByteFormat.png);
        if (png == null) continue;
        _icons[(c, urgent)] = BitmapDescriptor.bytes(
          png.buffer.asUint8List(),
          imagePixelRatio: ratio,
        );
      }
    }
    if (mounted) setState(() {});
  }

  /// Centers on the user when they allow location (FR-MAP-01); stays on
  /// downtown Pittsburgh otherwise, or when they are outside the county.
  /// Debug builds can skip the location prompt at launch, for the
  /// walkthrough tests: `--dart-define=SKIP_LOCATION=true`.
  static const bool _skipLocation =
      !kReleaseMode && bool.fromEnvironment('SKIP_LOCATION');

  Future<void> _centerOnUser() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm != LocationPermission.always &&
          perm != LocationPermission.whileInUse) {
        return;
      }
      if (mounted) setState(() => _locationOn = true);
      // On Android, read the platform location manager directly so Google's
      // "Location Accuracy" consent dialog doesn't pop up over the map.
      final android = defaultTargetPlatform == TargetPlatform.android;
      final pos =
          await Geolocator.getLastKnownPosition(
            forceAndroidLocationManager: android,
          ) ??
          await Geolocator.getCurrentPosition(
            locationSettings: android
                ? AndroidSettings(
                    accuracy: LocationAccuracy.medium,
                    forceLocationManager: true,
                    timeLimit: const Duration(seconds: 10),
                  )
                : const LocationSettings(
                    accuracy: LocationAccuracy.medium,
                    timeLimit: Duration(seconds: 10),
                  ),
          );
      if (!_inCounty(pos.latitude, pos.longitude)) return;
      await _map?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 15),
      );
    } on Exception {
      // No fix: the map stays where it is.
    }
  }

  Future<void> _onCameraIdle() async {
    final bounds = await _map?.getVisibleRegion();
    if (bounds != null && mounted) setState(() => _bounds = bounds);
  }

  Future<void> _searchPlace(String query) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    FocusScope.of(context).unfocus();
    setState(() => _searching = true);
    final hit = await findPlace(query);
    if (!mounted) return;
    setState(() => _searching = false);
    if (hit == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.addressNotFound)));
      return;
    }
    if (_list) setState(() => _list = false);
    await _map?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(hit.lat, hit.lng), 16),
    );
  }

  Future<void> _pickTimeRange() async {
    final l10n = AppLocalizations.of(context);
    final current = ref.read(mapFiltersProvider).timeRange;
    final picked = await showModalBottomSheet<TimeRange>(
      useRootNavigator: true,
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final t in TimeRange.values)
              ListTile(
                title: Text(timeRangeLabel(l10n, t)),
                selected: t == current,
                trailing: t == current ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, t),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      ref.read(mapFiltersProvider.notifier).setTimeRange(picked);
    }
  }

  BitmapDescriptor _icon(Report r) =>
      _icons[(r.category, r.severity == Severity.urgent)] ??
      BitmapDescriptor.defaultMarker;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filters = ref.watch(mapFiltersProvider);
    final notifier = ref.read(mapFiltersProvider.notifier);
    final key = viewportKey(_bounds, includeResolved: filters.showFixed);
    final loaded = ref.watch(viewportReportsProvider(key));
    final blocked = ref.watch(blockedUsersProvider);
    final reports = [
      for (final r in loaded.value ?? const <Report>[])
        if (filters.matches(r, blocked: blocked)) r,
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mapTitle),
        actions: [
          IconButton(
            tooltip: l10n.legendTitle,
            icon: const Icon(Icons.info_outline),
            onPressed: () => showMapLegend(context),
          ),
          IconButton(
            tooltip: _list ? l10n.showMapView : l10n.showListView,
            icon: Icon(_list ? Icons.map_outlined : Icons.view_list),
            onPressed: () => setState(() => _list = !_list),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              keyboardType: TextInputType.streetAddress,
              onSubmitted: _searchPlace,
              decoration: InputDecoration(
                labelText: l10n.searchMap,
                hintText: l10n.searchAddressHint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        tooltip: l10n.searchMap,
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () => _searchPlace(_search.text),
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                ActionChip(
                  avatar: const Icon(Icons.date_range, size: 18),
                  label: Text(timeRangeLabel(l10n, filters.timeRange)),
                  tooltip: l10n.timeRangeTooltip,
                  onPressed: _pickTimeRange,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l10n.showFixed),
                  selected: filters.showFixed,
                  onSelected: notifier.setShowFixed,
                ),
                const SizedBox(width: 8),
                for (final c in ReportCategory.values) ...[
                  FilterChip(
                    avatar: Icon(c.icon, size: 18, color: c.color),
                    label: Text(c.label(l10n)),
                    selected: filters.categories.contains(c),
                    onSelected: (_) => notifier.toggleCategory(c),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          if (loaded.isLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _list
                ? _ReportList(reports: reports)
                : Semantics(
                    label: l10n.mapReportsSemantics(reports.length),
                    child: GoogleMap(
                      initialCameraPosition: _start,
                      onMapCreated: (c) {
                        _map = c;
                        if (!_skipLocation) unawaited(_centerOnUser());
                      },
                      onCameraIdle: _onCameraIdle,
                      myLocationEnabled: _locationOn,
                      clusterManagers: {
                        const ClusterManager(clusterManagerId: _cluster),
                      },
                      markers: {
                        for (final r in reports)
                          Marker(
                            markerId: MarkerId(r.id),
                            clusterManagerId: _cluster,
                            position: LatLng(r.location.lat, r.location.lng),
                            icon: _icon(r),
                            anchor: const Offset(0.5, 0.5),
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

String timeRangeLabel(AppLocalizations l10n, TimeRange t) => switch (t) {
  TimeRange.week => l10n.rangeWeek,
  TimeRange.month => l10n.rangeMonth,
  TimeRange.quarter => l10n.rangeQuarter,
  TimeRange.year => l10n.rangeYear,
  TimeRange.all => l10n.rangeAll,
};

/// What the pins mean (BRD FR-MAP-02).
Future<void> showMapLegend(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<void>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.legendTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            for (final c in ReportCategory.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _LegendMarker(category: c),
                title: Text(c.label(l10n)),
              ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const _LegendMarker(
                category: ReportCategory.pothole,
                urgent: true,
              ),
              title: Text(l10n.legendUrgent),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Opacity(
                opacity: 0.55,
                child: _LegendMarker(category: ReportCategory.pothole),
              ),
              title: Text(l10n.legendFixed),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.bubble_chart_outlined, size: 32),
              title: Text(l10n.legendCluster),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LegendMarker extends StatelessWidget {
  const _LegendMarker({required this.category, this.urgent = false});

  final ReportCategory category;
  final bool urgent;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: const Size.square(_markerSize),
      painter: CategoryMarkerPainter(category, urgent: urgent),
    ),
  );
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
          leading: ExcludeSemantics(
            child: CustomPaint(
              size: const Size.square(_markerSize),
              painter: CategoryMarkerPainter(
                r.category,
                urgent: r.severity == Severity.urgent,
              ),
            ),
          ),
          title: Text(r.category.label(l10n)),
          subtitle: Text(
            [
              r.address ?? r.municipalityName,
              r.severity.label(l10n),
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
