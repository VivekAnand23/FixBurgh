# Store listing (App Store and Google Play)

Draft copy. Character limits are noted; counts include spaces.

## Name and short text

| Field | Text | Limit |
|---|---|---|
| App name | Burghood: Neighbors & Services | 30 |
| iOS subtitle | Your building, block and city | 30 |
| Play short description | Talk with your HOA, find trusted local help and report road problems | 80 |
| iOS promotional text | Channels for your HOA or building, local pros your neighbors recommend, and one-tap road reports to whoever fixes them. | 170 |
| iOS keywords | HOA,condo,neighbors,handyman,plumber,babysitter,pothole,Pittsburgh,311,Allegheny,community | 100 |

Counts: name 30, subtitle 29, short description 68, promotional text 119,
keywords 90.

## Full description (both stores, ≤ 4000)

Burghood brings your neighborhood into one app: talk with your HOA, condo or apartment community, find local help your neighbors trust, and report road problems to the office that fixes them.

YOUR SOCIETY, IN ONE PLACE
• Join your HOA, condo association or apartment community with an invite code, or ask to join and an admin approves you.
• Channels for everything: general chat, parking and snow, lost and found, events. Post photos, reply, react and @mention neighbors.
• Notices from your board, pinned so nobody misses them, and the documents you keep looking for: bylaws, minutes, forms.
• Admins manage members, channels and requests for the common areas, like a lobby light that's out.

LOCAL HELP YOUR NEIGHBORS TRUST
• Describe the problem in your own words ("kitchen tap leaking") and Burghood finds plumbers, handymen, cleaners, pet sitters, babysitters, tutors and more within the distance you choose.
• See ratings from real jobs, providers your society recommends, and a Background checked badge where the provider's check has passed.
• Send a request with photos, follow it from accepted to done, confirm the fix, then rate the work.
• Offer your own services: apply with your licence and insurance, and neighbors can find you once you're approved.

REPORT ROAD PROBLEMS
• Snap a pothole, a dark streetlight or a landslide anywhere in Allegheny County and drop a pin.
• Burghood works out who maintains the road (PennDOT, Allegheny County or your borough) and explains why.
• Call, email or open the office's form with one tap. Tap "Me too" on reports near you so the problems that matter most stand out.

SAFETY FIRST
Burghood asks whether anyone is in danger before every report. Downed wires, gas smells, crashes and deep water go straight to 911. Burghood is not monitored for emergencies.

PRIVATE BY DESIGN
• We never sell your data, and we show no third-party ads. Some provider listings are paid placements, clearly marked "Sponsored"; they use nothing about you.
• Your society's channels are visible only to its members.
• Your name is never shown on the road-report map, and hidden photo data is removed before upload.

Burghood is an independent Pittsburgh project. It is not affiliated with PennDOT, Allegheny County, the City of Pittsburgh, any municipality, or any HOA or management company. Providers are independent businesses; agree the price and scope with them directly.

## Categories and ratings

| Field | Value |
|---|---|
| iOS primary category | Lifestyle |
| iOS secondary category | Social Networking |
| Play category | House & Home |
| iOS age rating | 13+ under Apple's age rating questions: user-generated content and messaging with moderation, reporting and blocking. Answer "Infrequent/Mild" for user-generated content. Providers must be 18 or over (provider rules). |
| Play target audience | 13 and over (not designed for children) |
| Play content rating (IARC) | Users can interact and share content; shares location (the report pin); no violence, no in-app purchases |
| Price | Free, no in-app purchases, no third-party ads. Listing fees and sponsorships are paid outside the app, so they need no in-app purchase. |

## URLs (need the support email first)

| Field | URL |
|---|---|
| Privacy policy | https://fixburgh-prod.web.app/privacy |
| Terms | https://fixburgh-prod.web.app/terms |
| Account deletion (Play) | https://fixburgh-prod.web.app/delete-account |
| Support URL | https://fixburgh-prod.web.app |

## App Review notes (iOS) / App access (Play)

> Burghood works without an account: tap Get started, enter any birth date
> 13+ years ago, and you're in as a guest. Reporting is limited to locations
> in Allegheny County, Pennsylvania. To test from outside the area, use
> Simulator > Features > Location > Custom Location 40.4406, -79.9959
> (downtown Pittsburgh), or search "414 Grant St, Pittsburgh" on the location
> step. Sign in with Apple, Google and email are under Profile. Account
> deletion is under Profile > Delete my account. Content can be flagged from
> any report's detail sheet ("Report a problem with this") and people can be
> hidden ("Hide reports from this person"). The app never contacts 911 or
> agencies itself; it only opens the phone dialer, mail app or browser.
>
> Societies, channels and services: sign in with the review account
> (email and password in the review notes field, never in this file). It
> is a member of the "App Review HOA" test society, so the Channels,
> Notices, Docs and Services tabs have sample content. Posts and comments
> can be reported from their ⋯ menu, and people blocked from the same
> menu; society admins and staff review reports. Providers are
> independent businesses; listing fees and sponsorships are invoiced and
> paid outside the app, so there is no in-app purchase.

Before submitting, create the review account and the "App Review HOA" test
society on prod with a few channels, posts, a notice and two approved test
providers, and put the account's sign-in in each store's review form.

## Screenshots

### Burghood screens

`Images/store-screenshots/burghood/` has five screens at the App Store's
6.9-inch size (1320 × 2868) with sample data: society channels, a channel,
services search, a provider profile and a request's timeline. Google Play
accepts the same files. Regenerate them after UI changes:

```bash
flutter test tool/store_screenshots --update-goldens \
  --dart-define=FEATURES=society,channels,services,monetisation
```

They are drawn by Flutter's test renderer with sample data, so check them
against a real build on a phone before submitting, and swap in pilot
screenshots (with the society's permission) once there are some.

Suggested captions, one per screenshot:

1. Your HOA, condo or building, all in one place
2. Channels for parking, events, lost and found and more
3. Describe the problem, find local help nearby
4. Ratings from real jobs and your society's picks
5. Follow every request from booked to fixed

### Road reporting screens

`Images/store-screenshots/` has five captures from the iPhone 17 Pro simulator
(6.3-inch, 1206 × 2622): community map, safety check, precise location, details
and "Who fixes this?". Google Play accepts these as they are (it needs 2 to 8
phone screenshots).

The App Store needs a 6.9-inch set (1320 × 2868). Capture the same five screens on
the iPhone 17 Pro Max simulator. That simulator needs your OK in the simulator
panel first. Use the screenshot build, which hides the debug banner:

```bash
flutter build ios --simulator --debug --flavor dev -t lib/main_dev.dart --dart-define=SCREENSHOTS=true
```

The map shows only test reports. Before submitting, file a few real reports
with real photos so the map looks lived-in.
