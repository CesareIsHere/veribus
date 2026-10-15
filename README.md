<div align="center">

<img src="assets/images/logo.png" alt="Veribus logo" width="96" height="96">

# Veribus

**The real Rome bus & tram tracker.**<br>
Everything that is actually known about your bus, written so you can read it.

[![CI](https://github.com/CesareIsHere/veribus/actions/workflows/ci.yml/badge.svg)](https://github.com/CesareIsHere/veribus/actions/workflows/ci.yml)
[![Download APK](https://img.shields.io/badge/Android-download%20APK-3DDC84?logo=android&logoColor=white)](https://github.com/CesareIsHere/veribus/releases/latest)
[![Flutter](https://img.shields.io/badge/Flutter-3.47.5-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Material 3](https://img.shields.io/badge/Material-3-6750A4?logo=materialdesign&logoColor=white)](https://m3.material.io)
[![Supabase](https://img.shields.io/badge/Backend-Supabase-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

<img src="docs/screenshots/hero.jpg" alt="Veribus: arrivals at a stop, the nearby map, and a bus followed live on the map" width="100%">

[Download](#download) · [Features](#features) · [Quick start](#quick-start) · [Architecture](#architecture) · [Contributing](#contributing)

</div>

---

## Table of contents

- [Why Veribus](#why-veribus)
- [Features](#features)
- [Screenshots](#screenshots)
- [Download](#download)
- [Tech stack](#tech-stack)
- [Architecture](#architecture)
- [Project structure](#project-structure)
- [Quick start](#quick-start)
- [Configuration](#configuration)
- [Development](#development)
- [Backend setup](#backend-setup)
- [CI/CD and releases](#cicd-and-releases)
- [Before the public launch](#before-the-public-launch)
- [Contributing](#contributing)
- [Data and attribution](#data-and-attribution)
- [License](#license)

---

## Why Veribus

Rome's public transport publishes the same open data to everyone, but most apps show a single number ("4 min") and
hide how much it can be trusted. Veribus shows the whole picture, honestly: how reliable the prediction is, whether the
vehicle is moving or stuck at the terminus, and a warning when the trip you were waiting for disappears.

Every arrival has a **status** (Confirmed, To be checked, Scheduled, Suppressed, Canceled) that is always spelled out
in words, never told by color alone, and a one-line **reason** underneath. A scheduled time is never dressed up as
"minutes": minutes appear only for real-time predictions.

> The product spec, data measurements and technical document live in Notion (*App Bus Roma*). This README explains
> how to run, develop and ship the project.

## Features

- **Live arrivals** for every line at a stop, for the next 60 minutes, with status, reason and the vehicle behind them.
- **Minimal live maps**: a clean navigation-style base map (roads, water, green, street names, no buildings or shops),
  light and dark, with the buses (labelled with their line) refreshed every 15 seconds.
- **Nearby**: stops around you on a map or in a list, with the next arrival of each line.
- **Every bus leads to its line**: tap an arrival (stop, favorites, nearby, followed trips) and the line opens on its
  direction, with that trip's vehicle and **how the trip usually goes**: its delay at the stop on each of the last
  30 days of the same kind (weekdays or weekend), how often it was late, not tracked, canceled. Tap any bus on a map to
  see its whole route: dashed where it has been, solid where it still goes.
- **Buses without data are not dropped**: an arrival stays 10 minutes past its time ("it may still come") unless the
  bus was seen passing the stop.
- **Followed trips**: pick the exact trips you care about (say the 17:10 and 17:25 of line 64 at your stop), the weekdays
  they matter on, and up to three lead times (15, 10 and 5 minutes before). Veribus notifies you, even with the app closed,
  when the bus is about to pass, and when something happens to it: canceled, standing still, signal lost.
- **Line detail**: every stop in order with the vehicles between them, or the whole route on a map.
- **Daily timetable** by line, direction and day, from a stop or from a line (any stop along it).
- **Search** for lines and stops, running entirely on the phone, from its tab or straight from Nearby.
- **Favorites** for stops and lines (favorite stops first in the nearby list), and a dedicated **Alerts** section
  (severity is told by icon and text) filtered by line.
- **Honest signals**: cancelled trips, vehicles that stopped transmitting, stuck vehicles, old GPS fixes, late data,
  a stale feed. If the feed stops, the app says so.
- **A GPS that recovers by itself**: turn the location on while the app is open and the blue dot comes back, no restart.
- Material 3 design, light/dark theme, adaptive layouts, **Italian and English**.

## Screenshots

> Screenshots use the built-in demo data (`env/mock.json`): a handful of stops around Termini with arrivals in every status.

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/stop.jpg" width="160" alt="Arrivals at a stop"><br><sub><b>Arrivals</b><br>status and reason for every trip</sub></td>
    <td align="center"><img src="docs/screenshots/vehicle.jpg" width="160" alt="A bus followed live"><br><sub><b>Follow a bus</b><br>bus, stop and you in one view</sub></td>
    <td align="center"><img src="docs/screenshots/line-list.jpg" width="160" alt="Line detail"><br><sub><b>Line detail</b><br>stops on a rail, buses where they are</sub></td>
    <td align="center"><img src="docs/screenshots/line.jpg" width="160" alt="Line map"><br><sub><b>Line map</b><br>tap a bus: route travelled and still to go</sub></td>
    <td align="center"><img src="docs/screenshots/nearby.jpg" width="160" alt="Nearby map"><br><sub><b>Nearby</b><br>minimal map, blue dot is you</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/nearby-dark.jpg" width="160" alt="Dark mode"><br><sub><b>Dark mode</b><br>the map follows the theme</sub></td>
    <td align="center"><img src="docs/screenshots/alerts.jpg" width="160" alt="Service alerts"><br><sub><b>Alerts</b><br>one row, details on demand</sub></td>
    <td align="center"><img src="docs/screenshots/trips.jpg" width="160" alt="Followed trips"><br><sub><b>Followed trips</b><br>when, which days, how long before</sub></td>
    <td align="center"><img src="docs/screenshots/follow.jpg" width="160" alt="Follow a trip"><br><sub><b>Follow a trip</b><br>days and up to three notices</sub></td>
  </tr>
</table>

## Download

The latest Android build is attached to every [GitHub Release](https://github.com/CesareIsHere/veribus/releases/latest)
as `veribus-vX.Y.Z+N-arm64.apk` (release mode, arm64, about 24 MB).

1. Open the release page on your phone and download the `.apk`.
2. Allow *Install unknown apps* for your browser if Android asks.
3. Open the file to install.

To update, use **Settings → App updates**: it opens the releases page.

> **Updating over an existing install** only works when both builds are signed with the same key. Builds from the
> repository's CI use one stable key once the maintainer has run `tool/android_signing.sh` (see
> [CI/CD and releases](#cicd-and-releases)); until then, uninstall the previous build first.

## Tech stack

| Layer | Technology |
|---|---|
| **App** | Flutter 3.47.5 · Dart 3.13 · Material 3 · Riverpod 3 (codegen) · go_router · freezed / json_serializable |
| **Maps** | flutter_map · [OpenFreeMap](https://openfreemap.org) vector tiles drawn with the app's own minimal style (`vector_map_tiles`) · geolocator |
| **Backend** | [Supabase](https://supabase.com): Postgres 17 with SQL functions in the `api` schema, Auth, Storage, pg_cron, Edge Functions |
| **Realtime poller** | TypeScript on Deno (an Edge Function today, a container tomorrow) |
| **Raw archive** | Cloudflare R2 (S3-compatible, 30-day lifecycle rule) |
| **Quality** | very_good_analysis · riverpod_lint · flutter_test · mocktail · Deno test · SQL API tests |
| **CI/CD** | GitHub Actions: checks, nightly GTFS import, semver releases with an APK attached |

## Architecture

```mermaid
flowchart LR
  RSM[("RSM open data<br/>GTFS + GTFS-Realtime")]
  subgraph SB["Supabase"]
    PG[("Postgres<br/>network · live · config · api")]
    ST["Storage<br/>network/vMD5.json"]
    EF["Edge Function<br/>poller + notices"]
    CR["pg_cron<br/>every 10 s"]
  end
  FCM["Firebase Cloud<br/>Messaging"]
  GH["GitHub Actions<br/>nightly import"]
  R2[("Cloudflare R2<br/>raw snapshots")]
  APP["Flutter app"]

  RSM -- "GTFS zip" --> GH
  GH --> PG
  GH --> ST
  CR --> EF
  RSM -- "GTFS-RT feeds" --> EF
  EF --> PG
  EF --> R2
  EF -- "notices for followed trips" --> FCM
  FCM -- "push" --> APP
  APP -- "RPC api.* (user JWT)" --> PG
  APP -- "network file, once per version" --> ST
```

- The static network (stops, lines, trips, timetables) is imported every night and swapped atomically.
- The poller reads the real-time feeds every 10 seconds. The data changes at most every 30 seconds, so the app polls
  every 15 seconds while a page is open.
- Search and nearby stops run on the phone, on the network file downloaded once per version.

**Postgres schemas** (none exposed except `api`, row level security on everything):

| Schema | Content | Written by |
|---|---|---|
| `network` | stops, lines, main paths, trips, timetables, service days | the import, with an atomic swap |
| `network_meta` | imported versions, lines seen in real time | import, poller |
| `live` | vehicles, trip state, alerts, feed status, snapshot index, lease | the poller (role `poller`) |
| `config` | signal thresholds, minimum app version | by hand |
| `history` | when each tracked trip passed each stop, 30 days (`trip_run`, appended by `history.record` at every cycle) | the poller (role `poller`) |
| `notify` | what to notify now (`claim`), taking it back when sending failed (`release`), forgetting dead tokens | the poller (role `poller`) |
| `api` | `network()`, `arrivals(stop_ids, route_ids)`, `route(route_id, direction_id)`, `timetable(stop_id, route_id, day)`, `alerts()`, `my_follows()`, `trip_history(stop_id, route_id, direction_id, departure_s, weekend)`, `register_push_token(token, locale)` | nothing: read-only functions, except the token (one device, one user) |

Two small tables live in `public` (row level security, owner only): `push_tokens` (FCM token and app language per device)
and `trip_follow` (the trips each user follows).

**Followed trips.** A follow is *stop + line + direction + scheduled time at the stop + weekdays + 1 to 3 lead times*:
what stays true when the GTFS is reimported, resolved to that day's trip every time. After each cycle the poller calls
`notify.claim`, a SQL function that works out which notices are due (it reuses the arrivals rules for status and
signals), records each one as sent in the same statement, and returns it with the user's device tokens. The poller
(`backend/core/notify.ts`) writes the text in the language of each device and sends it through FCM; if FCM is down the
record is taken back and the next cycle retries. Each notice goes out once: with several lead times due at once (a new
follow, a phone that was off) only the nearest is sent. Notices of the same trip replace each other on the phone.

**Where the signals are computed.** What needs history is computed by the poller (S1 canceled, S2 trip vanished →
suppressed, S3 vehicle stopped, S5 at the terminus). What depends on the moment of reading is computed by the API
(S4 old GPS, S6 late data, stale feed, approximate time). If the poller dies, the API keeps telling the truth.

**App layers** (see [CLAUDE.md](CLAUDE.md) for the conventions): UI → notifiers/providers (`features/*/providers`) →
`repositories/` (backend data) and `services/` (SDK and platform wrappers). The backend is chosen only in the
repository providers (`BACKEND=mock|supabase`); UI code never knows which one it talks to. One place turns status,
signal and time into words: `features/stop/components/arrival_tile.dart`.

## Project structure

```
.
├── lib/
│   ├── core/            app shell, router, config, shared widgets (TransitMap, VehiclesLayer, …)
│   ├── features/        nearby · search · favorites · alerts · stop · line · notifications · settings · auth
│   ├── models/          transit (network, live data), user
│   ├── repositories/    I<X>Repository + mock_ / supabase_ implementations + providers
│   ├── services/        location, map tiles, push, sign-in wrappers
│   ├── styles/          Material 3 theme, spacing tokens, the minimal map style
│   └── l10n/            ARB files (it, en) and generated localizations
├── backend/
│   ├── core/            the engine: pure TypeScript, no I/O (signals, cycle)
│   ├── adapters/        HTTP, Postgres and FCM adapters
│   ├── runtimes/        Edge Function and container entry points
│   ├── static-import/   nightly GTFS import (bash + psql)
│   └── replay/          re-run the engine over an archive
├── supabase/            migrations and API tests
├── env/                 per-stage configuration (dev, mock, local, staging, prod)
├── tool/                project scripts (feature stripping, Android signing)
├── test/                app tests
└── .github/workflows/   CI, import, release, deploy
```

## Quick start

### Run it with no server (demo data)

```bash
fvm install && flutter pub get          # or use Flutter 3.47.5 directly
flutter run --dart-define-from-file=env/dev.json
```

`env/dev.json` uses the **mock** backend: a handful of stops around Termini with arrivals in every status. Login is
mandatory, but with the mock any email works (the password `wrongpass` simulates an error).

**Full mock mode**, to check the look of every screen (also on the web with `-d chrome`):

```bash
flutter run --dart-define-from-file=env/mock.json
```

It starts signed in (`MOCK_SIGNED_IN`) at a fixed position near Termini (`MOCK_POSITION`). The demo data covers the
edge cases on purpose: arrivals in every status and with every signal, a stop whose real-time data is stale,
a stop with no arrivals, a line without real time, a line with no trips in service, a line with variant stops.

### Run it with real buses, locally

Everything on your machine, no cloud project (needs Docker with at least 4 GB of RAM):

```bash
supabase start                                   # full stack: Postgres, Auth, API, Storage (migrations included)
bash backend/static-import/local.sh              # downloads today's GTFS and imports it (~3 minutes)
cd backend && DB_URL=postgresql://postgres:postgres@127.0.0.1:54322/postgres deno task poller   # leave it running
flutter run --dart-define-from-file=env/local.json                                              # in another terminal
```

Sign up with any email: locally there is no confirmation step (emails land in Mailpit, <http://127.0.0.1:54324>). The
poller downloads the real feeds every 10 seconds and archives the snapshots in `backend/archive`.

- On the Android emulator use `SUPABASE_URL: http://10.0.2.2:54321`.
- In the browser and on desktop you can pin the position with `--dart-define=MOCK_POSITION=41.9005,12.4960`.
- There is no nightly import locally: the network covers yesterday to 7 days ahead, so run `local.sh` at least once a week.

## Configuration

The app is configured at compile time with `--dart-define-from-file=env/<stage>.json`. Without a file it runs on the
mock backend with every optional feature off.

| Key | Meaning |
|---|---|
| `APP_STAGE`, `APP_NAME` | stage (`dev`, `staging`, `prod`) and display name |
| `BACKEND` | `mock` or `supabase` |
| `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` | the Supabase project (publishable key only: it is public by design) |
| `AUTH_REDIRECT_URL` | where OAuth returns on mobile (an App Link handled by the app) |
| `GOOGLE_SERVER_CLIENT_ID` | web client id for Google sign-in |
| `SEED_COLOR` | Material 3 seed color (`0xFF3F51B5`): change it to rebrand |
| `SENTRY_DSN` | crash reporting, off when empty |
| `SUPPORT_EMAIL`, `TERMS_URL`, `PRIVACY_URL`, `APP_STORE_ID` | support and legal links |
| `RELEASES_URL` | where *Settings → App updates* points (defaults to this repository's latest release) |
| `FEATURE_SOCIAL_LOGIN`, `FEATURE_CONNECTIVITY`, `FEATURE_FEEDBACK` | feature flags (compile-time: code behind a `false` flag is dropped) |
| `MOCK_SIGNED_IN`, `MOCK_POSITION` | mock mode only: start signed in, at a fixed `"lat,lon"` |

## Development

```bash
# App
flutter run --dart-define-from-file=env/dev.json    # mock backend
dart run build_runner watch -d                      # Riverpod / freezed / json codegen
flutter gen-l10n                                    # after editing the ARB files (it + en)
dart format lib test tool && flutter analyze && flutter test

# Poller: format, lint, types, engine tests (one per signal) and cycle tests on real snapshots
cd backend && deno task check

# Database: migrations + a minimal GTFS generated on the fly + API tests (needs Docker)
docker run -d --name vb-test -e POSTGRES_PASSWORD=postgres -v "$PWD:/repo" supabase/postgres:17.6.1.177 \
  -c config_file=/etc/postgresql/postgresql.conf
docker exec vb-test bash /repo/supabase/tests/run.sh

# Poller on the real feeds against a local Postgres (without R2_* the archive goes to backend/archive)
cd backend && DB_URL=postgres://postgres:postgres@localhost:54322/postgres deno task poller

# Re-run the engine over an archive: a CSV with the state changes of every trip
# (a day of production: rclone copy r2:veribus-archive/vp/2026/09/27 backend/archive/vp/2026/09/27, same for tu)
cd backend && DB_URL=... deno run -A replay/main.ts archive > changes.csv
```

To import the real GTFS locally: `GTFS_DIR=<unzipped folder> DB_URL=... bash backend/static-import/import.sh`
(about a minute; without `SUPABASE_URL` the network file stays in `network.json`).

**Quality bar.** `dart format`, `flutter analyze` (zero issues: very_good_analysis plus riverpod_lint) and
`flutter test` must pass before every push. Use `dart analyze` for the same view CI has: it loads the riverpod_lint
plugin. Generated files (`*.g.dart`, `lib/l10n/gen`) are committed and CI checks they are up to date.

## Backend setup

Done once per project. You need a Supabase project, a Cloudflare R2 bucket and the
[Supabase CLI](https://supabase.com/docs/guides/local-development/cli/getting-started).

**Supabase plan.** The imported network keeps only the timetables from yesterday to 7 days ahead: the database comes to
about **420 MB** (measured on the 27 Sep GTFS: 3.4 M stop times instead of 4.9 M). During the nightly import the old and
the new network coexist and it climbs to about 880 MB, so:

- **Pro** (8 GB): normal import; the active network stays in service until the new one has passed the checks.
- **Free** (500 MB): set the repository variable `IN_PLACE=1`. The import deletes the active network first and rebuilds
  it (measured peak 476 MB). The API is down for about 3 minutes every night, and if the import fails the network is
  missing until the next successful import. The margin is a few tens of MB: fine for development and testing, not for a beta.

1. **Schema**: `supabase link --project-ref <ref>` and `supabase db push` (tables, the `poller` role, the `network`
   bucket, the `api` functions, the pg_cron job).
2. **Expose the API**: dashboard → *Settings → API → Exposed schemas*, add `api` (locally `supabase/config.toml` does it).
3. **Poller role**: `alter role poller with login password '<password>';`
4. **First import**: put `SUPABASE_DB_URL` (pooler in *session* mode, user `postgres.<ref>`, not just `postgres`),
   `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` in the GitHub repository secrets, then run the *Static import*
   workflow by hand. From then on it runs every night at 06:30.
5. **R2 archive**: create a bucket (e.g. `veribus-archive`), an *Object lifecycle* rule in its settings that deletes
   objects after 30 days, and an R2 API token with *Object Read & Write* on that bucket only. Cost: 0.65–1 GB a day
   (measured on 1 Oct), about 20–30 GB at steady state, roughly $0.15–0.30 a month above the free 10 GB (with 7 days it
   is free); the writes (~180,000 a month) fit in the free million.
6. **Poller**:
   ```bash
   supabase secrets set POLLER_SECRET=<random string> \
     POLLER_DB_URL=postgres://poller.<ref>:<password>@<pooler-host>:5432/postgres \
     R2_ACCOUNT_ID=<account id> R2_ACCESS_KEY_ID=<key> R2_SECRET_ACCESS_KEY=<secret> R2_BUCKET=veribus-archive \
     HEALTHCHECKS_URL=https://hc-ping.com/<uuid>
   supabase functions deploy poller
   ```
   and, in SQL, the two secrets pg_cron uses to call it:
   ```sql
   select vault.create_secret('https://<ref>.supabase.co/functions/v1/poller', 'poller_url');
   select vault.create_secret('<the same string as POLLER_SECRET>', 'poller_secret');
   ```
7. **Monitoring**: a check on [Healthchecks.io](https://healthchecks.io) with a 1-minute period and a 5-minute grace.
   A failing import fails the workflow and GitHub sends the email.
8. **App**: set `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` in `env/staging.json` and `env/prod.json`.
9. **Push notifications** (followed trips): see the next section. Without it the app works as before and the follow
   screens warn that notifications are off.

**Moving to Cloud Run** (when the p95 CPU of the cycle exceeds 1 s, or an always-on process is needed):
`backend/runtimes/container/main.ts` is the same cycle in a loop. Start it with `DB_URL` and the `R2_*` variables
(minimum 1 instance, CPU always allocated), then `select cron.unschedule('poller');`. The lease in `live.lease`
prevents double cycles during the switch.

### Push notifications (followed trips)

Notices travel through Firebase Cloud Messaging; the Spark (free) plan is enough. Once:

1. **Firebase project**: create one at the [console](https://console.firebase.google.com), add an *Android app* with the
   package `com.emilianocesare.veribus` and download `google-services.json`.
2. **The app build**: the file is not in the repository. Locally copy it to `android/app/google-services.json` (git
   ignores it); for the release APK store it in a repository secret:
   ```bash
   base64 -w0 google-services.json | gh secret set GOOGLE_SERVICES_JSON_BASE64
   ```
   Without it the APK builds and runs, but cannot receive notifications. The Gradle plugin is applied only if the file exists.
3. **The server**: *Project settings → Service accounts → Generate new private key*, then
   ```bash
   supabase secrets set FCM_SERVICE_ACCOUNT="$(cat <the downloaded key>.json)"
   supabase functions deploy poller
   ```
   (the container runtime reads `FCM_SERVICE_ACCOUNT` from its environment). Without the secret the poller does exactly
   what it did before and nobody is notified.
4. **Check**: follow a trip that passes in a few minutes (Stop → Timetable → tap the time), and watch the poller's log:
   `notices` in the cycle summary says how many were claimed and sent.

**iOS is not wired yet** (the app skips push there, because without `GoogleService-Info.plist` Firebase's iOS SDK aborts). It needs the Push Notifications capability and a `Runner.entitlements`, the APNs key uploaded in
*Firebase → Cloud Messaging*, and `GoogleService-Info.plist` in `ios/Runner`; the Dart side is already there.

### Auth (Supabase)

- **Authentication → URL Configuration**: *Site URL* = your domain; in *Redirect URLs* add `AUTH_REDIRECT_URL` and,
  for the web in development, `http://localhost:*/**`.
- **Email Templates → Reset password**: the link must be `{{ .SiteURL }}/reset-password?token={{ .TokenHash }}`.
- **Google**: provider with the **web** client id (+ the iOS one in *Authorized Client IDs*), *Skip nonce check* on.
  Android: SHA-1 on Google Cloud, `GOOGLE_SERVER_CLIENT_ID` = the web client id. iOS: `GIDClientID` and the URL scheme in `Info.plist`.
- **Apple**: *Sign in with Apple* capability in Xcode; on Android and web an OAuth redirect (Services ID and key in the provider).
- **Reset deep link**: replace `example.com` in the `AndroidManifest.xml` intent filter and publish
  `/.well-known/assetlinks.json`; on iOS *Associated Domains* + `apple-app-site-association`.

## CI/CD and releases

| Workflow | When | What it does |
|---|---|---|
| `ci.yml` | every PR and push to `main` | app: codegen is up to date, format, analyze, test, web compile check · backend: `deno task check` and the SQL API tests |
| `release.yml` | every push to `main` | bumps the semver from the commits, tags it, creates the GitHub Release and attaches the release APK. Run by hand with a tag to rebuild only the APK of an existing release |
| `static_import.yml` | every night and by hand | imports the GTFS when its md5 changed (`vars.IN_PLACE=1` on the free plan) |
| `deploy_android.yml` · `deploy_ios.yml` · `deploy_web.yml` | after a release, if `vars.DEPLOY_ANDROID` / `DEPLOY_IOS` / `DEPLOY_WEB` is `true` | Play Store (internal track) · TestFlight · Firebase Hosting |
| `revert_release.yml` | a merged PR titled `Revert …` | reverts the last version bump and deletes its release |

The secrets and variables each workflow needs are listed at the top of its file.

**Versioning.** Versions come from [Conventional Commits](https://www.conventionalcommits.org): `feat:` bumps the
minor, `fix:` (or anything else) the patch, `feat!:` or a `BREAKING CHANGE` in a commit body the major, and `chore:`
alone only the build number. The highest bump among the pushed commits wins. Put `[skip release]` in the head commit
message to publish nothing.

**The release APK** is built in release mode for arm64 only, with R8 code and resource shrinking and the debug
symbols moved out of the binary (kept as a workflow artifact for 90 days).

**Push.** The release APK also needs the `GOOGLE_SERVICES_JSON_BASE64` secret to receive notifications (see *Push
notifications* above); `release.yml` warns when it is missing.

**Signing.** For an APK downloaded from the releases to install *over* the previous one, every build must be signed
with the same key. Once: `bash tool/android_signing.sh` (needs an authenticated `gh` and `keytool`) creates the
keystore and sets the `ANDROID_KEYSTORE_*` / `ANDROID_KEY_*` repository secrets. Keep `veribus-release.jks` and its
password somewhere safe: if you lose them, users must uninstall to update. Without those secrets `release.yml` signs
with a throwaway debug key that changes on every build (it installs, but it cannot be updated).

## Before the public launch

- Google Play listing: texts, images, Console answers and blockers are in [`store/`](store/README.md).
- Map tiles: the app draws OpenFreeMap vector tiles with its own style (no key needed, see
  `lib/styles/minimal_map_style.dart`). Check OpenFreeMap's terms of use for your expected traffic and consider hosting
  the tiles. `vector_map_tiles` is on its 9.x beta line, the one compatible with flutter_map 8.
- Terms for the RSM data and the attribution text. Privacy policy and terms are `web/privacy.html` and
  `web/terms.html`, published with the web app (`PRIVACY_URL`, `TERMS_URL` in `env/prod.json`).
- A per-client rate limit on the API.
- The signing key for the release APK (see above) and the store credentials if you enable the deploy workflows.

## Contributing

Contributions are welcome. The short version:

1. **Open an issue first** for anything bigger than a fix (templates for bugs, features, improvements and
   documentation are in `.github/ISSUE_TEMPLATE`).
2. **Branch** from `main` and keep the change focused.
3. **Follow the conventions** in [CLAUDE.md](CLAUDE.md): Riverpod with codegen only; strings only in the ARB files
   (it + en); Material 3 defaults, colors from `context.colors` / `context.appColors` and spacing from `Spacing.*`,
   never hard-coded; layers UI → providers → repositories/services; code, comments and SQL names in English.
4. **Check locally** before pushing: `dart format lib test tool`, `dart analyze`, `flutter test`, and
   `cd backend && deno task check` if you touched the backend. Database changes are new files in
   `supabase/migrations`, with row level security on every table.
5. **Use a Conventional Commit title** (`feat(stop): …`, `fix(map): …`): it decides the next version.
6. **Open a pull request** with the repository template. CI must be green.

Look at the screen, not only at the code, when you change the UI: the app runs in the browser with demo data
(`flutter run -d chrome --dart-define-from-file=env/mock.json`).

## Data and attribution

- Static and real-time transit data: open data of **Roma Servizi per la Mobilità** (GTFS and GTFS-Realtime). Veribus is
  an independent project, **not affiliated with Atac or RSM**. The data comes from automated instrumentation and is not
  exhaustive: road variability and malfunctions can make it inaccurate, and the app says so.
- Base map: © [OpenStreetMap](https://www.openstreetmap.org/copyright) contributors, © [OpenMapTiles](https://openmaptiles.org),
  served by [OpenFreeMap](https://openfreemap.org). The attribution is shown on every map.

## License

[MIT](LICENSE) © Emiliano Cesare
