# Privacy answers for the stores

Matches `ios/Runner/PrivacyInfo.xcprivacy` and the privacy policy
(`hosting/public/privacy.html`). Re-check these whenever an SDK or feature
changes. Firebase Analytics runs with ad-ID collection off, and no advertising
SDKs are included.

## Apple App Privacy ("nutrition label")

**Tracking:** No. Burghood does not track users across other companies' apps
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

**Shared:** none. Firebase (Google) processes data on Burghood's behalf as a
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

## Burghood additions (societies, channels, services)

DRAFT: fold these into the tables above when the features ship to prod,
and re-check them against the final privacy policy.

| Data | Apple type | Play type | Linked | Optional | Purpose |
|---|---|---|---|---|---|
| Name and unit shown in a society | Name; Other user content | Personal info > Name; App activity > Other user-generated content | Yes | Yes (joining a society) | App functionality |
| Channel posts, comments, reactions and their photos | Other user content; Photos | App activity > Other user-generated content; Photos | Yes | Yes | App functionality |
| Service requests: text, photos, category details, address | Other user content; Photos; Precise location (if pinned) | App activity; Photos; Location | Yes | Yes | App functionality |
| Completion photos and short video (providers) | Photos or videos | Photos and videos | Yes | Yes | App functionality |
| Reviews and star ratings | Other user content | App activity > Other user-generated content | Yes | Yes | App functionality |
| Provider phone number | Phone number | Personal info > Phone number | Yes | Yes (providers only) | App functionality |
| Society claim: photo ID and proof of office | Other data types | Personal info > Other info | Yes | Yes (society admins only) | App functionality, Fraud prevention |
| Provider licence, insurance, background-check and clearance documents | Other data types; Sensitive info (criminal record checks) | Personal info > Other info | Yes | Yes (providers only) | App functionality, Fraud prevention |
| Journey analytics (step names, counts) | Product interaction | App activity > App interactions | No | No | Analytics |

Google results in Services (`feature_google_places`, PR #13): when no
Burghood provider matches, the server sends the search words and the
society's location to the Google Places API and returns businesses. Nothing
identifying the person is sent, and results aren't stored, so this adds no
row to the forms; the privacy policy should name Google Maps as the source.

Not collected in the app: payment card or bank details. Listing fees and
sponsorships are paid outside the app and recorded by staff, so they don't
belong on the store forms; the privacy policy covers them.

Sponsored listings are first-party placements that use no data about the
viewer, so the app still collects no advertising data and does no tracking.
