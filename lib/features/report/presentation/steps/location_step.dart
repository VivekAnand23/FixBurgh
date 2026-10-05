import 'dart:async';

import 'package:fixburgh/features/report/presentation/report_draft_controller.dart';
import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Downtown Pittsburgh, used when location permission is denied.
const _fallback = GeoPoint(40.4406, -79.9959);

class LocationStep extends ConsumerStatefulWidget {
  const LocationStep({required this.onNext, super.key});

  final VoidCallback onNext;

  @override
  ConsumerState<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends ConsumerState<LocationStep> {
  GoogleMapController? _map;
  bool _locating = false;
  bool _denied = false;

  @override
  void initState() {
    super.initState();
    if (ref.read(reportDraftProvider).location == null) {
      unawaited(_useMyLocation());
    }
  }

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    final notifier = ref.read(reportDraftProvider.notifier);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() => _denied = true);
        await notifier.setLocation(_fallback);
      } else {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        );
        final p = GeoPoint(pos.latitude, pos.longitude);
        await notifier.setLocation(p, accuracyM: pos.accuracy);
        await _map?.animateCamera(
          CameraUpdate.newLatLng(LatLng(p.lat, p.lng)),
        );
      }
    } on Exception {
      await notifier.setLocation(_fallback);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final draft = ref.watch(reportDraftProvider);
    final loc = draft.location ?? _fallback;
    final pin = LatLng(loc.lat, loc.lng);
    final outside = draft.location != null && draft.municipality == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          child: Text(l10n.locationTitle, style: theme.textTheme.headlineSmall),
        ),
        Expanded(
          child: Semantics(
            label: l10n.mapSemantics,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: pin, zoom: 17),
              onMapCreated: (c) => _map = c,
              myLocationEnabled: !_denied,
              myLocationButtonEnabled: false,
              onTap: (p) => ref
                  .read(reportDraftProvider.notifier)
                  .setLocation(GeoPoint(p.latitude, p.longitude)),
              markers: {
                Marker(
                  markerId: const MarkerId('issue'),
                  position: pin,
                  draggable: true,
                  onDragEnd: (p) => ref
                      .read(reportDraftProvider.notifier)
                      .setLocation(GeoPoint(p.latitude, p.longitude)),
                ),
              },
              circles: {
                if (draft.accuracyM != null)
                  Circle(
                    circleId: const CircleId('accuracy'),
                    center: pin,
                    radius: draft.accuracyM!,
                    strokeWidth: 1,
                    strokeColor: theme.colorScheme.primary,
                    fillColor: theme.colorScheme.primary.withValues(
                      alpha: 0.12,
                    ),
                  ),
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.locationHint,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              if (_denied)
                Text(l10n.locationDenied, style: theme.textTheme.bodyMedium),
              Semantics(
                liveRegion: true,
                child: Text(
                  outside
                      ? l10n.outsideCounty
                      : [
                          if (draft.address != null) draft.address!,
                          if (draft.municipality != null)
                            l10n.inMunicipality(draft.municipality!.name),
                        ].join('\n'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: outside ? theme.colorScheme.error : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _locating ? null : _useMyLocation,
                icon: _locating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(l10n.useMyLocation),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: draft.hasLocation ? widget.onNext : null,
                child: Text(l10n.next),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
