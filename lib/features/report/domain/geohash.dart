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
