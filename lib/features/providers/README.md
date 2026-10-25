# providers

Burghood service providers (Phases 3 and 4): the provider directory and
profiles, "Become a provider", the provider's jobs, reviews, and later
listing fees and sponsored listings (`feature_monetisation`).

Not to be confused with Riverpod providers, which live next to the code that
uses them in every feature.

- `domain/provider.dart`: the profile, the Bayesian rank score (a new
  provider counts as 10 reviews at 4 stars) and the result order:
  recommended by your society, then rank, then distance.
- `data/provider_repository.dart`: search by category and keywords within a
  distance, applications with documents (private Storage, platform admins
  only), portfolio, reviews and replies, society recommendations.
- `presentation/`: the public profile and Become a provider.

Platform admins approve, reject, suspend and record background checks in the
admin console (`hosting/public/admin`), through callable functions.

Firestore: `providers/{id}` with its `reviews` and `audit` subcollections,
`societies/{sid}/recommended/{id}`, and later `sponsorships`.
