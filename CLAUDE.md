# CLAUDE.md

Flutter app template (Android, iOS, Web). Read README.md for the feature list.

## Toolchain
- Flutter 3.47.5 pinned in `.fvmrc` and `pubspec.yaml` (`fvm flutter ...` if FVM is used).
- Run: `flutter run --dart-define-from-file=env/dev.json` (mock backend, no server).
- After changing `@riverpod`/`@freezed`/`@JsonSerializable` code: `dart run build_runner build -d`.
- After changing `lib/l10n/*.arb`: `flutter gen-l10n`. Generated files are committed.
- Before finishing: `dart format lib test tool`, `flutter analyze` (must be clean), `flutter test`.
- Line length 120 (`analysis_options.yaml`). Lints: very_good_analysis + riverpod_lint.

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
- Supabase: schema changes are new files in `supabase/migrations` (`supabase migration new <name>`), every table
  with RLS on and policies using `(select auth.uid())`. Demo-only SQL goes in files listed under `demo`.
- Server-side logic: Cloud Functions following `docs/FIREBASE_FUNCTIONS.md` (Supabase: Edge Functions or SQL).
- The personal-finance demo is the `demo` feature (`FEATURE_DEMO`); its transactions stack is the reference
  pattern for new entities.
