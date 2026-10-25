/**
 * Shared setup, imported first by every module that defines functions so
 * the options apply to all of them.
 */
import { initializeApp } from 'firebase-admin/app';
import { setGlobalOptions } from 'firebase-functions/v2';

initializeApp();

// Same region as the Firestore database.
setGlobalOptions({ region: 'us-east1', maxInstances: 5 });

/**
 * Options for the callables the mobile app uses. App Check enforcement is
 * switched on per project with ENFORCE_APP_CHECK=true in
 * functions/.env.<project-id>, and stays off by default so the emulators and
 * debug builds work until each app is registered (docs/launch/app-check.md).
 * The admin console's callables are left out: they already require the
 * platformAdmin claim, and the web console has no App Check provider yet.
 */
export const appCallable = {
  enforceAppCheck: process.env.ENFORCE_APP_CHECK === 'true',
};
