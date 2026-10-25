# services

Burghood service requests (Phase 3): residents post or book a job, the
provider completes it, and the resident confirms and reviews it. Gated by the
`feature_services` Remote Config flag.

- `domain/service_category.dart`: the category groups read from the
  `service_categories` Remote Config JSON (default bundled in
  `lib/app/remote_config.dart`, kept in step with
  `firebase/remoteconfig.template.json` by a test), and `detectCategories`,
  which finds the category from everyday words ("kitchen tap leaking").
- `domain/service_request.dart`: the request, its status machine and the
  fields each category asks for.
- `data/service_request_repository.dart`: posting with photos, the poster's,
  provider's and society admin's steps. `data/request_outbox.dart` keeps
  requests made offline until they send.
- `presentation/`: "Where is the problem?" on the Report tab, the society's
  Services tab, the request form and detail (timeline, actions, review), and
  the Activity segments.

Firestore: `serviceRequests/{id}` with its `events` timeline, written by
Cloud Functions (`functions/src/services.ts`), which also send the pushes.
