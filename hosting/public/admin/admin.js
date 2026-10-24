// Burghood platform admin console. Signs in with Google and shows the
// console only to accounts with the `platformAdmin` custom claim. The
// claim is a convenience for the page: Firestore and Storage rules and the
// Cloud Functions are what protect the data.
import { initializeApp } from 'https://www.gstatic.com/firebasejs/11.10.0/firebase-app.js';
import {
  GoogleAuthProvider,
  connectAuthEmulator,
  getAuth,
  onAuthStateChanged,
  signInWithPopup,
  signOut,
} from 'https://www.gstatic.com/firebasejs/11.10.0/firebase-auth.js';
import {
  collection,
  connectFirestoreEmulator,
  doc,
  getDoc,
  getDocs,
  getFirestore,
  limit,
  orderBy,
  query,
  where,
} from 'https://www.gstatic.com/firebasejs/11.10.0/firebase-firestore.js';
import {
  connectFunctionsEmulator,
  getFunctions,
  httpsCallable,
} from 'https://www.gstatic.com/firebasejs/11.10.0/firebase-functions.js';

const $ = (id) => document.getElementById(id);
const local = ['localhost', '127.0.0.1'].includes(location.hostname);
let db;
let functions;

function show(view, message = '') {
  for (const id of ['signed-out', 'denied', 'console']) $(id).hidden = id !== view;
  $('status').textContent = message;
  $('status').hidden = !message;
}

/** Builds an element: el('p', {class: 'meta'}, 'text', child, ...). */
function el(tag, attrs = {}, ...children) {
  const e = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) {
    if (k === 'onclick') e.onclick = v;
    else if (v !== false && v != null) e.setAttribute(k, v === true ? '' : v);
  }
  for (const c of children.flat()) if (c != null && c !== false) e.append(c);
  return e;
}

const when = (t) => (t?.toDate ? t.toDate().toLocaleString() : '');
const POSITIONS = {
  president: 'President',
  secretary: 'Secretary',
  board_member: 'Board member',
  manager: 'Manager',
};

async function start() {
  // Firebase Hosting serves the config of the project it's deployed to, so
  // the same page works on fixburgh-dev and fixburgh-prod.
  const config = await fetch('/__/firebase/init.json').then((r) => {
    if (!r.ok) throw new Error(`No Firebase config (${r.status})`);
    return r.json();
  });
  const app = initializeApp(config);
  const auth = getAuth(app);
  db = getFirestore(app);
  functions = getFunctions(app, 'us-east1');
  if (local) {
    connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
    connectFirestoreEmulator(db, '127.0.0.1', 8080);
    connectFunctionsEmulator(functions, '127.0.0.1', 5001);
  }

  $('sign-in').onclick = () =>
    signInWithPopup(auth, new GoogleAuthProvider()).catch((e) => show('signed-out', e.message));
  $('sign-out').onclick = () => signOut(auth);
  $('claims-refresh').onclick = () => loadClaims();
  $('claim-close').onclick = () => $('claim-dialog').close();
  $('file-close').onclick = () => closeFile();

  onAuthStateChanged(auth, async (user) => {
    $('who').hidden = !user;
    $('email').textContent = user?.email ?? '';
    if (!user) return show('signed-out');
    show(null, 'Checking access…');
    // Force a refresh so a newly granted claim shows up straight away.
    const { claims } = await user.getIdTokenResult(true);
    if (claims.platformAdmin !== true) return show('denied');
    show('console');
    await loadClaims();
  });
}

// ---- Claims ----

async function loadClaims() {
  $('claims-pending').replaceChildren(el('p', { class: 'meta' }, 'Loading…'));
  $('claims-decided').replaceChildren();
  try {
    const pending = await getDocs(
      query(collection(db, 'societyClaims'), where('status', '==', 'pending'), orderBy('createdAt', 'desc')),
    );
    const decided = await getDocs(
      query(collection(db, 'societyClaims'), where('status', 'in', ['approved', 'rejected']), limit(50)),
    );
    $('claims-count').textContent = pending.size ? ` (${pending.size} waiting)` : '';
    $('claims-pending').replaceChildren(
      ...(pending.empty ? [el('p', { class: 'meta' }, 'No claims waiting.')] : pending.docs.map(claimRow)),
    );
    const recent = decided.docs.sort(
      (a, b) => (b.get('decidedAt')?.toMillis() ?? 0) - (a.get('decidedAt')?.toMillis() ?? 0),
    );
    $('claims-decided').replaceChildren(
      ...(recent.length ? recent.slice(0, 20).map(claimRow) : [el('p', { class: 'meta' }, 'None yet.')]),
    );
  } catch (e) {
    $('claims-pending').replaceChildren(el('p', { class: 'error' }, `Couldn't load claims: ${e.message}`));
  }
}

function claimRow(snap) {
  const c = snap.data();
  const status = c.status === 'pending' ? `Submitted ${when(c.createdAt)}` : `${c.status} ${when(c.decidedAt)}`;
  return el(
    'button',
    { type: 'button', class: 'row', onclick: () => openClaim(snap.id) },
    el('strong', {}, c.society?.name ?? '(no name)'),
    el('span', { class: 'meta' }, ` · ${c.society?.address ?? ''}`),
    el('br'),
    el('span', { class: `pill ${c.status}` }, c.status),
    el('span', { class: 'meta' }, ` ${c.applicantName || c.applicantEmail} · ${status}`),
  );
}

async function openClaim(id) {
  const dialog = $('claim-dialog');
  const body = $('claim-body');
  if (!dialog.open) {
    body.replaceChildren(el('p', { class: 'meta' }, 'Loading…'));
    dialog.showModal();
  }
  const snap = await getDoc(doc(db, 'societyClaims', id));
  if (!snap.exists()) {
    body.replaceChildren(el('p', {}, 'This claim no longer exists.'));
    return;
  }
  const c = snap.data();
  const s = c.society ?? {};
  const hoa = c.hoa ?? {};
  const link = (u) => (u ? el('a', { href: u, target: '_blank', rel: 'noopener noreferrer' }, u) : '(none)');
  const audit = await getDocs(query(collection(db, 'societyClaims', id, 'audit'), orderBy('at')));
  const filesGone = Boolean(c.filesDeletedAt);

  const decide = el('section', {});
  if (c.status === 'pending') {
    const reason = el('textarea', { id: 'reason', rows: 3, maxlength: 500, placeholder: 'Reason (required to reject; shown to the applicant)' });
    const error = el('p', { class: 'error', hidden: true });
    const busy = el('p', { class: 'meta', hidden: true }, 'Saving…');
    const run = async (decision) => {
      for (const b of decide.querySelectorAll('button')) b.disabled = true;
      error.hidden = true;
      busy.hidden = false;
      try {
        await httpsCallable(functions, 'decideClaim')({ claimId: id, decision, reason: reason.value });
        dialog.close();
        await loadClaims();
      } catch (e) {
        error.textContent = e.message;
        error.hidden = false;
        busy.hidden = true;
        for (const b of decide.querySelectorAll('button')) b.disabled = false;
      }
    };
    // Confirms in the page, not with window.confirm(), which some browsers
    // and in-app web views block without showing anything.
    const actions = el('div', { class: 'actions' });
    const choose = () =>
      actions.replaceChildren(
        el('button', { type: 'button', class: 'primary', onclick: () => ask('approve') }, 'Approve'),
        el('button', { type: 'button', class: 'danger', onclick: () => ask('reject') }, 'Reject'),
      );
    const ask = (decision) => {
      if (decision === 'reject' && !reason.value.trim()) {
        error.textContent = 'Say why, so the applicant can fix it.';
        error.hidden = false;
        reason.focus();
        return;
      }
      error.hidden = true;
      const question =
        decision === 'approve'
          ? `Approve ${s.name}? It goes live and ${c.applicantName || 'the applicant'} becomes its admin.`
          : `Reject ${s.name}? ${c.applicantName || 'The applicant'} sees your reason.`;
      actions.replaceChildren(
        el('p', { class: 'confirm' }, question),
        el(
          'button',
          { type: 'button', class: decision === 'approve' ? 'primary' : 'danger', onclick: () => run(decision) },
          decision === 'approve' ? 'Yes, approve' : 'Yes, reject',
        ),
        el('button', { type: 'button', onclick: choose }, 'Cancel'),
      );
    };
    choose();
    decide.append(el('h3', {}, 'Decision'), reason, error, actions, busy);
  } else {
    decide.append(
      ...[
        el('h3', {}, 'Decision'),
        el('p', {}, el('span', { class: `pill ${c.status}` }, c.status), ` by ${c.decidedByEmail || c.decidedBy} on ${when(c.decidedAt)}`),
        c.reason ? el('p', {}, `Reason: ${c.reason}`) : null,
        c.societyId ? el('p', { class: 'meta' }, `Society id: ${c.societyId}`) : null,
      ].filter(Boolean),
    );
  }

  body.replaceChildren(
    el('h2', {}, s.name ?? ''),
    el(
      'dl',
      {},
      el('dt', {}, 'Address'), el('dd', {}, `${s.address ?? ''} (${s.municipalityName ?? ''}, ${s.lat}, ${s.lng})`),
      el('dt', {}, 'Homes'), el('dd', {}, String(s.units ?? '')),
      el('dt', {}, 'Applicant'), el('dd', {}, `${c.applicantName || '(no name)'} · ${c.applicantEmail || ''}`),
      el('dt', {}, 'Position'), el('dd', {}, POSITIONS[c.position] ?? c.position ?? ''),
      el('dt', {}, 'HOA company'), el('dd', {}, hoa.company || '(none)'),
      el('dt', {}, 'Website'), el('dd', {}, link(hoa.website)),
      el('dt', {}, 'Account link'), el('dd', {}, link(hoa.accountUrl)),
      el('dt', {}, 'Submitted'), el('dd', {}, when(c.createdAt)),
      c.previousClaimId ? [el('dt', {}, 'Resubmits'), el('dd', {}, c.previousClaimId)] : null,
    ),
    el('h3', {}, 'Documents'),
    filesGone
      ? el('p', { class: 'meta' }, `Deleted ${when(c.filesDeletedAt)}, as the retention policy requires.`)
      : el(
          'div',
          { class: 'actions' },
          el('button', { type: 'button', onclick: () => viewFile(id, 'id') }, 'View photo ID'),
          el('button', { type: 'button', onclick: () => viewFile(id, 'proof') }, 'View proof of office'),
        ),
    el('p', { class: 'meta' }, 'Files open here only and are never saved as links. Each view is recorded below.'),
    decide,
    el('h3', {}, 'Audit trail'),
    audit.empty
      ? el('p', { class: 'meta' }, 'Nothing yet.')
      : el(
          'ol',
          { class: 'audit' },
          audit.docs.map((a) => {
            const e = a.data();
            const what = e.action === 'viewed_file' ? `viewed ${e.file === 'id' ? 'photo ID' : 'proof of office'}` : e.action.replace('_', ' ');
            return el('li', {}, `${when(e.at)}: ${what} by ${e.byEmail || e.by}${e.reason ? ` (${e.reason})` : ''}`);
          }),
        ),
  );
}

let fileUrl;

async function viewFile(claimId, which) {
  const dialog = $('file-dialog');
  const body = $('file-body');
  body.replaceChildren(el('p', { class: 'meta' }, 'Loading…'));
  dialog.showModal();
  try {
    const { data } = await httpsCallable(functions, 'getClaimFile')({ claimId, which });
    const bytes = Uint8Array.from(atob(data.data), (ch) => ch.charCodeAt(0));
    fileUrl = URL.createObjectURL(new Blob([bytes], { type: data.contentType }));
    body.replaceChildren(
      data.contentType === 'application/pdf'
        ? el('iframe', { src: fileUrl, title: which === 'id' ? 'Photo ID' : 'Proof of office' })
        : el('img', { src: fileUrl, alt: which === 'id' ? 'Photo ID' : 'Proof of office' }),
    );
    // Refresh the audit trail behind this dialog.
    void openClaim(claimId);
  } catch (e) {
    body.replaceChildren(el('p', { class: 'error' }, e.message));
  }
}

function closeFile() {
  $('file-dialog').close();
  $('file-body').replaceChildren();
  if (fileUrl) URL.revokeObjectURL(fileUrl);
  fileUrl = undefined;
}

start().catch((e) => show(null, `Couldn't load the console: ${e.message}`));
