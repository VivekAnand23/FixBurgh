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
}
