// Burghood society functions against the emulators. Run from the repo root:
//   firebase emulators:exec --only auth,firestore,functions,storage --project demo-fixburgh \
//     "npm --prefix firebase/test run test:functions"
import assert from 'node:assert/strict';
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

/** A pending claim by [applicant] with both files uploaded. */
async function fileClaim(applicant, extra = {}) {
  const id = tag('claim');
  const prefix = `societyClaims/${applicant.uid}/${id}`;
  await upload(`${prefix}/id.jpg`, Buffer.from([0xff, 0xd8, 0xff, 0x01]), 'image/jpeg');
  await upload(`${prefix}/proof.pdf`, Buffer.from('%PDF-1.4 minutes'), 'application/pdf');
  await putDoc(`societyClaims/${id}`, {
    applicantUid: applicant.uid,
    applicantName: 'Ann Lee',
    applicantEmail: applicant.email,
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
    hoa: { company: 'Acme Management', website: 'https://acme.example.com', accountUrl: 'https://acme.example.com/a' },
    files: { id: `${prefix}/id.jpg`, proof: `${prefix}/proof.pdf` },
    status: 'pending',
    createdAt: new Date(),
    ...extra,
  });
  return { id, prefix };
}

const platformAdmin = () => account('staff', { platformAdmin: true });

describe('decideClaim', () => {
  it('approves a claim into a live society with its applicant as admin', async () => {
    const [staff, ann] = await Promise.all([platformAdmin(), account('ann')]);
    const claim = await fileClaim(ann);
    const res = await call('decideClaim', staff, { claimId: claim.id, decision: 'approve' });
    assert.equal(res.status, 200, JSON.stringify(res.error));
    const sid = res.result.societyId;

    const society = await read(`societies/${sid}`);
    assert.equal(society.status, 'active');
    assert.equal(society.verified, true);
    assert.equal(society.nameLower, 'maple court hoa');
    assert.equal(society.municipalityId, '100');
    const member = await read(`societies/${sid}/members/${ann.uid}`);
    assert.equal(member.role, 'admin');
    assert.equal(member.status, 'approved');
    assert.equal((await read(`societies/${sid}/hoa/info`)).accountUrl, 'https://acme.example.com/a');
    const { code } = await read(`societies/${sid}/private/invite`);
    assert.match(code, /^[A-HJ-NP-Z2-9]{8}$/);
    assert.equal((await read(`inviteCodes/${code}`)).societyId, sid);

    const decided = await read(`societyClaims/${claim.id}`);
    assert.equal(decided.status, 'approved');
    assert.equal(decided.decidedBy, staff.uid);
    assert.equal(decided.decidedByEmail, staff.email);
    const trail = await list(`societyClaims/${claim.id}/audit`);
    assert.deepEqual(trail.map((e) => [e.action, e.by]), [['approved', staff.uid]]);

    await eventually(async () => {
      assert.deepEqual((await read(`users/${ann.uid}`))?.societyIds, [sid]);
      const notes = await list(`users/${ann.uid}/notifications`);
      assert.ok(notes.some((n) => n.kind === 'society' && n.societyId === sid));
    });
  });

  it('rejects with a reason, once, and only for platform admins', async () => {
    const [staff, ann, bob] = await Promise.all([platformAdmin(), account('ann'), account('bob')]);
    const claim = await fileClaim(ann);
    assert.equal((await call('decideClaim', bob, { claimId: claim.id, decision: 'approve' })).status, 403);
    assert.equal((await call('decideClaim', staff, { claimId: claim.id, decision: 'reject' })).status, 400);

    const reason = 'The proof of office does not name you.';
    const res = await call('decideClaim', staff, { claimId: claim.id, decision: 'reject', reason });
    assert.equal(res.status, 200, JSON.stringify(res.error));
    const decided = await read(`societyClaims/${claim.id}`);
    assert.equal(decided.status, 'rejected');
    assert.equal(decided.reason, reason);
    assert.equal((await list(`societyClaims/${claim.id}/audit`))[0].action, 'rejected');

    const again = await call('decideClaim', staff, { claimId: claim.id, decision: 'approve' });
    assert.equal(again.status, 400);
    assert.equal(again.error.status, 'FAILED_PRECONDITION');
  });
});

describe('getClaimFile', () => {
  it('shows a file to platform admins and records the view', async () => {
    const [staff, ann] = await Promise.all([platformAdmin(), account('ann')]);
    const claim = await fileClaim(ann);
    const res = await call('getClaimFile', staff, { claimId: claim.id, which: 'proof' });
    assert.equal(res.status, 200, JSON.stringify(res.error));
    assert.equal(res.result.contentType, 'application/pdf');
    assert.equal(Buffer.from(res.result.data, 'base64').toString(), '%PDF-1.4 minutes');
    const trail = await list(`societyClaims/${claim.id}/audit`);
    assert.deepEqual(trail.map((e) => [e.action, e.file]), [['viewed_file', 'proof']]);

    assert.equal((await call('getClaimFile', ann, { claimId: claim.id, which: 'id' })).status, 403);
  });
});

describe('purgeClaimFilesNow', () => {
  it('deletes files of claims decided before the window, and only those', async () => {
    const [staff, ann] = await Promise.all([platformAdmin(), account('ann')]);
    const day = 24 * 3600 * 1000;
    const old = await fileClaim(ann, { status: 'rejected', reason: 'x', decidedAt: new Date(Date.now() - 31 * day) });
    const recent = await fileClaim(ann, { status: 'rejected', reason: 'x', decidedAt: new Date(Date.now() - day) });
    const pending = await fileClaim(ann);

    const res = await call('purgeClaimFilesNow', staff, { retentionDays: 30 });
    assert.equal(res.status, 200, JSON.stringify(res.error));
    assert.ok(res.result.purged.includes(old.id));
    assert.ok(!res.result.purged.includes(recent.id));

    assert.equal(await fileExists(`${old.prefix}/id.jpg`), false);
    assert.equal(await fileExists(`${old.prefix}/proof.pdf`), false);
    assert.ok((await read(`societyClaims/${old.id}`)).filesDeletedAt);
    assert.equal(await fileExists(`${recent.prefix}/id.jpg`), true);
    assert.equal(await fileExists(`${pending.prefix}/id.jpg`), true);

    // A short window, as the emulator allows for testing.
    await call('purgeClaimFilesNow', staff, { retentionDays: 0 });
    assert.equal(await fileExists(`${recent.prefix}/id.jpg`), false);
    assert.equal(await fileExists(`${pending.prefix}/id.jpg`), true);
    assert.equal((await call('getClaimFile', staff, { claimId: recent.id, which: 'id' })).status, 404);
    assert.equal((await call('purgeClaimFilesNow', ann, {})).status, 403);
  });
});

/** A live society with [admin] as its admin, via an approved claim. */
async function liveSociety() {
  const [staff, admin] = await Promise.all([platformAdmin(), account('ann')]);
  const claim = await fileClaim(admin);
  const res = await call('decideClaim', staff, { claimId: claim.id, decision: 'approve' });
  const sid = res.result.societyId;
  const { code } = await read(`societies/${sid}/private/invite`);
  return { sid, admin, code };
}

describe('joining', () => {
  it('joins straight away with the invite code, however it is typed', async () => {
    const { sid, code } = await liveSociety();
    const nia = await account('nia');
    const typed = `${code.slice(0, 4).toLowerCase()}-${code.slice(4)}`;
    const res = await call('joinWithCode', nia, { code: typed, unit: '4B' });
    assert.equal(res.status, 200, JSON.stringify(res.error));
    assert.equal(res.result.societyId, sid);
    const member = await read(`societies/${sid}/members/${nia.uid}`);
    assert.equal(member.status, 'approved');
    assert.equal(member.role, 'member');
    assert.equal(member.unit, '4B');
    await eventually(async () => {
      assert.deepEqual((await read(`users/${nia.uid}`))?.societyIds, [sid]);
      assert.equal((await read(`societies/${sid}`)).memberCount, 2);
    });
  });

  it('refuses bad codes and guests', async () => {
    const { code } = await liveSociety();
    const nia = await account('nia');
    assert.equal((await call('joinWithCode', nia, { code: 'ZZZZZZZZ' })).status, 404);
    assert.equal((await call('joinWithCode', nia, { code: 'abc' })).status, 400);
    assert.equal((await call('joinWithCode', await guest(), { code })).status, 403);
  });

  it('counts requests, tells admins, and updates everything on approval', async () => {
    const { sid, admin } = await liveSociety();
    const pat = await account('pat');
    await putDoc(`societies/${sid}/members/${pat.uid}`, {
      uid: pat.uid, unit: '2C', displayName: 'Pat', role: 'member', status: 'pending', requestedAt: new Date(),
    });
    await eventually(async () => {
      assert.equal((await read(`societies/${sid}`)).pendingCount, 1);
      const notes = await list(`users/${admin.uid}/notifications`);
      assert.ok(notes.some((n) => /New request to join/.test(n.title) && /unit 2C/.test(n.body)));
    });
    await putDoc(`societies/${sid}/members/${pat.uid}`, {
      uid: pat.uid, unit: '2C', displayName: 'Pat', role: 'member', status: 'approved',
    });
    await eventually(async () => {
      const s = await read(`societies/${sid}`);
      assert.equal(s.pendingCount, 0);
      assert.equal(s.memberCount, 2);
      assert.deepEqual((await read(`users/${pat.uid}`))?.societyIds, [sid]);
      const notes = await list(`users/${pat.uid}/notifications`);
      assert.ok(notes.some((n) => /You're in/.test(n.title)));
    });
    await putDoc(`societies/${sid}/members/${pat.uid}`, {
      uid: pat.uid, unit: '2C', role: 'member', status: 'removed',
    });
    await eventually(async () => {
      assert.deepEqual((await read(`users/${pat.uid}`))?.societyIds, []);
      assert.equal((await read(`societies/${sid}`)).memberCount, 1);
    });
  });
});

describe('regenerateInviteCode', () => {
  it('replaces the code for admins only', async () => {
    const { sid, admin, code } = await liveSociety();
    const meg = await account('meg');
    assert.equal((await call('joinWithCode', meg, { code })).status, 200);
    assert.equal((await call('regenerateInviteCode', meg, { societyId: sid })).status, 403);

    const res = await call('regenerateInviteCode', admin, { societyId: sid });
    assert.equal(res.status, 200, JSON.stringify(res.error));
    assert.notEqual(res.result.code, code);
    assert.equal(await read(`inviteCodes/${code}`), null);
    assert.equal((await read(`societies/${sid}/private/invite`)).code, res.result.code);
    assert.equal((await call('joinWithCode', await account('late'), { code })).status, 404);
  });
});

describe('notices', () => {
  it('go to every approved member except the author, unless they opted out', async () => {
    const { sid, admin, code } = await liveSociety();
    const [meg, quiet, pat] = await Promise.all([account('meg'), account('quiet'), account('pat')]);
    await call('joinWithCode', meg, { code });
    await call('joinWithCode', quiet, { code });
    await putDoc(`users/${quiet.uid}`, { notify: { notices: false }, societyIds: [sid] });
    await putDoc(`societies/${sid}/members/${pat.uid}`, { uid: pat.uid, unit: '1', role: 'member', status: 'pending' });

    const noticeId = tag('n');
    await putDoc(`societies/${sid}/notices/${noticeId}`, {
      title: 'Water off Tuesday', body: 'From 9 to 12.', pinned: true, authorUid: admin.uid, createdAt: new Date(),
    });
    await eventually(async () => {
      const notes = await list(`users/${meg.uid}/notifications`);
      const n = notes.find((x) => x.kind === 'notice');
      assert.ok(n);
      assert.equal(n.title, 'Maple Court HOA: Water off Tuesday');
      assert.equal(n.societyId, sid);
      assert.equal(n.noticeId, noticeId);
    });
    await new Promise((r) => setTimeout(r, 1000));
    for (const u of [admin, quiet, pat]) {
      const notes = await list(`users/${u.uid}/notifications`);
      assert.ok(!notes.some((x) => x.kind === 'notice'), u.email);
    }
  });
});

describe('checkSocietyDuplicates', () => {
  it('finds live societies and pending claims within 200 m', async () => {
    const { sid } = await liveSociety();
    const bob = await account('bob');
    await fileClaim(bob, { society: {
      name: 'Pending Towers', address: 'x', lat: 40.4415, lng: -79.9959, geohash: 'dppn59kf0',
      municipalityId: '100', municipalityName: 'City of Pittsburgh', units: 10,
    } });
    const res = await call('checkSocietyDuplicates', bob, { lat: 40.4407, lng: -79.9960 });
    assert.equal(res.status, 200, JSON.stringify(res.error));
    const found = res.result.societies;
    assert.ok(found.some((s) => s.status === 'active' && s.societyId === sid && s.distanceM < 50));
    assert.ok(found.some((s) => s.status === 'pending' && s.name === 'Pending Towers' && !s.societyId));

    const far = await call('checkSocietyDuplicates', bob, { lat: 40.4500, lng: -79.9959 });
    assert.ok(!far.result.societies.some((s) => s.societyId === sid));
    assert.equal((await call('checkSocietyDuplicates', await guest(), { lat: 40.44, lng: -79.99 })).status, 403);
  });
});

describe('deleteAccount', () => {
  it("removes the person's memberships, claims and claim files", async () => {
    const { sid, code } = await liveSociety();
    const nia = await account('nia');
    await call('joinWithCode', nia, { code });
    const claim = await fileClaim(nia);
    const res = await call('deleteAccount', nia, { reports: 'delete' });
    assert.equal(res.status, 200, JSON.stringify(res.error));
    assert.equal(await read(`societies/${sid}/members/${nia.uid}`), null);
    assert.equal(await read(`societyClaims/${claim.id}`), null);
    assert.equal(await fileExists(`${claim.prefix}/id.jpg`), false);
    await new Promise((r) => setTimeout(r, 1500));
    assert.equal(await read(`users/${nia.uid}`), null, 'profile stays deleted');
  });
});

// ---- Phase 2: community channels ----

/** A live society with an admin and [count] more members who joined by code. */
async function societyWithMembers(count) {
  const { sid, admin, code } = await liveSociety();
  const members = [];
  for (let i = 0; i < count; i++) {
    const m = await account(`m${i}`);
    await call('joinWithCode', m, { code, unit: `${i + 1}A` });
    members.push(m);
  }
  return { sid, admin, members };
}

const notes = (u) => list(`users/${u.uid}/notifications`);
const general = (sid) => `societies/${sid}/channels/general`;

async function writePost(sid, author, extra = {}) {
  const id = tag('p');
  await putDoc(`${general(sid)}/posts/${id}`, {
    authorUid: author.uid, authorName: author.email.split('@')[0], authorUnit: '1A', text: 'Water is off in B block',
    photos: [], mentions: [], pinned: false, reactionCounts: {}, commentCount: 0, createdAt: new Date(), ...extra,
  });
  return id;
}

describe('channels', () => {
  it('every new society starts with General', async () => {
    const { sid } = await liveSociety();
    await eventually(async () => assert.equal((await read(general(sid)))?.name, 'General'));
  });

  it('keep the post count and preview, and push @mentions', async () => {
    const { sid, admin, members: [meg, cal] } = await societyWithMembers(2);
    await eventually(async () => assert.ok(await read(general(sid))));
    await writePost(sid, meg, { text: 'Thanks @cal for fixing the gate', mentions: [cal.uid] });
    await eventually(async () => {
      const ch = await read(general(sid));
      assert.equal(ch.postCount, 1);
      assert.match(ch.lastPostText, /fixing the gate/);
      const n = (await notes(cal)).find((x) => x.kind === 'mention');
      assert.ok(n);
      assert.equal(n.channelId, 'general');
    });
    assert.ok(!(await notes(admin)).some((x) => x.kind === 'mention'));
  });

  it('tell the author about comments and replies, unless muted or switched off', async () => {
    const { sid, members: [meg, cal, quiet, muted] } = await societyWithMembers(4);
    await eventually(async () => assert.ok(await read(general(sid))));
    await putDoc(`users/${quiet.uid}`, { notify: { interactions: false }, societyIds: [sid] });
    await putDoc(`societies/${sid}/members/${muted.uid}`, {
      uid: muted.uid, unit: '4A', role: 'member', status: 'approved', mutes: { general: 'always' },
    });

    const pid = await writePost(sid, meg);
    const quietPost = await writePost(sid, quiet);
    const mutedPost = await writePost(sid, muted);
    const comment = (post, author, extra = {}) =>
      putDoc(`${general(sid)}/posts/${post}/comments/${tag('c')}`, {
        authorUid: author.uid, authorName: 'Cal', text: 'Same here', replyTo: null, mentions: [],
        reactionCounts: {}, createdAt: new Date(), ...extra,
      });
    const c1 = tag('c');
    await putDoc(`${general(sid)}/posts/${pid}/comments/${c1}`, {
      authorUid: cal.uid, authorName: 'Cal', text: 'Same here', replyTo: null, mentions: [], reactionCounts: {}, createdAt: new Date(),
    });
    await comment(pid, meg, { text: 'Thanks', replyTo: c1 });
    await comment(quietPost, cal);
    await comment(mutedPost, cal);

    await eventually(async () => {
      assert.equal((await read(`${general(sid)}/posts/${pid}`)).commentCount, 2);
      assert.ok((await notes(meg)).some((x) => /commented on your post/.test(x.title)));
      assert.ok((await notes(cal)).some((x) => /replied to your comment/.test(x.title)));
    });
    await new Promise((r) => setTimeout(r, 1500));
    assert.ok(!(await notes(quiet)).some((x) => x.kind === 'interaction'), 'master switch off');
    assert.ok(!(await notes(muted)).some((x) => x.kind === 'interaction'), 'muted channel');
  });

  it('send @mentions in a muted channel', async () => {
    const { sid, members: [meg, muted] } = await societyWithMembers(2);
    await eventually(async () => assert.ok(await read(general(sid))));
    await putDoc(`societies/${sid}/members/${muted.uid}`, {
      uid: muted.uid, unit: '2A', role: 'member', status: 'approved', mutes: { general: 'always' },
    });
    await writePost(sid, meg, { text: 'Can you check the lobby light?', mentions: [muted.uid] });
    await eventually(async () => assert.ok((await notes(muted)).some((x) => x.kind === 'mention')));
  });

  it('bundle 5 reactions into one push for the author', async () => {
    const { sid, members } = await societyWithMembers(6);
    const [author, ...reactors] = members;
    await eventually(async () => assert.ok(await read(general(sid))));
    const pid = await writePost(sid, author);
    for (const r of reactors) {
      await putDoc(`${general(sid)}/posts/${pid}/reactions/${r.uid}`, { emoji: '👍', createdAt: new Date() });
    }
    await eventually(async () => {
      assert.deepEqual((await read(`${general(sid)}/posts/${pid}`)).reactionCounts, { '👍': 5 });
    });
    await eventually(async () => {
      const got = (await notes(author)).filter((x) => x.kind === 'interaction');
      assert.equal(got.length, 1);
      assert.equal(got[0].title, '5 people reacted to your post');
    }, 20000);
    // Changing a reaction moves the count without another push.
    await putDoc(`${general(sid)}/posts/${pid}/reactions/${reactors[0].uid}`, { emoji: '❤️', createdAt: new Date() });
    await eventually(async () => {
      assert.deepEqual((await read(`${general(sid)}/posts/${pid}`)).reactionCounts, { '👍': 4, '❤️': 1 });
    });
    await new Promise((r) => setTimeout(r, 5000));
    assert.equal((await notes(author)).filter((x) => x.kind === 'interaction').length, 1);
  });

  it('clean up a deleted post', async () => {
    const { sid, members: [meg, cal] } = await societyWithMembers(2);
    await eventually(async () => assert.ok(await read(general(sid))));
    const pid = await writePost(sid, meg);
    await upload(`societies/${sid}/posts/${pid}/a1.jpg`, Buffer.from([0xff, 0xd8]), 'image/jpeg');
    await putDoc(`${general(sid)}/posts/${pid}/comments/c1`, {
      authorUid: cal.uid, text: 'x', replyTo: null, mentions: [], reactionCounts: {}, createdAt: new Date(),
    });
    await eventually(async () => assert.equal((await read(general(sid))).postCount, 1));
    await fetch(`${FIRESTORE}/${general(sid)}/posts/${pid}`, { method: 'DELETE', headers: OWNER });
    await eventually(async () => {
      assert.equal(await read(`${general(sid)}/posts/${pid}/comments/c1`), null);
      assert.equal(await fileExists(`societies/${sid}/posts/${pid}/a1.jpg`), false);
      assert.equal((await read(general(sid))).postCount, 0);
    });
  });
});
