/**
 * Burghood societies (Phase 1).
 *
 * A society exists only once a platform admin has checked its first
 * admin's claim (photo ID and proof of office). Residents then join by
 * request, which a society admin approves, or instantly with an invite
 * code. Notices from admins and committee members go to every member.
 */
import './options';

import { randomInt } from 'node:crypto';

import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { logger } from 'firebase-functions/v2';
import { onDocumentCreated, onDocumentWritten } from 'firebase-functions/v2/firestore';
import { CallableRequest, HttpsError, onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import { distanceM, neighborGeohashes } from './geo';
import { notifyUsers } from './notify';

/** Days a decided claim keeps its ID and proof-of-office files. Set
 * CLAIM_FILE_RETENTION_DAYS in the functions' environment to change it. */
const retentionDays = () => {
  const days = Number(process.env.CLAIM_FILE_RETENTION_DAYS);
  return Number.isFinite(days) && days >= 0 ? days : 30;
};

/** Societies this close to a new one count as possible duplicates. */
export const NEARBY_M = 200;

/** No 0/O or 1/I/L, so codes survive being read aloud. */
const CODE_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
const CODE_LENGTH = 8;

export function newInviteCode(): string {
  let code = '';
  for (let i = 0; i < CODE_LENGTH; i++) code += CODE_ALPHABET[randomInt(CODE_ALPHABET.length)];
  return code;
}

/** Upper case without spaces or dashes, as people type codes. */
export const normalizeCode = (code: unknown) =>
  typeof code === 'string' ? code.toUpperCase().replace(/[^A-Z0-9]/g, '') : '';

function requirePlatformAdmin(request: CallableRequest) {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first.');
  if (request.auth.token.platformAdmin !== true) {
    throw new HttpsError('permission-denied', 'Platform admins only.');
  }
  return { uid: request.auth.uid, email: (request.auth.token.email as string | undefined) ?? '' };
}

function requireFullAccount(request: CallableRequest) {
  const auth = request.auth;
  if (!auth) throw new HttpsError('unauthenticated', 'Sign in first.');
  if (auth.token.firebase?.sign_in_provider === 'anonymous') {
    throw new HttpsError('permission-denied', 'Sign in to an account first.');
  }
  return auth;
}

const db = () => getFirestore();
const audit = (claimId: string) => db().collection('societyClaims').doc(claimId).collection('audit');

/** Picks an invite code nobody uses yet, inside [tx]. */
async function freeCode(tx: FirebaseFirestore.Transaction): Promise<string> {
  for (let i = 0; i < 5; i++) {
    const code = newInviteCode();
    if (!(await tx.get(db().collection('inviteCodes').doc(code))).exists) return code;
  }
  throw new HttpsError('aborted', 'Try again.');
}

/**
 * decideClaim: a platform admin approves or rejects a society claim from
 * the web console. Approving creates the society (active and verified),
 * its HOA links and invite code, and makes the applicant its admin and
 * first member. Either way the decision goes in the claim's audit trail.
 */
export const decideClaim = onCall(async (request) => {
  const admin = requirePlatformAdmin(request);
  const claimId = request.data?.claimId;
  const decision = request.data?.decision;
  const reason = typeof request.data?.reason === 'string' ? request.data.reason.trim() : '';
  if (typeof claimId !== 'string' || !claimId) {
    throw new HttpsError('invalid-argument', 'claimId is required.');
  }
  if (decision !== 'approve' && decision !== 'reject') {
    throw new HttpsError('invalid-argument', "decision must be 'approve' or 'reject'.");
  }
  if (decision === 'reject' && !reason) {
    throw new HttpsError('invalid-argument', 'Say why the claim was rejected.');
  }
  if (reason.length > 500) throw new HttpsError('invalid-argument', 'Reason is too long.');

  const claimRef = db().collection('societyClaims').doc(claimId);
  const result = await db().runTransaction(async (tx) => {
    const claim = await tx.get(claimRef);
    if (!claim.exists) throw new HttpsError('not-found', 'No such claim.');
    if (claim.get('status') !== 'pending') {
      throw new HttpsError('failed-precondition', 'This claim was already decided.');
    }
    const decided = {
      decidedBy: admin.uid,
      decidedByEmail: admin.email,
      decidedAt: FieldValue.serverTimestamp(),
      reason,
    };
    const event = { by: admin.uid, byEmail: admin.email, at: FieldValue.serverTimestamp(), reason };

    if (decision === 'reject') {
      tx.update(claimRef, { status: 'rejected', ...decided });
      tx.create(audit(claimId).doc(), { action: 'rejected', ...event });
      return { societyId: null as string | null, applicant: claim.get('applicantUid') as string };
    }

    const code = await freeCode(tx);
    const s = claim.get('society');
    const applicant = claim.get('applicantUid') as string;
    const society = db().collection('societies').doc();
    tx.create(society, {
      name: s.name,
      nameLower: String(s.name).toLowerCase(),
      address: s.address,
      lat: s.lat,
      lng: s.lng,
      geohash: s.geohash,
      municipalityId: s.municipalityId,
      municipalityName: s.municipalityName,
      units: s.units,
      status: 'active',
      verified: true,
      claimId,
      adminUids: [applicant],
      memberCount: 1,
      pendingCount: 0,
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.create(society.collection('members').doc(applicant), {
      uid: applicant,
      unit: '',
      displayName: claim.get('applicantName') ?? '',
      role: 'admin',
      status: 'approved',
      position: claim.get('position'),
      requestedAt: claim.get('createdAt'),
      decidedAt: FieldValue.serverTimestamp(),
      decidedBy: admin.uid,
    });
    const hoa = claim.get('hoa') ?? {};
    tx.create(society.collection('hoa').doc('info'), {
      company: hoa.company ?? '',
      website: hoa.website ?? '',
      accountUrl: hoa.accountUrl ?? '',
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.create(society.collection('private').doc('invite'), { code, updatedAt: FieldValue.serverTimestamp() });
    tx.create(db().collection('inviteCodes').doc(code), { societyId: society.id });
    tx.update(claimRef, { status: 'approved', societyId: society.id, ...decided });
    tx.create(audit(claimId).doc(), { action: 'approved', societyId: society.id, ...event });
    return { societyId: society.id, applicant };
  });

  const name = (await claimRef.get()).get('society.name') as string;
  await notifyUsers(
    [result.applicant],
    result.societyId
      ? { kind: 'society', title: `${name} is live on Burghood`, body: 'You are its admin. Invite your neighbors to join.', societyId: result.societyId }
      : { kind: 'society', title: `We couldn't verify ${name}`, body: reason, claimId },
    `claim_${claimId}`,
  );
  return { status: result.societyId ? 'approved' : 'rejected', societyId: result.societyId };
});

/**
 * getClaimFile: hands a platform admin one claim file (the photo ID or the
 * proof of office) as base64, so the console never holds a lasting link to
 * it. Each view is recorded in the audit trail.
 */
export const getClaimFile = onCall(async (request) => {
  const admin = requirePlatformAdmin(request);
  const { claimId, which } = request.data ?? {};
  if (typeof claimId !== 'string' || (which !== 'id' && which !== 'proof')) {
    throw new HttpsError('invalid-argument', "claimId and which ('id' or 'proof') are required.");
  }
  const claim = await db().collection('societyClaims').doc(claimId).get();
  if (!claim.exists) throw new HttpsError('not-found', 'No such claim.');
  if (claim.get('filesDeletedAt')) throw new HttpsError('not-found', 'The files have been deleted.');
  const path = claim.get(`files.${which}`) as string | undefined;
  const prefix = `societyClaims/${claim.get('applicantUid')}/${claimId}/`;
  if (!path || !path.startsWith(prefix)) throw new HttpsError('not-found', 'No such file.');
  const file = getStorage().bucket().file(path);
  const [exists] = await file.exists();
  if (!exists) throw new HttpsError('not-found', 'The file was not uploaded.');
  const [[data], [meta]] = await Promise.all([file.download(), file.getMetadata()]);
  await audit(claimId).add({
    action: 'viewed_file',
    file: which,
    by: admin.uid,
    byEmail: admin.email,
    at: FieldValue.serverTimestamp(),
  });
  // Uploads are limited to these types by the Storage rules.
  const byExtension: Record<string, string> = { jpg: 'image/jpeg', png: 'image/png', pdf: 'application/pdf' };
  const stored = meta.contentType && meta.contentType !== 'application/octet-stream' ? meta.contentType : undefined;
  const contentType = stored ?? byExtension[path.split('.').pop() ?? ''] ?? 'application/octet-stream';
  return { contentType, data: data.toString('base64') };
});

/**
 * Deletes the ID and proof-of-office files of claims decided more than
 * [retentionDays] ago. Returns the claims it cleaned up.
 */
export async function purgeDecidedClaimFiles(retentionDays: number, now = Date.now()): Promise<string[]> {
  const cutoff = Timestamp.fromMillis(now - retentionDays * 24 * 3600 * 1000);
  const claims = await db()
    .collection('societyClaims')
    .where('status', 'in', ['approved', 'rejected'])
    .where('decidedAt', '<=', cutoff)
    .get();
  const bucket = getStorage().bucket();
  const purged: string[] = [];
  for (const claim of claims.docs) {
    if (claim.get('filesDeletedAt')) continue;
    const prefix = `societyClaims/${claim.get('applicantUid')}/${claim.id}/`;
    await bucket.deleteFiles({ prefix }).catch((e) => logger.warn('claim file delete failed', { prefix, e }));
    await claim.ref.update({ filesDeletedAt: FieldValue.serverTimestamp() });
    await audit(claim.id).add({ action: 'files_deleted', by: 'system', at: FieldValue.serverTimestamp(), reason: '' });
    purged.push(claim.id);
  }
  return purged;
}

/** purgeClaimFiles: daily clean-up of decided claims' files. */
export const purgeClaimFiles = onSchedule('every day 03:00', async () => {
  const purged = await purgeDecidedClaimFiles(retentionDays());
  logger.info('claim files deleted', { count: purged.length });
});

/**
 * purgeClaimFilesNow: runs the same clean-up on demand, for platform
 * admins (and the emulator tests). [retentionDays] defaults to the
 * configured window and can't be shorter than it outside the emulator.
 */
export const purgeClaimFilesNow = onCall(async (request) => {
  requirePlatformAdmin(request);
  const configured = retentionDays();
  const asked = Number(request.data?.retentionDays);
  const emulator = process.env.FUNCTIONS_EMULATOR === 'true';
  const days = Number.isFinite(asked) && (emulator || asked >= configured) ? asked : configured;
  return { purged: await purgeDecidedClaimFiles(days) };
});

/**
 * checkSocietyDuplicates: active societies and pending claims within
 * NEARBY_M of a point, so the create form can warn before a duplicate.
 * Pending claims are private, so only their name and distance come back.
 */
export const checkSocietyDuplicates = onCall(async (request) => {
  requireFullAccount(request);
  const lat = Number(request.data?.lat), lng = Number(request.data?.lng);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    throw new HttpsError('invalid-argument', 'lat and lng are required.');
  }
  // Precision-6 cells are about 1.2 by 0.6 km, so with their neighbours
  // they cover the whole radius.
  const cells = neighborGeohashes(lat, lng, 6);
  const range = <T extends FirebaseFirestore.Query>(q: T, field: string, cell: string) =>
    q.where(field, '>=', cell).where(field, '<', `${cell}~`);
  const [societies, claims] = await Promise.all([
    Promise.all(cells.map((c) => range(db().collection('societies').where('status', '==', 'active'), 'geohash', c).get())),
    Promise.all(cells.map((c) => range(db().collection('societyClaims').where('status', '==', 'pending'), 'society.geohash', c).get())),
  ]);
  const near: { name: string; status: 'active' | 'pending'; distanceM: number; societyId?: string }[] = [];
  for (const doc of societies.flatMap((s) => s.docs)) {
    const d = distanceM(lat, lng, doc.get('lat'), doc.get('lng'));
    if (d <= NEARBY_M) near.push({ name: doc.get('name'), status: 'active', distanceM: Math.round(d), societyId: doc.id });
  }
  for (const doc of claims.flatMap((s) => s.docs)) {
    const d = distanceM(lat, lng, doc.get('society.lat'), doc.get('society.lng'));
    if (d <= NEARBY_M) near.push({ name: doc.get('society.name'), status: 'pending', distanceM: Math.round(d) });
  }
  return { societies: near.sort((a, b) => a.distanceM - b.distanceM) };
});

/**
 * joinWithCode: joins a society straight away with its invite code,
 * skipping the admin's approval.
 */
export const joinWithCode = onCall(async (request) => {
  const auth = requireFullAccount(request);
  const code = normalizeCode(request.data?.code);
  const unit = typeof request.data?.unit === 'string' ? request.data.unit.trim().slice(0, 20) : '';
  if (code.length !== CODE_LENGTH) throw new HttpsError('invalid-argument', 'Invite codes have 8 characters.');
  const invite = await db().collection('inviteCodes').doc(code).get();
  if (!invite.exists) throw new HttpsError('not-found', 'That invite code is not valid.');
  const societyId = invite.get('societyId') as string;
  const society = db().collection('societies').doc(societyId);
  await db().runTransaction(async (tx) => {
    const [s, member] = await Promise.all([tx.get(society), tx.get(society.collection('members').doc(auth.uid))]);
    if (!s.exists || s.get('status') !== 'active') throw new HttpsError('not-found', 'That society is not active.');
    if (member.exists && member.get('status') === 'approved') return;
    tx.set(society.collection('members').doc(auth.uid), {
      uid: auth.uid,
      unit,
      displayName: ((auth.token.name as string | undefined) ?? '').slice(0, 60),
      role: 'member',
      status: 'approved',
      joinedWith: 'invite',
      requestedAt: FieldValue.serverTimestamp(),
      decidedAt: FieldValue.serverTimestamp(),
      decidedBy: 'invite',
    });
  });
  return { societyId };
});

/** regenerateInviteCode: a society admin replaces the invite code. */
export const regenerateInviteCode = onCall(async (request) => {
  const auth = requireFullAccount(request);
  const societyId = request.data?.societyId;
  if (typeof societyId !== 'string' || !societyId) {
    throw new HttpsError('invalid-argument', 'societyId is required.');
  }
  const society = db().collection('societies').doc(societyId);
  const code = await db().runTransaction(async (tx) => {
    const [member, current] = await Promise.all([
      tx.get(society.collection('members').doc(auth.uid)),
      tx.get(society.collection('private').doc('invite')),
    ]);
    if (member.get('status') !== 'approved' || member.get('role') !== 'admin') {
      throw new HttpsError('permission-denied', 'Society admins only.');
    }
    const next = await freeCode(tx);
    const old = current.get('code');
    if (typeof old === 'string') tx.delete(db().collection('inviteCodes').doc(old));
    tx.set(db().collection('inviteCodes').doc(next), { societyId });
    tx.set(society.collection('private').doc('invite'), { code: next, updatedAt: FieldValue.serverTimestamp() });
    return next;
  });
  return { code };
});

/**
 * onMemberWritten: keeps `users/{uid}.societyIds` and the society's member,
 * pending and admin lists in step with membership, and tells people about
 * join requests and decisions.
 */
export const onMemberWritten = onDocumentWritten('societies/{sid}/members/{uid}', async (event) => {
  const { sid, uid } = event.params;
  const before = event.data?.before;
  const after = event.data?.after;
  const was = before?.exists ? (before.get('status') as string) : undefined;
  const now = after?.exists ? (after.get('status') as string) : undefined;

  const society = db().collection('societies').doc(sid);
  const members = society.collection('members');
  const userRef = db().collection('users').doc(uid);
  if (now === 'approved') {
    await userRef.set({ societyIds: FieldValue.arrayUnion(sid) }, { merge: true });
  } else {
    // update, not set: a deleted account's profile must stay deleted.
    await userRef.update({ societyIds: FieldValue.arrayRemove(sid) }).catch(() => undefined);
  }
  const [approved, pending, admins, snap] = await Promise.all([
    members.where('status', '==', 'approved').count().get(),
    members.where('status', '==', 'pending').count().get(),
    members.where('status', '==', 'approved').where('role', '==', 'admin').get(),
    society.get(),
  ]);
  if (!snap.exists) return;
  await society.update({
    memberCount: approved.data().count,
    pendingCount: pending.data().count,
    adminUids: admins.docs.map((d) => d.id),
  });

  if (was === now) return;
  const name = snap.get('name') as string;
  const key = `member_${event.id}`;
  if (now === 'pending') {
    const who = (after?.get('displayName') as string) || 'A neighbor';
    const unit = after?.get('unit') ? ` (unit ${after.get('unit')})` : '';
    await notifyUsers(admins.docs.map((d) => d.id), {
      kind: 'society',
      title: `New request to join ${name}`,
      body: `${who}${unit} asked to join. Open Manage to approve.`,
      societyId: sid,
    }, key);
  } else if (now === 'approved' && was === 'pending') {
    await notifyUsers([uid], { kind: 'society', title: `You're in: ${name}`, body: 'Your request to join was approved.', societyId: sid }, key);
  } else if (now === 'declined' && was === 'pending') {
    await notifyUsers([uid], { kind: 'society', title: `${name} declined your request`, body: 'Ask the society admin if you think this is a mistake.' }, key);
  }
});

/** onNoticeCreated: sends a new notice to every approved member. */
export const onNoticeCreated = onDocumentCreated('societies/{sid}/notices/{noticeId}', async (event) => {
  const notice = event.data;
  if (!notice) return;
  const { sid, noticeId } = event.params;
  const society = db().collection('societies').doc(sid);
  const [snap, members] = await Promise.all([
    society.get(),
    society.collection('members').where('status', '==', 'approved').get(),
  ]);
  const author = notice.get('authorUid');
  const body = String(notice.get('body') ?? '');
  await notifyUsers(
    members.docs.map((d) => d.id).filter((u) => u !== author),
    {
      kind: 'notice',
      title: `${snap.get('name') ?? 'Your society'}: ${notice.get('title')}`,
      body: body.length > 140 ? `${body.slice(0, 139)}…` : body,
      societyId: sid,
      noticeId,
    },
    `notice_${noticeId}`,
  );
});

/**
 * Removes a deleted account's memberships, claims and claim files
 * (called from deleteAccount).
 */
export async function deleteSocietyData(uid: string) {
  const memberships = await db().collectionGroup('members').where('uid', '==', uid).get();
  for (const m of memberships.docs) await m.ref.delete();
  const claims = await db().collection('societyClaims').where('applicantUid', '==', uid).get();
  await getStorage()
    .bucket()
    .deleteFiles({ prefix: `societyClaims/${uid}/` })
    .catch((e) => logger.warn('claim file delete failed', { uid, e }));
  for (const c of claims.docs) await db().recursiveDelete(c.ref);
}

