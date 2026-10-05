// Firestore security rules tests. Run from the repo root:
//   firebase emulators:exec --only firestore --project demo-fixburgh \
//     "npm --prefix firebase/test test"
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDoc,
  increment,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';

let env;

const report = (uid, extra = {}) => ({
  authorUid: uid,
  authorIsGuest: true,
  category: 'pothole',
  severity: 'medium',
  description: 'Deep pothole',
  geo: { lat: 40.4406, lng: -79.9959, geohash: 'dppn59kd3', accuracyM: 5 },
  address: '414 Grant St',
  municipalityId: '100',
  municipalityName: 'City of Pittsburgh',
  photos: [{ path: 'p.jpg', thumbPath: 't.jpg', thumbUrl: 'u', blurred: false }],
  status: 'reported',
  upvoteCount: 0,
  flagCount: 0,
  moderation: 'visible',
  agencyId: 'pittsburgh-311',
  agencyName: 'City of Pittsburgh 311',
  roadOwner: 'local',
  roadName: '',
  stateRoute: '',
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  ...extra,
});

// One Firestore instance per user; batches can't mix instances.
const dbs = new Map();
const db = (uid) => {
  if (!dbs.has(uid)) {
    dbs.set(
      uid,
      env
        .authenticatedContext(uid, { firebase: { sign_in_provider: 'anonymous' } })
        .firestore(),
    );
  }
  return dbs.get(uid);
};

async function seed(id, data) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'reports', id), data);
  });
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-fixburgh',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});

after(() => env.cleanup());

beforeEach(() => dbs.clear());

beforeEach(() => env.clearFirestore());

describe('creating reports', () => {
  it('lets a user create a valid report in the county', async () => {
    await assertSucceeds(setDoc(doc(db('alice'), 'reports', 'r1'), report('alice')));
  });

  it('rejects a report for someone else', async () => {
    await assertFails(setDoc(doc(db('alice'), 'reports', 'r1'), report('bob')));
  });

  it('rejects a report outside Allegheny County', async () => {
    const outside = report('alice', {
      geo: { lat: 40.17, lng: -80.24, geohash: 'dpnz0000a', accuracyM: 5 },
    });
    await assertFails(setDoc(doc(db('alice'), 'reports', 'r1'), outside));
  });

  it('rejects a report that starts with upvotes', async () => {
    await assertFails(
      setDoc(doc(db('alice'), 'reports', 'r1'), report('alice', { upvoteCount: 5 })),
    );
  });
});

describe('Me too', () => {
  beforeEach(() => seed('r1', { ...report('alice'), createdAt: new Date(), updatedAt: new Date() }));

  it('lets a neighbor add one upvote with their vote doc', async () => {
    const b = writeBatch(db('bob'));
    b.set(doc(db('bob'), 'reports/r1/upvotes/bob'), { createdAt: serverTimestamp() });
    b.update(doc(db('bob'), 'reports/r1'), { upvoteCount: increment(1) });
    await assertSucceeds(b.commit());
  });

  it('blocks bumping the count without a vote doc', async () => {
    await assertFails(updateDoc(doc(db('bob'), 'reports/r1'), { upvoteCount: increment(1) }));
  });

  it('blocks adding more than one', async () => {
    const b = writeBatch(db('bob'));
    b.set(doc(db('bob'), 'reports/r1/upvotes/bob'), { createdAt: serverTimestamp() });
    b.update(doc(db('bob'), 'reports/r1'), { upvoteCount: increment(2) });
    await assertFails(b.commit());
  });

  it('blocks voting a second time', async () => {
    const first = writeBatch(db('bob'));
    first.set(doc(db('bob'), 'reports/r1/upvotes/bob'), { createdAt: serverTimestamp() });
    first.update(doc(db('bob'), 'reports/r1'), { upvoteCount: increment(1) });
    await first.commit();
    const again = writeBatch(db('bob'));
    again.set(doc(db('bob'), 'reports/r1/upvotes/bob'), { createdAt: serverTimestamp() });
    again.update(doc(db('bob'), 'reports/r1'), { upvoteCount: increment(1) });
    await assertFails(again.commit());
  });

  it('lets a neighbor take back their upvote', async () => {
    const add = writeBatch(db('bob'));
    add.set(doc(db('bob'), 'reports/r1/upvotes/bob'), { createdAt: serverTimestamp() });
    add.update(doc(db('bob'), 'reports/r1'), { upvoteCount: increment(1) });
    await add.commit();
    const remove = writeBatch(db('bob'));
    remove.delete(doc(db('bob'), 'reports/r1/upvotes/bob'));
    remove.update(doc(db('bob'), 'reports/r1'), { upvoteCount: increment(-1) });
    await assertSucceeds(remove.commit());
  });

  it('blocks a neighbor from changing anything else', async () => {
    await assertFails(updateDoc(doc(db('bob'), 'reports/r1'), { status: 'resolved' }));
  });
});

describe('Looks fixed', () => {
  const vote = (uid, count, resolve = false) => {
    const b = writeBatch(db(uid));
    b.set(doc(db(uid), `reports/r1/fixedVotes/${uid}`), { createdAt: serverTimestamp() });
    b.update(doc(db(uid), 'reports/r1'), {
      fixedVoteCount: count,
      ...(resolve
        ? { status: 'resolved', resolvedBy: 'community', resolvedAt: serverTimestamp() }
        : {}),
    });
    return b.commit();
  };

  beforeEach(() => seed('r1', { ...report('alice'), createdAt: new Date(), updatedAt: new Date() }));

  it('counts votes and the third resolves the report', async () => {
    await assertSucceeds(vote('bob', 1));
    await assertSucceeds(vote('carol', 2));
    await assertSucceeds(vote('dan', 3, true));
    let status;
    await env.withSecurityRulesDisabled(async (ctx) => {
      status = (await getDoc(doc(ctx.firestore(), 'reports/r1'))).data().status;
    });
    if (status !== 'resolved') throw new Error(`expected resolved, got ${status}`);
  });

  it('blocks resolving before three votes', async () => {
    await assertFails(vote('bob', 1, true));
  });
});

describe('author changes', () => {
  beforeEach(() => seed('r1', { ...report('alice'), createdAt: new Date(), updatedAt: new Date() }));

  it('lets the author mark it fixed and delete it', async () => {
    await assertSucceeds(
      updateDoc(doc(db('alice'), 'reports/r1'), {
        status: 'resolved',
        resolvedBy: 'reporter',
        resolvedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
    await assertSucceeds(deleteDoc(doc(db('alice'), 'reports/r1')));
  });

  it('blocks others from deleting', async () => {
    await assertFails(deleteDoc(doc(db('bob'), 'reports/r1')));
  });
});

describe('flags', () => {
  it('accepts a valid flag and hides flags from residents', async () => {
    await assertSucceeds(
      addDoc(collection(db('bob'), 'flags'), {
        reportId: 'r1',
        reporterUid: 'bob',
        reason: 'wrong_routing',
        note: '',
        createdAt: serverTimestamp(),
      }),
    );
    await assertFails(getDoc(doc(db('bob'), 'flags/any')));
  });

  it('rejects an unknown reason', async () => {
    await assertFails(
      addDoc(collection(db('bob'), 'flags'), {
        reportId: 'r1',
        reporterUid: 'bob',
        reason: 'boring',
        createdAt: serverTimestamp(),
      }),
    );
  });
});
