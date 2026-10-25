/**
 * Burghood Phase 4: listing fees, sponsorships and the payments ledger.
 *
 * Payments happen outside the app. A platform admin records each one in
 * `payments` (append-only: the rules refuse edits and deletes, so a mistake
 * is corrected with a reversing entry). These functions keep providers'
 * listings and sponsorships in step with the ledger and the calendar.
 *
 * Everything here applies only while the `feature_monetisation` Remote
 * Config flag is on; with it off, approval makes a provider live as in
 * Phase 3.
 */
import './options';

import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { getRemoteConfig } from 'firebase-admin/remote-config';
import { logger } from 'firebase-functions/v2';
import { onDocumentCreated, onDocumentWritten } from 'firebase-functions/v2/firestore';
import { CallableRequest, HttpsError, onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import { addDays, listingPaidThrough, todayEt } from './listing';
import { notifyUsers } from './notify';

const db = () => getFirestore();

/** Placeholders until the fees are decided; admins change them in the
 * console (`config/monetisation`). */
export const DEFAULT_SETTINGS = {
  listingFeeUsd: 150,
  listingMonths: 12,
  sponsorshipWeeklyUsd: 25,
  maxSponsored: 2,
  reminderDays: 14,
  /** How to pay, shown to providers with each payment request. */
  paymentInstructions:
    'Pay by check to FixBurgh, or by bank transfer. Put your business name in the memo. ' +
    'Your profile goes live as soon as we record the payment.',
  /** An optional https payment link (e.g. a hosted checkout page). */
  payLink: '',
};
export type Settings = typeof DEFAULT_SETTINGS;

export async function settings(): Promise<Settings> {
  const d = (await db().collection('config').doc('monetisation').get()).data() ?? {};
  const out: Settings = { ...DEFAULT_SETTINGS };
  for (const k of Object.keys(out) as (keyof Settings)[]) {
    const v = d[k];
    if (typeof out[k] === 'number' && typeof v === 'number' && Number.isFinite(v)) (out as Record<string, unknown>)[k] = v;
    if (typeof out[k] === 'string' && typeof v === 'string') (out as Record<string, unknown>)[k] = v;
  }
  if (out.payLink && !isPayLink(out.payLink)) out.payLink = '';
  return out;
}

/** Payment links must be https. */
export const isPayLink = (v: unknown): v is string =>
  typeof v === 'string' && v.length <= 500 && /^https:\/\/[^\s]+$/.test(v);

/** A request to a provider for their listing fee, shown in the app. */
export type PaymentRequest = {
  amountUsd: number;
  periodMonths: number;
  instructions: string;
  payLink: string;
  dueDate: string | null;
  requestedAt: Date;
};

/** The default request, from the console's settings. */
export async function defaultPaymentRequest(today = todayEt()): Promise<PaymentRequest> {
  const s = await settings();
  return {
    amountUsd: s.listingFeeUsd,
    periodMonths: s.listingMonths,
    instructions: s.paymentInstructions,
    payLink: s.payLink,
    dueDate: addDays(today, 14),
    requestedAt: new Date(),
  };
}

let flagCache: { on: boolean; at: number } | undefined;

/**
 * The `feature_monetisation` flag. The emulator has no Remote Config, so
 * there it reads `config/monetisation.emulatorFlag` instead (tests set it).
 */
export async function monetisationOn(): Promise<boolean> {
  if (process.env.FUNCTIONS_EMULATOR === 'true') {
    return (await db().collection('config').doc('monetisation').get()).get('emulatorFlag') === true;
  }
  if (flagCache && Date.now() - flagCache.at < 60_000) return flagCache.on;
  try {
    const t = await getRemoteConfig().getTemplate();
    const v = t.parameters.feature_monetisation?.defaultValue;
    const on = !!v && 'value' in v && v.value === 'true';
    flagCache = { on, at: Date.now() };
    return on;
  } catch (e) {
    logger.warn('Remote Config read failed; treating monetisation as off', { e });
    return false;
  }
}

/** Payments of [kind] for [field] == [id], leaving out reversed ones and
 * the reversals themselves. */
async function standing(field: 'providerId' | 'sponsorshipId', id: string, kind: string) {
  const snap = await db().collection('payments').where(field, '==', id).get();
  const docs = snap.docs.filter((d) => d.get('kind') === kind);
  const reversed = new Set(docs.map((d) => d.get('reversalOf')).filter(Boolean));
  return docs.filter((d) => !d.get('reversalOf') && !reversed.has(d.id));
}

/**
 * Brings a provider's listing in line with the ledger and the date: an
 * approved provider whose listing ran out waits for the fee again; one
 * waiting whose fee is recorded goes live. Providers with no listing
 * payments at all (listed before fees started) are left as they are.
 */
export async function refreshListing(providerId: string, today = todayEt()) {
  const ref = db().collection('providers').doc(providerId);
  const pays = await standing('providerId', providerId, 'listing_fee');
  const through = listingPaidThrough(
    pays.map((d) => ({ date: d.get('date') as string, periodMonths: Number(d.get('periodMonths') ?? 12) })),
  );
  const on = await monetisationOn();
  const p = await ref.get();
  if (!p.exists) return null;
  const status = p.get('status') as string;
  const listing = p.get('listing') ?? {};
  const paid = through != null && through >= today;
  let next = status;
  if (on && status === 'awaiting_fee' && paid) next = 'approved';
  if (on && status === 'approved' && !paid && (through != null || listing.paidThrough != null)) next = 'awaiting_fee';
  if (next === status && (listing.paidThrough ?? null) === through) return { status, paidThrough: through };
  await ref.update({
    status: next,
    listing: { ...listing, paidThrough: through },
    ...(next === 'approved' && !p.get('liveAt') ? { liveAt: new Date() } : {}),
    // Paid: the request is done. Lapsed: ask again for the renewal.
    ...(paid ? { paymentRequest: FieldValue.delete() } : {}),
    ...(next === 'awaiting_fee' && status !== next ? { paymentRequest: await defaultPaymentRequest(today) } : {}),
  });
  const name = p.get('businessName') as string;
  if (next !== status) {
    const notice =
      next === 'approved'
        ? { title: `${name} is live on Burghood`, body: `Your listing runs until ${through}.` }
        : { title: `Your ${name} listing has ended`, body: 'Renew the listing fee to appear in search again.' };
    await notifyUsers([p.get('ownerUid')], { kind: 'service', ...notice }, `listing_${providerId}_${next}_${through}`);
  }
  return { status: next, paidThrough: through };
}

/**
 * A sponsorship shows while it is paid for and today is within its dates
 * (both inclusive).
 */
export async function refreshSponsorship(sponsorshipId: string, today = todayEt()) {
  const ref = db().collection('sponsorships').doc(sponsorshipId);
  const s = await ref.get();
  if (!s.exists) return null;
  const paid = (await standing('sponsorshipId', sponsorshipId, 'sponsorship')).length > 0;
  const start = s.get('startDate') as string;
  const end = s.get('endDate') as string;
  const active = paid && start <= today && today <= end;
  if (s.get('paid') !== paid || s.get('active') !== active) await ref.update({ paid, active });
  return { paid, active };
}

/** onPaymentCreated: a recorded fee (or its reversal) updates what it
 * paid for. */
export const onPaymentCreated = onDocumentCreated('payments/{id}', async (event) => {
  const d = event.data?.data();
  if (!d) return;
  if (d.kind === 'listing_fee' && typeof d.providerId === 'string') await refreshListing(d.providerId);
  if (d.kind === 'sponsorship' && typeof d.sponsorshipId === 'string') await refreshSponsorship(d.sponsorshipId);
});

/** onSponsorshipWritten: a new sponsorship, or one whose dates changed,
 * shows from today if it is paid and in its dates. Its own paid/active
 * updates are skipped, so they don't re-run with a different today. */
export const onSponsorshipWritten = onDocumentWritten('sponsorships/{id}', async (event) => {
  const before = event.data?.before;
  const after = event.data?.after;
  if (!after?.exists) return;
  if (before?.exists && before.get('startDate') === after.get('startDate')
      && before.get('endDate') === after.get('endDate')) return;
  await refreshSponsorship(event.params.id);
});

/** The daily pass: sponsorships on and off by date; listings that ran out
 * wait for the fee again; a reminder before a listing ends. */
export async function runDaily(today = todayEt()) {
  const out = { sponsorships: 0, listings: 0, reminders: 0 };
  const sponsorships = await db().collection('sponsorships').where('endDate', '>=', addDays(today, -1)).get();
  for (const s of sponsorships.docs) {
    const before = s.get('active');
    const r = await refreshSponsorship(s.id, today);
    if (r && r.active !== before) out.sponsorships++;
  }
  if (!(await monetisationOn())) return out;
  const { reminderDays } = await settings();
  const listed = await db().collection('providers').where('status', 'in', ['approved', 'awaiting_fee']).get();
  for (const p of listed.docs) {
    const through = p.get('listing.paidThrough') as string | undefined;
    if (!through) continue;
    const r = await refreshListing(p.id, today);
    if (r && r.status !== p.get('status')) out.listings++;
    if (r?.status === 'approved' && r.paidThrough && r.paidThrough <= addDays(today, reminderDays)
        && p.get('listing.remindedFor') !== r.paidThrough) {
      await notifyUsers([p.get('ownerUid')], {
        kind: 'service',
        title: `Your listing expires on ${r.paidThrough}`,
        body: 'Renew the listing fee to stay in search.',
      }, `listing_reminder_${p.id}_${r.paidThrough}`);
      await p.ref.update({ 'listing.remindedFor': r.paidThrough });
      out.reminders++;
    }
  }
  return out;
}

export const monetisationDaily = onSchedule(
  { schedule: 'every day 00:15', timeZone: 'America/New_York' },
  async () => {
    logger.info('monetisation daily pass', await runDaily());
  },
);

function requirePlatformAdmin(request: CallableRequest) {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first.');
  if (request.auth.token.platformAdmin !== true) {
    throw new HttpsError('permission-denied', 'Platform admins only.');
  }
}

/**
 * requestListingFee: a platform admin asks a provider for their listing fee
 * (or a renewal): amount, period, how to pay, an optional https payment link
 * and a due date. The provider sees it in the app and gets a push. Recording
 * the payment in the ledger clears it.
 */
export const requestListingFee = onCall(async (request) => {
  requirePlatformAdmin(request);
  const { providerId, amountUsd, periodMonths, instructions, payLink, dueDate } = request.data ?? {};
  if (
    typeof providerId !== 'string'
    || typeof amountUsd !== 'number' || !(amountUsd > 0) || amountUsd > 100_000
    || !Number.isInteger(periodMonths) || periodMonths < 1 || periodMonths > 36
    || typeof instructions !== 'string' || !instructions.trim() || instructions.length > 1000
    || !(payLink === '' || payLink == null || isPayLink(payLink))
    || !(dueDate == null || (typeof dueDate === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(dueDate)))
  ) {
    throw new HttpsError('invalid-argument', 'An amount, a period of 1 to 36 months, how to pay, and an https link if any.');
  }
  const ref = db().collection('providers').doc(providerId);
  const p = await ref.get();
  if (!p.exists) throw new HttpsError('not-found', 'No such provider.');
  if (!['awaiting_fee', 'approved'].includes(p.get('status'))) {
    throw new HttpsError('failed-precondition', 'Approve the provider first.');
  }
  const req: PaymentRequest = {
    amountUsd: Math.round(amountUsd * 100) / 100,
    periodMonths,
    instructions: instructions.trim(),
    payLink: payLink ?? '',
    dueDate: dueDate ?? null,
    requestedAt: new Date(),
  };
  await ref.update({ paymentRequest: req });
  await ref.collection('audit').add({
    action: 'payment_requested',
    reason: `$${req.amountUsd.toFixed(2)} for ${periodMonths} months${req.dueDate ? `, due ${req.dueDate}` : ''}`,
    by: request.auth!.uid,
    byEmail: (request.auth!.token.email as string | undefined) ?? '',
    at: new Date(),
  });
  await notifyUsers([p.get('ownerUid')], {
    kind: 'service',
    title: `Listing fee for ${p.get('businessName')}`,
    body: `$${req.amountUsd.toFixed(2)} for ${periodMonths} months${req.dueDate ? `, due ${req.dueDate}` : ''}. Open Burghood to see how to pay.`,
  }, `fee_request_${providerId}_${Date.now()}`);
  return { ok: true };
});

/** monetisationDailyNow: the daily pass on demand for platform admins. The
 * emulator also takes a `today` (YYYY-MM-DD) for tests. */
export const monetisationDailyNow = onCall(async (request) => {
  requirePlatformAdmin(request);
  const asked = request.data?.today;
  const today =
    process.env.FUNCTIONS_EMULATOR === 'true' && typeof asked === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(asked)
      ? asked
      : todayEt();
  return { today, ...(await runDaily(today)) };
});

/** What approval leads to: live, or waiting for the listing fee when fees
 * apply and none covers today. */
export async function approvedStatus(providerId: string) {
  if (!(await monetisationOn())) return 'approved';
  const pays = await standing('providerId', providerId, 'listing_fee');
  const through = listingPaidThrough(
    pays.map((d) => ({ date: d.get('date') as string, periodMonths: Number(d.get('periodMonths') ?? 12) })),
  );
  return through != null && through >= todayEt() ? 'approved' : 'awaiting_fee';
}

/** Removes a deleted provider's sponsorships. Their payments stay in the
 * ledger, which is a financial record. */
export async function deleteSponsorships(providerId: string) {
  const s = await db().collection('sponsorships').where('providerId', '==', providerId).get();
  await Promise.all(s.docs.map((d) => d.ref.delete()));
}
