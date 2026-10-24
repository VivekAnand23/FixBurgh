#!/usr/bin/env node
/**
 * Gives an account the Burghood `platformAdmin` custom claim, which opens
 * the admin web console (/admin) and the platform-admin reads in the rules.
 * Other claims (e.g. `role`) are kept.
 *
 *   npm --prefix functions run set:platform-admin -- --project fixburgh-dev --email you@example.com [--revoke] [--dry-run]
 *
 * Needs Google credentials for the project (a service-account key in
 * GOOGLE_APPLICATION_CREDENTIALS, or `gcloud auth application-default
 * login`). Against the emulator, set FIREBASE_AUTH_EMULATOR_HOST instead.
 * Writing to fixburgh-prod also needs --allow-prod. The person must sign
 * out and in again (or wait up to an hour) for the claim to reach the app.
 */
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');

const args = process.argv.slice(2);
const arg = (name) => {
  const i = args.indexOf(name);
  return i >= 0 ? args[i + 1] : undefined;
};
const projectId = arg('--project');
const email = arg('--email');
const revoke = args.includes('--revoke');
const dryRun = args.includes('--dry-run');
if (!projectId || !email) {
  console.error(
    'Usage: set-platform-admin.js --project <id> --email <email> [--revoke] [--dry-run] [--allow-prod]',
  );
  process.exit(2);
}
if (projectId.endsWith('-prod') && !args.includes('--allow-prod')) {
  console.error(`Refusing to change ${projectId} without --allow-prod.`);
  process.exit(2);
}

/** The claims to store: [current] with platformAdmin set or removed. */
function nextClaims(current, revoke) {
  const claims = { ...(current ?? {}) };
  if (revoke) delete claims.platformAdmin;
  else claims.platformAdmin = true;
  return claims;
}

async function main() {
  initializeApp({ projectId });
  const auth = getAuth();
  const user = await auth.getUserByEmail(email);
  const claims = nextClaims(user.customClaims, revoke);
  console.log(
    `${dryRun ? 'Would set' : 'Setting'} claims on ${user.uid} (${email}) in ${projectId}:`,
    JSON.stringify(claims),
  );
  if (dryRun) return;
  await auth.setCustomUserClaims(user.uid, claims);
  console.log('Done. Sign out and in again to pick it up.');
}

if (require.main === module) {
  main().catch((e) => {
    console.error(e.message ?? e);
    process.exit(1);
  });
}

module.exports = { nextClaims };
