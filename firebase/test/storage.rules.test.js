// Storage security rules tests. Society rules read member docs from
// Firestore, so both emulators run. From the repo root:
//   firebase emulators:exec --only firestore,storage --project demo-fixburgh \
//     "npm --prefix firebase/test run test:storage"
import { readFileSync } from 'node:fs';
import { after, before, describe, it } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, setDoc } from 'firebase/firestore';
import { deleteObject, getBytes, ref, uploadBytes } from 'firebase/storage';

let env;
const jpeg = new Uint8Array([0xff, 0xd8, 0xff]);
const pdf = new TextEncoder().encode('%PDF-1.4');
const claimFile = 'societyClaims/ann/c1/id.jpg';
const SID = 's1';

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-fixburgh',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
    storage: { rules: readFileSync('../storage.rules', 'utf8') },
  });
  await env.withSecurityRulesDisabled(async (ctx) => {
    await uploadBytes(ref(ctx.storage(), claimFile), jpeg, { contentType: 'image/jpeg' });
    await uploadBytes(ref(ctx.storage(), `societies/${SID}/documents/d1.pdf`), pdf, { contentType: 'application/pdf' });
    const f = ctx.firestore();
    const m = (uid, role, status) => setDoc(doc(f, `societies/${SID}/members/${uid}`), { uid, role, status });
    await m('ann', 'admin', 'approved');
    await m('cal', 'committee', 'approved');
    await m('meg', 'member', 'approved');
    await m('pat', 'member', 'pending');
  });
});

after(() => env.cleanup());

const storage = (uid, claims = {}) =>
  env
    .authenticatedContext(uid, { firebase: { sign_in_provider: 'google.com' }, ...claims })
    .storage();
const guest = () =>
  env.authenticatedContext('guest', { firebase: { sign_in_provider: 'anonymous' } }).storage();

describe('society claim files', () => {
  it('are hidden from everyone but platform admins, even the applicant', async () => {
    for (const s of [
      env.unauthenticatedContext().storage(),
      guest(),
      storage('ann'),
      storage('meg'),
      storage('eve', { platformAdmin: 'true' }),
    ]) {
      await assertFails(getBytes(ref(s, claimFile)));
    }
    await assertSucceeds(getBytes(ref(storage('admin', { platformAdmin: true }), claimFile)));
  });

  it('can be uploaded by the applicant into their own folder', async () => {
    await assertSucceeds(
      uploadBytes(ref(storage('ann'), 'societyClaims/ann/c2/id.jpg'), jpeg, { contentType: 'image/jpeg' }),
    );
    await assertSucceeds(
      uploadBytes(ref(storage('ann'), 'societyClaims/ann/c2/proof.pdf'), pdf, { contentType: 'application/pdf' }),
    );
  });

  it('refuse other folders, guests, odd names and file types', async () => {
    const put = (s, path, data = jpeg, contentType = 'image/jpeg') =>
      uploadBytes(ref(s, path), data, { contentType });
    await assertFails(put(storage('bob'), 'societyClaims/ann/c3/id.jpg'));
    await assertFails(put(guest(), 'societyClaims/guest/c3/id.jpg'));
    await assertFails(put(storage('ann'), 'societyClaims/ann/c3/selfie.jpg'));
    await assertFails(put(storage('ann'), 'societyClaims/ann/c3/id.jpg', jpeg, 'text/html'));
    await assertFails(put(storage('ann'), 'societyClaims/ann/c3/id.jpg', new Uint8Array(5 * 1024 * 1024)));
  });

  it("can't be replaced or deleted from the app", async () => {
    await assertFails(uploadBytes(ref(storage('ann'), claimFile), jpeg, { contentType: 'image/jpeg' }));
    await assertFails(deleteObject(ref(storage('ann'), claimFile)));
  });
});

describe('society documents', () => {
  const file = `societies/${SID}/documents/d1.pdf`;

  it('are readable by approved members only', async () => {
    for (const uid of ['ann', 'cal', 'meg']) await assertSucceeds(getBytes(ref(storage(uid), file)));
    for (const uid of ['pat', 'nia']) await assertFails(getBytes(ref(storage(uid), file)));
    await assertFails(getBytes(ref(env.unauthenticatedContext().storage(), file)));
  });

  it('are uploaded by admins as PDFs', async () => {
    const put = (uid, name, data = pdf, type = 'application/pdf') =>
      uploadBytes(ref(storage(uid), `societies/${SID}/documents/${name}`), data, { contentType: type });
    await assertSucceeds(put('ann', 'd2.pdf'));
    await assertFails(put('cal', 'd3.pdf'));
    await assertFails(put('meg', 'd3.pdf'));
    await assertFails(put('ann', 'd3.jpg', jpeg, 'image/jpeg'));
  });
});

describe('notice attachments', () => {
  it('are added by admins and committee members and read by members', async () => {
    const path = `societies/${SID}/notices/n1/agenda.pdf`;
    await assertSucceeds(uploadBytes(ref(storage('cal'), path), pdf, { contentType: 'application/pdf' }));
    await assertFails(
      uploadBytes(ref(storage('meg'), `societies/${SID}/notices/n1/x.pdf`), pdf, { contentType: 'application/pdf' }),
    );
    await assertSucceeds(getBytes(ref(storage('meg'), path)));
    await assertFails(getBytes(ref(storage('pat'), path)));
  });
});

describe('channel post photos', () => {
  it('are uploaded and read by approved members only', async () => {
    const path = `societies/${SID}/posts/p1/0a1b-2c.jpg`;
    await assertSucceeds(uploadBytes(ref(storage('meg'), path), jpeg, { contentType: 'image/jpeg' }));
    await assertSucceeds(getBytes(ref(storage('cal'), path)));
    await assertFails(getBytes(ref(storage('pat'), path)));
    await assertFails(
      uploadBytes(ref(storage('pat'), `societies/${SID}/posts/p1/ffff.jpg`), jpeg, { contentType: 'image/jpeg' }),
    );
    await assertFails(
      uploadBytes(ref(storage('meg'), `societies/${SID}/posts/p1/x.pdf`), pdf, { contentType: 'application/pdf' }),
    );
  });
});

describe('report photos', () => {
  it("still accept the owner's JPEG and stay public", async () => {
    const path = 'reports/alice/r1/0a1b-2c.jpg';
    await assertSucceeds(uploadBytes(ref(storage('alice'), path), jpeg, { contentType: 'image/jpeg' }));
    await assertSucceeds(getBytes(ref(env.unauthenticatedContext().storage(), path)));
    await assertFails(uploadBytes(ref(storage('bob'), 'reports/alice/r1/ff.jpg'), jpeg, { contentType: 'image/jpeg' }));
  });
});
