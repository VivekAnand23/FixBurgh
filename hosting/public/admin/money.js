// Burghood admin console, Phase 4: settings for fees, the payments ledger,
// sponsorships and the audit report. Payments are recorded straight into
// Firestore; the rules let platform admins add entries but never change or
// delete them, so a mistake is corrected with a reversing entry.
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  where,
} from 'https://www.gstatic.com/firebasejs/11.10.0/firebase-firestore.js';

import { buildReport, COLUMNS, toCsv, usd } from './report.js?v=4';

const $ = (id) => document.getElementById(id);
let db;
let el;
let me;

const DEFAULTS = { listingFeeUsd: 150, listingMonths: 12, sponsorshipWeeklyUsd: 25, maxSponsored: 2, reminderDays: 14 };
let settings = { ...DEFAULTS };
let providers = [];

const today = () => new Intl.DateTimeFormat('en-CA', { timeZone: 'America/New_York' }).format(new Date());
const field = (label, input, hint) => el('label', {}, label, ' ', input, hint ? el('span', { class: 'meta' }, ` ${hint}`) : null);
const input = (attrs) => el('input', attrs);
const select = (id, options, value) =>
  el('select', { id }, options.map(([v, label]) => el('option', { value: v, selected: v === value }, label)));
const errorBox = () => el('p', { class: 'error', hidden: true });
const fail = (box, message) => {
  box.textContent = message;
  box.hidden = false;
};

/** Called once the console shows; [ctx] carries the shared helpers. */
export async function initMoney(ctx) {
  ({ db, el, user: me } = ctx);
  $('payments-refresh').onclick = () => loadMoney();
  $('report-run').onclick = () => runReport();
  const now = today();
  $('report-from').value = `${now.slice(0, 7)}-01`;
  $('report-to').value = now;
  await loadMoney();
}

export async function loadMoney() {
  try {
    const s = await getDoc(doc(db, 'config', 'monetisation'));
    settings = { ...DEFAULTS, ...(s.data() ?? {}) };
    const p = await getDocs(query(collection(db, 'providers'), where('status', 'in', ['approved', 'awaiting_fee', 'suspended'])));
    providers = p.docs.map((d) => ({ id: d.id, ...d.data() })).sort((a, b) => a.businessName.localeCompare(b.businessName));
    renderSettings();
    renderRecordForm();
    await Promise.all([loadLedger(), loadSponsorships()]);
  } catch (e) {
    $('ledger').replaceChildren(el('p', { class: 'error' }, `Couldn't load payments: ${e.message}`));
  }
}

// ---- Settings ----

function renderSettings() {
  const inputs = {
    listingFeeUsd: input({ type: 'number', min: 0, step: '0.01', value: settings.listingFeeUsd }),
    listingMonths: input({ type: 'number', min: 1, max: 36, step: 1, value: settings.listingMonths }),
    sponsorshipWeeklyUsd: input({ type: 'number', min: 0, step: '0.01', value: settings.sponsorshipWeeklyUsd }),
    maxSponsored: input({ type: 'number', min: 0, max: 2, step: 1, value: settings.maxSponsored }),
    reminderDays: input({ type: 'number', min: 0, max: 60, step: 1, value: settings.reminderDays }),
  };
  const error = errorBox();
  const saved = el('span', { class: 'meta', hidden: true }, ' Saved.');
  $('money-settings').replaceChildren(
    el('p', { class: 'meta' }, 'Placeholders until the amounts are decided. Changes apply to new payments and sponsorships.'),
    field('Listing fee (USD)', inputs.listingFeeUsd),
    field('Listing period (months)', inputs.listingMonths),
    field('Sponsorship price per week (USD)', inputs.sponsorshipWeeklyUsd),
    field('Sponsored listings per search', inputs.maxSponsored, '(at most 2)'),
    field('Renewal reminder (days before)', inputs.reminderDays),
    error,
    el(
      'button',
      {
        type: 'button',
        onclick: async () => {
          error.hidden = true;
          const next = {
            listingFeeUsd: Number(inputs.listingFeeUsd.value),
            listingMonths: Math.round(Number(inputs.listingMonths.value)),
            sponsorshipWeeklyUsd: Number(inputs.sponsorshipWeeklyUsd.value),
            maxSponsored: Math.round(Number(inputs.maxSponsored.value)),
            reminderDays: Math.round(Number(inputs.reminderDays.value)),
          };
          try {
            const current = (await getDoc(doc(db, 'config', 'monetisation'))).data() ?? {};
            await setDoc(doc(db, 'config', 'monetisation'), {
              ...('emulatorFlag' in current ? { emulatorFlag: current.emulatorFlag } : {}),
              ...next,
              updatedBy: me().uid,
              updatedAt: serverTimestamp(),
            });
            settings = { ...settings, ...next };
            saved.hidden = false;
            renderRecordForm();
          } catch (e) {
            fail(error, e.message);
          }
        },
      },
      'Save settings',
    ),
    saved,
  );
}

// ---- Record a payment ----

function renderRecordForm() {
  const kind = select('pay-kind', [['listing_fee', 'Listing fee'], ['sponsorship', 'Sponsorship'], ['other', 'Other']], 'listing_fee');
  const type = select('pay-type', [['income', 'Income'], ['expense', 'Expense']], 'income');
  const provider = select('pay-provider', [['', '(none)'], ...providers.map((p) => [p.id, `${p.businessName} (${p.status})`])], '');
  const sponsorship = el('select', { id: 'pay-sponsorship' });
  const party = input({ id: 'pay-party', maxlength: 120, placeholder: 'Who paid, or who was paid' });
  const amount = input({ id: 'pay-amount', type: 'number', min: '0.01', step: '0.01', value: settings.listingFeeUsd });
  const date = input({ id: 'pay-date', type: 'date', value: today() });
  const method = select('pay-method', [['check', 'Check'], ['cash', 'Cash'], ['bank_transfer', 'Bank transfer'], ['card', 'Card'], ['online', 'Online'], ['other', 'Other']], 'check');
  const reference = input({ id: 'pay-reference', maxlength: 100, placeholder: 'Check number, transaction ID…' });
  const purpose = input({ id: 'pay-purpose', maxlength: 300, value: `Listing fee, ${settings.listingMonths} months` });
  const months = input({ id: 'pay-months', type: 'number', min: 1, max: 36, step: 1, value: settings.listingMonths });
  const error = errorBox();
  const busy = el('p', { class: 'meta', hidden: true }, 'Saving…');

  const loadSponsorships = async (pid) => {
    const s = pid ? await getDocs(query(collection(db, 'sponsorships'), where('providerId', '==', pid))) : { docs: [] };
    sponsorship.replaceChildren(
      el('option', { value: '' }, '(choose)'),
      ...s.docs.map((d) => el('option', { value: d.id }, `${d.get('startDate')} to ${d.get('endDate')} · ${d.get('categories').join(', ')}`)),
    );
  };
  const sync = () => {
    const k = kind.value;
    type.disabled = k !== 'other';
    if (k !== 'other') type.value = 'income';
    months.closest('label').hidden = k !== 'listing_fee';
    sponsorship.closest('label').hidden = k !== 'sponsorship';
    const p = providers.find((x) => x.id === provider.value);
    if (p && !party.value) party.value = p.businessName;
  };
  kind.onchange = () => {
    if (kind.value === 'listing_fee') {
      amount.value = settings.listingFeeUsd;
      purpose.value = `Listing fee, ${months.value} months`;
    } else if (kind.value === 'sponsorship') {
      purpose.value = 'Sponsored listing';
    }
    sync();
  };
  provider.onchange = async () => {
    party.value = providers.find((x) => x.id === provider.value)?.businessName ?? '';
    await loadSponsorships(provider.value);
    sync();
  };

  const submit = el('button', { type: 'button', class: 'primary' }, 'Record payment');
  const actions = el('div', { class: 'actions' }, submit);
  submit.onclick = () => {
    error.hidden = true;
    const cents = Math.round(Number(amount.value) * 100);
    const k = kind.value;
    const problem =
      !(cents > 0) ? 'Enter an amount.'
        : !party.value.trim() ? 'Say who paid or was paid.'
          : !purpose.value.trim() ? 'Say what it pays for.'
            : !/^\d{4}-\d{2}-\d{2}$/.test(date.value) ? 'Pick a date.'
              : k === 'listing_fee' && !provider.value ? 'Pick the provider the listing fee is for.'
                : k === 'sponsorship' && !sponsorship.value ? 'Pick the sponsorship it pays for.'
                  : null;
    if (problem) return fail(error, problem);
    const entry = {
      type: k === 'other' ? type.value : 'income',
      kind: k,
      amountCents: cents,
      currency: 'USD',
      date: date.value,
      method: method.value,
      reference: reference.value.trim(),
      purpose: purpose.value.trim(),
      party: party.value.trim(),
      providerId: provider.value || null,
      sponsorshipId: k === 'sponsorship' ? sponsorship.value : null,
      periodMonths: k === 'listing_fee' ? Math.round(Number(months.value)) : null,
      recordedBy: me().uid,
      recordedByEmail: me().email ?? '',
      recordedAt: serverTimestamp(),
    };
    // Confirms in the page: a recorded payment can only be reversed.
    actions.replaceChildren(
      el('p', { class: 'confirm' }, `Record ${entry.type} of ${usd(cents)} from ${entry.party} on ${entry.date}? It can't be edited afterwards, only reversed.`),
      el('button', {
        type: 'button',
        class: 'primary',
        onclick: async () => {
          busy.hidden = false;
          try {
            await setDoc(doc(collection(db, 'payments')), entry);
            await loadMoney();
          } catch (e) {
            busy.hidden = true;
            fail(error, e.message);
            actions.replaceChildren(submit);
          }
        },
      }, 'Yes, record it'),
      el('button', { type: 'button', onclick: () => actions.replaceChildren(submit) }, 'Cancel'),
    );
  };

  $('record-payment').replaceChildren(
    field('Kind', kind),
    field('Type', type),
    field('Provider', provider),
    field('Sponsorship', sponsorship),
    field('Payer / payee', party),
    field('Amount (USD)', amount),
    field('Date', date),
    field('Method', method),
    field('Reference', reference),
    field('Purpose', purpose),
    field('Listing period (months)', months),
    error,
    actions,
    busy,
  );
  sync();
}

// ---- Ledger ----

async function loadLedger() {
  const snap = await getDocs(query(collection(db, 'payments'), orderBy('date', 'desc'), limit(100)));
  const entries = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
  const reversed = new Set(entries.filter((p) => p.reversalOf).map((p) => p.reversalOf));
  $('ledger').replaceChildren(
    entries.length
      ? el('div', { class: 'scroll' }, el(
          'table',
          { class: 'ledger' },
          el('tr', {}, ['Date', 'Type', 'Payer / payee', 'Amount', 'Method', 'Purpose', ''].map((h) => el('th', {}, h))),
          entries.map((p) =>
            el(
              'tr',
              { class: p.reversalOf || reversed.has(p.id) ? 'reversed' : '' },
              el('td', {}, p.date),
              el('td', {}, p.type),
              el('td', {}, p.party),
              el('td', { class: 'num' }, usd(p.reversalOf ? -p.amountCents : p.amountCents)),
              el('td', {}, p.method),
              el('td', {}, p.reversalOf ? `${p.purpose} (reverses ${p.reversalOf}: ${p.reason})` : p.purpose),
              el('td', {}, p.reversalOf || reversed.has(p.id) ? '' : reverseButton(p)),
            ),
          ),
        ))
      : el('p', { class: 'meta' }, 'No payments recorded yet.'),
  );
}

function reverseButton(p) {
  const cellBox = el('div', {});
  const start = () =>
    cellBox.replaceChildren(el('button', { type: 'button', class: 'danger', onclick: ask }, 'Reverse'));
  const ask = () => {
    const reason = input({ maxlength: 300, placeholder: 'Why (required)' });
    const error = errorBox();
    cellBox.replaceChildren(
      reason,
      el('button', {
        type: 'button',
        class: 'danger',
        onclick: async () => {
          if (!reason.value.trim()) return fail(error, 'Say why.');
          try {
            await setDoc(doc(db, 'payments', `rev_${p.id}`), {
              type: p.type,
              kind: p.kind,
              amountCents: p.amountCents,
              currency: 'USD',
              date: today(),
              method: p.method,
              reference: p.reference ?? '',
              purpose: `Reversal of ${p.purpose}`.slice(0, 300),
              party: p.party,
              providerId: p.providerId ?? null,
              sponsorshipId: p.sponsorshipId ?? null,
              periodMonths: p.periodMonths ?? null,
              reversalOf: p.id,
              reason: reason.value.trim(),
              recordedBy: me().uid,
              recordedByEmail: me().email ?? '',
              recordedAt: serverTimestamp(),
            });
            await loadMoney();
          } catch (e) {
            fail(error, e.message);
          }
        },
      }, `Yes, reverse ${usd(p.amountCents)}`),
      el('button', { type: 'button', onclick: start }, 'Cancel'),
      error,
    );
  };
  start();
  return cellBox;
}

// ---- Sponsorships ----

async function loadSponsorships() {
  const snap = await getDocs(query(collection(db, 'sponsorships'), orderBy('startDate', 'desc'), limit(100)));
  const now = today();
  $('sponsorship-list').replaceChildren(
    snap.empty
      ? el('p', { class: 'meta' }, 'No sponsorships yet.')
      : el(
          'div',
          { class: 'rows' },
          snap.docs.map((d) => {
            const s = d.data();
            const when = s.active ? 'Showing now' : s.endDate < now ? 'Ended' : s.startDate > now ? 'Scheduled' : 'Not showing';
            return el(
              'div',
              { class: 'row' },
              el('strong', {}, s.businessName),
              el('span', { class: 'meta' }, ` · ${s.categories.join(', ')} · ${s.area.label || 'area'} within ${s.area.radiusMiles} mi`),
              el('br'),
              el('span', { class: `pill ${s.active ? 'approved' : 'pending'}` }, when),
              el('span', { class: 'meta' }, ` ${s.startDate} to ${s.endDate} · ${s.paid ? 'paid' : 'not paid yet'}${s.priceUsd ? ` · price ${usd(Math.round(s.priceUsd * 100))}` : ''}`),
              s.paid
                ? null
                : el('button', {
                    type: 'button',
                    class: 'danger',
                    onclick: async () => {
                      await deleteDoc(doc(db, 'sponsorships', d.id));
                      await loadMoney();
                    },
                  }, 'Delete'),
            );
          }),
        ),
  );
  renderSponsorshipForm();
}

function renderSponsorshipForm() {
  const live = providers.filter((p) => p.status === 'approved');
  const provider = select('sp-provider', [['', '(choose a live provider)'], ...live.map((p) => [p.id, p.businessName])], '');
  const categories = input({ id: 'sp-categories', placeholder: 'plumbing, handyman' });
  const label = input({ id: 'sp-label', maxlength: 60 });
  const radius = input({ id: 'sp-radius', type: 'number', min: 1, max: 25, step: 1, value: 10 });
  const start = input({ id: 'sp-start', type: 'date', value: today() });
  const end = input({ id: 'sp-end', type: 'date' });
  const price = input({ id: 'sp-price', type: 'number', min: 0, step: '0.01' });
  const note = input({ id: 'sp-note', maxlength: 300 });
  const error = errorBox();
  const quote = () => {
    if (!start.value || !end.value) return;
    const days = (Date.parse(end.value) - Date.parse(start.value)) / 86_400_000 + 1;
    if (days > 0) price.value = (Math.ceil(days / 7) * settings.sponsorshipWeeklyUsd).toFixed(2);
  };
  start.onchange = quote;
  end.onchange = quote;
  provider.onchange = () => {
    const p = live.find((x) => x.id === provider.value);
    categories.value = p?.categories?.join(', ') ?? '';
    label.value = p?.serviceArea?.label ?? '';
  };
  $('sponsorship-form').replaceChildren(
    el('p', { class: 'meta' }, `Shows at the top of matching searches (up to ${settings.maxSponsored} per search) from the start date to the end date, once its payment is recorded.`),
    field('Provider', provider),
    field('Categories', categories, '(category ids, comma separated)'),
    field('Area label', label),
    field('Radius (mi)', radius, 'around the provider’s service area'),
    field('Start', start),
    field('End', end),
    field('Price (USD)', price, `(${usd(Math.round(settings.sponsorshipWeeklyUsd * 100))} a week)`),
    field('Note', note),
    error,
    el('button', {
      type: 'button',
      class: 'primary',
      onclick: async () => {
        error.hidden = true;
        const p = live.find((x) => x.id === provider.value);
        const cats = categories.value.split(',').map((c) => c.trim()).filter(Boolean);
        if (!p) return fail(error, 'Pick a live provider.');
        if (!cats.length) return fail(error, 'Add at least one category.');
        if (!start.value || !end.value || end.value < start.value) return fail(error, 'Pick a start and an end on or after it.');
        try {
          await setDoc(doc(collection(db, 'sponsorships')), {
            providerId: p.id,
            businessName: p.businessName,
            categories: cats,
            area: {
              lat: p.serviceArea.lat,
              lng: p.serviceArea.lng,
              radiusMiles: Math.round(Number(radius.value)),
              label: label.value.trim(),
            },
            startDate: start.value,
            endDate: end.value,
            priceUsd: Number(price.value) || 0,
            note: note.value.trim(),
            createdBy: me().uid,
            createdAt: serverTimestamp(),
          });
          await loadMoney();
        } catch (e) {
          fail(error, e.message);
        }
      },
    }, 'Schedule sponsorship'),
  );
}

// ---- Audit report ----

let lastReport;

async function runReport() {
  const from = $('report-from').value;
  const to = $('report-to').value;
  const out = $('report-body');
  if (!from || !to || to < from) {
    out.replaceChildren(el('p', { class: 'error' }, 'Pick a start and an end on or after it.'));
    return;
  }
  out.replaceChildren(el('p', { class: 'meta' }, 'Loading…'));
  try {
    // Reversals of entries in range may fall later; load them too for the
    // "Reversed by" column.
    const [inRange, reversals] = await Promise.all([
      getDocs(query(collection(db, 'payments'), where('date', '>=', from), where('date', '<=', to), orderBy('date'))),
      getDocs(query(collection(db, 'payments'), where('date', '>', to), orderBy('date'), limit(500))),
    ]);
    const entries = [...inRange.docs, ...reversals.docs].map((d) => ({ id: d.id, ...d.data() }));
    lastReport = buildReport(entries, { from, to });
    renderReport(lastReport);
  } catch (e) {
    out.replaceChildren(el('p', { class: 'error' }, `Couldn't load the report: ${e.message}`));
  }
}

function renderReport(r) {
  const download = () => {
    const url = URL.createObjectURL(new Blob([toCsv(r)], { type: 'text/csv' }));
    const a = el('a', { href: url, download: `burghood-audit-${r.from}-to-${r.to}.csv` });
    document.body.append(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  };
  $('report-body').replaceChildren(
    el('div', { class: 'actions no-print' },
      el('button', { type: 'button', onclick: download }, 'Download CSV'),
      el('button', { type: 'button', onclick: () => printReport() }, 'Print or save as PDF'),
    ),
    el('div', { id: 'report-print' },
      el('h3', {}, `Burghood audit report, ${r.from} to ${r.to}`),
      el('p', { class: 'meta' }, `${r.rows.length} entries · generated ${new Date().toLocaleString()} by ${me().email ?? me().uid}`),
      el('dl', { class: 'totals' },
        el('dt', {}, 'Income'), el('dd', {}, usd(r.totals.income)),
        el('dt', {}, 'Expenses'), el('dd', {}, usd(r.totals.expense)),
        el('dt', {}, 'Net'), el('dd', {}, usd(r.totals.net)),
      ),
      el('h4', {}, 'By provider, sponsor or payee'),
      el('table', { class: 'ledger' },
        el('tr', {}, ['Name', 'Income', 'Expenses'].map((h) => el('th', {}, h))),
        r.byParty.map((t) => el('tr', {}, el('td', {}, t.label), el('td', { class: 'num' }, usd(t.income)), el('td', { class: 'num' }, usd(t.expense)))),
      ),
      el('h4', {}, 'Entries'),
      r.rows.length
        ? el('div', { class: 'scroll' }, el('table', { class: 'ledger' },
            el('tr', {}, COLUMNS.map((c) => el('th', {}, c.label))),
            r.rows.map((p) => el('tr', {}, COLUMNS.map((c) => el('td', { class: c.key === 'amount' ? 'num' : '' }, c.value(p, r))))),
          ))
        : el('p', { class: 'meta' }, 'No entries in this range.'),
    ),
  );
}

function printReport() {
  document.body.classList.add('printing-report');
  const done = () => {
    document.body.classList.remove('printing-report');
    window.removeEventListener('afterprint', done);
  };
  window.addEventListener('afterprint', done);
  window.print();
}
