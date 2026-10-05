import 'package:fixburgh/features/report/domain/report.dart';
import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const muni = Municipality(
    id: '100',
    name: 'City of Pittsburgh',
    type: 'city',
  );

  test('a draft needs a photo, a location in the county and a category', () {
    var d = const ReportDraft();
    expect(d.isComplete, isFalse);
    d = d.copyWith(photoPaths: ['a.jpg']);
    d = d.copyWith(location: const GeoPoint(40.44, -79.99), municipality: muni);
    expect(d.isComplete, isFalse);
    d = d.copyWith(category: ReportCategory.pothole);
    expect(d.isComplete, isTrue);
  });

  test('moving the pin outside the county clears the municipality', () {
    final d = const ReportDraft(municipality: muni).copyWith(
      location: const GeoPoint(40.17, -80.24),
      clearMunicipality: true,
    );
    expect(d.municipality, isNull);
    expect(d.hasLocation, isFalse);
  });

  test('category ids round-trip and unknown ids fall back to other', () {
    for (final c in ReportCategory.values) {
      expect(ReportCategory.fromId(c.id), c);
    }
    expect(ReportCategory.fromId('nope'), ReportCategory.other);
  });

  test('a hand-placed pin clears the GPS accuracy radius', () {
    final gps = const ReportDraft().copyWith(
      location: const GeoPoint(40.44, -79.99),
      accuracyM: 4,
    );
    expect(gps.accuracyM, 4);
    final moved = gps.copyWith(
      location: const GeoPoint(40.4401, -79.9901),
      clearAccuracy: true,
    );
    expect(moved.accuracyM, isNull);
  });
}
