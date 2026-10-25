# Burghood launch checklist (Phase 5)

Work through these in order. Items marked **(you)** need Vivek, a store
account, or a decision; the rest are done in the repo.

## Before the pilot

- [x] Accessibility: every new screen passes at 200% text in light and dark
      (`test/a11y_burghood_test.dart`): tap targets, labels, contrast, no
      overflow.
- [x] Analytics events and Crashlytics breadcrumbs for each journey
      (`lib/app/analytics.dart`). Parameters are kinds and counts only.
- [x] App Check ready to enforce on the app's callables
      ([app-check.md](app-check.md)).
- [x] Cost check script ([cost-check.md](cost-check.md)).
- [x] Draft policies: privacy policy, terms, provider rules and community
      guidelines in `hosting/public/`.
- [ ] **(you)** Legal review of the four policy pages, then remove the DRAFT
      banners and set the effective dates.
- [ ] **(you)** Decide the background-check route (PA State Police PATCH,
      DHS child abuse clearance, FBI fingerprints for child care) and
      confirm the provider rules match it.
- [ ] **(you)** Fees: listing fee and period, sponsorship price, sponsored
      slots per search, audit report columns, emailed receipts or not.
- [x] Deploy the latest main to fixburgh-dev.
- [ ] Run the cost check after a week of pilot use.

## Pilot (2 weeks)

- [ ] **(you)** 2 or 3 Allegheny County societies, each with an admin
      willing to verify and invite residents.
- [ ] **(you)** 5 to 10 pilot providers across repair, cleaning, pet care
      and babysitting, with their documents ready.
- [ ] TestFlight (iOS) and Google Play internal testing builds of the dev
      flavor, with `feature_society`, `feature_channels` and
      `feature_services` on in dev Remote Config.
- [ ] Register both apps for App Check and add debug tokens for testers.
- [ ] Weekly: Crashlytics crash-free sessions, Analytics journey funnels,
      the cost check, and feedback from the pilot admins.

## Store and legal

- [ ] **(you)** New logo and app icon; USPTO check on the Burghood name.
- [x] Store screenshots of the Burghood screens
      (`Images/store-screenshots/burghood/`); swap in real pilot ones with
      permission.
- [x] `docs/store/listing.md` text for societies, channels and services.
- [ ] Fold the Burghood additions into the store privacy answers
      (`docs/store/privacy-labels.md`) once the policy is final.
- [ ] Review account and "App Review HOA" test society on prod
      (`docs/store/listing.md`, App Review notes).
- [ ] Publish the final policy pages to fixburgh-prod hosting.

## Launch

- [ ] Production Remote Config: all feature flags off.
- [ ] Deploy rules, indexes, functions and hosting to fixburgh-prod
      **(you approve)**.
- [ ] Staged rollout: 10%, then 50%, then 100%, turning each feature flag
      on in prod Remote Config as its pilot checks pass. Flags are the kill
      switch for each feature.
- [ ] Exit check: pilot societies post, book and review without help;
      crashes under 0.5% of sessions; both stores approve the listing.
