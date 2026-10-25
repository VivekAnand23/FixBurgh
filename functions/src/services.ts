/**
 * Burghood service requests and the provider directory (Phase 3).
 *
 * Providers apply in the app; a platform admin approves them in the web
 * console. Personal-care providers can't go live until a background check
 * (and, for anyone caring for children, the Pennsylvania clearances) is
 * recorded. Ratings use a Bayesian average so a single 5-star review can't
 * outrank 200 reviews at 4.8.
 */
import './options';

import { AggregateField, FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { logger } from 'firebase-functions/v2';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { CallableRequest, HttpsError, onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import { approvedStatus, defaultPaymentRequest, deleteSponsorships, settings } from './monetisation';
import { notifyUsers } from './notify';
import { BACKGROUND_CHECK_GROUP, CHILD_CARE_CATEGORIES, categoryById } from './serviceCategories';

const db = () => getFirestore();

/** Bayesian prior: a new provider counts as [PRIOR_REVIEWS] reviews at
 * [PRIOR_MEAN] stars until real reviews outweigh it. */
export const PRIOR_REVIEWS = 10;
export const PRIOR_MEAN = 4.0;

export const rankScore = (avg: number, count: number) =>
  (PRIOR_REVIEWS * PRIOR_MEAN + avg * count) / (PRIOR_REVIEWS + count);

/** Days after "completed" before a job with no response closes. */
export const AUTO_CLOSE_DAYS = 7;

const STOP_WORDS = new Set([
  'a', 'an', 'and', 'the', 'of', 'for', 'to', 'in', 'on', 'my', 'our', 'is', 'it', 'with', 'at', 'we', 'i',
  'you', 'your', 'need', 'needs', 'help', 'please', 'from', 'or', 'not', 'no', 'are', 'be', 'by', 'under',
]);

/** Lower-case words of [text], without stop words. */
export const tokens = (text: string) =>
  text
    .toLowerCase()
    .split(/[^a-z0-9]+/)
    .filter((w) => w.length > 1 && !STOP_WORDS.has(w));

/** Search keywords for a provider: their words plus their categories'
 * labels and synonyms. */
export function providerKeywords(p: FirebaseFirestore.DocumentData): string[] {
  const words = new Set<string>([...tokens(String(p.businessName ?? '')), ...tokens(String(p.description ?? ''))]);
  for (const id of (p.categories ?? []) as string[]) {
    const c = categoryById(id);
    if (!c) continue;
    words.add(c.id);
    for (const w of tokens(c.label)) words.add(w);
    for (const s of c.synonyms) for (const w of tokens(s)) words.add(w);
  }
  return [...words].slice(0, 300);
}

/** Why [p] can't be approved yet, or null. */
export function approvalBlocker(p: FirebaseFirestore.DocumentData): string | null {
  const cats = ((p.categories ?? []) as string[]).map(categoryById).filter((c) => c != null);
  if (cats.length === 0) return 'No valid categories.';
  const check = p.backgroundCheck ?? {};
  if (cats.some((c) => c!.group === BACKGROUND_CHECK_GROUP) && check.status !== 'passed') {
    return 'Personal care providers need a passed background check first.';
  }
  if (cats.some((c) => CHILD_CARE_CATEGORIES.includes(c!.id)) && check.clearances !== true) {
    return 'Anyone caring for children needs the Pennsylvania child abuse clearances first.';
  }
  return null;
}

function requirePlatformAdmin(request: CallableRequest) {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first.');
  if (request.auth.token.platformAdmin !== true) {
    throw new HttpsError('permission-denied', 'Platform admins only.');
  }
  return { uid: request.auth.uid, email: (request.auth.token.email as string | undefined) ?? '' };
}

const audit = (pid: string) => db().collection('providers').doc(pid).collection('audit');

/**
 * decideProvider: a platform admin approves, rejects (with a reason),
 * suspends or reinstates a provider. Approval is refused while a required
 * background check or clearance is missing. While listing fees apply
 * (feature_monetisation), approval waits for the fee (`awaiting_fee`).
 */
export const decideProvider = onCall(async (request) => {
  const admin = requirePlatformAdmin(request);
  const { providerId, decision } = request.data ?? {};
  const reason = typeof request.data?.reason === 'string' ? request.data.reason.trim().slice(0, 500) : '';
  if (typeof providerId !== 'string' || !['approve', 'reject', 'suspend', 'reinstate'].includes(decision)) {
    throw new HttpsError('invalid-argument', 'providerId and a decision are required.');
  }
  if ((decision === 'reject' || decision === 'suspend') && !reason) {
    throw new HttpsError('invalid-argument', 'Say why.');
  }
  const ref = db().collection('providers').doc(providerId);
  const approved = decision === 'approve' || decision === 'reinstate' ? await approvedStatus(providerId) : 'approved';
  // Waiting for the fee: ask for it straight away, with the console's defaults.
  const feeRequest = approved === 'awaiting_fee' ? await defaultPaymentRequest() : null;
  const result = await db().runTransaction(async (tx) => {
    const p = await tx.get(ref);
    if (!p.exists) throw new HttpsError('not-found', 'No such provider.');
    const status = p.get('status');
    const allowed: Record<string, string[]> = {
      approve: ['applied', 'rejected'],
      reject: ['applied'],
      suspend: ['approved', 'awaiting_fee'],
      reinstate: ['suspended'],
    };
    if (!allowed[decision].includes(status)) {
      throw new HttpsError('failed-precondition', `Can't ${decision} a provider who is ${status}.`);
    }
    if (decision === 'approve' || decision === 'reinstate') {
      const blocker = approvalBlocker(p.data()!);
      if (blocker) throw new HttpsError('failed-precondition', blocker);
    }
    const next = { approve: approved, reject: 'rejected', suspend: 'suspended', reinstate: approved }[
      decision as 'approve'
    ];
    tx.update(ref, {
      status: next,
      rejectReason: decision === 'reject' || decision === 'suspend' ? reason : FieldValue.delete(),
      decidedBy: admin.uid,
      decidedAt: FieldValue.serverTimestamp(),
      ...(next === 'approved' && !p.get('liveAt') ? { liveAt: FieldValue.serverTimestamp() } : {}),
      ...(next === 'awaiting_fee' && feeRequest ? { paymentRequest: feeRequest } : {}),
    });
    tx.create(audit(providerId).doc(), {
      action: decision,
      reason,
      by: admin.uid,
      byEmail: admin.email,
      at: FieldValue.serverTimestamp(),
    });
    return { status: next, owner: p.get('ownerUid') as string, name: p.get('businessName') as string };
  });
  const notice = {
    approved: { title: `${result.name} is live on Burghood`, body: 'Neighbors can now find you and send you requests.' },
    rejected: { title: `We couldn't approve ${result.name}`, body: reason },
    suspended: { title: `${result.name} is paused`, body: reason },
    awaiting_fee: {
      title: `${result.name} is approved`,
      body: `It goes live once the $${(await settings()).listingFeeUsd} listing fee is paid. Open Burghood to see how to pay.`,
    },
  }[result.status as 'approved'];
  if (notice) {
    await notifyUsers([result.owner], { kind: 'society', ...notice }, `provider_${providerId}_${Date.now()}`);
  }
  return { status: result.status };
});

/** recordBackgroundCheck: a platform admin records a background check and,
 * for child care, the clearances. */
export const recordBackgroundCheck = onCall(async (request) => {
  const admin = requirePlatformAdmin(request);
  const { providerId, status, clearances } = request.data ?? {};
  const note = typeof request.data?.note === 'string' ? request.data.note.trim().slice(0, 500) : '';
  if (typeof providerId !== 'string' || !['passed', 'failed'].includes(status) || typeof clearances !== 'boolean') {
    throw new HttpsError('invalid-argument', 'providerId, status (passed or failed) and clearances are required.');
  }
  const ref = db().collection('providers').doc(providerId);
  if (!(await ref.get()).exists) throw new HttpsError('not-found', 'No such provider.');
  await ref.update({
    backgroundCheck: { status, clearances, note, checkedBy: admin.uid, checkedAt: FieldValue.serverTimestamp() },
  });
  await audit(providerId).add({
    action: 'background_check',
    reason: `${status}${clearances ? ', clearances on file' : ''}${note ? `: ${note}` : ''}`,
    by: admin.uid,
    byEmail: admin.email,
    at: FieldValue.serverTimestamp(),
  });
  return { ok: true };
});

/** getProviderDocument: a provider's licence, insurance or background
 * document for a platform admin, as base64 (no lasting link), audited. */
export const getProviderDocument = onCall(async (request) => {
  const admin = requirePlatformAdmin(request);
  const { providerId, which } = request.data ?? {};
  if (typeof providerId !== 'string' || !['license', 'insurance', 'background'].includes(which)) {
    throw new HttpsError('invalid-argument', 'providerId and which are required.');
  }
  const p = await db().collection('providers').doc(providerId).get();
  const path = p.get(`documents.${which}`) as string | undefined;
  if (!path || !path.startsWith(`providerDocs/${providerId}/`)) throw new HttpsError('not-found', 'No such document.');
  const file = getStorage().bucket().file(path);
  const [exists] = await file.exists();
  if (!exists) throw new HttpsError('not-found', 'The file was not uploaded.');
  const [[data], [meta]] = await Promise.all([file.download(), file.getMetadata()]);
  const byExtension: Record<string, string> = { jpg: 'image/jpeg', png: 'image/png', pdf: 'application/pdf' };
  const stored = meta.contentType && meta.contentType !== 'application/octet-stream' ? meta.contentType : undefined;
  await audit(providerId).add({
    action: 'viewed_document',
    reason: which,
    by: admin.uid,
    byEmail: admin.email,
    at: FieldValue.serverTimestamp(),
  });
  return {
    contentType: stored ?? byExtension[path.split('.').pop() ?? ''] ?? 'application/octet-stream',
    data: data.toString('base64'),
  };
});

/** onProviderWritten: keeps search keywords and the initial rank score. */
export const onProviderWritten = onDocumentWritten('providers/{pid}', async (event) => {
  const after = event.data?.after;
  if (!after?.exists) return;
  const d = after.data()!;
  const keywords = providerKeywords(d);
  const update: Record<string, unknown> = {};
  if (JSON.stringify(keywords) !== JSON.stringify(d.keywords ?? [])) update.keywords = keywords;
  if (typeof d.rankScore !== 'number') {
    update.rankScore = rankScore(0, 0);
    update.ratingAvg = 0;
    update.ratingCount = 0;
  }
  if (Object.keys(update).length) await after.ref.update(update);
});

/** onReviewWritten: re-averages the provider's ratings and rank score. */
export const onReviewWritten = onDocumentWritten('providers/{pid}/reviews/{rid}', async (event) => {
  const { pid, rid } = event.params;
  const provider = db().collection('providers').doc(pid);
  const reviews = provider.collection('reviews');
  const agg = await reviews.aggregate({ count: AggregateField.count(), avg: AggregateField.average('stars') }).get();
  const { count, avg } = agg.data();
  await provider.update({
    ratingCount: count,
    ratingAvg: avg ?? 0,
    rankScore: rankScore(avg ?? 0, count),
  });
  if (!event.data?.before?.exists && event.data?.after?.exists) {
    await db().collection('serviceRequests').doc(rid).update({ rated: true }).catch(() => undefined);
    const stars = event.data.after.get('stars');
    await notifyUsers([pid], {
      kind: 'service',
      title: `New ${stars}-star review`,
      body: String(event.data.after.get('comment') ?? '').slice(0, 140),
    }, `review_${rid}`);
  }
});

const STATUS_PUSH: Record<string, { to: 'poster' | 'provider'; title: (t: string) => string; body: string }> = {
  assigned: { to: 'provider', title: (t) => `New request: ${t}`, body: 'Open it to accept or decline.' },
  accepted: { to: 'poster', title: (t) => `Accepted: ${t}`, body: 'Your provider accepted the job.' },
  declined: { to: 'poster', title: (t) => `Declined: ${t}`, body: 'Pick another provider for this request.' },
  in_progress: { to: 'poster', title: (t) => `Started: ${t}`, body: 'Your provider started the job.' },
  completed: { to: 'poster', title: (t) => `Done: ${t}`, body: 'Your provider marked the job done. Confirm it or say it isn\'t fixed.' },
  not_fixed: { to: 'provider', title: (t) => `Not fixed yet: ${t}`, body: 'The resident says it still needs work.' },
  confirmed: { to: 'provider', title: (t) => `Confirmed: ${t}`, body: 'The resident confirmed the job is done.' },
};

/**
 * onServiceRequestWritten: records each status change in the request's
 * `events` (its timeline) and tells the other side. New common-area
 * requests go to the society's admins.
 */
export const onServiceRequestWritten = onDocumentWritten('serviceRequests/{rid}', async (event) => {
  const before = event.data?.before;
  const after = event.data?.after;
  if (!after?.exists) return;
  const was = before?.exists ? (before.get('status') as string) : undefined;
  const now = after.get('status') as string;
  if (was === now) return;
  const rid = event.params.rid;
  await after.ref.collection('events').doc(event.id).set({
    status: now,
    note: now === 'declined' ? after.get('declineReason') ?? '' : now === 'not_fixed' ? after.get('notFixedNote') ?? '' : '',
    // When the step happened (the rules pin updatedAt to the write's time),
    // not when this trigger ran: triggers can run late and out of order.
    at: after.get('updatedAt') ?? FieldValue.serverTimestamp(),
  });
  const title = String(after.get('title') ?? '');
  const push = STATUS_PUSH[now];
  if (push) {
    const to = push.to === 'poster' ? after.get('posterUid') : after.get('providerId');
    if (typeof to === 'string' && to) {
      await notifyUsers([to], { kind: 'service', title: push.title(title), body: push.body, requestId: rid }, `sr_${event.id}`);
    }
  }
  if (now === 'posted' && after.get('scope') === 'common') {
    const society = await db().collection('societies').doc(after.get('societyId')).get();
    const admins = ((society.get('adminUids') ?? []) as string[]).filter((u) => u !== after.get('posterUid'));
    await notifyUsers(admins, {
      kind: 'service',
      title: `Common-area request: ${title}`,
      body: 'Pick a provider for it in Services.',
      requestId: rid,
      societyId: after.get('societyId'),
    }, `sr_${event.id}`);
  }
});

/** Closes jobs marked completed more than [days] ago with no response. */
export async function closeStaleRequests(days: number, now = Date.now()): Promise<string[]> {
  const cutoff = Timestamp.fromMillis(now - days * 24 * 3600 * 1000);
  const stale = await db()
    .collection('serviceRequests')
    .where('status', '==', 'completed')
    .where('completedAt', '<=', cutoff)
    .get();
  const writer = db().bulkWriter();
  for (const d of stale.docs) {
    writer.update(d.ref, { status: 'closed', closedAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp() });
  }
  await writer.close();
  return stale.docs.map((d) => d.id);
}

export const closeStaleServiceRequests = onSchedule('every day 04:00', async () => {
  const closed = await closeStaleRequests(AUTO_CLOSE_DAYS);
  logger.info('stale service requests closed', { count: closed.length });
});

/** closeStaleServiceRequestsNow: the same, on demand for platform admins
 * (and tests, which may pass a shorter window in the emulator). */
export const closeStaleServiceRequestsNow = onCall(async (request) => {
  requirePlatformAdmin(request);
  const asked = Number(request.data?.days);
  const emulator = process.env.FUNCTIONS_EMULATOR === 'true';
  const days = Number.isFinite(asked) && (emulator || asked >= AUTO_CLOSE_DAYS) ? asked : AUTO_CLOSE_DAYS;
  return { closed: await closeStaleRequests(days) };
});

/**
 * Removes a deleted account's provider profile, documents and portfolio,
 * and the service requests they posted (called from deleteAccount).
 * Their reviews stay on providers' profiles without their name.
 */
export async function deleteServiceData(uid: string) {
  const bucket = getStorage().bucket();
  const provider = db().collection('providers').doc(uid);
  if ((await provider.get()).exists) await db().recursiveDelete(provider);
  await deleteSponsorships(uid);
  for (const prefix of [`providerDocs/${uid}/`, `providers/${uid}/`]) {
    await bucket.deleteFiles({ prefix }).catch((e) => logger.warn('provider file delete failed', { prefix, e }));
  }
  const posted = await db().collection('serviceRequests').where('posterUid', '==', uid).get();
  for (const r of posted.docs) {
    await bucket.deleteFiles({ prefix: `serviceRequests/${r.id}/` }).catch(() => undefined);
    await db().recursiveDelete(r.ref);
  }
  const reviews = await db().collectionGroup('reviews').where('authorUid', '==', uid).get();
  const writer = db().bulkWriter();
  for (const r of reviews.docs) writer.update(r.ref, { authorUid: '', authorName: '' });
  await writer.close();
}
