# Store listing (App Store and Google Play)

Draft copy. Character limits are noted; counts include spaces.

## Name and short text

| Field | Text | Limit |
|---|---|---|
| App name | FixBurgh: Report Road Problems | 30 |
| iOS subtitle | Find who fixes it. Tell them. | 30 |
| Play short description | Snap a pothole or landslide anywhere in Allegheny County and reach who fixes it | 80 |
| iOS promotional text | Know exactly who fixes it: PennDOT, Allegheny County or your borough. Snap, pin, send. | 170 |
| iOS keywords | pothole,Pittsburgh,311,PennDOT,streetlight,landslide,road,report,borough,township,Allegheny | 100 |

## Full description (both stores, ≤ 4000)

See a pothole, a dark streetlight or a landslide creeping onto the road? FixBurgh tells you exactly who fixes it and helps you tell them in under a minute.

Allegheny County has 130 municipalities, and a single street can belong to PennDOT, the County or your borough. FixBurgh works it out for you.

HOW IT WORKS
• Snap a photo and drop a pin. FixBurgh uses precise GPS, with satellite view and address search to place the pin.
• Pick what it is: pothole, landslide, flooding or blocked drain, streetlight, illegal dumping, fallen tree, sidewalk damage, or something else.
• FixBurgh shows the responsible office and explains why. For example: "Saw Mill Run Blvd is a state road, so PennDOT maintains it."
• Call, email or open the office's web form with one tap. FixBurgh copies the details for you.

BETTER TOGETHER
• See reports near you on the community map.
• Tap "Me too" instead of filing a duplicate, so the problems that matter most stand out.
• Tap "Looks fixed" when a repair is done. Three neighbors close the report.

SAFETY FIRST
FixBurgh asks whether anyone is in danger before every report. Downed wires, gas smells, crashes and deep water go straight to 911. FixBurgh is not monitored for emergencies.

PRIVATE BY DESIGN
• No ads, and we never sell your data.
• Your name is never shown on the map.
• Hidden photo data is removed before upload, and phone numbers and emails typed into descriptions are masked.
• Report as a guest, or sign in with Google or email to keep your history.

WORKS OFFLINE FOR ROUTING
FixBurgh carries public data from Allegheny County and PennDOT, so it can tell you who maintains a road even with a weak signal.

FixBurgh is an independent community project. It is not affiliated with PennDOT, Allegheny County, the City of Pittsburgh or any municipality.

## Categories and ratings

| Field | Value |
|---|---|
| iOS primary category | Utilities |
| iOS secondary category | Navigation |
| Play category | Maps & Navigation |
| iOS age rating | 12+ (user-generated content with moderation, reporting and blocking). Answer "Infrequent/Mild" for user-generated content questions. |
| Play target audience | 13 and over (not designed for children) |
| Play content rating (IARC) | Users can interact and share content; no violence, no purchases |
| Price | Free, no in-app purchases, no ads |

## URLs (need the support email first)

| Field | URL |
|---|---|
| Privacy policy | https://fixburgh-prod.web.app/privacy |
| Terms | https://fixburgh-prod.web.app/terms |
| Account deletion (Play) | https://fixburgh-prod.web.app/delete-account |
| Support URL | https://fixburgh-prod.web.app |

## App Review notes (iOS) / App access (Play)

> FixBurgh works without an account: tap Get started, enter any birth date
> 13+ years ago, and you're in as a guest. Reporting is limited to locations
> in Allegheny County, Pennsylvania. To test from outside the area, use
> Simulator > Features > Location > Custom Location 40.4406, -79.9959
> (downtown Pittsburgh), or search "414 Grant St, Pittsburgh" on the location
> step. Sign in with Apple, Google and email are under Profile. Account
> deletion is under Profile > Delete my account. Content can be flagged from
> any report's detail sheet ("Report a problem with this") and people can be
> hidden ("Hide reports from this person"). The app never contacts 911 or
> agencies itself; it only opens the phone dialer, mail app or browser.

## Screenshots

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
