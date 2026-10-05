/**
 * FixBurgh Cloud Functions.
 *
 * onFlagCreated: counts flags per report and hides a report from the public
 * map once FLAG_HIDE_THRESHOLD different people have flagged it
 * (BRD FR-MOD-02). Moderators restore or remove it in the console.
 */
import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { setGlobalOptions } from 'firebase-functions/v2';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';

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
