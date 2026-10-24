// Storage security rules tests. Run from the repo root:
//   firebase emulators:exec --only storage --project demo-fixburgh \
//     "npm --prefix firebase/test run test:storage"
import { readFileSync } from 'node:fs';
import { after, before, describe, it } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { getBytes, ref, uploadBytes } from 'firebase/storage';

let env;
const jpeg = new Uint8Array([0xff, 0xd8, 0xff]);
const claimFile = 'societyClaims/c1/id.jpg';

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-fixburgh',
    storage: { rules: readFileSync('../storage.rules', 'utf8') },
  });
  await env.withSecurityRulesDisabled(async (ctx) => {
    await uploadBytes(ref(ctx.storage(), claimFile), jpeg, { contentType: 'image/jpeg' });
  });
});

after(() => env.cleanup());

const storage = (uid, claims = {}) => env.authenticatedContext(uid, claims).storage();

describe('society claim files', () => {
  it('are hidden from the public, guests and residents', async () => {
    for (const s of [
      env.unauthenticatedContext().storage(),
      storage('guest', { firebase: { sign_in_provider: 'anonymous' } }),
      storage('alice'),
      storage('eve', { platformAdmin: 'true' }),
    ]) {
      await assertFails(getBytes(ref(s, claimFile)));
    }
  });

  it('can be read by platform admins', async () => {
    await assertSucceeds(getBytes(ref(storage('admin', { platformAdmin: true }), claimFile)));
  });

  it("can't be uploaded by anyone yet", async () => {
    for (const s of [storage('alice'), storage('admin', { platformAdmin: true })]) {
      await assertFails(
        uploadBytes(ref(s, 'societyClaims/c2/id.jpg'), jpeg, { contentType: 'image/jpeg' }),
      );
    }
  });
});

describe('report photos', () => {
  it('still accept the owner\'s JPEG and stay public', async () => {
    const path = 'reports/alice/r1/0a1b-2c.jpg';
    await assertSucceeds(uploadBytes(ref(storage('alice'), path), jpeg, { contentType: 'image/jpeg' }));
    await assertSucceeds(getBytes(ref(env.unauthenticatedContext().storage(), path)));
    await assertFails(uploadBytes(ref(storage('bob'), 'reports/alice/r1/ff.jpg'), jpeg, { contentType: 'image/jpeg' }));
  });
});
