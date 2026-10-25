# Burghood demo video: script

About 248 seconds (4:08) at an easy pace. Each scene shows the screen on the left and its caption on the right. The voice-over is what to say; timings are from the generated video (`Images/demo-video/burghood-demo.mp4`, built by `tool/demo_video/make_video.py` from `tool/demo_video/scenes.json`).

| # | Time | On screen | Caption |
| --- | --- | --- | --- |
| 1 | 0:00 | Title card | Burghood |
| 2 | 0:08 | `1-community-map.png` | The community map |
| 3 | 0:20 | `2-safety-first.png` | Safety first |
| 4 | 0:32 | `3-precise-location.png` | Pin the exact spot |
| 5 | 0:39 | `4-details.png` | What it is, and how bad |
| 6 | 0:45 | `5-who-fixes-it.png` | Sent to the right office |
| 7 | 0:59 | `03-society-home.png` | Your society |
| 8 | 1:17 | `04-channel.png` | Community channels |
| 9 | 1:30 | `05-report-fork.png` | Where is the problem? |
| 10 | 1:43 | `06-services-search.png` | Find a trusted provider |
| 11 | 2:01 | `07-provider-profile.png` | Provider profiles |
| 12 | 2:15 | `08-request-form.png` | Send a request |
| 13 | 2:32 | `09-job-for-provider.png` | The provider takes the job |
| 14 | 2:42 | `10-request-timeline.png` | Confirm it, then review |
| 15 | 2:56 | `11-google-fallback.png` | Nothing listed yet? |
| 16 | 3:04 | `12-become-provider.png` | Offer your services |
| 17 | 3:20 | `13-listing-fee.png` | Approved, then listed |
| 18 | 3:33 | `14-jobs.png` | Everything in Activity |
| 19 | 3:41 | Title card | The admin console |
| 20 | 3:56 | Title card | Burghood |

## Voice-over

**1. Burghood** (0:00, about 9 s)

> Meet Burghood: one app to get your street fixed, look after your home, and stay close to your neighbors, here in Allegheny County.

**2. The community map** (0:08, about 12 s)

> It starts with the community map. Every pothole, broken streetlight and illegal dump your neighbors have reported, in one place. Filter by type, and see what has already been fixed.

**3. Safety first** (0:20, about 12 s)

> Reporting takes under a minute. First, Burghood checks that no one is in danger. Downed power lines, a gas smell, or someone hurt? It points you to 911 straight away.

**4. Pin the exact spot** (0:32, about 8 s)

> Drop a pin on the exact spot, or search for an address. Burghood works out which municipality it is in.

**5. What it is, and how bad** (0:39, about 6 s)

> Pick what it is and how bad it is, add a photo and a short note, and you are done.

**6. Sent to the right office** (0:45, about 14 s)

> Then the part people love. Burghood tells you who actually fixes it. A state road goes to PennDOT, a local street to your city or borough, with the phone number and website. Neighbors can add a me too, and your name is never shown.

**7. Your society** (0:59, about 18 s)

> Burghood also brings your homeowners association or condo society into the app. Find your society by address, or join with an invite code. Every society is verified before it goes live, and members get notices, documents, the HOA account link, and a member list.

**8. Community channels** (1:17, about 13 s)

> Channels are where neighbors talk: snow updates, lost and found, events. Post photos, comment, react, and mention people. Mute a busy channel, and unread counts keep you up to date.

**9. Where is the problem?** (1:30, about 13 s)

> When you report a problem, Burghood now asks where it is. On the street goes to the city, exactly as before. In your home, or in your society's common areas, becomes a service request.

**10. Find a trusted provider** (1:43, about 18 s)

> Just describe it. Type kitchen tap leaking, and Burghood knows you need a plumber. Choose a distance from two to twenty five miles. Providers your society recommends come first, then the best rated, with a badge for those who passed a background check. Sponsored listings are clearly marked.

**11. Provider profiles** (2:01, about 15 s)

> Every provider has a profile with their services, area, photos of past work, and reviews from real jobs, with the provider's replies. Ratings are weighted, so one five star review cannot outrank two hundred great ones.

**12. Send a request** (2:15, about 17 s)

> Send a request with a title, details and up to six photos. The form asks what matters for that job: urgency and access for repairs, dates and ages for babysitting, pet size for dog walking. No signal? It saves the request and sends it when you are back online.

**13. The provider takes the job** (2:32, about 10 s)

> The provider gets a notification and can accept or decline. They start the job, then mark it done with a note, photos, or a short video.

**14. Confirm it, then review** (2:42, about 14 s)

> You follow every step on the timeline. If it is fixed, confirm it and leave a star rating. If not, tap Not fixed, and the provider comes back to it. For common areas, your society admin picks the provider.

**15. Nothing listed yet?** (2:56, about 8 s)

> Searching for something no one lists yet? Burghood offers a one tap search on Google Maps, so you are never stuck.

**16. Offer your services** (3:04, about 16 s)

> Service providers sign up right in the app, from the Profile tab, even if they do not live in a society. They choose their services and area, and upload their license, insurance or background check. Those documents are seen only by the Burghood team.

**17. Approved, then listed** (3:20, about 13 s)

> The Burghood team reviews every application. Once approved, the provider gets a listing fee request with clear payment instructions and a pay link. As soon as the payment is recorded, their profile goes live.

**18. Everything in Activity** (3:33, about 9 s)

> Providers manage their work from the Jobs tab, while residents track their city reports and service requests side by side in Activity.

**19. The admin console** (3:41, about 15 s)

> Behind the scenes, the admin console lets the Burghood team verify societies and providers, record background checks, request and record payments, schedule sponsored listings, and export an audit report for the accountant.

**20. Burghood** (3:56, about 12 s)

> Burghood. Built for Allegheny County, readable at any text size, private by design, and free for residents. Fix your street, look after your home, and know your neighbors.

## Notes for recording

- The video uses the Mac's built-in voice. For the launch version, record a person reading the voice-over above, then run `make_video.py` again with that audio, or replace the soundtrack in an editor.
- Screens use sample data (Maple Court HOA, Steel City Plumbing); no real people or businesses.
- The Google results scene shows the in-app list, which needs the `feature_google_places` switch. With it off, residents see only the "Search Google Maps" button under "No providers found yet".
