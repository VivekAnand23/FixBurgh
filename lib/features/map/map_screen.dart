import 'package:fixburgh/features/report/data/report_repository.dart';
import 'package:fixburgh/features/report/domain/report.dart';
import 'package:fixburgh/features/report/presentation/report_labels.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Downtown Pittsburgh.
const _start = CameraPosition(target: LatLng(40.4406, -79.9959), zoom: 12);

/// Community map. Clustering, filters, viewport queries and "Me too" come in
/// M3; for now it shows the most recent open reports county-wide.
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reports = ref.watch(openReportsProvider).value ?? const <Report>[];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mapTitle)),
      body: Semantics(
        label: l10n.mapReportsSemantics(reports.length),
        child: GoogleMap(
          initialCameraPosition: _start,
          myLocationEnabled: true,
          markers: {
            for (final r in reports)
              Marker(
                markerId: MarkerId(r.id),
                position: LatLng(r.location.lat, r.location.lng),
                icon: BitmapDescriptor.defaultMarkerWithHue(_hue(r.category)),
                infoWindow: InfoWindow(
                  title: r.category.label(l10n),
                  snippet: '${r.status.label(l10n)} · ${r.municipalityName}',
                ),
              ),
          },
        ),
      ),
    );
  }
}
