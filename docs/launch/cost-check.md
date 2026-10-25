# Firestore cost check

Run during the pilot, once real people use the app every day:

```
gcloud auth application-default login
npm --prefix functions run reads:per-user -- --project fixburgh-dev --days 7
```

It prints daily read totals from Cloud Monitoring, the number of active
accounts in the window from Firebase Auth, reads per user per day, and a
monthly estimate at 1,000 users. It only reads; it changes nothing.

## What to compare against

- Blaze includes 50,000 reads a day free, then charges per 100,000 reads.
- Check the budget alerts in Google Cloud Billing still cover the monthly
  estimate with headroom for growth.

## Where reads come from, and the levers

| Source | Reads | Lever if it's too high |
|---|---|---|
| Channel list unread badges | 2 count queries per channel with new posts since the member last read it (quiet channels cost nothing) | Store per-member unread counts on the member doc from a function instead |
| Channel feed | Up to 100 posts when opened, then only changes | Lower the limit, page older posts on scroll |
| Comments | Up to 300 per post opened | Page them |
| Provider search | Up to 50 per geohash cell and category, 50 for browse | Narrow cells, cache results for a few minutes |
| Request timelines and lists | Up to 100 requests, events per request opened | Page history |
| Map (city reports) | Reports in view | Unchanged from FixBurgh |

Change one lever at a time and re-run the script a week later to compare.

## Google results in Services (Places API)

When a service search finds no listed provider, Services shows a free
"Search Google Maps for …" link. With the `feature_google_places` flag on,
it also shows up to 10 Google Maps businesses in the app, through the
`searchGooglePlaces` function (Places API (New) Text Search).

- **Cost:** each search is one Text Search call billed by Google. The field
  mask includes phone, website and rating, which puts it in Google's
  higher Text Search tier, about $35 per 1,000 calls before the monthly
  free credit. Check the current price on Google's Places API pricing page.
- **Limits:** 20 searches per account per day (`DAILY_LIMIT` in
  `functions/src/googlePlaces.ts`). The app asks only when nothing listed
  matches, and only once per search term, distance and society.
- **Turning it on for a project:**
  1. Enable the Places API (New) for the project:
     `gcloud services enable places.googleapis.com --project <project>`.
  2. Deploy the functions.
  3. Set `feature_google_places` to true in that project's Remote Config.
  Until step 1 is done the function returns no results, and the app shows
  only the Google Maps link.
- **Terms:** results aren't stored, and they carry "Results from Google
  Maps" attribution and a link to each business on Google Maps, as Google's
  terms require.
