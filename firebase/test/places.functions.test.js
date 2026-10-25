// Google results when no listed provider matches, against the emulators.
// Run from the repo root (see README): npm --prefix firebase/test run test:functions
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { describe, it } from 'node:test';

const PROJECT = 'demo-fixburgh';
const AUTH = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1';
const FUNCTIONS = `http://127.0.0.1:5001/${PROJECT}/us-east1`;

const require = createRequire(import.meta.url);
const { mapsSearchUrl, parsePlaces, placesRequest } = require('../../functions/lib/placesQuery.js');

async function signUp(anonymous = false) {
  const res = await fetch(`${AUTH}/accounts:signUp?key=fake`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(
      anonymous
        ? { returnSecureToken: true }
        : { email: `places${Date.now()}${Math.random().toString(36).slice(2, 6)}@example.com`, password: 'correct-horse-1', returnSecureToken: true },
    ),
  });
  return res.json();
}

async function call(user, data) {
  const res = await fetch(`${FUNCTIONS}/searchGooglePlaces`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...(user ? { Authorization: `Bearer ${user.idToken}` } : {}) },
    body: JSON.stringify({ data }),
  });
  return { status: res.status, ...(await res.json()) };
}

const near = { lat: 40.4406, lng: -79.9959 };
const search = { query: 'Plumbing', ...near, miles: 10 };

describe('Google Places request and reply', () => {
  it('asks for plumbing near the society, within the distance', () => {
    const body = placesRequest(search);
    assert.equal(body.textQuery, 'Plumbing');
    assert.deepEqual(body.locationBias.circle.center, { latitude: 40.4406, longitude: -79.9959 });
    assert.equal(Math.round(body.locationBias.circle.radius), 16093);
    assert.equal(placesRequest({ ...search, miles: 25 }).locationBias.circle.radius, 25 * 1609.344);
  });

  it('keeps open businesses within the distance, with safe links only', () => {
    const place = (name, lat, extra = {}) => ({
      displayName: { text: name }, location: { latitude: lat, longitude: -79.9959 },
      formattedAddress: '1 Main St, Pittsburgh, PA', rating: 4.6, userRatingCount: 88,
      nationalPhoneNumber: '(412) 555-0100', websiteUri: 'https://example.com', googleMapsUri: 'https://maps.google.com/?cid=1',
      businessStatus: 'OPERATIONAL', ...extra,
    });
    const results = parsePlaces({
      places: [
        place('Near Plumbing', 40.45),
        place('Closed Plumbing', 40.45, { businessStatus: 'CLOSED_PERMANENTLY' }),
        place('Far Plumbing', 41.0), // About 39 miles away.
        place('Odd Links', 40.46, { websiteUri: 'javascript:alert(1)', googleMapsUri: 'http://x' }),
        { displayName: { text: 'No location' } },
      ],
    }, search);
    assert.deepEqual(results.map((r) => r.name), ['Near Plumbing', 'Odd Links']);
    assert.equal(results[0].rating, 4.6);
    assert.equal(results[0].ratingCount, 88);
    assert.equal(results[0].distanceMiles, 0.6);
    assert.equal(results[1].website, null);
    assert.ok(results[1].mapsUrl.startsWith('https://www.google.com/maps/search/'));
    assert.deepEqual(parsePlaces({}, search), []);
  });

  it('links to a free Google Maps search', () => {
    assert.equal(
      mapsSearchUrl('Lawn and garden', 40.4406, -79.9959),
      'https://www.google.com/maps/search/Lawn%20and%20garden/@40.44060,-79.99590,13z',
    );
  });
});

describe('searchGooglePlaces', () => {
  it('needs a signed-in account, not a guest', async () => {
    assert.equal((await call(null, search)).status, 401);
    const r = await call(await signUp(true), search);
    assert.equal(r.status, 403);
  });

  it('checks the query and the place', async () => {
    const user = await signUp();
    assert.equal((await call(user, { ...search, query: '' })).status, 400);
    assert.equal((await call(user, { ...search, lat: 39.95, lng: -75.16 })).status, 400, 'Philadelphia');
    assert.equal((await call(user, { ...search, miles: 100 })).status, 400);
  });

  it('always returns a Google Maps link, and stops after the daily limit', async () => {
    const user = await signUp();
    const first = await call(user, search);
    assert.equal(first.status, 200);
    assert.equal(first.result.available, false, 'the emulator never calls Google');
    assert.ok(first.result.mapsUrl.startsWith('https://www.google.com/maps/search/Plumbing/'));
    for (let i = 1; i < 20; i++) await call(user, search);
    const over = await call(user, search);
    assert.equal(over.result.limited, true);
    assert.ok(over.result.mapsUrl);
  });
});
