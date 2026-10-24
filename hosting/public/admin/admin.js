// Burghood platform admin console. Signs in with Google and shows the
// console only to accounts with the `platformAdmin` custom claim. The
// claim is a convenience for the page: Firestore and Storage rules are what
// protect the data.
import { initializeApp } from 'https://www.gstatic.com/firebasejs/11.10.0/firebase-app.js';
import {
  GoogleAuthProvider,
  connectAuthEmulator,
  getAuth,
  onAuthStateChanged,
  signInWithPopup,
  signOut,
} from 'https://www.gstatic.com/firebasejs/11.10.0/firebase-auth.js';

const $ = (id) => document.getElementById(id);
const local = ['localhost', '127.0.0.1'].includes(location.hostname);

function show(view, message = '') {
  for (const id of ['signed-out', 'denied', 'console']) $(id).hidden = id !== view;
  $('status').textContent = message;
  $('status').hidden = !message;
}

async function start() {
  // Firebase Hosting serves the config of the project it's deployed to, so
  // the same page works on fixburgh-dev and fixburgh-prod.
  const config = await fetch('/__/firebase/init.json').then((r) => {
    if (!r.ok) throw new Error(`No Firebase config (${r.status})`);
    return r.json();
  });
  const auth = getAuth(initializeApp(config));
  if (local) connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });

  $('sign-in').onclick = () =>
    signInWithPopup(auth, new GoogleAuthProvider()).catch((e) => show('signed-out', e.message));
  $('sign-out').onclick = () => signOut(auth);

  onAuthStateChanged(auth, async (user) => {
    $('who').hidden = !user;
    $('email').textContent = user?.email ?? '';
    if (!user) return show('signed-out');
    show(null, 'Checking access…');
    // Force a refresh so a newly granted claim shows up straight away.
    const { claims } = await user.getIdTokenResult(true);
    show(claims.platformAdmin === true ? 'console' : 'denied');
  });
}

start().catch((e) => show(null, `Couldn't load the console: ${e.message}`));
