/**
 * Shared setup, imported first by every module that defines functions so
 * the options apply to all of them.
 */
import { initializeApp } from 'firebase-admin/app';
import { setGlobalOptions } from 'firebase-functions/v2';

initializeApp();

// Same region as the Firestore database.
setGlobalOptions({ region: 'us-east1', maxInstances: 5 });
