/**
 * Burghood community channels (Phase 2).
 *
 * Posts, comments and reactions are written by members (see the rules);
 * these functions keep the counts and previews, and send pushes:
 * - @mentions go to the mentioned members even in muted channels, unless
 *   they turned off Interaction notifications or @mentions.
 * - Comments and replies go to the post's (or comment's) author, unless
 *   the channel is muted for them or Interaction notifications are off.
 * - Reactions are bundled: the first one starts a short timer, and when it
 *   fires the author gets one push for all of them ("5 people reacted").
 */
import './options';

import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { getFunctions } from 'firebase-admin/functions';
import { getStorage } from 'firebase-admin/storage';
import { logger } from 'firebase-functions/v2';
import { onDocumentCreated, onDocumentDeleted, onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onTaskDispatched } from 'firebase-functions/v2/tasks';

import { notifyUsers } from './notify';

const db = () => getFirestore();

/** Seconds a reaction digest waits before sending, so reactions bundle. */
export const digestDelaySeconds = () => {
  const s = Number(process.env.REACTION_DIGEST_SECONDS);
  if (Number.isFinite(s) && s >= 0) return s;
  return process.env.FUNCTIONS_EMULATOR === 'true' ? 3 : 120;
};

const snippet = (text: unknown, max = 80) => {
  const t = String(text ?? '').replace(/\s+/g, ' ').trim();
  return t.length > max ? `${t.slice(0, max - 1)}…` : t;
};

/** True when [member] has muted [channelId] right now. */
export function isMuted(mutes: unknown, channelId: string, now = Date.now()): boolean {
  const until = (mutes as Record<string, unknown> | undefined)?.[channelId];
  if (until === 'always') return true;
  const ms = (until as { toMillis?: () => number } | undefined)?.toMillis?.();
  return typeof ms === 'number' && ms > now;
}

/** Approved members among [uids], without anyone who muted the channel. */
async function unmutedMembers(sid: string, channelId: string, uids: Iterable<string>): Promise<string[]> {
  const out: string[] = [];
  for (const uid of new Set(uids)) {
    const m = await db().collection('societies').doc(sid).collection('members').doc(uid).get();
    if (m.get('status') === 'approved' && !isMuted(m.get('mutes'), channelId)) out.push(uid);
  }
  return out;
}

/** Approved members among [uids]. */
async function approvedMembers(sid: string, uids: Iterable<string>): Promise<string[]> {
  const out: string[] = [];
  for (const uid of new Set(uids)) {
    const m = await db().collection('societies').doc(sid).collection('members').doc(uid).get();
    if (m.get('status') === 'approved') out.push(uid);
  }
  return out;
}

const mentionList = (v: unknown) => (Array.isArray(v) ? v.filter((x): x is string => typeof x === 'string') : []);

/** Creates the General channel if the society doesn't have one yet. */
export async function ensureGeneralChannel(sid: string) {
  const ref = db().collection('societies').doc(sid).collection('channels').doc('general');
  await ref.create({ name: 'General', createdBy: 'system', archived: false, createdAt: FieldValue.serverTimestamp() })
    .catch(() => undefined); // Already there.
}

/**
 * onPostWritten: keeps the channel's post count and last-post preview,
 * pushes @mentions in new posts, and removes a deleted post's photos,
 * comments and reactions.
 */
export const onPostWritten = onDocumentWritten(
  'societies/{sid}/channels/{cid}/posts/{pid}',
  async (event) => {
    const { sid, cid, pid } = event.params;
    const before = event.data?.before;
    const after = event.data?.after;
    const channel = db().collection('societies').doc(sid).collection('channels').doc(cid);

    if (!before?.exists && after?.exists) {
      await channel.update({
        postCount: FieldValue.increment(1),
        lastPostAt: after.get('createdAt') ?? FieldValue.serverTimestamp(),
        lastPostText: snippet(after.get('text')) || '📷 Photo',
        lastPostAuthor: after.get('authorName') ?? '',
      });
      const author = after.get('authorUid') as string;
      const mentioned = mentionList(after.get('mentions')).filter((u) => u !== author);
      if (mentioned.length) {
        const [society, ch] = await Promise.all([db().collection('societies').doc(sid).get(), channel.get()]);
        await notifyUsers(await approvedMembers(sid, mentioned), {
          kind: 'mention',
          title: `${after.get('authorName') || 'A neighbor'} mentioned you in #${ch.get('name') ?? cid}`,
          body: snippet(after.get('text'), 140) || `${society.get('name') ?? ''}`,
          societyId: sid,
          channelId: cid,
          postId: pid,
        }, `mention_${pid}`);
      }
      return;
    }

    if (before?.exists && !after?.exists) {
      await channel.update({ postCount: FieldValue.increment(-1) }).catch(() => undefined);
      await getStorage()
        .bucket()
        .deleteFiles({ prefix: `societies/${sid}/posts/${pid}/` })
        .catch((e) => logger.warn('post photo delete failed', { pid, e }));
      // The post is gone; this removes its comments and reactions.
      await db().recursiveDelete(before.ref);
    }
  },
);

/**
 * onCommentWritten: keeps the post's comment count, and on a new comment
 * tells the post's author (or, for a reply, the comment's author) and
 * anyone @mentioned.
 */
export const onCommentWritten = onDocumentWritten(
  'societies/{sid}/channels/{cid}/posts/{pid}/comments/{commentId}',
  async (event) => {
    const { sid, cid, pid, commentId } = event.params;
    const before = event.data?.before;
    const after = event.data?.after;
    const post = db().collection('societies').doc(sid).collection('channels').doc(cid).collection('posts').doc(pid);
    if (before?.exists === after?.exists) return; // An edit.
    if (!after?.exists) {
      await post.update({ commentCount: FieldValue.increment(-1) }).catch(() => undefined);
      await db().recursiveDelete(before!.ref);
      return;
    }

    const postSnap = await post.get();
    if (!postSnap.exists) return;
    await post.update({ commentCount: FieldValue.increment(1) });

    const author = after.get('authorUid') as string;
    const who = (after.get('authorName') as string) || 'A neighbor';
    const text = snippet(after.get('text'), 140);
    const target = { societyId: sid, channelId: cid, postId: pid };

    const replyTo = after.get('replyTo') as string | null;
    const parent = replyTo ? await post.collection('comments').doc(replyTo).get() : undefined;
    const recipients = new Set<string>([postSnap.get('authorUid') as string]);
    if (parent?.exists) recipients.add(parent.get('authorUid') as string);
    recipients.delete(author);

    const mentioned = mentionList(after.get('mentions')).filter((u) => u !== author);
    for (const u of mentioned) recipients.delete(u); // They get the mention instead.

    await notifyUsers(await unmutedMembers(sid, cid, recipients), {
      kind: 'interaction',
      title: parent?.exists ? `${who} replied to your comment` : `${who} commented on your post`,
      body: text,
      ...target,
    }, `comment_${commentId}`);
    if (mentioned.length) {
      await notifyUsers(await approvedMembers(sid, mentioned), {
        kind: 'mention',
        title: `${who} mentioned you in a comment`,
        body: text,
        ...target,
      }, `mention_${commentId}`);
    }
  },
);

/** Reaction digests live at societies/{sid}/digests/{postId[_commentId]}. */
const digestRef = (sid: string, key: string) => db().collection('societies').doc(sid).collection('digests').doc(key);

/**
 * Updates the reaction count on [target] and, for a new reaction, counts
 * it toward the author's next digest, scheduling one if none is pending.
 */
async function reactionChanged(
  target: FirebaseFirestore.DocumentReference,
  before: FirebaseFirestore.DocumentSnapshot | undefined,
  after: FirebaseFirestore.DocumentSnapshot | undefined,
  digest: { sid: string; cid: string; pid: string; commentId?: string; reactor: string },
) {
  const was = before?.exists ? (before.get('emoji') as string) : undefined;
  const now = after?.exists ? (after.get('emoji') as string) : undefined;
  if (was === now) return;
  const counts: Record<string, FieldValue> = {};
  if (was) counts[`reactionCounts.${was}`] = FieldValue.increment(-1);
  if (now) counts[`reactionCounts.${now}`] = FieldValue.increment(1);
  const snap = await target.get();
  if (!snap.exists) return;
  await target.update(counts);
  if (was || !now) return; // Only new reactions count toward a push.

  const author = snap.get('authorUid') as string;
  if (author === digest.reactor) return;
  const key = digest.commentId ? `${digest.pid}_${digest.commentId}` : digest.pid;
  const schedule = await db().runTransaction(async (tx) => {
    const d = await tx.get(digestRef(digest.sid, key));
    tx.set(digestRef(digest.sid, key), {
      author,
      channelId: digest.cid,
      postId: digest.pid,
      commentId: digest.commentId ?? null,
      pending: FieldValue.increment(1),
      lastReactor: digest.reactor,
      lastEmoji: now,
      scheduled: true,
    }, { merge: true });
    return d.get('scheduled') !== true;
  });
  if (!schedule) return;
  await getFunctions()
    .taskQueue('locations/us-east1/functions/sendReactionDigest')
    .enqueue({ sid: digest.sid, key }, { scheduleDelaySeconds: digestDelaySeconds() });
}

export const onPostReactionWritten = onDocumentWritten(
  'societies/{sid}/channels/{cid}/posts/{pid}/reactions/{uid}',
  async (event) => {
    const { sid, cid, pid, uid } = event.params;
    const post = db().collection('societies').doc(sid).collection('channels').doc(cid).collection('posts').doc(pid);
    await reactionChanged(post, event.data?.before, event.data?.after, { sid, cid, pid, reactor: uid });
  },
);

export const onCommentReactionWritten = onDocumentWritten(
  'societies/{sid}/channels/{cid}/posts/{pid}/comments/{commentId}/reactions/{uid}',
  async (event) => {
    const { sid, cid, pid, commentId, uid } = event.params;
    const comment = db()
      .collection('societies').doc(sid).collection('channels').doc(cid)
      .collection('posts').doc(pid).collection('comments').doc(commentId);
    await reactionChanged(comment, event.data?.before, event.data?.after, { sid, cid, pid, commentId, reactor: uid });
  },
);

/**
 * sendReactionDigest: one push for the reactions collected since the
 * timer started ("Ann reacted 👍" or "5 people reacted to your post").
 */
export const sendReactionDigest = onTaskDispatched(
  { retryConfig: { maxAttempts: 3, minBackoffSeconds: 10 }, rateLimits: { maxConcurrentDispatches: 6 } },
  async (req) => {
    const { sid, key } = req.data as { sid: string; key: string };
    const ref = digestRef(sid, key);
    const d = await db().runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (!snap.exists) return undefined;
      tx.update(ref, { pending: 0, scheduled: false });
      return snap.data();
    });
    const count = Number(d?.pending ?? 0);
    if (!d || count <= 0) return;
    const [recipient] = await unmutedMembers(sid, d.channelId, [d.author]);
    if (!recipient) return;
    const what = d.commentId ? 'comment' : 'post';
    let title = `${count} people reacted to your ${what}`;
    if (count === 1) {
      const m = await db().collection('societies').doc(sid).collection('members').doc(d.lastReactor).get();
      title = `${(m.get('displayName') as string) || 'A neighbor'} reacted ${d.lastEmoji} to your ${what}`;
    }
    const target = db().collection('societies').doc(sid).collection('channels').doc(d.channelId)
      .collection('posts').doc(d.postId);
    const text = (await (d.commentId ? target.collection('comments').doc(d.commentId) : target).get()).get('text');
    await notifyUsers([recipient], {
      kind: 'interaction',
      title,
      body: snippet(text, 140),
      societyId: sid,
      channelId: d.channelId,
      postId: d.postId,
    }, `digest_${key}_${req.id ?? Date.now()}`);
  },
);

/** A new society's General channel. */
export const onSocietyCreated = onDocumentCreated('societies/{sid}', async (event) => {
  await ensureGeneralChannel(event.params.sid);
});

/** Removes a deleted channel's posts (channels are archived, not deleted,
 * from the app; this covers console clean-up). */
export const onChannelDeleted = onDocumentDeleted('societies/{sid}/channels/{cid}', async (event) => {
  if (event.data) await db().recursiveDelete(event.data.ref);
});
