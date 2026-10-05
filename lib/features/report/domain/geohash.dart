/// Standard base32 geohash encoding, used for nearby-report queries.
String encodeGeohash(double lat, double lng, {int precision = 9}) {
  const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
  var latMin = -90.0;
  var latMax = 90.0;
  var lngMin = -180.0;
  var lngMax = 180.0;
  final out = StringBuffer();
  var bit = 0;
  var ch = 0;
  var evenBit = true;
  while (out.length < precision) {
    if (evenBit) {
      final mid = (lngMin + lngMax) / 2;
      if (lng >= mid) {
        ch = (ch << 1) | 1;
        lngMin = mid;
      } else {
        ch <<= 1;
        lngMax = mid;
      }
    } else {
      final mid = (latMin + latMax) / 2;
      if (lat >= mid) {
        ch = (ch << 1) | 1;
        latMin = mid;
      } else {
        ch <<= 1;
        latMax = mid;
      }
    }
    evenBit = !evenBit;
    if (++bit == 5) {
      out.write(base32[ch]);
      bit = 0;
      ch = 0;
    }
  }
  return out.toString();
}

/// Geohash cells covering the point and its 8 neighbours at [precision].
/// Precision 7 cells are about 150 m by 150 m, comfortably wider than the
/// 50 m duplicate radius.
Set<String> neighborGeohashes(double lat, double lng, {int precision = 7}) {
  // Cell size in degrees for this precision.
  final lngBits = (precision * 5 + 1) ~/ 2;
  final latBits = precision * 5 ~/ 2;
  final dLat = 180 / (1 << latBits);
  final dLng = 360 / (1 << lngBits);
  return {
    for (final y in [-1, 0, 1])
      for (final x in [-1, 0, 1])
        encodeGeohash(lat + y * dLat, lng + x * dLng, precision: precision),
  };
}
