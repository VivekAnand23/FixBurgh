// Cloud Functions tests against the emulators. Run from the repo root:
//   firebase emulators:exec --only auth,firestore,functions,storage --project demo-fixburgh \
//     "npm --prefix firebase/test run test:functions"
import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

const PROJECT = 'demo-fixburgh';
const AUTH = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1';
const FIRESTORE = `http://127.0.0.1:8080/v1/projects/${PROJECT}/databases/(default)/documents`;
const FUNCTIONS = `http://127.0.0.1:5001/${PROJECT}/us-east1`;
const OWNER = { Authorization: 'Bearer owner' }; // Emulator admin bypass.

async function json(res) {
  const body = await res.json();
  if (!res.ok) throw new Error(JSON.stringify(body));
  return body;
}

const signUpGuest = () =>
  fetch(`${AUTH}/accounts:signUp?key=fake`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ returnSecureToken: true }),
  }).then(json);

const signUpEmail = (email) =>
  fetch(`${AUTH}/accounts:signUp?key=fake`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password: 'correct-horse-1', returnSecureToken: true }),
  }).then(json);

const putReport = (id, authorUid) =>
  fetch(`${FIRESTORE}/reports/${id}`, {
    method: 'PATCH',
    headers: { ...OWNER, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      fields: { authorUid: { stringValue: authorUid }, authorIsGuest: { booleanValue: true } },
    }),
  }).then(json);

const getReport = (id) =>
  fetch(`${FIRESTORE}/reports/${id}`, { headers: OWNER }).then(json);

const call = (name, idToken, data) =>
  fetch(`${FUNCTIONS}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${idToken}` },
    body: JSON.stringify({ data }),
  });

describe('claimGuestReports', () => {
  it("moves a guest's reports to the account they sign in to", async () => {
    const guest = await signUpGuest();
    const user = await signUpEmail(`u${Date.now()}@example.com`);
    await putReport('g1', guest.localId);
    await putReport('g2', guest.localId);
    await putReport('other', 'someone-else');

    const res = await call('claimGuestReports', user.idToken, { guestIdToken: guest.idToken });
    assert.equal(res.status, 200, await res.clone().text());
    assert.equal((await res.json()).result.moved, 2);

    for (const id of ['g1', 'g2']) {
      const r = await getReport(id);
      assert.equal(r.fields.authorUid.stringValue, user.localId);
      assert.equal(r.fields.authorIsGuest.booleanValue, false);
    }
    assert.equal((await getReport('other')).fields.authorUid.stringValue, 'someone-else');
  });

  it("refuses to claim a signed-in user's reports", async () => {
    const victim = await signUpEmail(`v${Date.now()}@example.com`);
    const attacker = await signUpEmail(`a${Date.now()}@example.com`);
    await putReport('v1', victim.localId);
    const res = await call('claimGuestReports', attacker.idToken, { guestIdToken: victim.idToken });
    assert.equal(res.status, 403);
    assert.equal((await getReport('v1')).fields.authorUid.stringValue, victim.localId);
  });

  it('requires the caller to be signed in', async () => {
    const guest = await signUpGuest();
    const res = await fetch(`${FUNCTIONS}/claimGuestReports`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ data: { guestIdToken: guest.idToken } }),
    });
    assert.equal(res.status, 401);
  });
});

/** Encodes plain JSON as Firestore REST fields. */
const toValue = (v) =>
  typeof v === 'string'
    ? { stringValue: v }
    : typeof v === 'number'
      ? Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v }
      : typeof v === 'boolean'
        ? { booleanValue: v }
        : Array.isArray(v)
          ? { arrayValue: { values: v.map(toValue) } }
          : { mapValue: { fields: toFields(v) } };
const toFields = (o) => Object.fromEntries(Object.entries(o).map(([k, v]) => [k, toValue(v)]));

const putDoc = (path, data) =>
  fetch(`${FIRESTORE}/${path}`, {
    method: 'PATCH',
    headers: { ...OWNER, 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields: toFields(data) }),
  }).then(json);

const getDoc = (path) => fetch(`${FIRESTORE}/${path}`, { headers: OWNER });

const listDocs = (path) =>
  fetch(`${FIRESTORE}/${path}`, { headers: OWNER })
    .then(json)
    .then((b) => b.documents ?? []);

/** Retries [check] until it stops throwing; triggers run asynchronously. */
async function eventually(check, ms = 8000) {
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

const accountExists = (idToken) =>
  fetch(`${AUTH}/accounts:lookup?key=fake`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ idToken }),
  }).then((r) => r.ok);

describe('deleteAccount', () => {
  const setup = async (tag) => {
    const user = await signUpEmail(`${tag}${Date.now()}@example.com`);
    const uid = user.localId;
    const mine = `${tag}-mine-${Date.now()}`;
    const theirs = `${tag}-theirs-${Date.now()}`;
    await putDoc(`reports/${mine}`, { authorUid: uid, status: 'reported', photos: [] });
    await putDoc(`reports/${theirs}`, { authorUid: 'someone-else', status: 'reported', upvoteCount: 1 });
    await putDoc(`reports/${theirs}/upvotes/${uid}`, { uid });
    await putDoc(`rateLimits/${uid}`, { day: 'x', count: 1 });
    return { user, uid, mine, theirs };
  };

  it('deletes the account, its reports and its votes', async () => {
    const { user, uid, mine, theirs } = await setup('d');
    const res = await call('deleteAccount', user.idToken, { reports: 'delete' });
    assert.equal(res.status, 200, await res.clone().text());

    assert.equal((await getDoc(`reports/${mine}`)).status, 404);
    assert.equal((await getDoc(`reports/${theirs}/upvotes/${uid}`)).status, 404);
    assert.equal((await getReport(theirs)).fields.upvoteCount.integerValue, '0');
    assert.equal((await getDoc(`rateLimits/${uid}`)).status, 404);
    assert.equal(await accountExists(user.idToken), false);
  });

  it('can keep the reports on the map without the account', async () => {
    const { user, mine } = await setup('a');
    const res = await call('deleteAccount', user.idToken, { reports: 'anonymize' });
    assert.equal(res.status, 200, await res.clone().text());
    const r = await getReport(mine);
    assert.equal(r.fields.authorUid.stringValue, '');
    assert.equal(r.fields.anonymized.booleanValue, true);
    assert.equal(await accountExists(user.idToken), false);
  });

  it('works for guests', async () => {
    const guest = await signUpGuest();
    const res = await call('deleteAccount', guest.idToken, { reports: 'delete' });
    assert.equal(res.status, 200, await res.clone().text());
  });

  it('rejects an unknown choice', async () => {
    const guest = await signUpGuest();
    const res = await call('deleteAccount', guest.idToken, { reports: 'keep' });
    assert.equal(res.status, 400);
    assert.equal(await accountExists(guest.idToken), true);
  });
});

describe('report triggers', () => {
  it('records status changes in the history', async () => {
    const id = `h${Date.now()}`;
    await putDoc(`reports/${id}`, { authorUid: 'u', status: 'reported' });
    await eventually(async () => {
      const events = await listDocs(`reports/${id}/events`);
      assert.deepEqual(events.map((e) => e.fields.type.stringValue), ['reported']);
    });
    await putDoc(`reports/${id}`, { authorUid: 'u', status: 'sent', contactChannel: 'call' });
    await eventually(async () => {
      const events = await listDocs(`reports/${id}/events`);
      const sent = events.find((e) => e.fields.type.stringValue === 'sent');
      assert.equal(sent?.fields.channel.stringValue, 'call');
    });
    await putDoc(`reports/${id}`, { authorUid: 'u', status: 'resolved', resolvedBy: 'community' });
    await eventually(async () => {
      const events = await listDocs(`reports/${id}/events`);
      const fixed = events.find((e) => e.fields.type.stringValue === 'resolved');
      assert.equal(fixed?.fields.by.stringValue, 'community');
    });
  });

  it("cleans up a deleted report's votes", async () => {
    const id = `x${Date.now()}`;
    await putDoc(`reports/${id}`, { authorUid: 'u', status: 'reported' });
    await putDoc(`reports/${id}/upvotes/v`, { uid: 'v' });
    await fetch(`${FIRESTORE}/reports/${id}`, { method: 'DELETE', headers: OWNER }).then(json);
    await eventually(async () => {
      assert.equal((await getDoc(`reports/${id}/upvotes/v`)).status, 404);
    });
  });

  it('bumps the directory version when an agency changes', async () => {
    await putDoc('agencies/test-agency', { name: 'Test', type: 'municipal' });
    await eventually(async () => {
      const res = await getDoc('config/directory');
      assert.equal(res.status, 200);
      assert.ok((await res.json()).fields.version.timestampValue);
    });
  });
});

describe('notifications', () => {
  const notifications = (uid) => listDocs(`users/${uid}/notifications`);
  const uid = (tag) => `${tag}-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;

  it('tells neighbors who said "Me too" when the reporter contacts the office', async () => {
    const id = uid('n');
    const reporter = uid('reporter');
    const fan = uid('fan');
    await putDoc(`reports/${id}`, { authorUid: reporter, status: 'reported', category: 'pothole', address: '414 Grant St' });
    await putDoc(`reports/${id}/upvotes/${fan}`, { uid: fan });
    await putDoc(`reports/${id}`, {
      authorUid: reporter, status: 'sent', category: 'pothole', address: '414 Grant St', agencyName: 'City of Pittsburgh 311',
    });
    await eventually(async () => {
      const got = await notifications(fan);
      assert.equal(got.length, 1);
      assert.match(got[0].fields.body.stringValue, /pothole at 414 Grant St/);
      assert.equal(got[0].fields.reportId.stringValue, id);
    });
    assert.equal((await notifications(reporter)).length, 0);
  });

  it('tells the reporter when neighbors confirm the fix, unless they opted out', async () => {
    const id = uid('c');
    const reporter = uid('reporter');
    const quiet = uid('quiet');
    const q = `${id}-q`;
    await putDoc(`users/${quiet}`, { notify: { status: false } });
    for (const [rid, author] of [[id, reporter], [q, quiet]]) {
      await putDoc(`reports/${rid}`, { authorUid: author, status: 'reported', category: 'streetlight' });
      await putDoc(`reports/${rid}`, { authorUid: author, status: 'resolved', resolvedBy: 'community', category: 'streetlight' });
    }
    await eventually(async () => {
      const got = await notifications(reporter);
      assert.equal(got.length, 1);
      assert.match(got[0].fields.body.stringValue, /Neighbors confirmed/);
    });
    assert.equal((await notifications(quiet)).length, 0);
  });

  it('sends at most 5 a day per person', async () => {
    const fan = uid('busy');
    for (let i = 0; i < 7; i++) {
      const id = `${fan}-r${i}`;
      await putDoc(`reports/${id}`, { authorUid: 'someone', status: 'reported', category: 'other' });
      await putDoc(`reports/${id}/upvotes/${fan}`, { uid: fan });
      await putDoc(`reports/${id}`, { authorUid: 'someone', status: 'resolved', resolvedBy: 'community', category: 'other' });
    }
    await eventually(async () => assert.equal((await notifications(fan)).length, 5));
    await new Promise((r) => setTimeout(r, 1500));
    assert.equal((await notifications(fan)).length, 5);
  });

  it('alerts people with a saved place near a new urgent report', async () => {
    const near = uid('near');
    const far = uid('far');
    const author = uid('author');
    await putDoc(`users/${near}/places/p1`, { kind: 'home', lat: 40.4410, lng: -79.9960, geohash: 'dppn59kd3', radiusMiles: 0.5 });
    await putDoc(`users/${far}/places/p1`, { kind: 'work', lat: 40.5200, lng: -79.9000, geohash: 'dppqh0000', radiusMiles: 0.25 });
    await putDoc(`users/${author}/places/p1`, { kind: 'home', lat: 40.4406, lng: -79.9959, geohash: 'dppn59kd3', radiusMiles: 2 });
    await putDoc(`reports/${uid('u')}`, {
      authorUid: author, status: 'reported', severity: 'urgent', category: 'landslide',
      geo: { lat: 40.4406, lng: -79.9959 },
    });
    await eventually(async () => {
      const got = await notifications(near);
      assert.equal(got.length, 1);
      assert.match(got[0].fields.title.stringValue, /Urgent landslide/);
    });
    assert.equal((await notifications(far)).length, 0);
    assert.equal((await notifications(author)).length, 0);
  });

  it('sends a test notification to the caller', async () => {
    const guest = await signUpGuest();
    const res = await call('sendTestNotification', guest.idToken, {});
    assert.equal(res.status, 200, await res.clone().text());
    assert.equal((await notifications(guest.localId)).length, 1);
  });
});
