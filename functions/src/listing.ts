/**
 * Listing periods as calendar days in Pittsburgh (YYYY-MM-DD). No Firebase
 * imports, so tests can load it directly.
 */

/** Today's date in Pittsburgh. */
export const todayEt = (now = new Date()) =>
  new Intl.DateTimeFormat('en-CA', { timeZone: 'America/New_York' }).format(now);

const parse = (d: string) => {
  const [y, m, day] = d.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, day));
};
const fmt = (d: Date) => d.toISOString().slice(0, 10);
export const addDays = (d: string, n: number) => fmt(new Date(parse(d).getTime() + n * 86_400_000));

/** [d] plus [months] calendar months, clamped to the month's last day. */
export function addMonths(d: string, months: number) {
  const x = parse(d);
  const target = new Date(Date.UTC(x.getUTCFullYear(), x.getUTCMonth() + months, 1));
  const last = new Date(Date.UTC(target.getUTCFullYear(), target.getUTCMonth() + 1, 0)).getUTCDate();
  target.setUTCDate(Math.min(x.getUTCDate(), last));
  return fmt(target);
}

/**
 * The last day a provider is listed, from their listing-fee payments in
 * date order: each one runs [periodMonths] from the later of its date and
 * the day after the previous period. Null with no payments.
 */
export function listingPaidThrough(payments: { date: string; periodMonths: number }[]): string | null {
  let through: string | null = null;
  for (const p of [...payments].sort((a, b) => a.date.localeCompare(b.date))) {
    const start = through && addDays(through, 1) > p.date ? addDays(through, 1) : p.date;
    through = addDays(addMonths(start, p.periodMonths), -1);
  }
  return through;
}

