// Seeds the LOCAL Firebase emulators with the training video's sample data.
// Never talks to a real project: every URL below is 127.0.0.1.
//
//   firebase emulators:start --only auth,firestore,functions,storage --project fixburgh-dev
//   node tool/training_video/seed.mjs
//
// The app's dev flavor uses the project id fixburgh-dev, so the emulators
// run under that id; the data lives only in the emulators.
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const PROJECT = 'fixburgh-dev';
const BUCKET = 'fixburgh-dev.firebasestorage.app';
const AUTH = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1';
const FIRESTORE = `http://127.0.0.1:8080/v1/projects/${PROJECT}/databases/(default)/documents`;
const FUNCTIONS = `http://127.0.0.1:5001/${PROJECT}/us-east1`;
const STORAGE = `http://127.0.0.1:9199/v0/b/${BUCKET}/o`;
const OWNER = { Authorization: 'Bearer owner' }; // Emulator admin bypass.
const HERE = dirname(fileURLToPath(import.meta.url));

/** Emulator-only sample accounts; the walkthrough signs in with these. */
export const PASSWORD = 'burghood-demo-1';
export const ACCOUNTS = {
  ann: { email: 'ann@burghood.test', name: 'Ann Lee' },
  cal: { email: 'cal@burghood.test', name: 'Cal Rivera' },
  meg: { email: 'meg@burghood.test', name: 'Meg Park' },
  raj: { email: 'raj@burghood.test', name: 'Raj Patel' },
  nia: { email: 'nia@burghood.test', name: 'Nia Brooks' },
  pete: { email: 'pete@burghood.test', name: 'Pete Novak' },
  sue: { email: 'sue@burghood.test', name: 'Sue Kim' },
  dan: { email: 'dan@burghood.test', name: 'Dan Moore' },
  rosa: { email: 'rosa@burghood.test', name: 'Rosa Diaz' },
  staff: { email: 'staff@burghood.test', name: 'Burghood Team', claims: { platformAdmin: true } },
};

async function json(res) {
  const body = await res.json();
  if (!res.ok) throw new Error(JSON.stringify(body));
  return body;
}

const toValue = (v) =>
  v instanceof Date ? { timestampValue: v.toISOString() }
    : v === null ? { nullValue: null }
      : typeof v === 'string' ? { stringValue: v }
        : typeof v === 'number' ? (Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v })
          : typeof v === 'boolean' ? { booleanValue: v }
            : Array.isArray(v) ? { arrayValue: { values: v.map(toValue) } }
              : { mapValue: { fields: toFields(v) } };
const toFields = (o) => Object.fromEntries(Object.entries(o).map(([k, v]) => [k, toValue(v)]));
const fromValue = (v) =>
  'stringValue' in v ? v.stringValue
    : 'integerValue' in v ? Number(v.integerValue)
      : 'doubleValue' in v ? v.doubleValue
        : 'booleanValue' in v ? v.booleanValue
          : 'timestampValue' in v ? new Date(v.timestampValue)
            : 'arrayValue' in v ? (v.arrayValue.values ?? []).map(fromValue)
              : 'mapValue' in v ? Object.fromEntries(Object.entries(v.mapValue.fields ?? {}).map(([k, x]) => [k, fromValue(x)]))
                : null;

const put = (path, data) =>
  fetch(`${FIRESTORE}/${path}`, {
    method: 'PATCH',
    headers: { ...OWNER, 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields: toFields(data) }),
  }).then(json);

async function read(path) {
  const res = await fetch(`${FIRESTORE}/${path}`, { headers: OWNER });
  if (res.status === 404) return null;
  const d = await json(res);
  return Object.fromEntries(Object.entries(d.fields ?? {}).map(([k, v]) => [k, fromValue(v)]));
}

/** Uploads a file and returns its download link, token included, as the
 * app's getDownloadURL would. */
async function upload(path, file, type) {
  const meta = await fetch(`${STORAGE}?name=${encodeURIComponent(path)}`, {
    method: 'POST',
    headers: { ...OWNER, 'Content-Type': type },
    body: readFileSync(file),
  }).then(json);
  const token = String(meta.downloadTokens ?? '').split(',')[0];
  return `${STORAGE}/${encodeURIComponent(path)}?alt=media${token ? `&token=${token}` : ''}`;
}

async function call(name, user, data) {
  const res = await fetch(`${FUNCTIONS}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${user.idToken}` },
    body: JSON.stringify({ data }),
  });
  const body = await res.json();
  if (!res.ok) throw new Error(`${name}: ${JSON.stringify(body)}`);
  return body.result;
}

async function eventually(check, ms = 20000) {
  const end = Date.now() + ms;
  for (;;) {
    try {
      const v = await check();
      if (v) return v;
    } catch (e) {
      if (Date.now() > end) throw e;
    }
    if (Date.now() > end) throw new Error('timed out');
    await new Promise((r) => setTimeout(r, 300));
  }
}

async function account(key) {
  const a = ACCOUNTS[key];
  const signUp = await fetch(`${AUTH}/accounts:signUp?key=fake`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: a.email, password: PASSWORD, displayName: a.name, returnSecureToken: true }),
  }).then(json);
  if (a.claims) {
    await fetch(`${AUTH}/projects/${PROJECT}/accounts:update`, {
      method: 'POST',
      headers: { ...OWNER, 'Content-Type': 'application/json' },
      body: JSON.stringify({ localId: signUp.localId, customAttributes: JSON.stringify(a.claims) }),
    }).then(json);
  }
  const signIn = await fetch(`${AUTH}/accounts:signInWithPassword?key=fake`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: a.email, password: PASSWORD, returnSecureToken: true }),
  }).then(json);
  return { key, uid: signUp.localId, idToken: signIn.idToken, ...a };
}

function geohash(lat, lng, precision = 9) {
  const base = '0123456789bcdefghjkmnpqrstuvwxyz';
  const la = [-90, 90];
  const lo = [-180, 180];
  let hash = '';
  let bit = 0;
  let ch = 0;
  let even = true;
  while (hash.length < precision) {
    const r = even ? lo : la;
    const v = even ? lng : lat;
    const mid = (r[0] + r[1]) / 2;
    if (v >= mid) { ch = (ch << 1) | 1; r[0] = mid; } else { ch <<= 1; r[1] = mid; }
    even = !even;
    if (++bit === 5) { hash += base[ch]; bit = 0; ch = 0; }
  }
  return hash;
}

const today = () => new Intl.DateTimeFormat('en-CA', { timeZone: 'America/New_York' }).format(new Date());
const daysFrom = (n) => new Date(Date.now() + n * 86_400_000).toISOString().slice(0, 10);
const ago = (minutes) => new Date(Date.now() - minutes * 60_000);
const photo = (name) => join(HERE, 'photos', `${name}.jpg`);
const pdf = Buffer.from(
  '%PDF-1.4\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj\n'
  + '3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 612 792]/Contents 4 0 R/Resources<</Font<</F1 5 0 R>>>>>>endobj\n'
  + '4 0 obj<</Length 60>>stream\nBT /F1 22 Tf 72 700 Td (Maple Court HOA: sample document) Tj ET\nendstream endobj\n'
  + '5 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>endobj\ntrailer<</Root 1 0 R>>\n%%EOF\n',
);

async function liveSociety(staff, admin, society) {
  const id = `claim-${society.name.replace(/\W+/g, '-').toLowerCase()}`;
  const prefix = `societyClaims/${admin.uid}/${id}`;
  await fetch(`${STORAGE}?name=${encodeURIComponent(`${prefix}/id.jpg`)}`, {
    method: 'POST', headers: { ...OWNER, 'Content-Type': 'image/jpeg' }, body: readFileSync(photo('keys')),
  }).then(json);
  await fetch(`${STORAGE}?name=${encodeURIComponent(`${prefix}/proof.pdf`)}`, {
    method: 'POST', headers: { ...OWNER, 'Content-Type': 'application/pdf' }, body: pdf,
  }).then(json);
  await put(`societyClaims/${id}`, {
    applicantUid: admin.uid,
    applicantName: admin.name,
    applicantEmail: admin.email,
    society: { ...society, geohash: geohash(society.lat, society.lng), municipalityId: '100', municipalityName: 'City of Pittsburgh' },
    position: 'president',
    hoa: { company: 'Allegheny Property Management', website: 'https://example.com', accountUrl: 'https://example.com/account' },
    files: { id: `${prefix}/id.jpg`, proof: `${prefix}/proof.pdf` },
    status: 'pending',
    createdAt: new Date(),
  });
  const { societyId } = await call('decideClaim', staff, { claimId: id, decision: 'approve' });
  const { code } = await eventually(() => read(`societies/${societyId}/private/invite`));
  return { sid: societyId, code };
}

async function main() {
  // Refuse anything but the local emulators.
  for (const url of [AUTH, FIRESTORE, FUNCTIONS, STORAGE]) {
    if (!url.startsWith('http://127.0.0.1:')) throw new Error(`Not the emulator: ${url}`);
  }
  const u = {};
  for (const key of Object.keys(ACCOUNTS)) u[key] = await account(key);
  const { ann, cal, meg, raj, nia, pete, sue, dan, staff } = u;
  await put('config/monetisation', {
    emulatorFlag: true, listingFeeUsd: 150, listingMonths: 12, sponsorshipWeeklyUsd: 25, maxSponsored: 2, reminderDays: 14,
    paymentInstructions: 'Pay by check to FixBurgh, or by bank transfer. Put your business name in the memo.',
    payLink: 'https://example.com/pay',
  });

  // Societies: Ann runs Maple Court and lives part-time at Grant Street Lofts.
  const maple = await liveSociety(staff, ann, {
    name: 'Maple Court HOA', address: '1200 Maple Ct, Pittsburgh, PA 15216', lat: 40.4062, lng: -80.0273, units: 84,
  });
  const grant = await liveSociety(staff, cal, {
    name: 'Grant Street Lofts', address: '414 Grant St, Pittsburgh, PA 15219', lat: 40.4385, lng: -79.9965, units: 120,
  });
  for (const [m, unit] of [[cal, '12C'], [meg, '7A'], [raj, '3B'], [dan, '9D']]) {
    await call('joinWithCode', m, { code: maple.code, unit });
  }
  await call('joinWithCode', ann, { code: grant.code, unit: 'PH2' });
  await put(`societies/${maple.sid}/members/${cal.uid}`, {
    ...(await read(`societies/${maple.sid}/members/${cal.uid}`)), role: 'committee',
  });
  await put(`societies/${maple.sid}/members/${nia.uid}`, {
    uid: nia.uid, unit: '5F', displayName: nia.name, role: 'member', status: 'pending', requestedAt: ago(90),
  });
  await put(`societies/${maple.sid}/hoa/info`, {
    company: 'Allegheny Property Management', website: 'https://example.com', accountUrl: 'https://example.com/account', updatedAt: new Date(),
  });

  // Channels, posts, comments and reactions.
  const ch = (id) => `societies/${maple.sid}/channels/${id}`;
  await eventually(() => read(ch('general')));
  for (const [id, name, by] of [['parking', 'Parking and snow', cal], ['lost', 'Lost and found', meg], ['events', 'Events', ann]]) {
    await put(ch(id), { name, createdBy: by.uid, archived: false, createdAt: ago(60 * 24 * 20) });
  }
  const snowUrl = await upload(`societies/${maple.sid}/channels/parking/posts/p-snow/0.jpg`, photo('snowy-lot'), 'image/jpeg');
  const keysUrl = await upload(`societies/${maple.sid}/channels/lost/posts/p-keys/0.jpg`, photo('keys'), 'image/jpeg');
  const post = (cid, id, by, unit, text, minutes, extra = {}) => put(`${ch(cid)}/posts/${id}`, {
    authorUid: by.uid, authorName: by.name, authorUnit: unit, text, photos: [], mentions: [], pinned: false,
    reactionCounts: {}, commentCount: 0, createdAt: ago(minutes), ...extra,
  });
  await post('general', 'p-welcome', ann, '4B', 'Welcome to the new Maple Court app! Notices, documents and channels all live here now.', 60 * 24 * 6, { pinned: true });
  await post('general', 'p-ladder', meg, '7A', 'Does anyone have a ladder I could borrow this weekend? Happy to swap for fresh cookies.', 60 * 5);
  await post('general', 'p-gate', raj, '3B', '@Ann Lee the side gate is sticking again. Could we get someone to look at it?', 45, { mentions: [ann.uid] });
  await post('parking', 'p-snow', cal, '12C', 'Snow removal starts at 6 tomorrow morning. Please move cars off the north lot by then.', 120, {
    photos: [{ path: `societies/${maple.sid}/channels/parking/posts/p-snow/0.jpg`, thumbPath: `societies/${maple.sid}/channels/parking/posts/p-snow/0.jpg`, thumbUrl: snowUrl }],
  });
  await post('lost', 'p-keys', dan, '9D', 'Found a set of keys with a blue fob by the mailboxes. They are at the front desk.', 60 * 26, {
    photos: [{ path: `societies/${maple.sid}/channels/lost/posts/p-keys/0.jpg`, thumbPath: `societies/${maple.sid}/channels/lost/posts/p-keys/0.jpg`, thumbUrl: keysUrl }],
  });
  await post('events', 'p-cleanup', ann, '4B', 'Fall cleanup day is Saturday at 10. Gloves and coffee provided!', 60 * 30);
  await put(`${ch('general')}/posts/p-ladder/comments/c1`, {
    authorUid: cal.uid, authorName: cal.name, text: 'I have one in my garage, come by anytime.', replyTo: null, mentions: [], reactionCounts: {}, createdAt: ago(200),
  });
  await put(`${ch('general')}/posts/p-ladder/comments/c2`, {
    authorUid: meg.uid, authorName: meg.name, text: 'Thank you Cal!', replyTo: 'c1', mentions: [], reactionCounts: {}, createdAt: ago(180),
  });
  for (const [who, cid, pid, emoji] of [[cal, 'general', 'p-welcome', '👍'], [meg, 'general', 'p-welcome', '❤️'], [raj, 'general', 'p-welcome', '👍'],
    [ann, 'parking', 'p-snow', '🙏'], [meg, 'parking', 'p-snow', '👍'], [cal, 'events', 'p-cleanup', '🎉']]) {
    await put(`${ch(cid)}/posts/${pid}/reactions/${who.uid}`, { emoji, createdAt: new Date() });
  }
  // Ann last read everything a day ago, so new posts show as unread.
  const annMember = await read(`societies/${maple.sid}/members/${ann.uid}`);
  await put(`societies/${maple.sid}/members/${ann.uid}`, {
    ...annMember, lastRead: { general: ago(60 * 24), parking: ago(60 * 24), lost: ago(60 * 24 * 2), events: ago(60) },
  });

  // Notices and documents.
  await put(`societies/${maple.sid}/notices/n-water`, {
    title: 'Water shut-off on Tuesday', body: 'Water will be off from 9am to 1pm on Tuesday while the main valve is replaced.',
    pinned: true, expiresAt: null, attachment: null, authorUid: ann.uid, authorName: ann.name, createdAt: ago(60 * 24),
  });
  await put(`societies/${maple.sid}/notices/n-pool`, {
    title: 'Pool closes for the season', body: 'The pool closes on Sunday. Thanks for a great summer!',
    pinned: false, expiresAt: null, attachment: null, authorUid: cal.uid, authorName: cal.name, createdAt: ago(60 * 24 * 3),
  });
  for (const [id, title, category] of [['d-bylaws', 'Bylaws 2026', 'bylaws'], ['d-budget', 'Annual budget 2026', 'budget'], ['d-minutes', 'October board minutes', 'minutes']]) {
    const path = `societies/${maple.sid}/documents/${id}.pdf`;
    await fetch(`${STORAGE}?name=${encodeURIComponent(path)}`, { method: 'POST', headers: { ...OWNER, 'Content-Type': 'application/pdf' }, body: pdf }).then(json);
    await put(`societies/${maple.sid}/documents/${id}`, {
      title, category, path, fileName: `${id}.pdf`, sizeBytes: pdf.length, uploadedBy: ann.uid, createdAt: ago(60 * 24 * 10),
    });
  }

  // City reports on the community map, around downtown and the South Hills.
  const reportPhoto = async (uid, id, name) => {
    const path = `reports/${uid}/${id}/0.jpg`;
    const url = await upload(path, photo(name), 'image/jpeg');
    return [{ path, thumbPath: path, thumbUrl: url, blurred: false }];
  };
  const reports = [
    ['r-grant', cal, 40.4392, -79.9961, 'pothole', 'urgent', 'reported', 'Deep pothole in the right lane, cars swerving around it', '414 Grant St', 'pothole', 'City of Pittsburgh 311'],
    ['r-light', meg, 40.4411, -79.9989, 'streetlight', 'medium', 'sent', 'Streetlight out at the corner, very dark at night', 'Smithfield St & 5th Ave', 'streetlight', 'Duquesne Light'],
    ['r-saw', raj, 40.4078, -80.0101, 'pothole', 'medium', 'reported', 'Pothole near the bus stop', 'Saw Mill Run Blvd', 'pothole', 'PennDOT District 11'],
    ['r-fixed', dan, 40.4450, -80.0020, 'pothole', 'low', 'resolved', 'Patched last week, thanks!', 'Penn Ave & 6th St', 'pothole', 'City of Pittsburgh 311'],
  ];
  for (const [id, by, lat, lng, category, severity, status, description, address, img, agency] of reports) {
    await put(`reports/${id}`, {
      authorUid: by.uid, authorIsGuest: false, category, severity, description,
      geo: { lat, lng, geohash: geohash(lat, lng), accuracyM: 5 }, address,
      municipalityId: '100', municipalityName: 'City of Pittsburgh',
      photos: await reportPhoto(by.uid, id, img), status, upvoteCount: id === 'r-grant' ? 6 : 2, fixedVoteCount: 0, flagCount: 0,
      moderation: 'visible', agencyId: 'pittsburgh-311', agencyName: agency, roadOwner: 'local', roadName: '', stateRoute: '',
      createdAt: ago(60 * 24 * (id === 'r-fixed' ? 9 : 2)), updatedAt: ago(60),
      ...(status === 'resolved' ? { resolvedAt: ago(60 * 24 * 2), resolvedBy: dan.uid } : {}),
      ...(status === 'sent' ? { sentAt: ago(60 * 24) } : {}),
    });
  }

  // Service providers.
  const area = (lat, lng, label) => ({ lat, lng, geohash: geohash(lat, lng), radiusMiles: 10, label });
  const provider = (who, extra) => put(`providers/${who.uid}`, {
    ownerUid: who.uid, description: '', phone: '412-555-0100', documents: {}, portfolio: [], status: 'approved',
    createdAt: ago(60 * 24 * 60), updatedAt: ago(60 * 24), listing: { paidThrough: daysFrom(300) },
    // Search orders by rank; a provider with no reviews starts at the prior.
    ratingAvg: 0, ratingCount: 0, rankScore: 4, ...extra,
  });
  await provider(pete, {
    businessName: 'Steel City Plumbing', description: 'Leaks, drains and water heaters fixed fast, 7 days a week. Licensed and insured.',
    categories: ['plumbing', 'handyman'], serviceArea: area(40.4100, -80.0200, 'South Hills'),
  });
  await provider(sue, {
    businessName: 'Sunny Days Sitting', description: 'Babysitting and pet sitting by a mom of two. CPR certified.',
    categories: ['babysitting', 'pet_sitting', 'dog_walking'], serviceArea: area(40.4050, -80.0250, 'Brookline'),
    backgroundCheck: { status: 'passed', clearances: true, note: 'PATCH + clearances on file', checkedAt: ago(60 * 24 * 30) },
  });
  await provider(dan, {
    businessName: 'Three Rivers Drain Co.', description: 'Drain cleaning and sewer cameras.',
    categories: ['plumbing'], serviceArea: area(40.4300, -80.0000, 'Pittsburgh'),
  });
  await provider(raj, {
    businessName: 'Mon Valley Handyman', description: 'Odd jobs, mounting, assembly and small repairs.',
    categories: ['handyman', 'carpentry', 'painting'], serviceArea: area(40.4000, -80.0300, 'Dormont'),
  });
  await put(`societies/${maple.sid}/recommended/${pete.uid}`, { by: ann.uid, at: ago(60 * 24 * 5) });

  // Past jobs and reviews, so ratings and the timeline have history.
  const job = (id, poster, prov, title, category, group, status, minutes, extra = {}) => put(`serviceRequests/${id}`, {
    posterUid: poster.uid, posterName: poster.name, scope: 'home', societyId: null, title, description: '', category, group,
    details: {}, photos: [], location: null, providerId: prov.uid, status, createdAt: ago(minutes), updatedAt: ago(minutes - 30), ...extra,
  });
  const reviews = [[cal, 5, 'Fixed our water heater the same day. Tidy and on time.'], [meg, 5, 'Great work on a leaky shower, fair price.'], [raj, 4, 'Good job, came a bit later than planned.']];
  for (const [i, [who, stars, comment]] of reviews.entries()) {
    const rid = `past-${i}`;
    await job(rid, who, pete, 'Plumbing repair', 'plumbing', 'home_repair', 'confirmed', 60 * 24 * (20 + i));
    await put(`providers/${pete.uid}/reviews/${rid}`, { stars, comment, authorUid: who.uid, authorName: who.name, category: 'plumbing', createdAt: ago(60 * 24 * (19 + i)) });
  }
  await put(`providers/${pete.uid}/reviews/past-0`, {
    ...(await read(`providers/${pete.uid}/reviews/past-0`)), reply: 'Thanks Cal, glad it is sorted!', replyAt: ago(60 * 24 * 18),
  });
  await job('past-sue', meg, sue, 'Date night babysitting', 'babysitting', 'personal_care', 'confirmed', 60 * 24 * 12);
  await put(`providers/${sue.uid}/reviews/past-sue`, { stars: 5, comment: 'The kids loved her!', authorUid: meg.uid, authorName: meg.name, category: 'babysitting', createdAt: ago(60 * 24 * 11) });
  // A common-area request waiting for the admin to pick a provider.
  await put('serviceRequests/common-gate', {
    posterUid: raj.uid, posterName: raj.name, scope: 'common', societyId: maple.sid, title: 'Side gate sticking',
    description: 'The side gate by the parking lot sticks and does not latch.', category: 'handyman', group: 'home_repair',
    details: { urgency: 'soon' }, photos: [], location: { lat: 40.4062, lng: -80.0273, geohash: geohash(40.4062, -80.0273) },
    providerId: null, status: 'posted', createdAt: ago(40), updatedAt: ago(40),
  });

  // A sponsored listing, paid and showing now.
  await put('sponsorships/sp-drain', {
    providerId: dan.uid, businessName: 'Three Rivers Drain Co.', categories: ['plumbing'],
    area: { lat: 40.4300, lng: -80.0000, radiusMiles: 15, label: 'Pittsburgh' },
    startDate: daysFrom(-3), endDate: daysFrom(30), priceUsd: 125, note: '', createdBy: staff.uid, createdAt: ago(60 * 24 * 3),
  });
  await put('payments/pay-sp-drain', {
    type: 'income', kind: 'sponsorship', amountCents: 12500, currency: 'USD', date: today(), method: 'check', reference: 'Check 2207',
    purpose: 'Sponsored listing, 5 weeks', party: 'Three Rivers Drain Co.', providerId: dan.uid, sponsorshipId: 'sp-drain',
    periodMonths: null, recordedBy: staff.uid, recordedByEmail: staff.email, recordedAt: new Date(),
  });
  await eventually(async () => (await read('sponsorships/sp-drain'))?.active === true);
  await eventually(async () => (await read(`providers/${pete.uid}`))?.ratingCount === 3);

  console.log(JSON.stringify({ maple: maple.sid, mapleCode: maple.code, grant: grant.sid, staff: staff.uid }));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
