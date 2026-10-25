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
