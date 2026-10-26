// Approves a provider application in the LOCAL emulators, as the Burghood
// team would in the admin console. Used by run_chapter.sh when the
// walkthrough prints "ACTION approve-provider <email>".
//   node tool/training_video/approve.mjs rosa@burghood.test
const PROJECT = 'fixburgh-dev';
const AUTH = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1';
const FUNCTIONS = `http://127.0.0.1:5001/${PROJECT}/us-east1`;
const PASSWORD = 'burghood-demo-1';

const signIn = (email) =>
  fetch(`${AUTH}/accounts:signInWithPassword?key=fake`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password: PASSWORD, returnSecureToken: true }),
  }).then((r) => r.json());

const [staff, provider] = await Promise.all([signIn('staff@burghood.test'), signIn(process.argv[2])]);
const res = await fetch(`${FUNCTIONS}/decideProvider`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${staff.idToken}` },
  body: JSON.stringify({ data: { providerId: provider.localId, decision: 'approve' } }),
});
console.log('approve', process.argv[2], res.status, JSON.stringify(await res.json()));
