// Cloud Functions tests against the emulators. Run from the repo root:
//   firebase emulators:exec --only auth,firestore,functions --project demo-fixburgh \
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
