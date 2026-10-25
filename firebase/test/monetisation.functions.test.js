// Burghood Phase 4: listing fees, sponsorships and the ledger, against the
// emulators. Run from the repo root (see README): npm --prefix firebase/test run test:functions
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { after, before, describe, it } from 'node:test';

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


const require = createRequire(import.meta.url);
const { addMonths, addDays, listingPaidThrough, todayEt } = require('../../functions/lib/listing.js');

/** The emulator has no Remote Config: functions read this flag instead. */
const setFlag = (on) => putDoc('config/monetisation', { emulatorFlag: on });

let seq = 0;
/** Records a payment as the console does (the rules are tested separately). */
async function pay(admin, data) {
  const id = data.id ?? tag('pay');
  delete data.id;
  await putDoc(`payments/${id}`, {
    type: 'income', currency: 'USD', method: 'check', reference: `T${++seq}`, purpose: 'Test',
    party: 'Test party', recordedBy: admin.uid, recordedByEmail: admin.email, recordedAt: new Date(), ...data,
  });
  return id;
}

describe('listing periods', () => {
  it('run a number of calendar months, ending the day before', () => {
    assert.equal(addMonths('2026-01-31', 1), '2026-02-28');
    assert.equal(addMonths('2026-10-24', 12), '2027-10-24');
    assert.equal(listingPaidThrough([{ date: '2026-10-24', periodMonths: 12 }]), '2027-10-23');
    assert.equal(listingPaidThrough([]), null);
  });

  it('add a renewal to the end of the current period, not from its payment date', () => {
    assert.equal(
      listingPaidThrough([
        { date: '2026-10-24', periodMonths: 12 },
        { date: '2027-09-01', periodMonths: 12 },
      ]),
      '2028-10-23',
    );
    // A late renewal starts on its own date.
    assert.equal(
      listingPaidThrough([
        { date: '2025-01-01', periodMonths: 1 },
        { date: '2026-10-24', periodMonths: 1 },
      ]),
      addDays('2026-11-24', -1),
    );
  });
});

describe('listing fees', () => {
  before(() => setFlag(true));
  after(() => setFlag(false));

  it('keeps an approved provider waiting until the fee is recorded, then makes them live', async () => {
    const [admin, pete] = await Promise.all([platformAdmin(), account('pete')]);
    await putProvider(pete.uid, { status: 'applied' });
    const r = await call('decideProvider', admin, { providerId: pete.uid, decision: 'approve' });
    assert.equal(r.result?.status, 'awaiting_fee', JSON.stringify(r));
    await eventually(async () => assert.ok((await notes(pete)).some((n) => /is approved/.test(n.title))));
    // Approval asks for the fee straight away, with the default settings.
    const asked = (await read(`providers/${pete.uid}`)).paymentRequest;
    assert.equal(asked.amountUsd, 150);
    assert.equal(asked.periodMonths, 12);
    assert.match(asked.instructions, /check/);
    assert.equal(asked.dueDate, addDays(todayEt(), 14));

    const today = todayEt();
    const fee = await pay(admin, { kind: 'listing_fee', amountCents: 15000, date: today, providerId: pete.uid, periodMonths: 12 });
    const live = await eventually(async () => {
      const p = await read(`providers/${pete.uid}`);
      assert.equal(p.status, 'approved');
      return p;
    });
    assert.equal(live.listing.paidThrough, listingPaidThrough([{ date: today, periodMonths: 12 }]));
    assert.equal(live.paymentRequest, undefined, 'paid: the request is cleared');
    await eventually(async () => assert.ok((await notes(pete)).some((n) => /is live/.test(n.title))));

    // Reversing the fee takes the listing down again.
    await pay(admin, {
      id: `rev_${fee}`, kind: 'listing_fee', amountCents: 15000, date: today, providerId: pete.uid,
      periodMonths: 12, reversalOf: fee, reason: 'Check bounced',
    });
    await eventually(async () => assert.equal((await read(`providers/${pete.uid}`)).status, 'awaiting_fee'));
  });

  it('lets admins ask a provider for the fee, with how to pay', async () => {
    const [admin, pete, other] = await Promise.all([platformAdmin(), account('pete'), account('other')]);
    await putProvider(pete.uid, { status: 'awaiting_fee' });
    const ask = (user, extra = {}) => call('requestListingFee', user, {
      providerId: pete.uid, amountUsd: 99.5, periodMonths: 6, instructions: 'Zelle to pay@fixburgh.example',
      payLink: 'https://pay.example.com/burghood', dueDate: '2026-12-01', ...extra,
    });
    assert.equal((await ask(other)).status, 403);
    assert.equal((await ask(admin, { payLink: 'http://pay.example.com' })).status, 400);
    assert.equal((await ask(admin, { amountUsd: 0 })).status, 400);
    const r = await ask(admin);
    assert.equal(r.status, 200, JSON.stringify(r));
    const req = (await read(`providers/${pete.uid}`)).paymentRequest;
    assert.equal(req.amountUsd, 99.5);
    assert.equal(req.periodMonths, 6);
    assert.equal(req.payLink, 'https://pay.example.com/burghood');
    assert.equal(req.dueDate, '2026-12-01');
    await eventually(async () => assert.ok((await notes(pete)).some((n) => /Listing fee for/.test(n.title))));
    const audit = await list(`providers/${pete.uid}/audit`);
    assert.ok(audit.some((a) => a.action === 'payment_requested'));

    const applied = tag('applied');
    await putProvider(applied, { status: 'applied' });
    assert.equal((await ask(admin, { providerId: applied })).error?.status, 'FAILED_PRECONDITION');
  });

  it('reminds before a listing ends, and takes it down after', async () => {
    const [admin, pete] = await Promise.all([platformAdmin(), account('pete')]);
    await putProvider(pete.uid, { status: 'awaiting_fee' });
    const today = todayEt();
    await pay(admin, { kind: 'listing_fee', amountCents: 15000, date: today, providerId: pete.uid, periodMonths: 1 });
    const through = listingPaidThrough([{ date: today, periodMonths: 1 }]);
    await eventually(async () => assert.equal((await read(`providers/${pete.uid}`)).status, 'approved'));

    await call('monetisationDailyNow', admin, { today: addDays(through, -5) });
    await eventually(async () => assert.ok((await notes(pete)).some((n) => n.title === `Your listing expires on ${through}`)));
    assert.equal((await read(`providers/${pete.uid}`)).status, 'approved');

    await call('monetisationDailyNow', admin, { today: addDays(through, 1) });
    await eventually(async () => assert.equal((await read(`providers/${pete.uid}`)).status, 'awaiting_fee'));
    await eventually(async () => assert.ok((await notes(pete)).some((n) => /listing has ended/.test(n.title))));
  });

  it('leaves providers listed before fees started alone', async () => {
    const admin = await platformAdmin();
    const old = tag('old');
    await putProvider(old, { status: 'approved' });
    await call('monetisationDailyNow', admin, { today: '2030-01-01' });
    assert.equal((await read(`providers/${old}`)).status, 'approved');
  });

  it('can suspend a provider waiting for the fee', async () => {
    const [admin, pete] = await Promise.all([platformAdmin(), account('pete')]);
    await putProvider(pete.uid, { status: 'awaiting_fee' });
    const r = await call('decideProvider', admin, { providerId: pete.uid, decision: 'suspend', reason: 'Complaint' });
    assert.equal(r.result?.status, 'suspended', JSON.stringify(r));
  });
});

describe('without listing fees', () => {
  before(() => setFlag(false));

  it('approval makes a provider live straight away, as in Phase 3', async () => {
    const [admin, pete] = await Promise.all([platformAdmin(), account('pete')]);
    await putProvider(pete.uid, { status: 'applied' });
    const r = await call('decideProvider', admin, { providerId: pete.uid, decision: 'approve' });
    assert.equal(r.result?.status, 'approved', JSON.stringify(r));
  });
});

describe('sponsorships', () => {
  const sponsorship = (pid, extra = {}) => ({
    providerId: pid, businessName: 'Steel City Plumbing', categories: ['plumbing'],
    area: { lat: 40.44, lng: -79.99, radiusMiles: 10, label: 'Pittsburgh' },
    startDate: '2030-01-10', endDate: '2030-01-20', priceUsd: 50, note: '', createdBy: 'staff', createdAt: new Date(), ...extra,
  });

  it('shows from its start date to its end date once paid', async () => {
    const [admin, pete] = await Promise.all([platformAdmin(), account('pete')]);
    await putProvider(pete.uid);
    const sid = tag('sp');
    await putDoc(`sponsorships/${sid}`, sponsorship(pete.uid));
    await pay(admin, { kind: 'sponsorship', amountCents: 5000, date: '2030-01-02', sponsorshipId: sid, providerId: pete.uid });
    await eventually(async () => {
      const s = await read(`sponsorships/${sid}`);
      assert.equal(s.paid, true);
      assert.equal(s.active, false); // Not started yet.
    });
    const on = async (today) => {
      await call('monetisationDailyNow', admin, { today });
      return (await read(`sponsorships/${sid}`)).active;
    };
    assert.equal(await on('2030-01-09'), false);
    assert.equal(await on('2030-01-10'), true, 'on its start date');
    assert.equal(await on('2030-01-20'), true, 'through its end date');
    assert.equal(await on('2030-01-21'), false, 'gone the day after');
  });

  it('stays hidden while unpaid, even within its dates', async () => {
    const [admin, pete] = await Promise.all([platformAdmin(), account('pete')]);
    await putProvider(pete.uid);
    const sid = tag('sp');
    await putDoc(`sponsorships/${sid}`, sponsorship(pete.uid));
    await call('monetisationDailyNow', admin, { today: '2030-01-15' });
    const s = await eventually(async () => {
      const x = await read(`sponsorships/${sid}`);
      assert.equal(x.paid, false);
      return x;
    });
    assert.equal(s.active, false);
  });

  it('runs the daily pass for platform admins only', async () => {
    const r = await call('monetisationDailyNow', await account('pete'), {});
    assert.equal(r.status, 403);
  });
});
