# Emiliano Cesare Flutter Template

Template Flutter pronto all'uso per app **Android, iOS e Web**: crei il repo dal template, lanci uno script, tieni solo le feature che ti servono.

- **Flutter 3.47.5** (fissato in `.fvmrc` e `pubspec.yaml`), Dart 3.13
- **Riverpod 3** + codegen, **go_router 18**, **freezed**
- Backend intercambiabile: **Mock** (nessun server), **REST** (JWT), **Firebase** o **Supabase**
- Feature accendibili/spegnibili con un flag, rimovibili per sempre con `tool/setup.dart`
- CI/CD completa: check su PR, versioning automatico, deploy Web / Play Store / TestFlight

---

## Indice

- [Quick start](#quick-start)
- [Cosa c'è dentro](#cosa-cè-dentro)
- [Ambienti e feature flag](#ambienti-e-feature-flag)
- [Backend: Mock, REST, Firebase, Supabase](#backend-mock-rest-firebase-supabase)
- [Architettura](#architettura)
- [Setup per feature](#setup-per-feature)
- [Comandi utili](#comandi-utili)
- [CI/CD](#cicd)
- [Docker](#docker)

---

## Quick start

```bash
# 1. "Use this template" su GitHub, poi clona il nuovo repo
fvm install                      # usa la versione di Flutter fissata in .fvmrc
flutter pub get

# 2. Personalizza: nome, id, backend e feature da eliminare (fai prima un commit!)
dart run tool/setup.dart --name my_app --org com.acme --display-name "My App" \
    --backend supabase --without payments,ai

# 3. Avvia (backend mock, nessun server necessario)
flutter run --dart-define-from-file=env/dev.json
```

Con il backend mock qualsiasi email funziona. La password `wrongpass` simula un errore di login.

`dart run tool/setup.dart --help` elenca tutte le opzioni, e `--dry-run` mostra cosa cambierebbe senza toccare nulla.

---

## Cosa c'è dentro

| Area | Feature | Flag / toggle |
|---|---|---|
| **Core** | Riverpod 3 + codegen, go_router, freezed, lint very_good_analysis + riverpod_lint | sempre attivo |
| | Ambienti dev/staging/prod (`env/*.json`) | sempre attivo |
| | Tema Material 3 da colore seed, dark mode persistita | sempre attivo |
| | Localizzazione it/en (gen-l10n), lingua selezionabile | sempre attivo |
| | Shell adattiva: bottom bar / rail / rail estesa | sempre attivo |
| | Errori tipizzati (`AppFailure`) con messaggi localizzati | sempre attivo |
| | Logging con Talker (log visibili in app nelle build non prod) | sempre attivo |
| | Crash reporting **Sentry** (attivo se `SENTRY_DSN` è valorizzato) | `SENTRY_DSN` |
| | Splash nativa + icone generate, pagina 404, splash di sessione | sempre attivo |
| **Auth** | Login, registrazione, password dimenticata, reset da deep link | sempre attivo |
| | Profilo (nome, avatar), **cancellazione account** (obbligatoria per gli store) | sempre attivo |
| | Google / Apple sign-in | `FEATURE_SOCIAL_LOGIN` |
| **Dati** | Client HTTP Dio con token + refresh automatico su 401 | backend REST |
| **Demo** | App di finanza personale: dashboard mensile, movimenti con filtri, paginazione, swipe-to-delete con annulla, form completo, insight Premium | `FEATURE_DEMO` |
| **Feature** | Onboarding | `FEATURE_ONBOARDING` |
| | Banner offline | `FEATURE_CONNECTIVITY` |
| | Recensione in-app | `FEATURE_APP_REVIEW` |
| | Invio feedback (mailto a `SUPPORT_EMAIL`) | `FEATURE_FEEDBACK` |
| | Blocco con biometria / PIN | `FEATURE_BIOMETRIC_LOCK` |
| | Push FCM + notifiche locali + apertura della pagina al tap | `FEATURE_PUSH` 🔥 |
| | Aggiornamento forzato / manutenzione (Remote Config) | `FEATURE_REMOTE_CONFIG` 🔥 |
| | Analytics con tracking automatico delle schermate | `FEATURE_ANALYTICS` 🔥 |
| | Abbonamenti RevenueCat + paywall | `FEATURE_PAYMENTS` |
| | Chat AI Gemini (Firebase AI Logic) | `FEATURE_AI` 🔥 |
| **DevOps** | CI, release semver da titolo PR, revert, deploy Web/Android/iOS, Dependabot, Docker | [CI/CD](#cicd) |

🔥 = richiede Firebase configurato (`flutterfire configure`).

---

## Ambienti e feature flag

Tutta la configurazione passa da `--dart-define-from-file`:

| File | Uso | Backend di default |
|---|---|---|
| `env/dev.json` | sviluppo locale | `mock` |
| `env/staging.json` | test / QA | `rest` |
| `env/prod.json` | produzione | `rest` |

I valori vengono letti come costanti in [lib/core/config.dart](lib/core/config.dart) (`AppConfig`, `Features`). Siccome i flag sono `const`, il compilatore **elimina il codice** dietro un flag `false`.

Per i segreti locali crea `env/dev.local.json` (è ignorato da git) e lancia con quello.

Chiavi principali:

| Chiave | Descrizione |
|---|---|
| `APP_STAGE` | `dev` / `staging` / `prod` (in prod i log in-app sono nascosti) |
| `BACKEND` | `mock` / `rest` / `firebase` / `supabase` |
| `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` | progetto Supabase (chiave `sb_publishable_...`, mai la secret key) |
| `AUTH_REDIRECT_URL` | dove torna l'OAuth Supabase su mobile (App Link, es. `https://tuodominio.com/`) |
| `API_BASE_URL` | base URL dell'API REST |
| `SENTRY_DSN` | vuoto = Sentry disattivato |
| `SEED_COLOR` | colore del brand (`0xFFRRGGBB`), da cui deriva tutto il tema |
| `SUPPORT_EMAIL`, `TERMS_URL`, `PRIVACY_URL` | link nelle Impostazioni |
| `FEATURE_*` | accende o spegne la feature |

**Spegnere o eliminare una feature.** Metti il flag a `false` per spegnerla. Per rimuoverla del tutto (codice + pacchetti) usa `dart run tool/setup.dart --without <feature>`. Lo script usa i marker nel codice:

```dart
import '...push_notifications_provider.dart'; // feature:push   ← riga rimossa

// feature:push:start                                            ← blocco rimosso
...
// feature:push:end
```

Le cartelle e i pacchetti di ogni feature sono elencati in [tool/features.json](tool/features.json).

---

## Backend: Mock, REST, Firebase, Supabase

Ogni repository ha un'interfaccia `I…Repository` e un'implementazione per backend. Il backend si sceglie **in un solo punto**, il provider del repository:

```dart
@Riverpod(keepAlive: true)
IAuthRepository authRepository(Ref ref) => switch (AppConfig.backend) {
  Backend.mock => MockAuthRepository(),
  Backend.rest => RestAuthRepository(...),
  Backend.firebase => FirebaseAuthRepository(),
  Backend.supabase => SupabaseAuthRepository(),
};
```

UI e notifier non sanno quale backend è attivo: per passare da REST a Firebase o Supabase basta cambiare `BACKEND` nel file env.

| | Mock | REST | Firebase | Supabase |
|---|---|---|---|---|
| Auth | in memoria | JWT access + refresh (`docs/BACKEND_API.md`) | Firebase Auth | Supabase Auth (PKCE) |
| Sessione | in memoria | `flutter_secure_storage` | SDK Firebase | SDK Supabase (refresh automatico) |
| Dati (demo) | generati | `GET /transactions` | Firestore `users/{uid}/transactions` | Postgres `transactions` + RLS |
| Avatar | in memoria | `POST /me/avatar` multipart | Firebase Storage | Storage, bucket `avatars` |
| Token push | ignorato | `POST /devices` | Firestore `users/{uid}.pushTokens` | tabella `push_tokens` |
| Cancellazione account | in memoria | `DELETE /me` | Firebase Auth | funzione SQL `delete_account()` |
| Regole di sicurezza | – | server | `firestore.rules`, `storage.rules` | policy RLS in `supabase/migrations` |

Il contratto REST atteso è in [docs/BACKEND_API.md](docs/BACKEND_API.md). La logica server (trigger, invio push, webhook) va nelle Cloud Functions: vedi [docs/FIREBASE_FUNCTIONS.md](docs/FIREBASE_FUNCTIONS.md).

Push, Remote Config, Analytics e AI usano Firebase anche con backend Supabase o REST: `Firebase.initializeApp` parte solo se una di queste feature è accesa.

---

## Architettura

La struttura riprende quella di Atoms Platform:

```
lib/
├── main.dart                  # bootstrap: error handling, prefs, Firebase, Supabase, Sentry, ProviderScope
├── firebase_options.dart      # placeholder, sovrascritto da `flutterfire configure`
├── core/
│   ├── app/app.dart           # MaterialApp.router + gate globali (lock, update)
│   ├── config.dart            # AppConfig + Features (da env/*.json)
│   ├── navigation/            # router (redirect testato), AppShell adattiva, splash, 404
│   ├── providers/             # auth, tema, lingua, connettività, prefs...
│   ├── utils/                 # AppFailure, ExceptionHandler, validators, logger, date formatter
│   └── widgets/               # LoadingButton, ConfirmDialog, MessageView, OfflineBanner...
├── extensions/                # context.l10n, context.colors, context.showError...
├── features/<feature>/
│   ├── components/            # widget della feature
│   ├── providers/             # notifier / provider (Riverpod codegen)
│   └── <feature>_page.dart
├── models/<dominio>/          # modelli freezed
├── repositories/<dominio>/    # dati del backend: I<X>Repository + mock/rest/firebase/supabase + provider
├── services/                  # wrapper di SDK e piattaforma (push, biometria, remote config, AI, social sign-in)
│   └── api/                   # Dio client, endpoints
├── styles/app_theme.dart
└── l10n/                      # app_en.arb, app_it.arb (+ gen/)
```

**Regole**
- La UI parla solo con i notifier/provider. I notifier usano repository e service. **Solo `repositories/` e `services/` toccano rete e SDK**, e ognuno è esposto da un provider, così nei test si sostituisce con `overrideWithValue`. Nelle pagine sono ammessi solo plugin di pura UI (url_launcher, image_picker, in_app_review).
- Gli errori si propagano come eccezioni. Per le azioni utente la UI usa `ExceptionHandler.handle(context, () => ...)`, che mostra lo snackbar localizzato e manda a Sentry solo gli errori inattesi. Per i caricamenti si usa `AsyncValue` con `MessageView.error`.
- Gli stili stanno solo in `styles/app_theme.dart`: nei widget niente colori hard-coded, si usa `context.colors`.
- I testi stanno solo negli ARB.

**Aggiungere una schermata:** crea `features/<nome>/<nome>_page.dart` con `static const route`, registrala in [router.dart](lib/core/navigation/router.dart) (tra le tab della shell o come route top-level) e aggiungi i testi agli ARB.

**Aggiungere un'entità:** copia lo schema dei movimenti della demo: `models/transactions`, `repositories/transactions` (interfaccia + mock/rest/firestore + provider), `features/transactions/providers`.

---

## App demo: finanza personale

Con `FEATURE_DEMO=true` (il default) il template è un'app completa per le finanze personali, pensata per mostrare ogni feature e il design system all'opera:

| Schermata | Cosa mostra |
|---|---|
| **Panoramica** | selettore del mese, card saldo, spese per categoria, analisi (sbloccate con Premium se i pagamenti sono attivi), movimenti recenti. Una colonna su telefono, due da *expanded* in su |
| **Movimenti** | lista infinita raggruppata per giorno, filtri a chip, skeleton, pull-to-refresh, swipe per eliminare con "Annulla", FAB esteso |
| **Nuovo/modifica movimento** | full-screen dialog M3: segmented button entrata/uscita, importo con valuta, menu categorie, date picker, eliminazione con conferma |
| **Assistente** (`FEATURE_AI`) | chat Gemini con suggerimenti a chip |
| **Impostazioni** | profilo, Premium, tema e lingua (dialog M3), biometria, supporto, versione, licenze, log |

I dati girano sugli stessi backend dell'auth (mock con 4 mesi di dati realistici, REST, Firestore `users/{uid}/transactions`, tabella Supabase `transactions`). Per partire da zero: `dart run tool/setup.dart --without demo` rimuove la demo e rimette una home vuota.

---

## Design system (Material 3)

Tutto segue le linee guida [Material 3](https://m3.material.io):

- **Componenti con i default M3** (bottoni da 40dp, forme, colori): [styles/app_theme.dart](lib/styles/app_theme.dart) sovrascrive solo font, stile dei campi (outlined) e snackbar floating. Il brand si cambia con `SEED_COLOR`.
- **Spaziature solo da token** ([styles/app_spacing.dart](lib/styles/app_spacing.dart)), sulla griglia da 4dp: 8 tra bottoni dello stesso gruppo, 16 tra campi e card, 24 tra sezioni. Margini pagina 16dp su telefono e 24dp da tablet in su.
- **Layout per window size class** (`context.windowSize`): barra di navigazione su *compact*, rail su *medium/expanded*, rail estesa su *large*. I contenuti sono centrati entro 480dp (form), 840dp (liste) o 1200dp (dashboard).
- **Pattern**: dialog con bottoni di testo e verbo esplicito (`showConfirmDialog`), scelte con *simple dialog* a radio (`showChoiceDialog`), full-screen dialog per creare e modificare, subheader di lista (`SectionHeader`), stati vuoto/errore (`MessageView`), snackbar standard con azione.
- **Colori custom M3**: `context.appColors.success*` (tonal palette generata come quelle dello schema), usati per le entrate.

---

## Setup per feature

<details>
<summary><b>Firebase</b> (backend firebase, push, remote config, analytics, AI)</summary>

```bash
dart pub global activate flutterfire_cli
flutterfire configure        # genera lib/firebase_options.dart e i file nativi
firebase deploy --only firestore,storage   # regole di sicurezza + indici (firestore.rules, storage.rules)
```
Nella console Firebase abilita i servizi che usi (Authentication → Email/Password, Google, Apple; Firestore; Storage).

Cloud Functions (trigger, push lato server, logica privilegiata): [docs/FIREBASE_FUNCTIONS.md](docs/FIREBASE_FUNCTIONS.md).
</details>

<details>
<summary><b>Supabase</b> (backend supabase)</summary>

```bash
# CLI: https://supabase.com/docs/guides/local-development/cli/getting-started
supabase init                         # crea supabase/config.toml (le migration ci sono già)
supabase link --project-ref <ref>
supabase db push                      # tabelle, policy RLS, bucket avatars, delete_account()
```
Poi in `env/*.json`: `BACKEND: "supabase"`, `SUPABASE_URL` e `SUPABASE_PUBLISHABLE_KEY` (dashboard → *Connect*). In locale: `supabase start` e usa l'URL/chiave che stampa.

Nella dashboard:
- **Authentication → URL Configuration**: *Site URL* = il tuo dominio; in *Redirect URLs* aggiungi `AUTH_REDIRECT_URL` e, per il web in sviluppo, `http://localhost:*/**`.
- **Authentication → Email Templates → Reset password**: il link deve essere
  `{{ .SiteURL }}/reset-password?token={{ .TokenHash }}`. L'app verifica il token con `verifyOTP` e salva la nuova password.
- **Confirm email** attivo (default): dopo la registrazione l'utente vede "conferma l'email" e accede dopo aver aperto il link. Spegnilo per entrare subito come con Firebase.
- **Google**: abilita il provider con il client id **web** (+ quello iOS in *Authorized Client IDs*) e attiva *Skip nonce check* (serve per iOS). Mobile usa il login nativo (`signInWithIdToken`), web il redirect OAuth.
- **Apple**: iOS/macOS usano il login nativo; Android e web il redirect OAuth (Services ID e chiave nel provider Apple).

Le policy usano `(select auth.uid())` (valutato una volta per query) e ogni tabella ha RLS attiva: una nuova tabella va creata con lo stesso schema, vedi `supabase/migrations/*_transactions.sql`. Nuove modifiche allo schema: `supabase migration new <nome>`.
</details>

<details>
<summary><b>Google Sign-In</b></summary>

- Android: aggiungi lo SHA-1 alla app Firebase / Google Cloud. `GOOGLE_SERVER_CLIENT_ID` = client id **web** (serve per ottenere l'idToken).
- iOS: aggiungi `GIDClientID` e lo URL scheme (`REVERSED_CLIENT_ID`) in `Info.plist`.
- Web: con Firebase si usa il popup, con Supabase il redirect OAuth. Con REST sul web serve il bottone renderizzato da Google (`google_sign_in_web`), non incluso.
</details>

<details>
<summary><b>Sign in with Apple</b></summary>

Abilita la capability *Sign in with Apple* in Xcode. Con Firebase e Supabase funziona anche su Android e Web: configura Services ID e chiave nella console del backend.
</details>

<details>
<summary><b>Push (FCM)</b></summary>

- iOS: capability *Push Notifications* + *Background Modes → Remote notifications*, e carica la chiave APNs su Firebase.
- Web: compila `web/firebase-messaging-sw.js` e `FCM_VAPID_KEY`.
- Il payload `data.route` (es. `/settings`) apre quella pagina al tap.
</details>

<details>
<summary><b>Remote Config</b></summary>

Chiavi: `min_version` (es. `1.4.0`: le versioni inferiori vedono "aggiornamento richiesto") e `maintenance_mode` (bool). Per il link allo store su iOS imposta `APP_STORE_ID`.
</details>

<details>
<summary><b>RevenueCat</b></summary>

Imposta `REVENUECAT_APPLE_KEY`, `REVENUECAT_GOOGLE_KEY` e `REVENUECAT_ENTITLEMENT`. Il paywall mostra i pacchetti dell'offering *current*, mentre `isPremiumProvider` dice se l'entitlement è attivo.
</details>

<details>
<summary><b>AI (Gemini)</b></summary>

Abilita *Firebase AI Logic* nella console. Nessuna API key finisce nell'app. In produzione abilita **App Check**. Il modello si imposta con `AI_MODEL`.
</details>

<details>
<summary><b>Blocco biometrico</b></summary>

`MainActivity` estende già `FlutterFragmentActivity` e `NSFaceIDUsageDescription` è già in `Info.plist`.
</details>

<details>
<summary><b>Deep link (reset password, notifiche)</b></summary>

- Android: sostituisci `example.com` nell'intent-filter di `AndroidManifest.xml` e pubblica `/.well-known/assetlinks.json`.
- iOS: capability *Associated Domains* (`applinks:tuodominio.com`) + `apple-app-site-association`.
- Il link di reset deve puntare a `https://tuodominio.com/reset-password?token=...`. Con Firebase è accettato anche `oobCode`, con Supabase il token è il `TokenHash` (vedi setup Supabase).
- Supabase OAuth su Android torna su `AUTH_REDIRECT_URL`: usa lo stesso dominio dell'App Link, così lo gestisce l'intent-filter già presente.
</details>

<details>
<summary><b>Sentry</b></summary>

Imposta `SENTRY_DSN` nel file env. Registra crash, errori HTTP (Dio), navigazione e l'utente corrente.
</details>

<details>
<summary><b>Firma release Android</b></summary>

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
Poi crea `android/key.properties` (è ignorato da git):
```
storeFile=upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```
</details>

<details>
<summary><b>Icone e splash</b></summary>

Sostituisci `assets/images/logo.png` (1024×1024), poi:
```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```
</details>

---

## Comandi utili

```bash
flutter run --dart-define-from-file=env/dev.json          # avvio
dart run build_runner watch -d                             # codegen (riverpod, freezed, json)
flutter gen-l10n                                           # dopo aver modificato gli ARB
flutter analyze && flutter test                            # prima di ogni PR
flutter build web --release --dart-define-from-file=env/prod.json
flutter build appbundle --release --dart-define-from-file=env/prod.json
flutter build ipa --release --dart-define-from-file=env/prod.json
```

In VS Code ci sono già le configurazioni di avvio *dev*, *staging* e *prod*.

---

## CI/CD

| Workflow | Quando | Cosa fa |
|---|---|---|
| `ci.yml` | ogni PR e push su main | codegen aggiornato, format, analyze, test, build web |
| `release.yml` | merge PR su main | bump semver dal titolo PR (`feat:` minor, `fix:` patch, `chore:` solo build, `!` major), tag + GitHub Release |
| `revert_release.yml` | merge PR "Revert …" | annulla l'ultimo bump, cancella tag e release |
| `deploy_web.yml` | dopo release, se `vars.DEPLOY_WEB == 'true'` | Firebase Hosting |
| `deploy_android.yml` | dopo release, se `vars.DEPLOY_ANDROID == 'true'` | Play Store (track internal, manuale a scelta) |
| `deploy_ios.yml` | dopo release, se `vars.DEPLOY_IOS == 'true'` | TestFlight |
| `dependabot.yml` | settimanale | aggiornamento di pacchetti e action |

I deploy si attivano con le **variabili del repository**, così un progetto solo web non prova a pubblicare sugli store. Secret e variabili richiesti sono elencati in testa a ogni workflow.

Se `main` è protetto, consenti a `github-actions[bot]` di pushare il commit di bump.

---

## Docker

```bash
docker compose -f docker/docker-compose.yml up --build     # http://localhost:8080
```

---

## Licenza

MIT, vedi [LICENSE](LICENSE).
