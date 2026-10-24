<p align="center"><img src="Images/Logo.jpeg" alt="Burghood logo" width="120"/></p>

# Burghood

_Formerly FixBurgh. The bundle IDs (`com.fixburgh.app`, `com.fixburgh.app.dev`),
Firebase projects and Dart package name keep the old name so existing installs
update in place._

Snap, pin and route local infrastructure problems anywhere in Allegheny County,
Pennsylvania. Burghood tells residents exactly which office fixes a pothole,
landslide, dark streetlight or blocked drain: PennDOT, Allegheny County or one
of the county's 130 municipalities.

- Business requirements: [BRD/FixBurgh_BRD.md](BRD/FixBurgh_BRD.md)
- Data sources: [docs/data-sources.md](docs/data-sources.md)

**Burghood is not an emergency service. Call 911 for emergencies.**

## Stack

Flutter (iOS + Android) · Firebase (Auth, Firestore, Storage, App Check,
Crashlytics) · Google Maps SDK · Riverpod · go_router · public GIS data from
Allegheny County and PennDOT.

## Project layout

```
lib/
  app/            app shell: bootstrap, flavors, router, theme, Firebase options
  features/
    auth/         guest, Google, Apple and email sign-in (guest upgrade keeps reports)
    onboarding/   welcome and neutral 13+ age screen
    routing/      smart routing engine (pure Dart), municipality lookup
    map/ report/ my_reports/ profile/
  l10n/           strings (ARB); generated code in l10n/gen
assets/gis/       bundled boundaries and road ownership (built by tools/gis)
tools/gis/        script that downloads and simplifies the GIS data
BRD/  Images/     requirements document and all images
```

## Getting started

Requirements: Flutter 3.47+, Xcode 26+ with CocoaPods, and Android Studio
(Android SDK) for Android builds.

```bash
flutter pub get
flutter test
```

Run a flavor (each uses its own Firebase project):

```bash
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor prod -t lib/main_prod.dart
```

| Flavor | App ID | Firebase project |
|---|---|---|
| dev | `com.fixburgh.app.dev` | `fixburgh-dev` |
| prod | `com.fixburgh.app` | `fixburgh-prod` |

Debug builds use the App Check debug provider. The first run prints a debug
token in the device log; add it in the Firebase console under App Check >
Apps > Manage debug tokens before App Check enforcement is turned on.

The Firebase config files in this repo (`firebase_options_*.dart`,
`GoogleService-Info.plist`, `google-services.json`) identify the projects and
are meant to be public. Access is protected by Security Rules, App Check and
API key restrictions. Never commit service-account keys or other secrets.

## Backend

Firestore and Storage rules, indexes, Cloud Functions and the Remote Config
template are deployed with the Firebase CLI. Use the dev project unless you
are releasing:

```bash
firebase deploy --project fixburgh-dev --only firestore,storage,functions,remoteconfig
```

Rules and functions tests run against the emulators:

```bash
firebase emulators:exec --only auth,firestore,functions,storage --project demo-fixburgh \
  "npm --prefix firebase/test test && npm --prefix firebase/test run test:storage && npm --prefix firebase/test run test:functions"
```

### Phase 2 switches

Remote Config parameters `feature_offline_outbox`, `feature_push` and
`feature_saved_places` turn offline mode, push notifications and saved places
on or off without a release (`firebase/remoteconfig.template.json`, on in
dev). The app treats a missing value as on.

Push on iOS needs an APNs authentication key uploaded in the Firebase console
(Project settings > Cloud Messaging > Apple app configuration). Until then iOS
devices don't get a token; Android works as is.

### Office directory

The app bundles `assets/directory/agencies.json` and lays Firestore's
`agencies` collection over it, so contacts can be corrected without a
release. To publish the bundled directory to Firestore (needs Google
credentials for the project, e.g. a service-account key in
`GOOGLE_APPLICATION_CREDENTIALS`):

```bash
npm --prefix functions run seed:agencies -- --project fixburgh-dev
```

Edits to any `agencies` document (including in the console) bump
`config/directory.version`, and apps refetch on their next launch.

### Societies (Burghood Phase 1)

Behind the `feature_society` Remote Config flag (off by default). Debug
builds can turn flags on with `--dart-define=FEATURES=society` and talk to
the local emulators with `--dart-define=USE_EMULATORS=true`:

```bash
firebase emulators:start --project fixburgh-dev
flutter run --flavor dev -t lib/main_dev.dart --dart-define=USE_EMULATORS=true --dart-define=FEATURES=society
```

`integration_test/society_walkthrough_test.dart` runs the Phase 1 exit check
on two devices against those emulators: `ROLE=admin` claims a society
(approve it in the console at `http://127.0.0.1:5002/admin`), `ROLE=resident`
finds it, asks to join, and reads the notice and document the admin posts.
Claim files are deleted 30 days after the decision
(`CLAIM_FILE_RETENTION_DAYS`); platform admins can run the clean-up now
with the `purgeClaimFilesNow` function. The verification wording and the
privacy policy additions are drafts: see `docs/society-verification.md`.

### Channels (Burghood Phase 2)

Behind `feature_channels` (and `feature_society`). Reaction pushes are
bundled through the `sendReactionDigest` Cloud Tasks queue: the first
reaction starts a 120-second timer (`REACTION_DIGEST_SECONDS`; 3 seconds in
the emulator). `integration_test/channels_walkthrough_test.dart` runs the
Phase 2 exit check on two devices; seed the emulators first with
`node firebase/test/seed-channels-walkthrough.js fixburgh-dev` and pass the
dart-defines it prints, plus `--dart-define=SKIP_LOCATION=true`.

### Platform admins

Burghood staff get the `platformAdmin` custom claim, which opens the admin
console at `/admin` on the Hosting site and lets the rules show them the
Burghood collections. Existing claims are kept; `--revoke` removes it.

```bash
npm --prefix functions run set:platform-admin -- --project fixburgh-dev --email you@example.com
```

The console (`hosting/public/admin`) reads the project's config from
Hosting's `/__/firebase/init.json`. To try it locally, run
`firebase emulators:start --only hosting,auth --project demo-fixburgh`, open
`http://127.0.0.1:5002/admin`, sign in, then run the script above with
`FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 --project demo-fixburgh`.

## Updating GIS data

```bash
python3 tools/gis/build_gis_assets.py
```

## License

[MIT](LICENSE)
