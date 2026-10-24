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

// Same date format as the rules' today() (UTC, no zero padding).
const today = () => {
  const d = new Date();
  return `${d.getUTCFullYear()}-${d.getUTCMonth() + 1}-${d.getUTCDate()}`;
};

/** Creates a report together with the daily counter, as the app does. */
const createReport = (uid, id, count, data = report(uid)) => {
  const d = db(uid);
  const b = writeBatch(d);
  b.set(doc(d, 'rateLimits', uid), { day: today(), count });
  b.set(doc(d, 'reports', id), data);
  return b.commit();
};

describe('creating reports', () => {
  it('lets a user create a valid report in the county', async () => {
    await assertSucceeds(createReport('alice', 'r1', 1));
  });

  it('requires the daily counter to move with the report', async () => {
    await assertFails(setDoc(doc(db('alice'), 'reports', 'r1'), report('alice')));
  });

  it('stops guests after 3 reports a day', async () => {
    for (let i = 1; i <= 3; i++) await assertSucceeds(createReport('alice', `r${i}`, i));
    await assertFails(createReport('alice', 'r4', 4));
  });

  it('blocks skipping the counter back', async () => {
    await assertSucceeds(createReport('alice', 'r1', 1));
    await assertFails(createReport('alice', 'r2', 1));
  });

  it('rejects a report for someone else', async () => {
    await assertFails(createReport('alice', 'r1', 1, report('bob')));
  });

  it('rejects a report outside Allegheny County', async () => {
    const outside = report('alice', {
      geo: { lat: 40.17, lng: -80.24, geohash: 'dpnz0000a', accuracyM: 5 },
    });
    await assertFails(createReport('alice', 'r1', 1, outside));
  });

  it('accepts a report sent later from the offline outbox', async () => {
    await assertSucceeds(createReport('alice', 'r1', 1, report('alice', { source: 'offline_queue' })));
    await assertFails(createReport('alice', 'r2', 2, report('alice', { source: 'bot' })));
  });

  it('rejects a report that starts with upvotes', async () => {
    await assertFails(createReport('alice', 'r1', 1, report('alice', { upvoteCount: 5 })));
  });
});

describe('Me too', () => {
  beforeEach(() => seed('r1', { ...report('alice'), createdAt: new Date(), updatedAt: new Date() }));

  /** Adds a "Me too" with today's vote counter, as the app does. */
  const upvote = (uid, count = 1, { by = 1, id = 'r1', d = db(uid) } = {}) => {
    const b = writeBatch(d);
    b.set(doc(d, `reports/${id}/upvotes/${uid}`), { uid, createdAt: serverTimestamp() });
    b.set(doc(d, 'voteLimits', uid), { day: today(), count });
    b.update(doc(d, `reports/${id}`), { upvoteCount: increment(by) });
    return b.commit();
  };

  it('lets a neighbor add one upvote with their vote doc', async () => {
    await assertSucceeds(upvote('bob'));
  });

  it('requires the daily vote counter to move with the upvote', async () => {
    const b = writeBatch(db('bob'));
    b.set(doc(db('bob'), 'reports/r1/upvotes/bob'), { createdAt: serverTimestamp() });
    b.update(doc(db('bob'), 'reports/r1'), { upvoteCount: increment(1) });
    await assertFails(b.commit());
  });

  it('stops after 30 upvotes a day', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'voteLimits/bob'), { day: today(), count: 29 });
      await setDoc(doc(ctx.firestore(), 'reports/r2'), { ...report('alice'), createdAt: new Date() });
    });
    await assertSucceeds(upvote('bob', 30));
    await assertFails(upvote('bob', 31, { id: 'r2' }));
  });

  it('blocks winding the vote counter back', async () => {
    await assertSucceeds(upvote('bob'));
    await assertFails(setDoc(doc(db('bob'), 'voteLimits/bob'), { day: today(), count: 1 }));
    await assertFails(setDoc(doc(db('bob'), 'voteLimits/bob'), { day: today(), count: 0 }));
  });

  it('requires a verified email for email accounts', async () => {
    const unverified = env
      .authenticatedContext('erin', { firebase: { sign_in_provider: 'password' }, email_verified: false })
      .firestore();
    await assertFails(upvote('erin', 1, { d: unverified }));
    const verified = env
      .authenticatedContext('erin', { firebase: { sign_in_provider: 'password' }, email_verified: true })
      .firestore();
    await assertSucceeds(upvote('erin', 1, { d: verified }));
  });

  it('blocks bumping the count without a vote doc', async () => {
    await assertFails(updateDoc(doc(db('bob'), 'reports/r1'), { upvoteCount: increment(1) }));
  });

  it('blocks adding more than one', async () => {
    await assertFails(upvote('bob', 1, { by: 2 }));
  });

  it("blocks a vote doc with someone else's uid", async () => {
    const b = writeBatch(db('bob'));
    b.set(doc(db('bob'), 'reports/r1/upvotes/bob'), { uid: 'carol', createdAt: serverTimestamp() });
    b.set(doc(db('bob'), 'voteLimits', 'bob'), { day: today(), count: 1 });
    b.update(doc(db('bob'), 'reports/r1'), { upvoteCount: increment(1) });
    await assertFails(b.commit());
  });

  it('blocks voting a second time', async () => {
    await upvote('bob');
    await assertFails(upvote('bob', 2));
  });

  it('lets a neighbor take back their upvote', async () => {
    await upvote('bob');
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

  const fixedWith = (afterPhoto) =>
    updateDoc(doc(db('alice'), 'reports/r1'), {
      status: 'resolved',
      resolvedBy: 'reporter',
      resolvedAt: serverTimestamp(),
      afterPhoto,
      updatedAt: serverTimestamp(),
    });

  it('accepts an "after" photo from the author\'s own folder', async () => {
    await assertSucceeds(
      fixedWith({ path: 'reports/alice/r1/a.jpg', thumbPath: 'reports/alice/r1/a_thumb.jpg', thumbUrl: 'u' }),
    );
  });

  it('rejects an "after" photo from someone else\'s folder', async () => {
    await assertFails(
      fixedWith({ path: 'reports/bob/r9/a.jpg', thumbPath: 'reports/bob/r9/a_thumb.jpg', thumbUrl: 'u' }),
    );
  });
});

describe('status history', () => {
  beforeEach(() => seed('r1', { ...report('alice'), createdAt: new Date(), updatedAt: new Date() }));

  it('is public to read and closed to writes', async () => {
    await assertSucceeds(getDoc(doc(db('bob'), 'reports/r1/events/e1')));
    await assertFails(
      setDoc(doc(db('alice'), 'reports/r1/events/e1'), { type: 'resolved', at: serverTimestamp() }),
    );
  });
});

describe('directory', () => {
  it('is public to read and closed to writes', async () => {
    await assertSucceeds(getDoc(doc(db('bob'), 'agencies/penndot-d11')));
    await assertSucceeds(getDoc(doc(db('bob'), 'config/directory')));
    await assertFails(setDoc(doc(db('bob'), 'agencies/penndot-d11'), { name: 'x' }));
    await assertFails(setDoc(doc(db('bob'), 'config/directory'), { version: 1 }));
  });
});

describe('flags', () => {
  it('accepts a valid flag and hides flags from residents', async () => {
    await assertSucceeds(
      setDoc(doc(db('bob'), 'flags', 'r1_bob'), {
        reportId: 'r1',
        reporterUid: 'bob',
        reason: 'wrong_routing',
        note: '',
        createdAt: serverTimestamp(),
      }),
    );
    await assertFails(getDoc(doc(db('bob'), 'flags/any')));
  });

  it('allows only one flag per person per report', async () => {
    const flag = { reportId: 'r1', reporterUid: 'bob', reason: 'spam', note: '', createdAt: serverTimestamp() };
    await assertSucceeds(setDoc(doc(db('bob'), 'flags', 'r1_bob'), flag));
    await assertFails(setDoc(doc(db('bob'), 'flags', 'r1_bob'), flag));
    await assertFails(setDoc(doc(db('bob'), 'flags', 'r1_other'), flag));
  });

  it('rejects an unknown reason', async () => {
    await assertFails(
      setDoc(doc(db('bob'), 'flags', 'r1_bob'), {
        reportId: 'r1',
        reporterUid: 'bob',
        reason: 'boring',
        createdAt: serverTimestamp(),
      }),
    );
  });
});

describe('notification settings', () => {
  const place = (extra = {}) => ({
    kind: 'home',
    label: 'Home',
    lat: 40.44,
    lng: -80,
    geohash: 'dppn59kd3',
    radiusMiles: 1,
    updatedAt: serverTimestamp(),
    ...extra,
  });

  it('lets people save up to 3 places of their own', async () => {
    for (const id of ['p1', 'p2', 'p3']) {
      await assertSucceeds(setDoc(doc(db('alice'), `users/alice/places/${id}`), place()));
    }
    await assertFails(setDoc(doc(db('alice'), 'users/alice/places/p4'), place()));
    await assertFails(setDoc(doc(db('bob'), 'users/alice/places/p1'), place()));
    await assertFails(getDoc(doc(db('bob'), 'users/alice/places/p1')));
  });

  it('keeps the alert radius between 0.25 and 2 miles', async () => {
    await assertFails(setDoc(doc(db('alice'), 'users/alice/places/p1'), place({ radiusMiles: 5 })));
    await assertFails(setDoc(doc(db('alice'), 'users/alice/places/p1'), place({ radiusMiles: 0.1 })));
    await assertFails(setDoc(doc(db('alice'), 'users/alice/places/p1'), place({ address: '414 Grant St' })));
  });

  it('stores push tokens per device for their owner only', async () => {
    const device = { token: 't', platform: 'android', updatedAt: serverTimestamp() };
    await assertSucceeds(setDoc(doc(db('alice'), 'users/alice/devices/d1'), device));
    await assertFails(setDoc(doc(db('bob'), 'users/alice/devices/d1'), device));
    await assertFails(setDoc(doc(db('alice'), 'users/alice/devices/d2'), { ...device, platform: 'web' }));
  });

  it('accepts valid choices and quiet hours', async () => {
    await assertSucceeds(
      setDoc(doc(db('alice'), 'users/alice'), {
        notify: { status: true, nearby: false },
        quietHours: { enabled: true, start: 1320, end: 420 },
        utcOffsetMinutes: -240,
      }),
    );
    await assertFails(
      setDoc(doc(db('alice'), 'users/alice'), { quietHours: { enabled: true, start: 2000, end: 0 } }),
    );
    await assertFails(setDoc(doc(db('alice'), 'users/alice'), { notify: { marketing: true } }));
  });

  it('lets people read their notifications but not write them', async () => {
    await assertSucceeds(getDoc(doc(db('alice'), 'users/alice/notifications/n1')));
    await assertFails(getDoc(doc(db('bob'), 'users/alice/notifications/n1')));
    await assertFails(setDoc(doc(db('alice'), 'users/alice/notifications/n1'), { title: 'x' }));
  });
});

describe('Burghood collections', () => {
  const paths = [
    'societies/s1',
    'societies/s1/members/alice',
    'societies/s1/channels/general',
    'societies/s1/channels/general/posts/p1',
    'societies/s1/channels/general/posts/p1/comments/c1',
    'societies/s1/channels/general/posts/p1/reactions/alice',
    'societies/s1/channels/general/posts/p1/comments/c1/reactions/alice',
    'societies/s1/notices/n1',
    'societies/s1/documents/d1',
    'societies/s1/hoa/info',
    'societyClaims/c1',
    'serviceRequests/r1',
    'providers/pr1',
    'providers/pr1/reviews/v1',
    'sponsorships/sp1',
    'payments/pay1',
  ];

  const signedIn = (uid, claims = {}) =>
    env
      .authenticatedContext(uid, { firebase: { sign_in_provider: 'google.com' }, ...claims })
      .firestore();

  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      for (const p of paths) await setDoc(doc(ctx.firestore(), p), { name: 'x' });
    });
  });

  for (const p of paths) {
    it(`denies ${p} to guests, residents and the public`, async () => {
      for (const d of [db('guest'), signedIn('alice'), env.unauthenticatedContext().firestore()]) {
        await assertFails(getDoc(doc(d, p)));
        await assertFails(setDoc(doc(d, p), { name: 'y' }));
        await assertFails(deleteDoc(doc(d, p)));
      }
    });

    it(`lets platform admins read ${p} but not write it`, async () => {
      const admin = signedIn('admin', { platformAdmin: true });
      await assertSucceeds(getDoc(doc(admin, p)));
      await assertFails(setDoc(doc(admin, p), { name: 'y' }));
      await assertFails(deleteDoc(doc(admin, p)));
    });
  }

  it('ignores a platformAdmin claim that is not exactly true', async () => {
    await assertFails(getDoc(doc(signedIn('eve', { platformAdmin: 'true' }), 'payments/pay1')));
    await assertFails(getDoc(doc(signedIn('mod', { role: 'admin' }), 'societyClaims/c1')));
  });
});
