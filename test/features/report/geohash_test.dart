import 'package:fixburgh/features/report/domain/geohash.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('matches the reference geohash for a known point', () {
    // Reference value from geohash.org for 57.64911, 10.40744.
    expect(encodeGeohash(57.64911, 10.40744, precision: 11), 'u4pruydqqvj');
  });

  test('downtown Pittsburgh encodes with the dppn prefix', () {
    final hash = encodeGeohash(40.4406, -79.9959);
    expect(hash, hasLength(9));
    expect(hash, startsWith('dppn'));
  });

  test('neighbor cells cover points just across a cell edge', () {
    const lat = 40.4406;
    const lng = -79.9959;
    final cells = neighborGeohashes(lat, lng);
    expect(cells, hasLength(9));
    // 40 m north, south, east and west all fall inside the 9 cells.
    for (final (dLat, dLng) in [
      (0.00036, 0.0),
      (-0.00036, 0.0),
      (0.0, 0.00047),
      (0.0, -0.00047),
    ]) {
      expect(
        cells,
        contains(encodeGeohash(lat + dLat, lng + dLng, precision: 7)),
      );
    }
  });

  group('geohashesCovering', () {
    // Roughly downtown Pittsburgh and the North Side.
    const south = 40.43;
    const west = -80.02;
    const north = 40.46;
    const east = -79.98;

    test('covers the box with at most 9 cells', () {
      final cells = geohashesCovering(
        south: south,
        west: west,
        north: north,
        east: east,
      );
      expect(cells.length, inInclusiveRange(1, 9));
      // Every point in the box falls in one of the cells.
      for (final lat in [south, 40.445, north]) {
        for (final lng in [west, -80.0, east]) {
          final hash = encodeGeohash(lat, lng);
          expect(cells.any(hash.startsWith), isTrue, reason: '$lat,$lng');
        }
      }
    });

    test('uses longer prefixes for smaller boxes', () {
      final city = geohashesCovering(
        south: south,
        west: west,
        north: north,
        east: east,
      );
      final block = geohashesCovering(
        south: 40.4405,
        west: -79.9960,
        north: 40.4407,
        east: -79.9958,
      );
      expect(block.first.length, greaterThan(city.first.length));
    });

    test('whole county still fits in a few cells', () {
      final cells = geohashesCovering(
        south: 40.18,
        west: -80.37,
        north: 40.68,
        east: -79.68,
      );
      expect(cells.length, lessThanOrEqualTo(9));
    });
  });
}
