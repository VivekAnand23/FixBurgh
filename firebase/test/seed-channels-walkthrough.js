// Seeds the emulators for integration_test/channels_walkthrough_test.dart:
// a live society "Grant Street Lofts" with admin Ann Lee and member Nia
// Patel, plus two neighbors. Prints the accounts' emulator passwords as
// dart-defines. Run with the emulators up:
//   node firebase/test/seed-channels-walkthrough.js fixburgh-dev
const PROJECT = process.argv[2] ?? 'demo-fixburgh';
const AUTH = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1';
const FIRESTORE = `http://127.0.0.1:8080/v1/projects/${PROJECT}/databases/(default)/documents`;
const FUNCTIONS = `http://127.0.0.1:5001/${PROJECT}/us-east1`;
const OWNER = { Authorization: 'Bearer owner' };
const stamp = Date.now();

async function json(res) {
  const body = await res.json();
  if (!res.ok) throw new Error(JSON.stringify(body));
  return body;
}

async function account(name, claims) {
  const email = `${name.split(' ')[0].toLowerCase()}${stamp}@example.test`;
  const password = `emulator-${stamp}`;
  const up = await fetch(`${AUTH}/accounts:signUp?key=fake`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, displayName: name, returnSecureToken: true }),
  }).then(json);
  if (claims) {
    await fetch(`${AUTH}/projects/${PROJECT}/accounts:update`, {
      method: 'POST',
      headers: { ...OWNER, 'Content-Type': 'application/json' },
      body: JSON.stringify({ localId: up.localId, customAttributes: JSON.stringify(claims) }),
    }).then(json);
  }
  const signIn = await fetch(`${AUTH}/accounts:signInWithPassword?key=fake`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, returnSecureToken: true }),
  }).then(json);
  return { uid: up.localId, idToken: signIn.idToken, email, password, name };
}

const call = (name, user, data) =>
  fetch(`${FUNCTIONS}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${user.idToken}` },
    body: JSON.stringify({ data }),
  }).then(json);

const str = (v) => ({ stringValue: v });

async function main() {
  const staff = await account('Burghood Staff', { platformAdmin: true });
  const ann = await account('Ann Lee');
  const claimId = `walk${stamp}`;
  await fetch(`${FIRESTORE}/societyClaims/${claimId}`, {
    method: 'PATCH',
    headers: { ...OWNER, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      fields: {
        applicantUid: str(ann.uid),
        applicantName: str('Ann Lee'),
        applicantEmail: str(ann.email),
        status: str('pending'),
        position: str('president'),
        createdAt: { timestampValue: new Date().toISOString() },
        society: {
          mapValue: {
            fields: {
              name: str('Grant Street Lofts'),
              address: str('414 Grant St, Pittsburgh, PA 15219'),
              lat: { doubleValue: 40.438 },
              lng: { doubleValue: -79.9969 },
              geohash: str('dppn59hzg'),
              municipalityId: str('100'),
              municipalityName: str('City of Pittsburgh'),
              units: { integerValue: '84' },
            },
          },
        },
        hoa: { mapValue: { fields: { accountUrl: str('https://acme-hoa.example.com/residents') } } },
        files: { mapValue: { fields: { id: str('x'), proof: str('y') } } },
      },
    }),
  }).then(json);
  const { result } = await call('decideClaim', staff, { claimId, decision: 'approve' });
  const sid = result.societyId;
  const invite = await fetch(`${FIRESTORE}/societies/${sid}/private/invite`, { headers: OWNER }).then(json);
  const code = invite.fields.code.stringValue;
  const nia = await account('Nia Patel');
  await call('joinWithCode', nia, { code, unit: '4B' });
  for (const name of ['Cal Ortiz', 'Meg Chen']) {
    await call('joinWithCode', await account(name), { code, unit: '2C' });
  }
  console.log(`SOCIETY=${sid}`);
  console.log(`--dart-define=ADMIN_EMAIL=${ann.email} --dart-define=ADMIN_PASSWORD=${ann.password}`);
  console.log(`--dart-define=RESIDENT_EMAIL=${nia.email} --dart-define=RESIDENT_PASSWORD=${nia.password}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
