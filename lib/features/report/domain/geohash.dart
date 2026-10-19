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

/// Geohash prefixes covering the box from ([south], [west]) to ([north],
/// [east]), at the longest precision that needs at most [maxCells] cells,
/// so a map viewport becomes a few range queries (BRD FR-MAP-04).
List<String> geohashesCovering({
  required double south,
  required double west,
  required double north,
  required double east,
  int maxCells = 9,
}) {
  for (var precision = 9; precision >= 1; precision--) {
    final lngBits = (precision * 5 + 1) ~/ 2;
    final latBits = precision * 5 ~/ 2;
    final dLat = 180 / (1 << latBits);
    final dLng = 360 / (1 << lngBits);
    final y0 = ((south + 90) / dLat).floor();
    final y1 = ((north + 90) / dLat).floor();
    final x0 = ((west + 180) / dLng).floor();
    final x1 = ((east + 180) / dLng).floor();
    final count = (y1 - y0 + 1) * (x1 - x0 + 1);
    if (count > maxCells && precision > 1) continue;
    return [
      for (var y = y0; y <= y1; y++)
        for (var x = x0; x <= x1; x++)
          encodeGeohash(
            ((y + 0.5) * dLat - 90).clamp(-90, 90),
            ((x + 0.5) * dLng - 180).clamp(-180, 180),
            precision: precision,
          ),
    ];
  }
  return const [];
}
