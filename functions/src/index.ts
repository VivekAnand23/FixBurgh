/**
 * Burghood (formerly FixBurgh) Cloud Functions. Society functions are in
 * society.ts.
 *
 * onFlagCreated: counts flags per report and hides a report from the public
 * map once FLAG_HIDE_THRESHOLD different people have flagged it
 * (BRD FR-MOD-02). Moderators restore or remove it in the console.
 */
import './options';

import { getAuth } from 'firebase-admin/auth';
import { DocumentData, FieldValue, getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { logger } from 'firebase-functions/v2';
import {
  onDocumentCreated,
  onDocumentDeleted,
  onDocumentWritten,
} from 'firebase-functions/v2/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { categoryLabel, notifyUsers, placeOwnersNear } from './notify';
import { deleteSocietyData } from './society';
export {
  onChannelDeleted,
  onCommentReactionWritten,
  onCommentWritten,
  onPostReactionWritten,
  onPostWritten,
  onSocietyCreated,
  sendReactionDigest,
} from './channels';

export {
  checkSocietyDuplicates,
  decideClaim,
  getClaimFile,
  joinWithCode,
  onMemberWritten,
  onNoticeCreated,
  purgeClaimFiles,
  purgeClaimFilesNow,
  regenerateInviteCode,
} from './society';

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

/** Account deletion needs a sign-in this recent (BRD FR-AUTH-05). */
const RECENT_LOGIN_SECONDS = 5 * 60;

/** Storage paths of a report's photos, including the "after" photo. */
function photoPaths(data: DocumentData | undefined): string[] {
  const photos: unknown[] = Array.isArray(data?.photos) ? data.photos : [];
  const after = data?.afterPhoto ? [data.afterPhoto] : [];
  return [...photos, ...after].flatMap((p) => {
    const photo = p as { path?: unknown; thumbPath?: unknown };
    return [photo.path, photo.thumbPath].filter(
      (x): x is string => typeof x === 'string' && x.startsWith('reports/'),
    );
  });
}

async function deleteFiles(paths: string[]): Promise<void> {
  const bucket = getStorage().bucket();
  await Promise.all(
    paths.map((path) =>
      bucket
        .file(path)
        .delete({ ignoreNotFound: true })
        .catch((e) => logger.warn('photo delete failed', { path, e })),
    ),
  );
}

/**
 * deleteAccount: deletes the caller's account (BRD FR-PRF-04, journey 6.5).
 *
 * `reports: 'delete'` removes their reports, photos and the reports' votes
 * and history; `'anonymize'` keeps the reports on the map with no link to
 * the account. Either way their own votes, limits, profile and sign-in are
 * removed. Signed-in (non-guest) accounts must have signed in within the
 * last five minutes; otherwise this fails with `failed-precondition` and the
 * app asks them to sign in again.
 */
export const deleteAccount = onCall({ timeoutSeconds: 60 }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in first.');
  const mode = request.data?.reports;
  if (mode !== 'delete' && mode !== 'anonymize') {
    throw new HttpsError('invalid-argument', "reports must be 'delete' or 'anonymize'.");
  }
  const token = request.auth!.token;
  const isGuest = token.firebase?.sign_in_provider === 'anonymous';
  const signedInAgo = Date.now() / 1000 - (token.auth_time ?? 0);
  if (!isGuest && signedInAgo > RECENT_LOGIN_SECONDS) {
    throw new HttpsError('failed-precondition', 'requires-recent-login');
  }

  const db = getFirestore();
  const reports = await db.collection('reports').where('authorUid', '==', uid).get();
  if (mode === 'delete') {
    await deleteFiles(reports.docs.flatMap((d) => photoPaths(d.data())));
    // Takes the votes and history subcollections with each report.
    for (const doc of reports.docs) await db.recursiveDelete(doc.ref);
  } else {
    const writer = db.bulkWriter();
    for (const doc of reports.docs) {
      writer.update(doc.ref, {
        authorUid: '',
        authorIsGuest: false,
        anonymized: true,
        claimedFromGuest: FieldValue.delete(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
    await writer.close();
  }

  // Their "Me too" and "Looks fixed" votes on other people's reports.
  for (const [coll, field] of [
    ['upvotes', 'upvoteCount'],
    ['fixedVotes', 'fixedVoteCount'],
  ] as const) {
    const votes = await db.collectionGroup(coll).where('uid', '==', uid).get();
    for (const vote of votes.docs) {
      const report = vote.ref.parent.parent!;
      await db.runTransaction(async (tx) => {
        const snap = await tx.get(report);
        tx.delete(vote.ref);
        // A resolved report stays resolved; only open counts go down.
        if (snap.exists && (coll === 'upvotes' || snap.get('status') !== 'resolved')) {
          tx.update(report, { [field]: FieldValue.increment(-1) });
        }
      });
    }
  }

  // Flags stay for moderators, without the person who sent them.
  const flags = await db.collection('flags').where('reporterUid', '==', uid).get();
  const writer = db.bulkWriter();
  for (const flag of flags.docs) writer.update(flag.ref, { reporterUid: '' });
  for (const coll of ['rateLimits', 'voteLimits', 'notifyLimits']) {
    writer.delete(db.collection(coll).doc(uid));
  }
  writer.delete(db.collection('notifyLimits').doc(`${uid}_society`));
  await writer.close();
  // Burghood society memberships, claims and claim files.
  await deleteSocietyData(uid);
  // The profile with its devices, saved places and notifications.
  await db.recursiveDelete(db.collection('users').doc(uid));

  await getAuth().deleteUser(uid);
  return { reports: reports.size, mode };
});

/**
 * onReportDeleted: when a report is deleted (by its author in My Reports),
 * removes its photos, votes and history (BRD FR-MYR-04).
 */
export const onReportDeleted = onDocumentDeleted('reports/{reportId}', async (event) => {
  if (!event.data) return;
  await deleteFiles(photoPaths(event.data.data()));
  // The document is gone; this removes what is left beneath it.
  await getFirestore().recursiveDelete(event.data.ref);
});

/**
 * onReportWritten: records each status change in `reports/{id}/events`
 * for the timeline on the report detail (BRD FR-MAP-09). Runs on the server
 * so the history can't be edited by clients.
 */
export const onReportWritten = onDocumentWritten('reports/{reportId}', async (event) => {
  const before = event.data?.before;
  const after = event.data?.after;
  if (!after?.exists) return;
  const prev = before?.exists ? before.get('status') : undefined;
  const next = after.get('status');
  if (prev === next) return;

  const entry: Record<string, unknown> = {
    type:
      prev === undefined
        ? 'reported'
        : next === 'resolved'
          ? 'resolved'
          : prev === 'resolved'
            ? 'reopened'
            : next,
    by: next === 'resolved' ? (after.get('resolvedBy') ?? 'reporter') : 'reporter',
    at: FieldValue.serverTimestamp(),
  };
  if (next === 'sent' && typeof after.get('contactChannel') === 'string') {
    entry.channel = after.get('contactChannel');
  }
  const afterThumb = after.get('afterPhoto.thumbUrl');
  if (next === 'resolved' && typeof afterThumb === 'string') entry.photoUrl = afterThumb;
  // The event ID makes a retried trigger write the same entry once.
  await after.ref.collection('events').doc(event.id).set(entry);
  await notifyStatusChange(event.id, after, entry.type as string);
});

type Snapshot = FirebaseFirestore.DocumentSnapshot;

/**
 * Tells the reporter and everyone who said "Me too" (FR-NTF-02), and on a
 * new urgent report, people with a saved place nearby (FR-NTF-04).
 */
async function notifyStatusChange(key: string, report: Snapshot, type: string) {
  const author = report.get('authorUid') as string | undefined;
  const what = categoryLabel(report.get('category'));
  const where = (report.get('address') as string | undefined) || (report.get('municipalityName') as string) || '';
  const at = where ? ` at ${where}` : '';
  const reportId = report.id;

  if (type === 'reported') {
    if (report.get('severity') !== 'urgent') return;
    const lat = Number(report.get('geo.lat')), lng = Number(report.get('geo.lng'));
    const owners = (await placeOwnersNear(lat, lng)).filter((u) => u !== author);
    await notifyUsers(owners, {
      kind: 'nearby',
      title: `Urgent ${what} near your saved place`,
      body: `Reported${at}. Take care if you're passing by.`,
      reportId,
    }, key);
    return;
  }

  const byCommunity = type === 'resolved' && report.get('resolvedBy') === 'community';
  const upvoters = (await report.ref.collection('upvotes').get()).docs.map((d) => d.id);
  // The reporter made every other change, so they don't need telling.
  const recipients = byCommunity ? [...upvoters, author ?? ''] : upvoters.filter((u) => u !== author);
  const agency = report.get('agencyName') as string | undefined;
  const notice = {
    sent: { title: `Your neighbor contacted ${agency ?? 'the office'}`, body: `The ${what}${at} has been reported to the people who fix it.` },
    resolved: byCommunity
      ? { title: `Fixed: ${what}${at}`, body: 'Neighbors confirmed it looks fixed.' }
      : { title: `Fixed: ${what}${at}`, body: 'The reporter marked it fixed.' },
    reopened: { title: `Not fixed after all: ${what}`, body: `The ${what}${at} was reopened.` },
  }[type];
  if (!notice) return;
  await notifyUsers(recipients, { kind: 'status', ...notice, reportId }, key);
}

/**
 * sendTestNotification: sends a test notification to the caller's own
 * devices, from Profile > Notifications. Counts toward the daily limit.
 */
export const sendTestNotification = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in first.');
  const sent = await notifyUsers([uid], {
    kind: 'test',
    title: 'Burghood notifications work',
    body: "You'll hear from us when reports you follow change.",
  }, `test_${Date.now()}`);
  return { sent: sent.length };
});

/**
 * onAgencyWritten: bumps `config/directory.version` whenever an agency
 * record changes (including console edits), so apps fetch the directory
 * again on their next launch (BRD FR-RTE-10).
 */
export const onAgencyWritten = onDocumentWritten('agencies/{agencyId}', async () => {
  await getFirestore()
    .collection('config')
    .doc('directory')
    .set({ version: FieldValue.serverTimestamp() }, { merge: true });
});
