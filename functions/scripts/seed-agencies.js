#!/usr/bin/env node
/**
 * Seeds Firestore `agencies/{id}` from assets/directory/agencies.json
 * (BRD FR-RTE-10). The onAgencyWritten function then bumps
 * `config/directory.version`, and apps pick up the change on next launch.
 *
 *   npm --prefix functions run seed:agencies -- --project fixburgh-dev [--dry-run]
 *
 * Needs Google credentials for the project (a service-account key in
 * GOOGLE_APPLICATION_CREDENTIALS, or `gcloud auth application-default
 * login`). Against the emulator, set FIRESTORE_EMULATOR_HOST instead.
 * Writing to fixburgh-prod also needs --allow-prod.
 *
 * Also lists records not verified in the last 120 days (BRD section 8.4).
 */
const { readFileSync } = require('node:fs');
const path = require('node:path');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const STALE_DAYS = 120;
const args = process.argv.slice(2);
const arg = (name) => {
  const i = args.indexOf(name);
  return i >= 0 ? args[i + 1] : undefined;
};
const projectId = arg('--project');
const dryRun = args.includes('--dry-run');
if (!projectId) {
  console.error('Usage: seed-agencies.js --project <id> [--dry-run] [--allow-prod]');
  process.exit(2);
}
if (projectId.endsWith('-prod') && !args.includes('--allow-prod')) {
  console.error(`Refusing to write to ${projectId} without --allow-prod.`);
  process.exit(2);
}

const file = path.resolve(__dirname, '../../assets/directory/agencies.json');
const { agencies } = JSON.parse(readFileSync(file, 'utf8'));

const cutoff = Date.now() - STALE_DAYS * 24 * 3600 * 1000;
const stale = agencies.filter((a) => !a.lastVerifiedAt || Date.parse(a.lastVerifiedAt) < cutoff);
if (stale.length) {
  console.log(`Needs re-verification (older than ${STALE_DAYS} days):`);
  for (const a of stale) console.log(`  ${a.id}  ${a.name}  ${a.lastVerifiedAt ?? 'never'}`);
}

async function main() {
  console.log(`${dryRun ? 'Would write' : 'Writing'} ${agencies.length} agencies to ${projectId}`);
  if (dryRun) return;
  initializeApp({ projectId });
  const db = getFirestore();
  const writer = db.bulkWriter();
  for (const { id, ...data } of agencies) {
    // Drop nulls so a removed field doesn't linger as null.
    const clean = Object.fromEntries(Object.entries(data).filter(([, v]) => v !== null));
    writer.set(db.collection('agencies').doc(id), clean);
  }
  await writer.close();
  console.log('Done.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
