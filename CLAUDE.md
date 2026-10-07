# CLAUDE.md

Veribus: Rome bus/tram app (Flutter) + realtime backend (Supabase, Deno). README.md has the architecture and setup;
the product spec and technical doc are in Notion (*App Bus Roma*). All code, comments, SQL names and API JSON keys in
English; user-facing strings in the ARB files. Login is mandatory (product decision, overrides spec RNF-04).

## Toolchain
- Flutter 3.47.5 pinned in `.fvmrc` and `pubspec.yaml` (`fvm flutter ...` if FVM is used).
- Run: `flutter run --dart-define-from-file=env/dev.json` (mock backend, no server).
- After changing `@riverpod`/`@freezed`/`@JsonSerializable` code: `dart run build_runner build -d`.
- After changing `lib/l10n/*.arb`: `flutter gen-l10n`. Generated files are committed.
- Before finishing: `dart format lib test tool`, `flutter analyze` (must be clean), `flutter test`.
- Line length 120 (`analysis_options.yaml`). Lints: very_good_analysis + riverpod_lint.
- Backend: `cd backend && deno task check` (fmt, lint, types, engine tests). API: `supabase/tests/run.sh` in the
  `supabase/postgres` image (see README). `backend/core` must not import adapters, runtimes or Supabase.
- `api` functions are PL/pgSQL (never `language sql` or `BEGIN ATOMIC`, never `%ROWTYPE` of `network` tables): the
  import drops and recreates the `network` schema at every swap.

## Conventions
- Structure follows Atoms Platform: `core/`, `features/<f>/{components,providers}/`, `models/<domain>/`,
  `repositories/<domain>/` (`I<X>Repository` + `mock_`/`rest_`/`firebase_`/`supabase_` impls + `*_provider.dart`), `services/api/`.
- Riverpod 3 codegen only. Class `FooNotifier` generates `fooProvider`. `ref.watch` in build, `ref.read` in callbacks.
- Backend is chosen only in the repository providers via `AppConfig.backend`. UI/notifiers never know it.
- Layers: UI → notifiers/providers (`features/*/providers`) → `repositories/` (backend data) and `services/`
  (SDK/platform wrappers). Only repositories and services import SDKs (Firebase, Supabase, RevenueCat, local_auth...);
  each is exposed by a provider so tests can override it. Pages never call a data SDK or a repository directly;
  UI-only platform plugins (url_launcher, image_picker, in_app_review) are fine in pages.
- Error text for users lives in `extensions/app_failure_extensions.dart`, not in `AppFailure` (data layer).
- Errors: repositories throw (`AppFailure` or raw Dio/Firebase/Supabase errors). UI actions go through
  `ExceptionHandler.handle(context, ...)`; loading states render `AsyncValue` + `MessageView.error`.
- Pages expose `static const route`; register them in `core/navigation/router.dart`.
  Redirect rules live in the pure `appRedirect()` function (tested).
- Strings only in ARB files (it + en). Styles only in `styles/app_theme.dart` (use `context.colors`).
- Classic constructors (`ClassName(...)`), not the Dart 3.13 `new(...)` shorthand.

## Material 3 design system (mandatory)
- Keep M3 component defaults; theme overrides only in `styles/app_theme.dart`. No hard-coded colors (use
  `context.colors` / `context.appColors`) and no raw spacing numbers: use `Spacing.*` from `styles/app_spacing.dart`.
- Gaps: 8 between buttons in a group, 16 between fields/cards, 24 between sections; page margins via
  `context.pagePadding()` / `context.listPadding()` (ListTile already has its 16dp inset).
- Dialogs: `showConfirmDialog` (text buttons, confirm label = the action verb), `showChoiceDialog` for options.
  Create/edit screens are full-screen dialogs (close icon + Save text button).
- Adapt by `context.windowSize` (compact/medium/expanded/large), constrain content with `ContentWidth`.
- Empty/error states: `MessageView`; list subheaders: `SectionHeader`; snackbars: `context.showSnackBar`.

## Feature toggles
- Flags: `Features.*` in `lib/core/config.dart`, set by `FEATURE_*` keys in `env/*.json`.
- Code belonging to an optional feature must be marked so `tool/setup.dart` can strip it:
  a single line ending in `// feature:<name>`, or a block between `// feature:<name>:start` and
  `// feature:<name>:end`. Same for backends (`backend:rest`, `backend:firebase`, `backend:supabase`) and `firebase`.
- A new optional feature needs an entry in `tool/features.json` (flag, paths, packages).
- Push (`FEATURE_PUSH`) = followed trips + FCM notices. The app needs `android/app/google-services.json` (git-ignored; CI secret
  `GOOGLE_SERVICES_JSON_BASE64`) and the poller `FCM_SERVICE_ACCOUNT`; without them everything else still works. iOS is
  skipped in `FirebasePushService`. What to notify is decided in SQL (`notify.claim`), the text is written in
  `backend/core/notify.ts` (it/en): a new notice type touches both.
- Supabase: schema changes are new files in `supabase/migrations` (`supabase migration new <name>`), every table
  with RLS on and policies using `(select auth.uid())`. Demo-only SQL goes in files listed under `demo`.
- Server-side logic: Cloud Functions following `docs/FIREBASE_FUNCTIONS.md` (Supabase: Edge Functions or SQL).
- Reference pattern for new data: `repositories/transit` (interface + mock + supabase + provider), `models/transit`,
  `features/stop`. Status/signal/time wording lives only in `features/stop/components/arrival_tile.dart`.
