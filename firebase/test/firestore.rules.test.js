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
  collection,
  collectionGroup,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  increment,
  query,
  where,
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

describe('Burghood closed collections', () => {
  const paths = [
    'societies/s1/channels/general',
    'societies/s1/channels/general/posts/p1',
    'societies/s1/channels/general/posts/p1/comments/c1',
    'societies/s1/channels/general/posts/p1/reactions/alice',
    'societies/s1/channels/general/posts/p1/comments/c1/reactions/alice',
    'serviceRequests/r1',
    'providers/pr1',
    'providers/pr1/reviews/v1',
    'sponsorships/sp1',
    'payments/pay1',
    'inviteCodes/ABCD2345',
  ];

  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      for (const p of paths) await setDoc(doc(ctx.firestore(), p), { name: 'x' });
    });
  });

  for (const p of paths) {
    it(`denies ${p} to guests, residents and the public`, async () => {
      for (const d of [db('guest'), account('alice'), env.unauthenticatedContext().firestore()]) {
        await assertFails(getDoc(doc(d, p)));
        await assertFails(setDoc(doc(d, p), { name: 'y' }));
        await assertFails(deleteDoc(doc(d, p)));
      }
    });
  }

  it('lets platform admins read them but not write them', async () => {
    const admin = account('admin', { platformAdmin: true });
    for (const p of paths.filter((x) => !x.startsWith('inviteCodes'))) {
      await assertSucceeds(getDoc(doc(admin, p)));
      await assertFails(setDoc(doc(admin, p), { name: 'y' }));
    }
    await assertFails(getDoc(doc(admin, 'inviteCodes/ABCD2345')));
  });

  it('ignores a platformAdmin claim that is not exactly true', async () => {
    await assertFails(getDoc(doc(account('eve', { platformAdmin: 'true' }), 'payments/pay1')));
    await assertFails(getDoc(doc(account('mod', { role: 'admin' }), 'payments/pay1')));
  });
});

/** A signed-in (non-guest) account, with extra token claims. */
function account(uid, claims = {}) {
  return env
    .authenticatedContext(uid, {
      email: `${uid}@example.com`,
      firebase: { sign_in_provider: 'google.com' },
      ...claims,
    })
    .firestore();
}

const SID = 's1';

/** An active society with admin "ann", committee "cal", member "meg",
 * pending "pat" and removed "rex". */
async function seedSociety() {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const f = ctx.firestore();
    await setDoc(doc(f, `societies/${SID}`), {
      name: 'Maple Court HOA', nameLower: 'maple court hoa', status: 'active', verified: true,
      lat: 40.4406, lng: -79.9959, geohash: 'dppn59kd3', units: 84,
    });
    await setDoc(doc(f, 'societies/gone'), { name: 'Old', status: 'suspended' });
    const m = (uid, role, status) =>
      setDoc(doc(f, `societies/${SID}/members/${uid}`), { uid, unit: '1A', role, status });
    await m('ann', 'admin', 'approved');
    await m('cal', 'committee', 'approved');
    await m('meg', 'member', 'approved');
    await m('pat', 'member', 'pending');
    await m('rex', 'member', 'removed');
    await setDoc(doc(f, `societies/${SID}/notices/n1`), { title: 'Pool closed', authorUid: 'cal' });
    await setDoc(doc(f, `societies/${SID}/documents/d1`), { title: 'Bylaws' });
    await setDoc(doc(f, `societies/${SID}/hoa/info`), { company: 'Acme', website: '', accountUrl: '' });
    await setDoc(doc(f, `societies/${SID}/private/invite`), { code: 'ABCD2345' });
  });
}

const joinRequest = (uid, extra = {}) => ({
  uid,
  unit: '4B',
  displayName: 'Nia',
  role: 'member',
  status: 'pending',
  requestedAt: serverTimestamp(),
  ...extra,
});

const notice = (authorUid, extra = {}) => ({
  title: 'Water off Tuesday',
  body: 'From 9 to 12 for repairs.',
  pinned: true,
  expiresAt: null,
  attachment: null,
  authorUid,
  authorName: 'Ann',
  createdAt: serverTimestamp(),
  ...extra,
});

describe('societies', () => {
  beforeEach(seedSociety);

  it('lists active societies to anyone with an account, not guests', async () => {
    const q = (d) => getDocs(query(collection(d, 'societies'), where('status', '==', 'active')));
    await assertSucceeds(q(account('nia')));
    await assertSucceeds(getDoc(doc(account('nia'), `societies/${SID}`)));
    await assertFails(q(db('guest')));
    await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), `societies/${SID}`)));
    await assertFails(getDoc(doc(account('nia'), 'societies/gone')));
  });

  it('can only be created or changed by Cloud Functions', async () => {
    await assertFails(setDoc(doc(account('nia'), 'societies/new'), { name: 'Mine', status: 'active' }));
    await assertFails(updateDoc(doc(account('ann'), `societies/${SID}`), { name: 'Renamed' }));
  });

  it('keeps notices, documents and HOA links for approved members', async () => {
    for (const p of ['notices/n1', 'documents/d1', 'hoa/info']) {
      for (const uid of ['ann', 'cal', 'meg']) {
        await assertSucceeds(getDoc(doc(account(uid), `societies/${SID}/${p}`)));
      }
      for (const uid of ['pat', 'rex', 'nia']) {
        await assertFails(getDoc(doc(account(uid), `societies/${SID}/${p}`)));
      }
      await assertSucceeds(getDoc(doc(account('admin', { platformAdmin: true }), `societies/${SID}/${p}`)));
    }
  });

  it('shows the member list to members, and their own request to applicants', async () => {
    await assertSucceeds(getDocs(collection(account('meg'), `societies/${SID}/members`)));
    await assertFails(getDocs(collection(account('nia'), `societies/${SID}/members`)));
    await assertSucceeds(getDoc(doc(account('pat'), `societies/${SID}/members/pat`)));
    await assertFails(getDoc(doc(account('pat'), `societies/${SID}/members/meg`)));
  });

  it('lets people list their own memberships across societies', async () => {
    const mine = (d, uid) => getDocs(query(collectionGroup(d, 'members'), where('uid', '==', uid)));
    await assertSucceeds(mine(account('pat'), 'pat'));
    await assertFails(mine(account('pat'), 'meg'));
  });

  it('shows the invite code only to admins', async () => {
    await assertSucceeds(getDoc(doc(account('ann'), `societies/${SID}/private/invite`)));
    await assertFails(getDoc(doc(account('cal'), `societies/${SID}/private/invite`)));
    await assertFails(setDoc(doc(account('ann'), `societies/${SID}/private/invite`), { code: 'X' }));
  });
});

describe('joining a society', () => {
  beforeEach(seedSociety);
  const path = (uid, sid = SID) => `societies/${sid}/members/${uid}`;

  it('lets an account ask to join with a unit number', async () => {
    await assertSucceeds(setDoc(doc(account('nia'), path('nia')), joinRequest('nia')));
  });

  it('refuses guests, other people, approved requests and admin roles', async () => {
    await assertFails(setDoc(doc(db('guest'), path('guest')), joinRequest('guest')));
    await assertFails(setDoc(doc(account('nia'), path('ned')), joinRequest('ned')));
    await assertFails(setDoc(doc(account('nia'), path('nia')), joinRequest('nia', { status: 'approved' })));
    await assertFails(setDoc(doc(account('nia'), path('nia')), joinRequest('nia', { role: 'admin' })));
    await assertFails(setDoc(doc(account('nia'), path('nia')), joinRequest('nia', { unit: '' })));
    await assertFails(setDoc(doc(account('nia'), path('nia', 'gone')), joinRequest('nia')));
  });

  it('lets a member who is already in not change their own role', async () => {
    await assertFails(updateDoc(doc(account('meg'), path('meg')), { role: 'admin' }));
  });

  const decide = (by, uid, data) =>
    updateDoc(doc(account(by), path(uid)), {
      decidedBy: by,
      decidedAt: serverTimestamp(),
      ...data,
    });

  it('lets admins approve, decline, promote and remove members', async () => {
    await assertSucceeds(decide('ann', 'pat', { status: 'approved' }));
    await assertSucceeds(decide('ann', 'meg', { role: 'committee' }));
    await assertSucceeds(decide('ann', 'cal', { role: 'admin' }));
    await assertSucceeds(decide('ann', 'meg', { status: 'removed' }));
  });

  it('keeps everyone else out of member decisions', async () => {
    await assertFails(decide('cal', 'pat', { status: 'approved' }));
    await assertFails(decide('meg', 'pat', { status: 'approved' }));
    await assertFails(decide('pat', 'pat', { status: 'approved' }));
    // Admins can't demote or remove themselves, so one always remains.
    await assertFails(decide('ann', 'ann', { role: 'member' }));
    await assertFails(decide('ann', 'pat', { status: 'owner' }));
    await assertFails(decide('ann', 'pat', { unit: '9Z' }));
  });

  it('lets people leave, except admins', async () => {
    await assertSucceeds(deleteDoc(doc(account('meg'), path('meg'))));
    await assertSucceeds(deleteDoc(doc(account('pat'), path('pat'))));
    await assertFails(deleteDoc(doc(account('ann'), path('ann'))));
    await assertFails(deleteDoc(doc(account('ann'), path('cal'))));
  });
});

describe('society notices, documents and HOA links', () => {
  beforeEach(seedSociety);
  const n = (id) => `societies/${SID}/notices/${id}`;

  it('lets admins and committee members post notices', async () => {
    await assertSucceeds(setDoc(doc(account('ann'), n('a')), notice('ann')));
    await assertSucceeds(setDoc(doc(account('cal'), n('b')), notice('cal', { pinned: false })));
    await assertSucceeds(
      setDoc(doc(account('cal'), n('c')), notice('cal', {
        attachment: { path: `societies/${SID}/notices/c/agenda.pdf`, name: 'agenda.pdf', contentType: 'application/pdf' },
      })),
    );
  });

  it('refuses notices from members, outsiders and in a bad shape', async () => {
    await assertFails(setDoc(doc(account('meg'), n('a')), notice('meg')));
    await assertFails(setDoc(doc(account('pat'), n('a')), notice('pat')));
    await assertFails(setDoc(doc(account('cal'), n('a')), notice('ann')));
    await assertFails(setDoc(doc(account('ann'), n('a')), notice('ann', { title: '' })));
    await assertFails(setDoc(doc(account('ann'), n('a')), notice('ann', { body: 'x'.repeat(2001) })));
    await assertFails(
      setDoc(doc(account('ann'), n('a')), notice('ann', {
        attachment: { path: 'societies/other/notices/a/x.pdf', name: 'x.pdf', contentType: 'application/pdf' },
      })),
    );
  });

  it('lets the author or an admin edit and delete a notice', async () => {
    const edit = { title: 'Pool open', updatedAt: serverTimestamp() };
    await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), n('x')), {
      title: 'Pool closed', body: '', pinned: false, expiresAt: null, attachment: null, authorUid: 'cal',
    }));
    await assertSucceeds(updateDoc(doc(account('cal'), n('x')), edit));
    await assertSucceeds(updateDoc(doc(account('ann'), n('x')), edit));
    await assertFails(updateDoc(doc(account('meg'), n('x')), edit));
    await assertFails(updateDoc(doc(account('cal'), n('x')), { authorUid: 'meg', updatedAt: serverTimestamp() }));
    await assertFails(deleteDoc(doc(account('meg'), n('x'))));
    await assertSucceeds(deleteDoc(doc(account('ann'), n('x'))));
  });

  const document = (extra = {}) => ({
    title: 'Bylaws 2026',
    category: 'bylaws',
    path: `societies/${SID}/documents/d2.pdf`,
    fileName: 'bylaws.pdf',
    sizeBytes: 1234,
    uploadedBy: 'ann',
    createdAt: serverTimestamp(),
    ...extra,
  });

  it('lets only admins add and remove documents', async () => {
    const p = `societies/${SID}/documents/d2`;
    await assertFails(setDoc(doc(account('cal'), p), document({ uploadedBy: 'cal' })));
    await assertFails(setDoc(doc(account('ann'), p), document({ category: 'secret' })));
    await assertFails(setDoc(doc(account('ann'), p), document({ path: 'elsewhere/d2.pdf' })));
    await assertSucceeds(setDoc(doc(account('ann'), p), document()));
    await assertFails(deleteDoc(doc(account('meg'), p)));
    await assertSucceeds(deleteDoc(doc(account('ann'), p)));
  });

  it('lets only admins edit the HOA links, which must be https', async () => {
    const p = `societies/${SID}/hoa/info`;
    const hoa = (extra = {}) => ({
      company: 'Acme Management',
      website: 'https://acme.example.com',
      accountUrl: 'https://acme.example.com/account',
      updatedAt: serverTimestamp(),
      ...extra,
    });
    await assertSucceeds(setDoc(doc(account('ann'), p), hoa()));
    await assertFails(setDoc(doc(account('cal'), p), hoa()));
    await assertFails(setDoc(doc(account('ann'), p), hoa({ accountUrl: 'javascript:alert(1)' })));
    await assertFails(setDoc(doc(account('ann'), p), hoa({ balance: 120 })));
    await assertFails(setDoc(doc(account('ann'), `societies/${SID}/hoa/other`), hoa()));
  });
});

describe('society claims', () => {
  const claim = (uid, id, extra = {}) => ({
    applicantUid: uid,
    applicantName: 'Ann Lee',
    applicantEmail: `${uid}@example.com`,
    society: {
      name: 'Maple Court HOA',
      address: '1200 Maple Ct, Pittsburgh, PA',
      lat: 40.4406,
      lng: -79.9959,
      geohash: 'dppn59kd3',
      municipalityId: '100',
      municipalityName: 'City of Pittsburgh',
      units: 84,
    },
    position: 'president',
    hoa: { company: 'Acme', website: 'https://acme.example.com', accountUrl: '' },
    files: {
      id: `societyClaims/${uid}/${id}/id.jpg`,
      proof: `societyClaims/${uid}/${id}/proof.pdf`,
    },
    status: 'pending',
    createdAt: serverTimestamp(),
    ...extra,
  });
  const at = (id) => `societyClaims/${id}`;

  it('lets an account file a claim for a society in the county', async () => {
    await assertSucceeds(setDoc(doc(account('ann'), at('c1')), claim('ann', 'c1')));
  });

  it('refuses claims from guests, for others, decided or outside the county', async () => {
    await assertFails(setDoc(doc(db('guest'), at('c1')), claim('guest', 'c1', { applicantEmail: '' })));
    await assertFails(setDoc(doc(account('ann'), at('c1')), claim('bob', 'c1')));
    await assertFails(setDoc(doc(account('ann'), at('c1')), claim('ann', 'c1', { status: 'approved' })));
    await assertFails(setDoc(doc(account('ann'), at('c1')), claim('ann', 'c1', { position: 'tenant' })));
    await assertFails(setDoc(doc(account('ann'), at('c1')), claim('ann', 'c1', { applicantEmail: 'x@example.com' })));
    const far = claim('ann', 'c1');
    far.society = { ...far.society, lat: 39.95, lng: -75.16 }; // Philadelphia
    await assertFails(setDoc(doc(account('ann'), at('c1')), far));
    // Files must sit in the applicant's own folder for this claim.
    await assertFails(
      setDoc(doc(account('ann'), at('c1')), claim('ann', 'c1', {
        files: { id: 'societyClaims/bob/c1/id.jpg', proof: 'societyClaims/ann/c1/proof.pdf' },
      })),
    );
  });

  it('shows a claim to its applicant and platform admins only', async () => {
    await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), at('c2')), claim('ann', 'c2')));
    await assertSucceeds(getDoc(doc(account('ann'), at('c2'))));
    await assertSucceeds(getDoc(doc(account('admin', { platformAdmin: true }), at('c2'))));
    await assertFails(getDoc(doc(account('bob'), at('c2'))));
    await assertSucceeds(getDocs(query(collection(account('ann'), 'societyClaims'), where('applicantUid', '==', 'ann'))));
  });

  it('lets nobody decide or edit a claim from the app', async () => {
    await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), at('c3')), claim('ann', 'c3')));
    await assertFails(updateDoc(doc(account('ann'), at('c3')), { status: 'approved' }));
    await assertFails(updateDoc(doc(account('admin', { platformAdmin: true }), at('c3')), { status: 'approved' }));
    await assertFails(deleteDoc(doc(account('ann'), at('c3'))));
    await assertFails(setDoc(doc(account('admin', { platformAdmin: true }), `${at('c3')}/audit/e1`), { action: 'x' }));
    await assertSucceeds(getDocs(collection(account('admin', { platformAdmin: true }), `${at('c3')}/audit`)));
    await assertFails(getDocs(collection(account('ann'), `${at('c3')}/audit`)));
  });
});

describe('profile society list', () => {
  it('is written only by Cloud Functions', async () => {
    await assertFails(setDoc(doc(account('nia'), 'users/nia'), { societyIds: ['s1'] }));
    await env.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), 'users/nia'), { societyIds: ['s1'] }),
    );
    await assertSucceeds(
      setDoc(doc(account('nia'), 'users/nia'), { notify: { status: true, notices: false } }, { merge: true }),
    );
    await assertFails(updateDoc(doc(account('nia'), 'users/nia'), { societyIds: ['s1', 's2'] }));
  });
});
