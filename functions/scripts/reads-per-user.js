#!/usr/bin/env node
/**
 * Firestore reads per active user per day, for the Phase 5 cost check.
 *
 *   npm --prefix functions run reads:per-user -- --project fixburgh-dev [--days 7]
 *
 * Reads come from Cloud Monitoring (firestore.googleapis.com/document/
 * read_count, summed per day). Active users are accounts whose last sign-in
 * or token refresh falls inside the window, from Firebase Auth. Read-only.
 *
 * Needs Google credentials for the project (`gcloud auth
 * application-default login`, or a service-account key in
 * GOOGLE_APPLICATION_CREDENTIALS) with Monitoring Viewer and Firebase
 * Authentication Viewer.
 */
const { applicationDefault, initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');

const args = process.argv.slice(2);
const arg = (name) => {
  const i = args.indexOf(name);
  return i >= 0 ? args[i + 1] : undefined;
};
const projectId = arg('--project');
const days = Number(arg('--days') ?? 7);
if (!projectId || !(days >= 1 && days <= 42)) {
  console.error('Usage: reads-per-user.js --project <id> [--days 1-42]');
  process.exit(2);
}

/** Daily read totals from Cloud Monitoring, oldest first. */
async function dailyReads(credential, start, end) {
  const { access_token: token } = await credential.getAccessToken();
  const params = new URLSearchParams({
    filter: 'metric.type="firestore.googleapis.com/document/read_count"',
    'interval.startTime': start.toISOString(),
    'interval.endTime': end.toISOString(),
    'aggregation.alignmentPeriod': '86400s',
    'aggregation.perSeriesAligner': 'ALIGN_SUM',
    'aggregation.crossSeriesReducer': 'REDUCE_SUM',
  });
  const url = `https://monitoring.googleapis.com/v3/projects/${projectId}/timeSeries?${params}`;
  const res = await fetch(url, { headers: { Authorization: `Bearer ${token}` } });
  if (!res.ok) throw new Error(`Monitoring: ${res.status} ${await res.text()}`);
  const body = await res.json();
  const points = (body.timeSeries ?? []).flatMap((s) => s.points ?? []);
  return points
    .map((p) => ({ day: p.interval.endTime.slice(0, 10), reads: Number(p.value.int64Value ?? 0) }))
    .sort((a, b) => a.day.localeCompare(b.day));
}

/** Accounts seen (signed in or refreshed a token) since [since]. */
async function activeUsers(since) {
  let count = 0;
  let pageToken;
  do {
    const page = await getAuth().listUsers(1000, pageToken);
    for (const u of page.users) {
      const seen = u.metadata.lastRefreshTime ?? u.metadata.lastSignInTime;
      if (seen && new Date(seen) >= since) count++;
    }
    pageToken = page.pageToken;
  } while (pageToken);
  return count;
}

async function main() {
  const credential = applicationDefault();
  initializeApp({ credential, projectId });
  const end = new Date();
  const start = new Date(end.getTime() - days * 86400e3);
  const [reads, users] = await Promise.all([dailyReads(credential, start, end), activeUsers(start)]);
  const total = reads.reduce((sum, d) => sum + d.reads, 0);
  for (const d of reads) console.log(`${d.day}  ${d.reads.toLocaleString()} reads`);
  console.log(`\n${projectId}, last ${days} days`);
  console.log(`  reads:        ${total.toLocaleString()}`);
  console.log(`  active users: ${users}`);
  if (users > 0) {
    const perDay = total / users / days;
    console.log(`  per user/day: ${perDay.toFixed(0)} reads`);
    // Blaze charges per 100k reads past the free 50k a day.
    console.log(`  at 1,000 users: ~${((perDay * 1000 * 30) / 1e6).toFixed(1)}M reads a month`);
  }
}

main().catch((e) => {
  console.error(e.message ?? e);
  process.exit(1);
});
