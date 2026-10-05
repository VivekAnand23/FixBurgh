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

/// Stop sampling once a fix is this accurate (metres).
const _goodEnoughM = 5.0;

/// Never sample longer than this.
const _maxSampling = Duration(seconds: 15);

/// iOS purpose key under NSLocationTemporaryUsageDescriptionDictionary.
const _precisePurposeKey = 'IncidentLocation';

class LocationStep extends ConsumerStatefulWidget {
  const LocationStep({required this.onNext, super.key});

  final VoidCallback onNext;

  @override
  ConsumerState<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends ConsumerState<LocationStep> {
  GoogleMapController? _map;
  StreamSubscription<Position>? _sampling;
  bool _locating = false;
  bool _denied = false;
  bool _approximateOnly = false;
  bool _satellite = false;

  /// Set once the user moves the pin, so GPS updates stop overriding it.
  bool _pinMovedByUser = false;

  @override
  void initState() {
    super.initState();
    if (ref.read(reportDraftProvider).location == null) {
      unawaited(_useMyLocation());
    }
  }

  @override
  void dispose() {
    unawaited(_sampling?.cancel());
    _map?.dispose();
    super.dispose();
  }

  /// Gets the most precise fix available: requests full accuracy, then
  /// samples high-accuracy GPS and keeps the best reading until it is within
  /// [_goodEnoughM] or [_maxSampling] passes.
  Future<void> _useMyLocation() async {
    await _sampling?.cancel();
    setState(() {
      _locating = true;
      _pinMovedByUser = false;
    });
    final notifier = ref.read(reportDraftProvider.notifier);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() {
          _denied = true;
          _locating = false;
        });
        await notifier.setLocation(_fallback);
        return;
      }
      _denied = false;

      // iOS lets users share only an approximate location; ask once for
      // precise location for this report.
      var accuracy = await Geolocator.getLocationAccuracy();
      if (accuracy == LocationAccuracyStatus.reduced) {
        accuracy = await Geolocator.requestTemporaryFullAccuracy(
          purposeKey: _precisePurposeKey,
        );
      }
      setState(
        () => _approximateOnly = accuracy == LocationAccuracyStatus.reduced,
      );

      Position? best;
      final done = Completer<void>();
      final timer = Timer(_maxSampling, () {
        if (!done.isCompleted) done.complete();
      });
      _sampling =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.bestForNavigation,
            ),
          ).listen(
            (pos) async {
              if (best != null && pos.accuracy >= best!.accuracy) return;
              best = pos;
              if (!_pinMovedByUser) {
                final p = GeoPoint(pos.latitude, pos.longitude);
                await notifier.setLocation(p, accuracyM: pos.accuracy);
                await _map?.animateCamera(
                  CameraUpdate.newLatLngZoom(LatLng(p.lat, p.lng), 19),
                );
              }
              if (pos.accuracy <= _goodEnoughM && !done.isCompleted) {
                done.complete();
              }
            },
            onError: (Object _) {
              if (!done.isCompleted) done.complete();
            },
          );
      await done.future;
      timer.cancel();
      await _sampling?.cancel();
      _sampling = null;
      if (best == null && ref.read(reportDraftProvider).location == null) {
        await notifier.setLocation(_fallback);
      }
    } on Exception {
      if (ref.read(reportDraftProvider).location == null) {
        await notifier.setLocation(_fallback);
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _movePin(LatLng p) {
    setState(() => _pinMovedByUser = true);
    // A hand-placed pin has no GPS error radius.
    unawaited(
      ref
          .read(reportDraftProvider.notifier)
          .setLocation(GeoPoint(p.latitude, p.longitude)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final draft = ref.watch(reportDraftProvider);
    final loc = draft.location ?? _fallback;
    final pin = LatLng(loc.lat, loc.lng);
    final outside = draft.location != null && draft.municipality == null;
    final acc = draft.accuracyM;

    final status = _locating
        ? (acc == null ? l10n.locating : l10n.improvingAccuracy(acc.round()))
        : _pinMovedByUser || acc == null
        ? l10n.pinPlacedByHand
        : l10n.accurateTo(acc.round());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          child: Text(l10n.locationTitle, style: theme.textTheme.headlineSmall),
        ),
        Expanded(
          child: Stack(
            children: [
              Semantics(
                label: l10n.mapSemantics,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(target: pin, zoom: 19),
                  mapType: _satellite ? MapType.hybrid : MapType.normal,
                  onMapCreated: (c) => _map = c,
                  myLocationEnabled: !_denied,
                  myLocationButtonEnabled: false,
                  onTap: _movePin,
                  markers: {
                    Marker(
                      markerId: const MarkerId('issue'),
                      position: pin,
                      draggable: true,
                      onDragEnd: _movePin,
                    ),
                  },
                  circles: {
                    if (acc != null && !_pinMovedByUser)
                      Circle(
                        circleId: const CircleId('accuracy'),
                        center: pin,
                        radius: acc,
                        strokeWidth: 1,
                        strokeColor: theme.colorScheme.primary,
                        fillColor: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                      ),
                  },
                ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: FloatingActionButton.small(
                  heroTag: 'mapType',
                  tooltip: _satellite ? l10n.showMap : l10n.showSatellite,
                  onPressed: () => setState(() => _satellite = !_satellite),
                  child: Icon(
                    _satellite ? Icons.map_outlined : Icons.satellite_alt,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.locationHint, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Semantics(
                liveRegion: true,
                child: Text(status, style: theme.textTheme.labelLarge),
              ),
              if (_approximateOnly)
                Text(
                  l10n.approximateOnly,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              if (_denied)
                Text(l10n.locationDenied, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text(
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
