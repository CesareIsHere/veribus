# Veribus (nome provvisorio)

App per bus e tram di Roma: **tutto quello che si sa davvero sul tuo bus, scritto in modo leggibile**.
Stessi open data pubblici di Roma Servizi per la Mobilità (RSM), mostrati per intero e con onestà: quanto è
affidabile l'orario, se il mezzo è fermo o ancora al capolinea, e un avviso quando la corsa che aspettavi sparisce.

Specifica, misure sui dati e documento tecnico sono su Notion (*App Bus Roma*). Questo README dice come far girare
e pubblicare il progetto.

| Parte | Dove | Tecnologia |
|---|---|---|
| App (Android, iOS, web per sviluppo) | radice del repo (`lib/`) | Flutter 3.47.5, Riverpod 3, go_router, flutter_map |
| Import del GTFS statico | `backend/static-import` | bash + psql, ogni notte su GitHub Actions |
| Poller realtime e motore | `backend/core`, `backend/adapters`, `backend/runtimes` | TypeScript su Deno (Edge Function oggi, container domani) |
| Database e API | `supabase/migrations` | Supabase: Postgres, funzioni SQL nello schema `api`, Storage, pg_cron |
| Archivio degli snapshot grezzi | Cloudflare R2 | bucket S3, scadenza a 30 giorni con una regola del bucket |

---

## Quick start (senza server)

```bash
fvm install && flutter pub get
flutter run --dart-define-from-file=env/dev.json
```

`env/dev.json` usa il backend **mock**: una manciata di fermate intorno a Termini con arrivi in tutti gli stati.
Il login è obbligatorio, ma con il mock va bene qualsiasi email (la password `wrongpass` simula un errore).

**Modalità mock completa**, per controllare la grafica di ogni schermata (anche sul web, `-d chrome`):

```bash
flutter run --dart-define-from-file=env/mock.json
```

Parte già loggata (`MOCK_SIGNED_IN`) e con una posizione fissa vicino a Termini (`MOCK_POSITION`). I dati mock
coprono apposta i casi limite: arrivi in tutti gli stati e con ogni segnale, CAVOUR con i dati in tempo reale fermi
(RF-60), MANIN senza arrivi, 8BUS senza tempo reale, n11 senza corse in servizio, la 64 con fermate di variante.

---

## Architettura

```
RSM (GTFS zip + feed GTFS-RT) ──► GitHub Actions: import notturno ──► Postgres `network` + Storage `network/v<md5>.json`
                              └─► pg_cron ogni 10 s ──► Edge Function `poller` ──► Postgres `live` + R2 (archivio)
App ──► RPC `api.*` (JWT dell'utente) ──► legge `network` + `live`, aggiunge i segnali che dipendono dall'istante
App ──► Storage `network/v<md5>.json` una volta per versione (ricerca e fermate vicine girano sul telefono)
```

**Schemi Postgres** (nessuno esposto tranne `api`, RLS attiva su tutto):

| Schema | Contenuto | Chi scrive |
|---|---|---|
| `network` | fermate, linee, percorsi principali, corse, orari, giorni di servizio | import, con swap atomico |
| `network_meta` | versioni importate, linee viste in tempo reale (RF-35) | import, poller |
| `live` | veicoli, stato delle corse, avvisi, stato dei feed, indice degli snapshot, lease | poller (ruolo `poller`) |
| `config` | soglie dei segnali, versione minima dell'app, URL delle tile (modificabili senza rilascio) | a mano |
| `api` | `network()`, `arrivals(stop_ids, route_ids)`, `route(route_id, direction_id)`, `timetable(stop_id, route_id, day)`, `alerts()` | — |

**Dove si calcolano i segnali**: ciò che richiede storia lo calcola il poller (S1 cancellata, S2 corsa sparita →
soppressa, S3 mezzo fermo, S5 al capolinea); ciò che dipende dall'istante di lettura lo calcola l'API (S4 GPS
vecchio, S6 dati in ritardo, RF-60 feed fermo, orario approssimato). Se il poller muore l'API continua a dire la verità.

**App** (`lib/`), secondo le convenzioni in [CLAUDE.md](CLAUDE.md):
`features/{nearby,search,favorites,alerts,stop,line,settings,auth}`, dati in `repositories/transit`
(interfaccia + `mock_` + `supabase_`), modelli in `models/transit`, posizione in `services/location_service.dart`.
Un solo posto traduce stato, segnale e orario in parole: `features/stop/components/arrival_tile.dart`.

---

## Setup del backend (una volta per progetto)

Serve un progetto Supabase, un bucket Cloudflare R2 e la
[CLI Supabase](https://supabase.com/docs/guides/local-development/cli/getting-started).

**Piano Supabase.** La rete importata tiene solo gli orari da ieri a 7 giorni avanti: il database arriva a circa
**420 MB** (misurato sul GTFS del 27/09: 3,4 M orari invece di 4,9 M). Durante l'import notturno la rete vecchia e
quella nuova convivono e si sale a circa 880 MB, quindi:
- **Pro** (8 GB): import normale, la rete attiva resta in servizio finché la nuova non ha passato i controlli (RF-81).
- **Gratuito** (500 MB): variabile di repository `IN_PLACE=1`. L'import cancella prima la rete attiva e ricostruisce
  (picco misurato 476 MB). Ogni notte l'API è giù per circa 3 minuti, e se l'import fallisce la rete manca fino
  all'import riuscito successivo. Il margine è di poche decine di MB: va bene per sviluppo e test, non per la beta.

1. **Schema**: `supabase link --project-ref <ref>` e `supabase db push` (tabelle, ruolo `poller`, bucket
   `network`, funzioni `api`, job pg_cron).
2. **Esporre l'API**: dashboard → *Settings → API → Exposed schemas*, aggiungi `api` (in locale lo fa `supabase/config.toml`).
3. **Ruolo del poller**: `alter role poller with login password '<password>';`
4. **Import iniziale**: nei secret del repository GitHub metti `SUPABASE_DB_URL` (pooler in modalità *session*,
   utente `postgres.<ref>`, non solo `postgres`), `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, poi lancia a mano il workflow *Static import*.
   Da lì gira ogni notte alle 06:30.
5. **Archivio su R2**: crea un bucket (es. `veribus-archive`), nelle sue impostazioni una regola *Object lifecycle*
   che cancella gli oggetti dopo 30 giorni (la specifica RF-83 ne chiede 90), e un token API R2 con permesso *Object Read & Write* solo su quel
   bucket. Costo: 0,65-1 GB al giorno (misurato il 01/10), a regime ~20-30 GB, 0,15-0,30 $ al mese oltre i 10 GB gratuiti (con 7 giorni è gratis); le scritture
   (~180.000 al mese) stanno nel milione gratuito.
6. **Poller**:
   ```bash
   supabase secrets set POLLER_SECRET=<stringa casuale> \
     POLLER_DB_URL=postgres://poller.<ref>:<password>@<pooler-host>:5432/postgres \
     R2_ACCOUNT_ID=<account id> R2_ACCESS_KEY_ID=<key> R2_SECRET_ACCESS_KEY=<secret> R2_BUCKET=veribus-archive \
     HEALTHCHECKS_URL=https://hc-ping.com/<uuid>
   supabase functions deploy poller
   ```
   e in SQL i due segreti che pg_cron usa per chiamarlo:
   ```sql
   select vault.create_secret('https://<ref>.supabase.co/functions/v1/poller', 'poller_url');
   select vault.create_secret('<la stessa stringa di POLLER_SECRET>', 'poller_secret');
   ```
7. **Monitoraggio**: su [Healthchecks.io](https://healthchecks.io) un check con periodo 1 minuto e tolleranza
   5 minuti. L'import che fallisce fa fallire il workflow e GitHub manda l'email.
8. **App**: in `env/staging.json` e `env/prod.json` imposta `SUPABASE_URL` e `SUPABASE_PUBLISHABLE_KEY`.

**Passare a Cloud Run** (quando il p95 della CPU del ciclo supera 1 s, o serve un processo sempre acceso):
`backend/runtimes/container/main.ts` è lo stesso ciclo in un loop. Avvialo con `DB_URL` e le variabili `R2_*`
(istanza minima 1, CPU sempre allocata), poi `select cron.unschedule('poller');`.
Il lease in `live.lease` evita cicli doppi durante il passaggio.

### Auth (Supabase)

- **Authentication → URL Configuration**: *Site URL* = il tuo dominio; in *Redirect URLs* aggiungi `AUTH_REDIRECT_URL`
  e, per il web in sviluppo, `http://localhost:*/**`.
- **Email Templates → Reset password**: il link deve essere `{{ .SiteURL }}/reset-password?token={{ .TokenHash }}`.
- **Google**: provider con il client id **web** (+ quello iOS in *Authorized Client IDs*), *Skip nonce check* attivo.
  Android: SHA-1 su Google Cloud, `GOOGLE_SERVER_CLIENT_ID` = client id web. iOS: `GIDClientID` e URL scheme in `Info.plist`.
- **Apple**: capability *Sign in with Apple* in Xcode; su Android e web redirect OAuth (Services ID e chiave nel provider).
- **Deep link del reset**: sostituisci `example.com` nell'intent-filter di `AndroidManifest.xml` e pubblica
  `/.well-known/assetlinks.json`; su iOS *Associated Domains* + `apple-app-site-association`.

---

## Dati veri in locale

L'app sul tuo computer con gli autobus veri, senza progetto Supabase in cloud (serve Docker con almeno 4 GB di RAM):

```bash
supabase start                                   # stack completo: Postgres, Auth, API, Storage (migration incluse)
bash backend/static-import/local.sh              # scarica il GTFS di oggi e lo importa (~3 minuti)
cd backend && DB_URL=postgresql://postgres:postgres@127.0.0.1:54322/postgres deno task poller   # lascialo girare
flutter run --dart-define-from-file=env/local.json                                              # in un altro terminale
```

Registrati con un'email qualsiasi: in locale non serve confermarla (le email finiscono in Mailpit,
http://127.0.0.1:54324). Il poller scarica i feed veri ogni 10 secondi e archivia gli snapshot in `backend/archive`.
Sull'emulatore Android usa `SUPABASE_URL: http://10.0.2.2:54321`; nel browser e sul desktop la posizione si può
fissare con `--dart-define=MOCK_POSITION=41.9005,12.4960`. In locale non c'è l'import notturno: la rete
copre da ieri a 7 giorni avanti, quindi rilancia `local.sh` almeno una volta a settimana.

## Sviluppo in locale

```bash
# App
flutter run --dart-define-from-file=env/dev.json    # mock
dart run build_runner watch -d                      # codegen Riverpod/freezed
flutter gen-l10n                                    # dopo aver modificato gli ARB (it + en)
dart format lib test tool && flutter analyze && flutter test

# Poller: formattazione, lint, tipi, test del motore (uno per segnale) e del ciclo su snapshot reali
cd backend && deno task check

# Database: migration + GTFS minimo generato al volo + test dell'API (serve Docker)
docker run -d --name vb-test -e POSTGRES_PASSWORD=postgres -v "$PWD:/repo" supabase/postgres:17.6.1.177 \
  -c config_file=/etc/postgresql/postgresql.conf
docker exec vb-test bash /repo/supabase/tests/run.sh

# Poller sui feed veri contro un Postgres locale (senza R2_* l'archivio va in backend/archive, stessa struttura)
cd backend && DB_URL=postgres://postgres:postgres@localhost:54322/postgres deno task poller

# Riesecuzione del motore su un archivio (RF-85): un CSV con i cambi di stato di ogni corsa
# (un giorno di produzione: rclone copy r2:veribus-archive/vp/2026/09/27 backend/archive/vp/2026/09/27, idem per tu)
cd backend && DB_URL=... deno run -A replay/main.ts archive > changes.csv
```

Per importare il GTFS vero in locale: `GTFS_DIR=<cartella dello zip scompattato> DB_URL=... bash backend/static-import/import.sh`
(circa un minuto; senza `SUPABASE_URL` il file di rete resta in `network.json`).

---

## CI/CD

| Workflow | Quando | Cosa fa |
|---|---|---|
| `ci.yml` | ogni PR e push su main | app: codegen, format, analyze, test, build web; backend: `deno task check` e test SQL |
| `static_import.yml` | ogni notte e a mano | import del GTFS se l'md5 è cambiato (`vars.IN_PLACE=1` sul piano gratuito) |
| `release.yml` | ogni push su main | bump semver dai commit (Conventional Commits; `[skip release]` per saltarlo), tag + GitHub Release con l'APK release arm64 allegato (`veribus-vX.Y.Z+N-arm64.apk`) |
| `deploy_android.yml` / `deploy_ios.yml` | dopo release, se `vars.DEPLOY_ANDROID` / `vars.DEPLOY_IOS` | Play Store (internal) / TestFlight |

Secret e variabili richiesti sono elencati in testa a ogni workflow.

**Firma dell'APK.** Perché un APK scaricato dalle release si installi *sopra* quello precedente, tutte le build devono
essere firmate con la stessa chiave. Una volta sola: `bash tool/android_signing.sh` (serve `gh` autenticato) crea il
keystore e imposta i secret `ANDROID_KEYSTORE_*` / `ANDROID_KEY_*` del repo; conserva `veribus-release.jks`. Senza
quei secret `release.yml` firma con una chiave di debug diversa a ogni build (si installa, ma non si aggiorna).

---

## Da decidere prima del rilascio

- Nome dell'app (senza richiami ad Atac) e icona (`assets/images/logo.png`, poi `dart run flutter_launcher_icons`).
- Fornitore delle tile della mappa: oggi `config.setting.tile_url` punta a OpenStreetMap, che non va usato in produzione.
- Licenza dei dati RSM e testo di attribuzione; privacy policy (`PRIVACY_URL`), obbligatoria per gli store.
- Limite di richieste per client sull'API (RNF-09).

## Licenza

MIT, vedi [LICENSE](LICENSE).
