// The admin console's audit report (hosting/public/admin/report.js).
// Run: npm --prefix firebase/test run test:report
import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { buildReport, COLUMNS, toCsv, usd } from '../../hosting/public/admin/report.js';

const entry = (id, date, type, cents, extra = {}) => ({
  id, date, type, amountCents: cents, kind: 'other', currency: 'USD', method: 'check',
  reference: '', purpose: 'Test', party: 'Acme', recordedBy: 'admin', recordedByEmail: 'admin@example.com', ...extra,
});

// A test ledger across three months, with a reversal inside October and
// one in November of an October entry.
const ledger = [
  entry('a', '2026-09-30', 'income', 15000, { kind: 'listing_fee', providerId: 'p1', party: 'Steel City Plumbing' }),
  entry('b', '2026-10-01', 'income', 15000, { kind: 'listing_fee', providerId: 'p2', party: 'Sue Sitter' }),
  entry('c', '2026-10-15', 'income', 5000, { kind: 'sponsorship', sponsorshipId: 's1', providerId: 'p1', party: 'Steel City Plumbing' }),
  entry('d', '2026-10-20', 'expense', 2599, { party: 'Print shop, "Main St"', purpose: 'Flyers\nfor launch' }),
  entry('rev_b', '2026-10-28', 'income', 15000, { kind: 'listing_fee', providerId: 'p2', party: 'Sue Sitter', reversalOf: 'b', reason: 'Check bounced' }),
  entry('e', '2026-10-31', 'income', 15000, { kind: 'listing_fee', providerId: 'p3', party: 'Bright Painters' }),
  entry('rev_c', '2026-11-02', 'income', 5000, { kind: 'sponsorship', sponsorshipId: 's1', providerId: 'p1', party: 'Steel City Plumbing', reversalOf: 'c', reason: 'Refund' }),
];

describe('audit report', () => {
  it('totals for a test month match the ledger lines in it', () => {
    const r = buildReport(ledger, { from: '2026-10-01', to: '2026-10-31' });
    assert.deepEqual(r.rows.map((p) => p.id), ['b', 'c', 'd', 'rev_b', 'e']);
    // Summed straight from the ledger: income b + c - rev_b + e, expense d.
    const inMonth = ledger.filter((p) => p.date.startsWith('2026-10'));
    const sum = (type) => inMonth.filter((p) => p.type === type).reduce((t, p) => t + (p.reversalOf ? -1 : 1) * p.amountCents, 0);
    assert.equal(r.totals.income, sum('income'));
    assert.equal(r.totals.income, 15000 + 5000 - 15000 + 15000);
    assert.equal(r.totals.expense, sum('expense'));
    assert.equal(r.totals.net, r.totals.income - r.totals.expense);
    assert.equal(usd(r.totals.net), '$174.01');
  });

  it('counts a reversal in the month it was made', () => {
    const nov = buildReport(ledger, { from: '2026-11-01', to: '2026-11-30' });
    assert.equal(nov.totals.income, -5000);
    const all = buildReport(ledger, { from: '2026-01-01', to: '2026-12-31' });
    assert.equal(all.totals.income, 15000 + 15000 + 5000 - 15000 + 15000 - 5000);
  });

  it('totals by provider or sponsor', () => {
    const r = buildReport(ledger, { from: '2026-10-01', to: '2026-10-31' });
    const by = Object.fromEntries(r.byParty.map((t) => [t.label, t]));
    assert.equal(by['Sue Sitter'].income, 0);
    assert.equal(by['Bright Painters'].income, 15000);
    assert.equal(by['Print shop, "Main St"'].expense, 2599);
  });

  it('exports CSV with the standard columns, escaped, and the totals', () => {
    const r = buildReport(ledger, { from: '2026-10-01', to: '2026-10-31' });
    const csv = toCsv(r);
    const lines = csv.split('\r\n');
    assert.equal(lines[0], COLUMNS.map((c) => c.label).join(','));
    assert.deepEqual(COLUMNS.map((c) => c.key).slice(0, 9), [
      'date', 'type', 'party', 'amount', 'method', 'reference', 'purpose', 'recordedBy', 'reversal',
    ]);
    assert.ok(csv.includes('"Print shop, ""Main St"""'));
    assert.ok(csv.includes('"Flyers\nfor launch"'));
    assert.ok(csv.includes('2026-10-01,Income,Sue Sitter,150.00,Check,,Test,admin@example.com,Reversed by rev_b,b'));
    assert.ok(csv.includes('-150.00'));
    assert.ok(csv.includes('Reverses b: Check bounced'));
    assert.ok(csv.includes('Net,174.01'));
  });
});
