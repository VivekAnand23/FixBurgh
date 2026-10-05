import 'package:fixburgh/features/report/domain/report.dart';
import 'package:fixburgh/features/routing/data/routing_providers.dart';
import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';

final NotifierProvider<ReportDraftController, ReportDraft> reportDraftProvider =
    NotifierProvider.autoDispose<ReportDraftController, ReportDraft>(
      ReportDraftController.new,
    );

class ReportDraftController extends Notifier<ReportDraft> {
  @override
  ReportDraft build() => const ReportDraft();

  void addPhoto(String path) {
    if (state.photoPaths.length >= maxPhotos) return;
    state = state.copyWith(photoPaths: [...state.photoPaths, path]);
  }

  void removePhoto(String path) => state = state.copyWith(
    photoPaths: state.photoPaths.where((p) => p != path).toList(),
  );

  /// Sets the pin and resolves the municipality (offline) and address.
  Future<void> setLocation(GeoPoint point, {double? accuracyM}) async {
    final locator = await ref.read(municipalityLocatorProvider.future);
    final muni = locator.locate(point);
    state = state.copyWith(
      location: point,
      accuracyM: accuracyM,
      // A hand-placed pin has no GPS error radius.
      clearAccuracy: accuracyM == null,
      municipality: muni,
      clearMunicipality: muni == null,
    );
    final address = await _reverseGeocode(point);
    // Ignore a stale lookup if the pin moved again meanwhile.
    if (address != null && identical(state.location, point)) {
      state = state.copyWith(address: address);
    }
  }

  void setCategory(ReportCategory c) => state = state.copyWith(category: c);

  void setSeverity(Severity s) => state = state.copyWith(severity: s);

  void setDescription(String d) => state = state.copyWith(description: d);

  static Future<String?> _reverseGeocode(GeoPoint p) async {
    try {
      final marks = await Geocoding().placemarkFromCoordinates(p.lat, p.lng);
      if (marks.isEmpty) return null;
      final m = marks.first;
      final street = <String?>[
        m.subThoroughfare,
        m.thoroughfare,
      ].whereType<String>().where((s) => s.isNotEmpty).join(' ');
      return [
        if (street.isNotEmpty) street,
        if ((m.locality ?? '').isNotEmpty) m.locality,
      ].join(', ');
    } on Exception {
      return null; // Offline or no result; the pin is what matters.
    }
  }
}
