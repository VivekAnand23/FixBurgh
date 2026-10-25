// Audit report for the payments ledger: pure functions, shared by the admin
// console and its tests (firebase/test/report.test.js). Change COLUMNS to
// match what the accountant asks for.

/** A ledger entry's signed amount in cents: reversals undo the original. */
export const signedCents = (p) => (p.reversalOf ? -p.amountCents : p.amountCents);

export const usd = (cents) =>
  `${cents < 0 ? '-' : ''}$${(Math.abs(cents) / 100).toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',')}`;

const METHODS = {
  cash: 'Cash',
  check: 'Check',
  bank_transfer: 'Bank transfer',
  card: 'Card',
  online: 'Online',
  other: 'Other',
};

/** The report's columns, in order. `value` gets the entry and the report. */
export const COLUMNS = [
  { key: 'date', label: 'Date', value: (p) => p.date },
  { key: 'type', label: 'Type', value: (p) => (p.type === 'income' ? 'Income' : 'Expense') },
  { key: 'party', label: 'Payer / payee', value: (p) => p.party },
  { key: 'amount', label: 'Amount (USD)', value: (p) => (signedCents(p) / 100).toFixed(2) },
  { key: 'method', label: 'Method', value: (p) => METHODS[p.method] ?? p.method },
  { key: 'reference', label: 'Reference', value: (p) => p.reference ?? '' },
  { key: 'purpose', label: 'Purpose', value: (p) => p.purpose },
  { key: 'recordedBy', label: 'Recorded by', value: (p) => p.recordedByEmail || p.recordedBy },
  {
    key: 'reversal',
    label: 'Reversal',
    value: (p, r) =>
      p.reversalOf
        ? `Reverses ${p.reversalOf}${p.reason ? `: ${p.reason}` : ''}`
        : r.reversedBy.has(p.id)
          ? `Reversed by ${r.reversedBy.get(p.id)}`
          : '',
  },
  { key: 'id', label: 'Entry ID', value: (p) => p.id },
];

/**
 * Entries dated [from] to [to] (YYYY-MM-DD, both included), oldest first,
 * with totals by type and by provider or sponsor. A reversal counts on its
 * own date, so a month's total always matches its ledger lines.
 */
export function buildReport(entries, { from, to }) {
  const rows = entries
    .filter((p) => p.date >= from && p.date <= to)
    .sort((a, b) => a.date.localeCompare(b.date) || String(a.id).localeCompare(String(b.id)));
  const reversedBy = new Map(entries.filter((p) => p.reversalOf).map((p) => [p.reversalOf, p.id]));
  const totals = { income: 0, expense: 0, net: 0 };
  const byParty = new Map();
  for (const p of rows) {
    const c = signedCents(p);
    totals[p.type] += c;
    totals.net += p.type === 'income' ? c : -c;
    const key = p.providerId ? `provider:${p.providerId}` : p.sponsorshipId ? `sponsorship:${p.sponsorshipId}` : `party:${p.party}`;
    const t = byParty.get(key) ?? { label: p.party, income: 0, expense: 0 };
    t[p.type] += c;
    byParty.set(key, t);
  }
  return { from, to, rows, totals, byParty: [...byParty.values()].sort((a, b) => a.label.localeCompare(b.label)), reversedBy };
}

const cell = (v) => {
  const s = String(v ?? '');
  return /[",\n\r]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
};

/** The report as CSV (RFC 4180), with a totals block at the end. */
export function toCsv(report, columns = COLUMNS) {
  const lines = [columns.map((c) => cell(c.label)).join(',')];
  for (const p of report.rows) lines.push(columns.map((c) => cell(c.value(p, report))).join(','));
  lines.push('');
  lines.push(`Total income,${(report.totals.income / 100).toFixed(2)}`);
  lines.push(`Total expenses,${(report.totals.expense / 100).toFixed(2)}`);
  lines.push(`Net,${(report.totals.net / 100).toFixed(2)}`);
  return `${lines.join('\r\n')}\r\n`;
}
