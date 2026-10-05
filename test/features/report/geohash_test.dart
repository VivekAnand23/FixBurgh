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
}
