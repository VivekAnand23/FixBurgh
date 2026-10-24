# services

Burghood service requests (Phase 3): residents post or book a job, the
provider completes it, and the resident confirms and reviews it. Gated by the
`feature_services` Remote Config flag.

Today it holds only `domain/service_category.dart`: the category groups read
from the `service_categories` Remote Config JSON (default bundled in
`lib/app/remote_config.dart`, kept in step with
`firebase/remoteconfig.template.json` by a test).

Firestore: `serviceRequests`. Same `data/` / `domain/` / `presentation/`
layout as the other features.
