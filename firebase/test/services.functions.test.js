// Burghood service requests and providers (Phase 3) against the emulators.
// Run from the repo root (see README): npm --prefix firebase/test run test:functions
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { describe, it } from 'node:test';

const PROJECT = 'demo-fixburgh';
const AUTH = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1';
const FIRESTORE = `http://127.0.0.1:8080/v1/projects/${PROJECT}/databases/(default)/documents`;
const FUNCTIONS = `http://127.0.0.1:5001/${PROJECT}/us-east1`;
const STORAGE = `http://127.0.0.1:9199/v0/b/${PROJECT}.appspot.com/o`;
const OWNER = { Authorization: 'Bearer owner' }; // Emulator admin bypass.

async function json(res) {
  const body = await res.json();
  if (!res.ok) throw new Error(JSON.stringify(body));
  return body;
}

const tag = (t) => `${t}${Date.now()}${Math.random().toString(36).slice(2, 6)}`;

/** A new email account, optionally with custom claims, signed in. */
async function account(name, claims) {
  const email = `${tag(name)}@example.com`;
  const password = 'correct-horse-1';
  const signUp = await fetch(`${AUTH}/accounts:signUp?key=fake`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, displayName: name, returnSecureToken: true }),
  }).then(json);
  if (!claims) return { uid: signUp.localId, idToken: signUp.idToken, email };
  await fetch(`${AUTH}/projects/${PROJECT}/accounts:update`, {
    method: 'POST',
    headers: { ...OWNER, 'Content-Type': 'application/json' },
    body: JSON.stringify({ localId: signUp.localId, customAttributes: JSON.stringify(claims) }),
  }).then(json);
  const signIn = await fetch(`${AUTH}/accounts:signInWithPassword?key=fake`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, returnSecureToken: true }),
  }).then(json);
  return { uid: signUp.localId, idToken: signIn.idToken, email };
}

const guest = () =>
  fetch(`${AUTH}/accounts:signUp?key=fake`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ returnSecureToken: true }),
  }).then(json);

const toValue = (v) =>
  v instanceof Date
    ? { timestampValue: v.toISOString() }
    : v === null
      ? { nullValue: null }
      : typeof v === 'string'
        ? { stringValue: v }
        : typeof v === 'number'
          ? Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v }
          : typeof v === 'boolean'
            ? { booleanValue: v }
            : Array.isArray(v)
              ? { arrayValue: { values: v.map(toValue) } }
              : { mapValue: { fields: toFields(v) } };
const toFields = (o) => Object.fromEntries(Object.entries(o).map(([k, v]) => [k, toValue(v)]));

const fromValue = (v) =>
  'stringValue' in v ? v.stringValue
    : 'integerValue' in v ? Number(v.integerValue)
      : 'doubleValue' in v ? v.doubleValue
        : 'booleanValue' in v ? v.booleanValue
          : 'timestampValue' in v ? new Date(v.timestampValue)
            : 'nullValue' in v ? null
              : 'arrayValue' in v ? (v.arrayValue.values ?? []).map(fromValue)
                : 'mapValue' in v ? fromFields(v.mapValue.fields ?? {})
                  : undefined;
const fromFields = (f) => Object.fromEntries(Object.entries(f).map(([k, v]) => [k, fromValue(v)]));

const putDoc = (path, data) =>
  fetch(`${FIRESTORE}/${path}`, {
    method: 'PATCH',
    headers: { ...OWNER, 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields: toFields(data) }),
  }).then(json);

/** The document's fields as plain JSON, or null when it doesn't exist. */
async function read(path) {
  const res = await fetch(`${FIRESTORE}/${path}`, { headers: OWNER });
  if (res.status === 404) return null;
  return fromFields((await json(res)).fields ?? {});
}

const list = (path) =>
  fetch(`${FIRESTORE}/${path}`, { headers: OWNER })
    .then(json)
    .then((b) => (b.documents ?? []).map((d) => ({ id: d.name.split('/').pop(), ...fromFields(d.fields ?? {}) })));

const upload = (path, body, contentType) =>
  fetch(`${STORAGE}?name=${encodeURIComponent(path)}`, {
    method: 'POST',
    headers: { ...OWNER, 'Content-Type': contentType },
    body,
  }).then(json);

const fileExists = (path) =>
  fetch(`${STORAGE}/${encodeURIComponent(path)}`, { headers: OWNER }).then((r) => r.ok);

async function call(name, user, data) {
  const res = await fetch(`${FUNCTIONS}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${user.idToken}` },
    body: JSON.stringify({ data }),
  });
  const body = await res.json();
  return { status: res.status, result: body.result, error: body.error };
}

async function eventually(check, ms = 10000) {
  const end = Date.now() + ms;
  for (;;) {
    try {
      return await check();
    } catch (e) {
      if (Date.now() > end) throw e;
      await new Promise((r) => setTimeout(r, 250));
    }
  }
}


const platformAdmin = () => account('staff', { platformAdmin: true });
const notes = (u) => list(`users/${u.uid ?? u}/notifications`);
const area = { lat: 40.44, lng: -79.99, geohash: 'dppn59kd3', radiusMiles: 10 };

async function putProvider(uid, extra = {}) {
  await putDoc(`providers/${uid}`, {
    ownerUid: uid, businessName: 'Steel City Plumbing', description: 'Leaks and drains fixed fast',
    categories: ['plumbing'], serviceArea: area, documents: {}, portfolio: [], status: 'approved',
    createdAt: new Date(), updatedAt: new Date(), ...extra,
  });
}

/** Writes many documents in one commit (each still fires its trigger). */
async function commit(docs) {
  const res = await fetch(`${FIRESTORE.replace('/documents', '/documents:commit')}`, {
    method: 'POST',
    headers: { ...OWNER, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      writes: docs.map(([path, data]) => ({
        update: { name: `projects/${PROJECT}/databases/(default)/documents/${path}`, fields: toFields(data) },
      })),
    }),
  });
  if (!res.ok) throw new Error(await res.text());
}

describe('provider search keywords', () => {
  it('include the categories and their everyday words', async () => {
    const pid = tag('pk');
    await putProvider(pid);
    await eventually(async () => {
      const kw = (await read(`providers/${pid}`)).keywords;
      for (const w of ['plumbing', 'tap', 'leaking', 'faucet', 'drains', 'steel']) assert.ok(kw.includes(w), w);
    });
  });
});

describe('ranking', () => {
  it('puts 200 reviews at 4.8 above one 5-star review', async () => {
    const one = tag('one');
    const many = tag('many');
    await putProvider(one);
    await putProvider(many);
    await commit([[`providers/${one}/reviews/r0`, { stars: 5, comment: '', authorUid: 'a', createdAt: new Date() }]]);
    const reviews = [];
    for (let i = 0; i < 200; i++) {
      reviews.push([`providers/${many}/reviews/r${i}`, { stars: i < 160 ? 5 : 4, comment: '', authorUid: `a${i}`, createdAt: new Date() }]);
    }
    for (let i = 0; i < reviews.length; i += 100) await commit(reviews.slice(i, i + 100));
    await eventually(async () => {
      const a = await read(`providers/${one}`);
      const b = await read(`providers/${many}`);
      assert.equal(a.ratingCount, 1);
      assert.equal(a.ratingAvg, 5);
      assert.equal(b.ratingCount, 200);
      assert.ok(Math.abs(b.ratingAvg - 4.8) < 1e-9, String(b.ratingAvg));
      assert.ok(b.rankScore > a.rankScore, `${b.rankScore} > ${a.rankScore}`);
    }, 60000);
  });
});

describe('decideProvider', () => {
  it('keeps personal care providers off until a background check is recorded', async () => {
    const [staff, sitter, nia] = await Promise.all([platformAdmin(), account('sitter'), account('nia')]);
    await putProvider(sitter.uid, { businessName: 'Happy Kids Sitting', categories: ['babysitting'], status: 'applied' });
    const approve = () => call('decideProvider', staff, { providerId: sitter.uid, decision: 'approve' });

    assert.equal((await call('decideProvider', nia, { providerId: sitter.uid, decision: 'approve' })).status, 403);
    let res = await approve();
    assert.equal(res.error?.status, 'FAILED_PRECONDITION');
    assert.match(res.error.message, /background check/);

    await call('recordBackgroundCheck', staff, { providerId: sitter.uid, status: 'passed', clearances: false });
    res = await approve();
    assert.match(res.error?.message ?? '', /clearances/);

    await call('recordBackgroundCheck', staff, { providerId: sitter.uid, status: 'passed', clearances: true, note: 'PATCH + CY113' });
    res = await approve();
    assert.equal(res.status, 200, JSON.stringify(res.error));
    const p = await read(`providers/${sitter.uid}`);
    assert.equal(p.status, 'approved');
    assert.ok(p.liveAt);
    const trail = await list(`providers/${sitter.uid}/audit`);
    assert.deepEqual(trail.map((e) => e.action).sort(), ['approve', 'background_check', 'background_check']);
    await eventually(async () => assert.ok((await notes(sitter)).some((n) => /is live/.test(n.title))));
  });

  it('approves a plumber straight away, and needs a reason to reject or suspend', async () => {
    const [staff, plumber] = await Promise.all([platformAdmin(), account('plumber')]);
    await putProvider(plumber.uid, { status: 'applied' });
    assert.equal((await call('decideProvider', staff, { providerId: plumber.uid, decision: 'reject' })).status, 400);
    assert.equal((await call('decideProvider', staff, { providerId: plumber.uid, decision: 'approve' })).status, 200);
    assert.equal((await call('decideProvider', staff, { providerId: plumber.uid, decision: 'suspend' })).status, 400);
    const res = await call('decideProvider', staff, { providerId: plumber.uid, decision: 'suspend', reason: 'Licence expired' });
    assert.equal(res.result.status, 'suspended');
    assert.equal((await read(`providers/${plumber.uid}`)).rejectReason, 'Licence expired');
  });
});

describe('service request lifecycle', () => {
  it('records every step and tells the other side', async () => {
    const [nia, pete] = await Promise.all([account('nia'), account('pete')]);
    await putProvider(pete.uid);
    const rid = tag('job');
    const base = {
      posterUid: nia.uid, posterName: 'Nia', scope: 'home', title: 'Kitchen tap leaking', description: 'Under the sink',
      category: 'plumbing', group: 'home_repair', details: {}, photos: [], providerId: pete.uid,
      createdAt: new Date(), updatedAt: new Date(),
    };
    const steps = [
      { status: 'assigned' },
      { status: 'accepted' },
      { status: 'in_progress' },
      { status: 'completed', completedAt: new Date(), completion: { note: 'New washer', photos: [], video: null } },
      { status: 'not_fixed', notFixedNote: 'Still drips' },
      { status: 'completed', completedAt: new Date(), completion: { note: 'New cartridge', photos: [], video: null } },
      { status: 'confirmed', confirmedAt: new Date() },
    ];
    for (const [i, s] of steps.entries()) {
      // Each step has its own time, as the rules require (updatedAt == request.time).
      await putDoc(`serviceRequests/${rid}`, { ...base, ...s, updatedAt: new Date() });
      await eventually(async () => assert.equal((await list(`serviceRequests/${rid}/events`)).length, i + 1));
    }
    const events = await list(`serviceRequests/${rid}/events`);
    const order = events.sort((a, b) => a.at - b.at).map((e) => e.status);
    assert.deepEqual(order, steps.map((s) => s.status));
    assert.equal(events.find((e) => e.status === 'not_fixed').note, 'Still drips');

    await eventually(async () => {
      const toPoster = (await notes(nia)).map((n) => n.title);
      for (const t of ['Accepted', 'Started', 'Done']) assert.ok(toPoster.some((x) => x.startsWith(t)), t);
      const toProvider = (await notes(pete)).map((n) => n.title);
      for (const t of ['New request', 'Not fixed yet', 'Confirmed']) assert.ok(toProvider.some((x) => x.startsWith(t)), t);
      assert.ok((await notes(pete)).every((n) => n.kind === 'service'));
    });

    await putDoc(`providers/${pete.uid}/reviews/${rid}`, {
      stars: 4, comment: 'Took two visits but sorted', authorUid: nia.uid, category: 'plumbing', createdAt: new Date(),
    });
    await eventually(async () => {
      assert.equal((await read(`providers/${pete.uid}`)).ratingCount, 1);
      assert.equal((await read(`serviceRequests/${rid}`)).rated, true);
    });
  });

  it('dates each timeline step by when it happened, even when written quickly', async () => {
    const nia = await account('nia');
    const pete = await account('pete');
    await putProvider(pete.uid);
    const rid = tag('fast');
    const t0 = Date.now() - 60_000;
    const base = {
      posterUid: nia.uid, posterName: 'Nia', scope: 'home', title: 'Fast job', description: '',
      category: 'plumbing', group: 'home_repair', details: {}, photos: [], providerId: pete.uid, createdAt: new Date(t0),
    };
    const steps = ['assigned', 'accepted', 'in_progress'];
    // No waiting between writes, as when someone taps through quickly.
    for (const [i, status] of steps.entries()) {
      await putDoc(`serviceRequests/${rid}`, { ...base, status, updatedAt: new Date(t0 + i * 1000) });
    }
    const events = await eventually(async () => {
      const e = await list(`serviceRequests/${rid}/events`);
      assert.equal(e.length, steps.length);
      return e;
    });
    for (const [i, status] of steps.entries()) {
      const e = events.find((x) => x.status === status);
      assert.equal(new Date(e.at).getTime(), t0 + i * 1000, status);
    }
  });

  it('tells society admins about new common-area requests', async () => {
    const [admin, meg] = await Promise.all([account('ann'), account('meg')]);
    const sid = tag('s');
    await putDoc(`societies/${sid}`, { name: 'Maple Court', status: 'active', adminUids: [admin.uid] });
    await putDoc(`serviceRequests/${tag('c')}`, {
      posterUid: meg.uid, scope: 'common', societyId: sid, title: 'Lobby light out', description: '', category: 'electrical',
      group: 'home_repair', details: {}, photos: [], providerId: null, status: 'posted', createdAt: new Date(), updatedAt: new Date(),
    });
    await eventually(async () => assert.ok((await notes(admin)).some((n) => /Common-area request: Lobby light out/.test(n.title))));
  });

  it('closes jobs left unconfirmed for 7 days', async () => {
    const staff = await platformAdmin();
    const day = 24 * 3600 * 1000;
    const old = tag('old');
    const fresh = tag('fresh');
    for (const [id, ago] of [[old, 8], [fresh, 1]]) {
      await putDoc(`serviceRequests/${id}`, {
        posterUid: 'p', scope: 'home', title: 't', status: 'completed', completedAt: new Date(Date.now() - ago * day),
        createdAt: new Date(), updatedAt: new Date(),
      });
    }
    const res = await call('closeStaleServiceRequestsNow', staff, {});
    assert.equal(res.status, 200, JSON.stringify(res.error));
    assert.ok(res.result.closed.includes(old));
    assert.equal((await read(`serviceRequests/${old}`)).status, 'closed');
    assert.equal((await read(`serviceRequests/${fresh}`)).status, 'completed');
  });
});

describe('service categories', () => {
  it('match the Remote Config template the app reads', () => {
    const require = createRequire(import.meta.url);
    const { SERVICE_GROUPS } = require('../../functions/lib/serviceCategories.js');
    const template = JSON.parse(readFileSync(new URL('../remoteconfig.template.json', import.meta.url)));
    assert.deepEqual(SERVICE_GROUPS, JSON.parse(template.parameters.service_categories.defaultValue.value));
  });
});
