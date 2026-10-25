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

import { initMoney } from './money.js?v=5';

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
  $('providers-refresh').onclick = () => loadProviders();
  $('provider-close').onclick = () => $('provider-dialog').close();

  onAuthStateChanged(auth, async (user) => {
    $('who').hidden = !user;
    $('email').textContent = user?.email ?? '';
    if (!user) return show('signed-out');
    show(null, 'Checking access…');
    // Force a refresh so a newly granted claim shows up straight away.
    const { claims } = await user.getIdTokenResult(true);
    if (claims.platformAdmin !== true) return show('denied');
    show('console');
    await Promise.all([loadClaims(), loadProviders(), initMoney({ db, el, user: () => auth.currentUser })]);
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

// ---- Providers ----

const DOCUMENTS = {
  license: 'Contractor registration (HIC)',
  insurance: 'Insurance',
  background: 'Background check',
};
const PROVIDER_STATUS = {
  applied: 'Applied',
  awaiting_fee: 'Waiting for fee',
  approved: 'Live',
  rejected: 'Rejected',
  suspended: 'Paused',
};
const PERSONAL_CARE = ['babysitting', 'nanny', 'elder_care_and_companionship', 'pet_sitting', 'dog_walking', 'pet_grooming', 'tutoring'];
const CHILD_CARE = ['babysitting', 'nanny', 'tutoring'];

async function loadProviders() {
  $('providers-pending').replaceChildren(el('p', { class: 'meta' }, 'Loading…'));
  $('providers-live').replaceChildren();
  try {
    const pending = await getDocs(
      query(collection(db, 'providers'), where('status', '==', 'applied'), orderBy('createdAt', 'desc')),
    );
    const live = await getDocs(
      query(collection(db, 'providers'), where('status', 'in', ['awaiting_fee', 'approved', 'suspended']), limit(100)),
    );
    $('providers-count').textContent = pending.size ? ` (${pending.size} waiting)` : '';
    $('providers-pending').replaceChildren(
      ...(pending.empty ? [el('p', { class: 'meta' }, 'No applications waiting.')] : pending.docs.map(providerRow)),
    );
    $('providers-live').replaceChildren(
      ...(live.empty ? [el('p', { class: 'meta' }, 'None yet.')] : live.docs.map(providerRow)),
    );
  } catch (e) {
    $('providers-pending').replaceChildren(el('p', { class: 'error' }, `Couldn't load providers: ${e.message}`));
  }
}

function providerRow(snap) {
  const p = snap.data();
  const check = p.backgroundCheck?.status;
  return el(
    'button',
    { type: 'button', class: 'row', onclick: () => openProvider(snap.id) },
    el('strong', {}, p.businessName ?? '(no name)'),
    el('span', { class: 'meta' }, ` · ${(p.categories ?? []).join(', ')}`),
    el('br'),
    el('span', { class: `pill ${p.status}` }, PROVIDER_STATUS[p.status] ?? p.status),
    el('span', { class: 'meta' }, ` ${p.serviceArea?.label ?? ''} · applied ${when(p.createdAt)}${check ? ` · check ${check}` : ''}`),
  );
}

async function openProvider(id) {
  const dialog = $('provider-dialog');
  const body = $('provider-body');
  if (!dialog.open) {
    body.replaceChildren(el('p', { class: 'meta' }, 'Loading…'));
    dialog.showModal();
  }
  const snap = await getDoc(doc(db, 'providers', id));
  if (!snap.exists()) {
    body.replaceChildren(el('p', {}, 'This provider no longer exists.'));
    return;
  }
  const p = snap.data();
  const cats = p.categories ?? [];
  const needsCheck = cats.some((c) => PERSONAL_CARE.includes(c));
  const needsClearances = cats.some((c) => CHILD_CARE.includes(c));
  const check = p.backgroundCheck ?? {};
  const audit = await getDocs(query(collection(db, 'providers', id, 'audit'), orderBy('at')));
  const refresh = async () => {
    await openProvider(id);
    await loadProviders();
  };

  // Background check, for personal care.
  const checkSection = el('section', {});
  if (needsCheck) {
    const passed = el('input', { type: 'radio', name: 'check', value: 'passed', checked: check.status !== 'failed' });
    const failed = el('input', { type: 'radio', name: 'check', value: 'failed', checked: check.status === 'failed' });
    const clearances = el('input', { type: 'checkbox', checked: check.clearances === true });
    const note = el('input', { type: 'text', maxlength: 500, placeholder: 'Vendor, reference or date (optional)', value: check.note ?? '' });
    const error = el('p', { class: 'error', hidden: true });
    checkSection.append(
      el('h3', {}, 'Background check'),
      el('p', { class: 'meta' }, check.status ? `Recorded: ${check.status}${check.clearances ? ', clearances on file' : ''} on ${when(check.checkedAt)}` : 'Not recorded yet.'),
      el(
        'fieldset',
        {},
        el('label', {}, passed, ' Passed'),
        el('label', {}, failed, ' Failed'),
        needsClearances ? el('label', {}, clearances, ' PA child abuse clearances on file (needed for child care)') : null,
        el('label', {}, 'Note ', note),
      ),
      error,
      el(
        'button',
        {
          type: 'button',
          onclick: async (e) => {
            e.target.disabled = true;
            error.hidden = true;
            try {
              await httpsCallable(functions, 'recordBackgroundCheck')({
                providerId: id,
                status: failed.checked ? 'failed' : 'passed',
                clearances: clearances.checked,
                note: note.value,
              });
              await refresh();
            } catch (err) {
              error.textContent = err.message;
              error.hidden = false;
              e.target.disabled = false;
            }
          },
        },
        'Record check',
      ),
    );
  }

  // Ask for the listing fee (or a renewal) once approved.
  const feeSection = el('section', {});
  if (['awaiting_fee', 'approved'].includes(p.status)) {
    const fees = (await getDoc(doc(db, 'config', 'monetisation'))).data() ?? {};
    const r = p.paymentRequest;
    const due = new Date(Date.now() + 14 * 86_400_000).toISOString().slice(0, 10);
    const amount = el('input', { type: 'number', min: '0.01', step: '0.01', value: r?.amountUsd ?? fees.listingFeeUsd ?? 150 });
    const months = el('input', { type: 'number', min: 1, max: 36, step: 1, value: r?.periodMonths ?? fees.listingMonths ?? 12 });
    const how = el('textarea', { rows: 3, maxlength: 1000 }, r?.instructions ?? fees.paymentInstructions ?? 'Pay by check to FixBurgh.');
    const link = el('input', { type: 'url', maxlength: 500, placeholder: 'https://… (optional)', value: r?.payLink ?? fees.payLink ?? '' });
    const dueDate = el('input', { type: 'date', value: r?.dueDate ?? due });
    const error = el('p', { class: 'error', hidden: true });
    feeSection.append(
      el('h3', {}, 'Listing fee'),
      el('p', { class: 'meta' }, r
        ? `Asked for $${Number(r.amountUsd).toFixed(2)} for ${r.periodMonths} months${r.dueDate ? `, due ${r.dueDate}` : ''} on ${when(r.requestedAt)}.`
        : p.status === 'approved' && p.listing?.paidThrough
          ? `Listed until ${p.listing.paidThrough}. Ask here for a renewal.`
          : 'Not asked yet.'),
      el('label', {}, 'Amount (USD) ', amount),
      el('label', {}, 'Months ', months),
      el('label', {}, 'How to pay ', how),
      el('label', {}, 'Payment link ', link),
      el('label', {}, 'Due ', dueDate),
      error,
      el('div', { class: 'actions' },
        el('button', {
          type: 'button',
          class: 'primary',
          onclick: async (e) => {
            error.hidden = true;
            if (link.value.trim() && !/^https:\/\/\S+$/.test(link.value.trim())) {
              error.textContent = 'The payment link must start with https://';
              error.hidden = false;
              return;
            }
            e.target.disabled = true;
            try {
              await httpsCallable(functions, 'requestListingFee')({
                providerId: id,
                amountUsd: Number(amount.value),
                periodMonths: Math.round(Number(months.value)),
                instructions: how.value,
                payLink: link.value.trim(),
                dueDate: dueDate.value || null,
              });
              await refresh();
            } catch (err) {
              error.textContent = err.message;
              error.hidden = false;
              e.target.disabled = false;
            }
          },
        }, r ? 'Send again' : 'Ask for the fee'),
      ),
      el('p', { class: 'meta' }, 'The provider gets a push and sees this in the app. When the payment arrives, record it under Payments (kind: Listing fee) and the profile goes live.'),
    );
  }

  // Approve, reject, suspend or reinstate.
  const decide = el('section', {});
  const choices = {
    applied: [['approve', 'Approve', 'primary'], ['reject', 'Reject', 'danger']],
    rejected: [['approve', 'Approve', 'primary']],
    approved: [['suspend', 'Suspend', 'danger']],
    suspended: [['reinstate', 'Reinstate', 'primary']],
  }[p.status] ?? [];
  if (choices.length) {
    const reason = el('textarea', { rows: 3, maxlength: 500, placeholder: 'Reason (required to reject or suspend; shown to the provider)' });
    const error = el('p', { class: 'error', hidden: true });
    const actions = el('div', { class: 'actions' });
    const run = async (decision) => {
      for (const b of actions.querySelectorAll('button')) b.disabled = true;
      error.hidden = true;
      try {
        await httpsCallable(functions, 'decideProvider')({ providerId: id, decision, reason: reason.value });
        await refresh();
      } catch (e) {
        error.textContent = e.message;
        error.hidden = false;
        choose();
      }
    };
    const choose = () =>
      actions.replaceChildren(
        ...choices.map(([decision, label, cls]) =>
          el('button', { type: 'button', class: cls, onclick: () => ask(decision, label) }, label),
        ),
      );
    // Confirms in the page; window.confirm() is blocked in some browsers.
    const ask = (decision, label) => {
      if ((decision === 'reject' || decision === 'suspend') && !reason.value.trim()) {
        error.textContent = 'Say why, so the provider knows what to fix.';
        error.hidden = false;
        reason.focus();
        return;
      }
      error.hidden = true;
      actions.replaceChildren(
        el('p', { class: 'confirm' }, `${label} ${p.businessName}?`),
        el('button', { type: 'button', class: decision === 'approve' || decision === 'reinstate' ? 'primary' : 'danger', onclick: () => run(decision) }, `Yes, ${label.toLowerCase()}`),
        el('button', { type: 'button', onclick: choose }, 'Cancel'),
      );
    };
    choose();
    decide.append(el('h3', {}, 'Decision'), reason, error, actions);
  }

  const documents = Object.keys(p.documents ?? {});
  body.replaceChildren(
    el('h2', {}, p.businessName ?? ''),
    el(
      'dl',
      {},
      el('dt', {}, 'Status'), el('dd', {}, el('span', { class: `pill ${p.status}` }, PROVIDER_STATUS[p.status] ?? p.status), p.rejectReason ? ` (${p.rejectReason})` : ''),
      el('dt', {}, 'Services'), el('dd', {}, cats.join(', ')),
      el('dt', {}, 'Area'), el('dd', {}, `${p.serviceArea?.label ?? ''}, within ${p.serviceArea?.radiusMiles ?? '?'} mi (${p.serviceArea?.lat}, ${p.serviceArea?.lng})`),
      el('dt', {}, 'Phone'), el('dd', {}, p.phone || '(none)'),
      el('dt', {}, 'About'), el('dd', {}, p.description || '(none)'),
      el('dt', {}, 'Rating'), el('dd', {}, p.ratingCount ? `${Number(p.ratingAvg).toFixed(2)} from ${p.ratingCount} reviews` : 'No reviews'),
      el('dt', {}, 'Applied'), el('dd', {}, when(p.createdAt)),
      el('dt', {}, 'Owner uid'), el('dd', {}, p.ownerUid ?? id),
    ),
    el('h3', {}, 'Documents'),
    documents.length
      ? el(
          'div',
          { class: 'actions' },
          documents.map((which) =>
            el('button', { type: 'button', onclick: () => viewProviderDocument(id, which) }, `View ${DOCUMENTS[which] ?? which}`),
          ),
        )
      : el('p', { class: 'meta' }, 'None uploaded.'),
    el('p', { class: 'meta' }, 'Files open here only and are never saved as links. Each view is recorded below.'),
    checkSection,
    feeSection,
    decide,
    el('h3', {}, 'Audit trail'),
    audit.empty
      ? el('p', { class: 'meta' }, 'Nothing yet.')
      : el(
          'ol',
          { class: 'audit' },
          audit.docs.map((a) => {
            const e = a.data();
            const what = e.action === 'viewed_document' ? `viewed ${DOCUMENTS[e.reason] ?? e.reason}` : e.action.replace('_', ' ');
            const why = e.action === 'viewed_document' ? '' : e.reason ? ` (${e.reason})` : '';
            return el('li', {}, `${when(e.at)}: ${what} by ${e.byEmail || e.by}${why}`);
          }),
        ),
  );
}

async function viewProviderDocument(providerId, which) {
  await showFile(
    () => httpsCallable(functions, 'getProviderDocument')({ providerId, which }),
    DOCUMENTS[which] ?? which,
    () => openProvider(providerId),
  );
}

let fileUrl;

/** Opens a file returned as base64 by [load], then runs [after]. */
async function showFile(load, title, after) {
  const dialog = $('file-dialog');
  const body = $('file-body');
  body.replaceChildren(el('p', { class: 'meta' }, 'Loading…'));
  dialog.showModal();
  try {
    const { data } = await load();
    const bytes = Uint8Array.from(atob(data.data), (ch) => ch.charCodeAt(0));
    fileUrl = URL.createObjectURL(new Blob([bytes], { type: data.contentType }));
    body.replaceChildren(
      data.contentType === 'application/pdf'
        ? el('iframe', { src: fileUrl, title })
        : el('img', { src: fileUrl, alt: title }),
    );
    // Refresh the audit trail behind this dialog.
    void after();
  } catch (e) {
    body.replaceChildren(el('p', { class: 'error' }, e.message));
  }
}

async function viewFile(claimId, which) {
  await showFile(
    () => httpsCallable(functions, 'getClaimFile')({ claimId, which }),
    which === 'id' ? 'Photo ID' : 'Proof of office',
    () => openClaim(claimId),
  );
}

function closeFile() {
  $('file-dialog').close();
  $('file-body').replaceChildren();
  if (fileUrl) URL.revokeObjectURL(fileUrl);
  fileUrl = undefined;
}

start().catch((e) => show(null, `Couldn't load the console: ${e.message}`));
