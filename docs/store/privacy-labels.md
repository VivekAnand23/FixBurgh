# Privacy answers for the stores

Matches `ios/Runner/PrivacyInfo.xcprivacy` and the privacy policy
(`hosting/public/privacy.html`). Re-check these whenever an SDK or feature
changes. Firebase Analytics runs with ad-ID collection off, and no advertising
SDKs are included.

## Apple App Privacy ("nutrition label")

**Tracking:** No. FixBurgh does not track users across other companies' apps
or websites.

| Data type | Collected | Linked to the user | Used for tracking | Purpose |
|---|---|---|---|---|
| Precise location (the pin on a report) | Yes | Yes | No | App functionality |
| Photos | Yes | Yes | No | App functionality |
| Other user content (description, votes, flags) | Yes | Yes | No | App functionality |
| User ID | Yes | Yes | No | App functionality |
| Email address (Google or email sign-in only) | Yes | Yes | No | App functionality |
| Name (Google sign-in only) | Yes | Yes | No | App functionality |
| Crash data | Yes | No | No | App functionality |
| Product interaction | Yes | No | No | Analytics |
| Contacts, browsing history, health, financial info, purchases, advertising data | No | | | |

Notes for the form:
- The location is collected only for the pin the user confirms. There is no
  background location.
- Reports are public on the map, but the account behind them is not shown.

## Google Play Data safety

**Does your app collect or share any of the required user data types?** Yes.
**Is all collected data encrypted in transit?** Yes (HTTPS/TLS for Firebase
and Google Maps).
**Can users request that their data be deleted?** Yes: in the app (Profile >
Delete my account) and at https://fixburgh-prod.web.app/delete-account.

| Category | Data type | Collected | Shared | Optional | Purpose |
|---|---|---|---|---|---|
| Location | Precise location | Yes | No | No (needed to report) | App functionality |
| Photos and videos | Photos | Yes | No | No (needed to report) | App functionality |
| Personal info | Email address | Yes | No | Yes (sign-in) | App functionality, Account management |
| Personal info | Name | Yes | No | Yes (Google sign-in) | Account management |
| Personal info | User IDs | Yes | No | No | App functionality, Fraud prevention |
| App activity | Other user-generated content | Yes | No | Yes | App functionality |
| App activity | App interactions | Yes | No | No | Analytics |
| App info and performance | Crash logs, Diagnostics | Yes | No | No | App functionality |

**Shared:** none. Firebase (Google) processes data on FixBurgh's behalf as a
service provider, which Play does not count as sharing. Reports are visible
to everyone in the app on purpose; describe this in the privacy policy, as we
do.

## Permissions (both platforms)

| Permission | When it's asked | Why |
|---|---|---|
| Location while using the app | On the location step | Place the pin |
| Precise location (iOS temporary) | If only approximate is shared | Crews need the exact spot |
| Camera | When tapping Take photo | Photograph the problem |
| Photos | None (system photo picker) | Pick a photo without library access |
