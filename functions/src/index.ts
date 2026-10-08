/**
 * FixBurgh Cloud Functions.
 *
 * onFlagCreated: counts flags per report and hides a report from the public
 * map once FLAG_HIDE_THRESHOLD different people have flagged it
 * (BRD FR-MOD-02). Moderators restore or remove it in the console.
 */
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { setGlobalOptions } from 'firebase-functions/v2';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

initializeApp();

// Same region as the Firestore database.
setGlobalOptions({ region: 'us-east1', maxInstances: 5 });

const FLAG_HIDE_THRESHOLD = 3;

export const onFlagCreated = onDocumentCreated('flags/{flagId}', async (event) => {
  const reportId = event.data?.get('reportId');
  if (typeof reportId !== 'string' || reportId.length === 0) return;
  const db = getFirestore();
  const ref = db.collection('reports').doc(reportId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return;
    const flags = (snap.get('flagCount') ?? 0) + 1;
    const hide = flags >= FLAG_HIDE_THRESHOLD && snap.get('moderation') === 'visible';
    tx.update(ref, {
      flagCount: flags,
      ...(hide ? { moderation: 'hidden', hiddenAt: FieldValue.serverTimestamp() } : {}),
    });
  });
});

/**
 * claimGuestReports: when a guest signs in to an account that already
 * exists, moves the guest's reports to that account (BRD FR-AUTH-03).
 *
 * The app sends the guest's ID token, captured just before switching
 * accounts, which proves the caller controlled the guest session.
 */
export const claimGuestReports = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in first.');
  const token = request.data?.guestIdToken;
  if (typeof token !== 'string') {
    throw new HttpsError('invalid-argument', 'guestIdToken is required.');
  }
  let guest;
  try {
    guest = await getAuth().verifyIdToken(token);
  } catch {
    throw new HttpsError('permission-denied', 'Guest session could not be verified.');
  }
  if (guest.firebase.sign_in_provider !== 'anonymous') {
    throw new HttpsError('permission-denied', 'Only guest reports can be claimed.');
  }
  if (guest.uid === uid) return { moved: 0 };

  const db = getFirestore();
  const reports = await db.collection('reports').where('authorUid', '==', guest.uid).get();
  const writer = db.bulkWriter();
  for (const doc of reports.docs) {
    writer.update(doc.ref, {
      authorUid: uid,
      authorIsGuest: false,
      claimedFromGuest: guest.uid,
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  await writer.close();
  // The guest account has nothing left; remove it.
  await getAuth().deleteUser(guest.uid).catch(() => undefined);
  return { moved: reports.size };
});
