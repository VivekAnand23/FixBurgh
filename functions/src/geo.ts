/** Geohash helpers, matching lib/features/report/domain/geohash.dart. */
const BASE32 = '0123456789bcdefghjkmnpqrstuvwxyz';

export function encodeGeohash(lat: number, lng: number, precision = 9): string {
  let latMin = -90, latMax = 90, lngMin = -180, lngMax = 180;
  let out = '', bit = 0, ch = 0, even = true;
  while (out.length < precision) {
    if (even) {
      const mid = (lngMin + lngMax) / 2;
      if (lng >= mid) { ch = (ch << 1) | 1; lngMin = mid; } else { ch <<= 1; lngMax = mid; }
    } else {
      const mid = (latMin + latMax) / 2;
      if (lat >= mid) { ch = (ch << 1) | 1; latMin = mid; } else { ch <<= 1; latMax = mid; }
    }
    even = !even;
    if (++bit === 5) { out += BASE32[ch]; bit = 0; ch = 0; }
  }
  return out;
}

/** The cell containing the point and its 8 neighbours. */
export function neighborGeohashes(lat: number, lng: number, precision: number): string[] {
  const lngBits = Math.floor((precision * 5 + 1) / 2);
  const latBits = Math.floor((precision * 5) / 2);
  const dLat = 180 / 2 ** latBits;
  const dLng = 360 / 2 ** lngBits;
  const cells = new Set<string>();
  for (const y of [-1, 0, 1]) {
    for (const x of [-1, 0, 1]) cells.add(encodeGeohash(lat + y * dLat, lng + x * dLng, precision));
  }
  return [...cells];
}

/** Great-circle distance in metres. */
export function distanceM(aLat: number, aLng: number, bLat: number, bLng: number): number {
  const rad = (d: number) => (d * Math.PI) / 180;
  const h =
    Math.sin(rad(bLat - aLat) / 2) ** 2 +
    Math.cos(rad(aLat)) * Math.cos(rad(bLat)) * Math.sin(rad(bLng - aLng) / 2) ** 2;
  return 2 * 6371000 * Math.asin(Math.sqrt(h));
}

export const METRES_PER_MILE = 1609.344;
