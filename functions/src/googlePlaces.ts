/**
 * Google results for a service search that finds no listed provider. The
 * app shows them as "Not on Burghood yet", with a link to Google Maps.
 *
 * Calls the Places API (New) with this function's own Google credentials,
 * so no key ships in the app. Places is billed per search, so each account
 * has a daily limit, and the app only calls this while the
 * `feature_google_places` Remote Config flag is on. Results are passed
 * straight through and never stored, as Google's terms require.
 */
import { appCallable } from './options';

import { getApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { todayEt } from './listing';
import { FIELD_MASK, PLACES_URL, mapsSearchUrl, parsePlaces, placesRequest } from './placesQuery';

/** Searches per account per day. */
export const DAILY_LIMIT = 20;

/** Roughly Allegheny County and its neighbours: searches start here. */
const inArea = (lat: number, lng: number) => lat > 39.7 && lat < 41.2 && lng > -80.9 && lng < -79.1;

export const searchGooglePlaces = onCall(appCallable, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in first.');
  if (request.auth?.token.firebase?.sign_in_provider === 'anonymous') {
    throw new HttpsError('permission-denied', 'Sign in with an account first.');
  }
  const { query, lat, lng, miles } = request.data ?? {};
  if (
    typeof query !== 'string' || !query.trim() || query.length > 80
    || typeof lat !== 'number' || typeof lng !== 'number' || !inArea(lat, lng)
    || typeof miles !== 'number' || miles < 1 || miles > 25
  ) {
    throw new HttpsError('invalid-argument', 'A short query, a place in the county and 1 to 25 miles are required.');
  }
  const q = { query: query.trim(), lat, lng, miles };
  const mapsUrl = mapsSearchUrl(q.query, lat, lng);

  // The daily limit, counted before calling Google.
  const counter = getFirestore().collection('placesLimits').doc(uid);
  const today = todayEt();
  const allowed = await getFirestore().runTransaction(async (tx) => {
    const c = await tx.get(counter);
    const count = c.get('day') === today ? Number(c.get('count') ?? 0) : 0;
    if (count >= DAILY_LIMIT) return false;
    tx.set(counter, { day: today, count: count + 1 });
    return true;
  });
  if (!allowed) return { available: false, limited: true, results: [], mapsUrl };
  // Tests run against the emulators and never call Google.
  if (process.env.FUNCTIONS_EMULATOR === 'true') return { available: false, limited: false, results: [], mapsUrl };

  try {
    const token = await getApp().options.credential!.getAccessToken();
    const project = process.env.GCLOUD_PROJECT ?? getApp().options.projectId ?? '';
    const res = await fetch(PLACES_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token.access_token}`,
        'X-Goog-User-Project': project,
        'X-Goog-FieldMask': FIELD_MASK,
      },
      body: JSON.stringify(placesRequest(q)),
    });
    if (!res.ok) {
      // Most often the Places API isn't enabled for the project yet.
      logger.warn('Places search failed', { status: res.status, body: (await res.text()).slice(0, 500) });
      return { available: false, limited: false, results: [], mapsUrl };
    }
    return { available: true, limited: false, results: parsePlaces(await res.json(), q), mapsUrl };
  } catch (e) {
    logger.warn('Places search unavailable', { e: String(e) });
    return { available: false, limited: false, results: [], mapsUrl };
  }
});
