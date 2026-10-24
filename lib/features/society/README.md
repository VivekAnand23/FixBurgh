# society

Burghood societies (Phases 1 and 2): find, join and create a society,
notices, documents, the HOA link, and later the community channels.

Today it holds only `SocietyScreen`, the Society tab, which shows "Coming
soon" while the `feature_society` Remote Config flag is off. Joining needs an
account, so actions here go through `requireFullAccount`
(`features/auth/account_gate.dart`).

Follow the existing feature layout as it grows: `data/` (Firestore
repositories and providers), `domain/` (plain Dart models) and
`presentation/` (screens and widgets, Riverpod `ConsumerWidget`s), with routes
added to `lib/app/router.dart`. Firestore paths: `societies/{id}` and its
`members`, `channels`, `posts`, `comments`, `reactions`, `notices`,
`documents` and `hoa` subcollections, plus `societyClaims`.
