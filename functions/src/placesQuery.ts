/**
 * Google Places (New) Text Search: the request and the parts of the reply
 * the app shows. No Firebase imports, so tests can load it directly.
 */

export const PLACES_URL = 'https://places.googleapis.com/v1/places:searchText';

/** Only what the app shows; the field mask sets what Google bills for. */
export const FIELD_MASK = [
  'places.id',
  'places.displayName',
  'places.formattedAddress',
  'places.location',
  'places.rating',
  'places.userRatingCount',
  'places.nationalPhoneNumber',
  'places.websiteUri',
  'places.googleMapsUri',
  'places.businessStatus',
].join(',');

const METRES_PER_MILE = 1609.344;

export type PlacesQuery = { query: string; lat: number; lng: number; miles: number };

export type GooglePlace = {
  name: string;
  address: string;
  rating: number | null;
  ratingCount: number;
  phone: string | null;
  website: string | null;
  mapsUrl: string;
  distanceMiles: number;
};

export function placesRequest(q: PlacesQuery) {
  return {
    textQuery: q.query,
    // Text Search caps the bias circle at 50 km.
    locationBias: {
      circle: {
        center: { latitude: q.lat, longitude: q.lng },
        radius: Math.min(q.miles * METRES_PER_MILE, 50_000),
      },
    },
    maxResultCount: 10,
    languageCode: 'en',
    regionCode: 'US',
  };
}

export function milesBetween(a: { lat: number; lng: number }, b: { lat: number; lng: number }) {
  const R = 3958.8;
  const rad = Math.PI / 180;
  const dLat = (b.lat - a.lat) * rad;
  const dLng = (b.lng - a.lng) * rad;
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(a.lat * rad) * Math.cos(b.lat * rad) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}

/** Open businesses within the distance, in Google's order. */
export function parsePlaces(body: unknown, q: PlacesQuery): GooglePlace[] {
  const places = (body as { places?: Record<string, any>[] })?.places ?? [];
  const out: GooglePlace[] = [];
  for (const p of places) {
    const lat = p.location?.latitude;
    const lng = p.location?.longitude;
    if (typeof lat !== 'number' || typeof lng !== 'number') continue;
    if (p.businessStatus && p.businessStatus !== 'OPERATIONAL') continue;
    const distanceMiles = milesBetween(q, { lat, lng });
    if (distanceMiles > q.miles) continue;
    const name = p.displayName?.text;
    if (typeof name !== 'string' || !name) continue;
    out.push({
      name,
      address: typeof p.formattedAddress === 'string' ? p.formattedAddress : '',
      rating: typeof p.rating === 'number' ? p.rating : null,
      ratingCount: typeof p.userRatingCount === 'number' ? p.userRatingCount : 0,
      phone: typeof p.nationalPhoneNumber === 'string' ? p.nationalPhoneNumber : null,
      website: typeof p.websiteUri === 'string' && p.websiteUri.startsWith('https://') ? p.websiteUri : null,
      mapsUrl:
        typeof p.googleMapsUri === 'string' && p.googleMapsUri.startsWith('https://')
          ? p.googleMapsUri
          : mapsSearchUrl(name, lat, lng),
      distanceMiles: Math.round(distanceMiles * 10) / 10,
    });
  }
  return out;
}

/** Google Maps searching for [query] around a point: free, no API call. */
export const mapsSearchUrl = (query: string, lat: number, lng: number) =>
  `https://www.google.com/maps/search/${encodeURIComponent(query)}/@${lat.toFixed(5)},${lng.toFixed(5)},13z`;
