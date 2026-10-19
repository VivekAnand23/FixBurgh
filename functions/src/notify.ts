/**
 * Push notifications (BRD FR-NTF-02, 04 to 06).
 *
 * Every notification is first recorded in `users/{uid}/notifications`, in
 * a transaction with the person's daily counter, so retries never send
 * twice and nobody gets more than DAILY_LIMIT a day. Then it goes to each
 * of their devices through FCM.
 */
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { logger } from 'firebase-functions/v2';

import { METRES_PER_MILE, distanceM, neighborGeohashes } from './geo';

export const DAILY_LIMIT = 5;

/** `status`: reports you made or said "Me too" to. `nearby`: urgent
 * reports near a saved place. `test`: the settings screen's test button. */
export type NotificationKind = 'status' | 'nearby' | 'test';

export interface Notice {
  kind: NotificationKind;
  title: string;
  body: string;
  reportId?: string;
}

const CATEGORY: Record<string, string> = {
  pothole: 'pothole',
  landslide: 'landslide',
  flooding: 'flooding or blocked drain',
  streetlight: 'streetlight',
  dumping: 'illegal dumping',
  fallen_tree: 'fallen tree',
  sidewalk: 'sidewalk problem',
  other: 'problem',
};

export const categoryLabel = (id: unknown) =>
  CATEGORY[typeof id === 'string' ? id : 'other'] ?? 'problem';

/** True when [now] falls in the person's quiet hours. */
export function inQuietHours(
  quiet: { start?: unknown; end?: unknown; enabled?: unknown } | undefined,
  utcOffsetMinutes: unknown,
  now = new Date(),
): boolean {
  if (!quiet || quiet.enabled !== true) return false;
  const start = Number(quiet.start), end = Number(quiet.end);
  if (!Number.isFinite(start) || !Number.isFinite(end) || start === end) return false;
  const offset = Number.isFinite(Number(utcOffsetMinutes)) ? Number(utcOffsetMinutes) : 0;
  const minute = (((now.getUTCHours() * 60 + now.getUTCMinutes() + offset) % 1440) + 1440) % 1440;
  return start < end ? minute >= start && minute < end : minute >= start || minute < end;
}

const utcDay = (d = new Date()) => `${d.getUTCFullYear()}-${d.getUTCMonth() + 1}-${d.getUTCDate()}`;

/**
 * Sends [notice] to each of [uids] that wants it. [key] identifies the
 * triggering event so a retried function sends once.
 */
export async function notifyUsers(uids: Iterable<string>, notice: Notice, key: string) {
  const db = getFirestore();
  const sent: string[] = [];
  for (const uid of new Set(uids)) {
    if (!uid) continue;
    const userRef = db.collection('users').doc(uid);
    const user = (await userRef.get()).data() ?? {};
    const prefs = (user.notify ?? {}) as Record<string, unknown>;
    if (notice.kind !== 'test' && prefs[notice.kind] === false) continue;
    if (notice.kind !== 'test' && inQuietHours(user.quietHours, user.utcOffsetMinutes)) continue;

    const recordRef = userRef.collection('notifications').doc(`${key}_${uid}`.slice(0, 1400));
    const counterRef = db.collection('notifyLimits').doc(uid);
    const allowed = await db.runTransaction(async (tx) => {
      const [record, counter] = await Promise.all([tx.get(recordRef), tx.get(counterRef)]);
      if (record.exists) return false;
      const day = utcDay();
      const count = counter.get('day') === day ? Number(counter.get('count') ?? 0) : 0;
      if (count >= DAILY_LIMIT) return false;
      tx.set(counterRef, { day, count: count + 1 });
      tx.create(recordRef, {
        kind: notice.kind,
        title: notice.title,
        body: notice.body,
        reportId: notice.reportId ?? null,
        at: FieldValue.serverTimestamp(),
      });
      return true;
    });
    if (!allowed) continue;
    sent.push(uid);
    await sendToDevices(uid, notice);
  }
  return sent;
}

async function sendToDevices(uid: string, notice: Notice) {
  const devices = await getFirestore().collection('users').doc(uid).collection('devices').get();
  const tokens = devices.docs.map((d) => d.get('token')).filter((t): t is string => typeof t === 'string');
  if (tokens.length === 0) return;
  try {
    const res = await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title: notice.title, body: notice.body },
      data: { kind: notice.kind, ...(notice.reportId ? { reportId: notice.reportId } : {}) },
      android: { priority: notice.kind === 'nearby' ? 'high' : 'normal' },
      apns: { payload: { aps: { sound: 'default' } } },
    });
    // Forget devices whose app was uninstalled or whose token expired.
    await Promise.all(
      res.responses.map((r, i) => {
        const code = r.error?.code ?? '';
        if (code === 'messaging/registration-token-not-registered' || code === 'messaging/invalid-argument' || code === 'messaging/invalid-registration-token') {
          return devices.docs[i].ref.delete();
        }
        return undefined;
      }),
    );
  } catch (e) {
    // Delivery is best effort; the record above still shows it in the app.
    logger.warn('FCM send failed', { uid, e });
  }
}

/** Owners of saved places whose alert radius covers the point (FR-NTF-04). */
export async function placeOwnersNear(lat: number, lng: number): Promise<string[]> {
  // Precision-5 cells are about 4.9 km wide; with their neighbours they
  // cover the largest radius (2 miles = 3.2 km).
  const places = getFirestore().collectionGroup('places');
  const snaps = await Promise.all(
    neighborGeohashes(lat, lng, 5).map((cell) =>
      places.where('geohash', '>=', cell).where('geohash', '<', `${cell}~`).get(),
    ),
  );
  const owners = new Set<string>();
  for (const doc of snaps.flatMap((s) => s.docs)) {
    const radius = Number(doc.get('radiusMiles')) * METRES_PER_MILE;
    const pLat = Number(doc.get('lat')), pLng = Number(doc.get('lng'));
    if (!Number.isFinite(radius) || !Number.isFinite(pLat) || !Number.isFinite(pLng)) continue;
    const owner = doc.ref.parent.parent?.id;
    if (owner && distanceM(lat, lng, pLat, pLng) <= radius) owners.add(owner);
  }
  return [...owners];
}
