import 'dart:async';

import 'package:fixburgh/features/auth/auth_repository.dart';
import 'package:fixburgh/features/map/data/place_search.dart';
import 'package:fixburgh/features/notifications/notification_settings.dart';
import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:fixburgh/l10n/gen/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const _metresPerMile = 1609.344;

String placeKindLabel(AppLocalizations l10n, String kind) => switch (kind) {
  'home' => l10n.placeHome,
  'school' => l10n.placeSchool,
  'work' => l10n.placeWork,
  _ => l10n.placeOther,
};

IconData placeKindIcon(String kind) => switch (kind) {
  'home' => Icons.home_outlined,
  'school' => Icons.school_outlined,
  'work' => Icons.work_outline,
  _ => Icons.place_outlined,
};

/// Up to 3 saved places that get alerts for new urgent reports nearby
/// (BRD FR-NTF-03, 04).
class SavedPlacesScreen extends ConsumerWidget {
  const SavedPlacesScreen({super.key});

  Future<void> _edit(BuildContext context, SavedPlace? place, String slot) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PlaceEditor(place: place, slot: slot),
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final places = ref.watch(savedPlacesProvider).value ?? const [];
    final free = freePlaceSlot(places);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.savedPlacesTitle)),
      floatingActionButton: free == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _edit(context, null, free),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: Text(l10n.addPlace),
            ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.savedPlacesIntro),
          const SizedBox(height: 16),
          if (places.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(l10n.noSavedPlaces, textAlign: TextAlign.center),
            ),
          for (final p in places)
            Card(
              child: ListTile(
                leading: Icon(placeKindIcon(p.kind)),
                title: Text(
                  p.label.isEmpty ? placeKindLabel(l10n, p.kind) : p.label,
                ),
                subtitle: Text(l10n.alertRadius(_miles(p.radiusMiles))),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _edit(context, p, p.id),
              ),
            ),
          if (free == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l10n.placesFull(placeSlots.length)),
            ),
        ],
      ),
    );
  }
}

String _miles(double m) =>
    m == m.roundToDouble() ? m.toStringAsFixed(0) : m.toString();

/// Adds or edits one saved place.
class PlaceEditor extends ConsumerStatefulWidget {
  const PlaceEditor({required this.slot, this.place, super.key});

  final SavedPlace? place;
  final String slot;

  @override
  ConsumerState<PlaceEditor> createState() => _PlaceEditorState();
}

class _PlaceEditorState extends ConsumerState<PlaceEditor> {
  late String _kind = widget.place?.kind ?? 'home';
  late final _label = TextEditingController(text: widget.place?.label);
  final _search = TextEditingController();
  late GeoPoint? _location = widget.place?.location;
  late double _radius = widget.place?.radiusMiles ?? 0.5;
  GoogleMapController? _map;
  bool _busy = false;

  @override
  void dispose() {
    _label.dispose();
    _search.dispose();
    _map?.dispose();
    super.dispose();
  }

  Future<void> _moveTo(GeoPoint p) async {
    setState(() => _location = p);
    await _map?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(p.lat, p.lng), 14),
    );
  }

  Future<void> _useMyLocation() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.locationDenied)));
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: defaultTargetPlatform == TargetPlatform.android
            ? AndroidSettings(forceLocationManager: true)
            : const LocationSettings(),
      );
      await _moveTo(GeoPoint(pos.latitude, pos.longitude));
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _find(String q) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final hit = await findPlace(q);
    if (!mounted) return;
    setState(() => _busy = false);
    if (hit == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.addressNotFound)));
      return;
    }
    await _moveTo(hit);
  }

  Future<void> _save() async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    final loc = _location;
    if (uid == null || loc == null) return;
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(notificationsRepositoryProvider)
          .savePlace(
            uid,
            SavedPlace(
              id: widget.slot,
              kind: _kind,
              label: _label.text.trim(),
              location: loc,
              radiusMiles: _radius,
            ),
          );
      nav.pop();
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }

  Future<void> _delete() async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return;
    final nav = Navigator.of(context);
    await ref
        .read(notificationsRepositoryProvider)
        .deletePlace(uid, widget.slot);
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final loc = _location;
    // Downtown Pittsburgh until a place is chosen.
    final center = LatLng(loc?.lat ?? 40.4406, loc?.lng ?? -79.9959);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.place == null ? l10n.addPlace : l10n.editPlace),
        actions: [
          if (widget.place != null)
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            segments: [
              for (final k in ['home', 'school', 'work', 'other'])
                ButtonSegment(
                  value: k,
                  icon: Icon(placeKindIcon(k)),
                  tooltip: placeKindLabel(l10n, k),
                  label: Text(placeKindLabel(l10n, k)),
                ),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
            showSelectedIcon: false,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _label,
            maxLength: 40,
            decoration: InputDecoration(labelText: l10n.placeLabel),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: _find,
            decoration: InputDecoration(
              labelText: l10n.searchAddress,
              hintText: l10n.searchAddressHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: l10n.searchAddress,
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => _find(_search.text),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _useMyLocation,
            icon: const Icon(Icons.my_location),
            label: Text(l10n.useMyLocation),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 220,
              child: Semantics(
                label: l10n.placeMapSemantics,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: center,
                    zoom: loc == null ? 11 : 14,
                  ),
                  onMapCreated: (c) => _map = c,
                  onTap: (p) => setState(
                    () => _location = GeoPoint(p.latitude, p.longitude),
                  ),
                  zoomControlsEnabled: false,
                  markers: {
                    if (loc != null)
                      Marker(
                        markerId: const MarkerId('place'),
                        position: LatLng(loc.lat, loc.lng),
                      ),
                  },
                  circles: {
                    if (loc != null)
                      Circle(
                        circleId: const CircleId('radius'),
                        center: LatLng(loc.lat, loc.lng),
                        radius: _radius * _metresPerMile,
                        strokeWidth: 2,
                        strokeColor: theme.colorScheme.primary,
                        fillColor: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                      ),
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            loc == null ? l10n.placeTapMap : l10n.placeChosen,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.alertRadius(_miles(_radius)),
            style: theme.textTheme.titleMedium,
          ),
          Slider(
            value: _radius,
            min: minRadiusMiles,
            max: maxRadiusMiles,
            divisions: 7,
            label: l10n.alertRadius(_miles(_radius)),
            onChanged: (v) => setState(() => _radius = v),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: loc == null ? null : _save,
            child: Text(l10n.savePlace),
          ),
        ],
      ),
    );
  }
}
