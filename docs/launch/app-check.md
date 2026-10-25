# App Check enforcement

App Check proves a request comes from the real Burghood app. The app already
activates it (`lib/app/bootstrap.dart`): Play Integrity on Android, App
Attest with DeviceCheck fallback on iOS, and the debug provider in debug
builds. Nothing is enforced yet, so turn it on per project in this order,
watching the metrics at each step.

## 1. Register the apps

Firebase console > App Check > Apps, for each project:

- Android `com.fixburgh.app` (and `.dev`): Play Integrity, with the app's
  SHA-256 signing certificate (from Play Console > App integrity).
- iOS `com.fixburgh.app` (and `.dev`): App Attest, plus DeviceCheck with the
  team's key.
- Debug tokens: run a debug build, copy the token from the device log, and
  add it under Manage debug tokens.

## 2. Watch before enforcing

App Check > APIs shows verified and unverified requests for Firestore,
Storage and Cloud Functions. Wait until unverified requests are only old app
versions (a week after a release that includes App Check is usually enough).

## 3. Enforce the callables

The six callables the app uses (`claimGuestReports`, `deleteAccount`,
`sendTestNotification`, `checkSocietyDuplicates`, `joinWithCode`,
`regenerateInviteCode`) read `appCallable` from `functions/src/options.ts`.
Create `functions/.env.<project-id>`:

```
ENFORCE_APP_CHECK=true
```

and deploy functions to that project. Remove the line (or set `false`) and
redeploy to turn it off again.

The admin console's callables are not enforced: they already require the
`platformAdmin` claim, and the web console has no App Check provider. Add
reCAPTCHA Enterprise for the console first if you want them covered too.

## 4. Enforce Firestore and Storage

App Check > APIs > Cloud Firestore > Enforce, then Cloud Storage > Enforce.
This is a console switch, takes effect within minutes, and can be turned
off the same way. The admin console reads Firestore from the web, so either
register it with reCAPTCHA Enterprise first or leave Firestore unenforced
until you do.

## Emulators and tests

Leave `ENFORCE_APP_CHECK` unset for the emulators (`functions/.env.local`
must not set it); the emulator tests call the functions without App Check.
