# Google Play listing

Everything the Play Console asks for, ready to paste or upload. Phone only, Italian (default) and English.

```
store/
├── logo_source.png            original logo (465×332, transparent)
├── make_assets.py             regenerates every image below + assets/images/{logo,launcher_foreground}.png
└── metadata/android/          fastlane `supply` layout
    └── it-IT | en-US/
        ├── title.txt                 ≤30
        ├── short_description.txt     ≤80
        ├── full_description.txt      ≤4000
        ├── changelogs/default.txt    ≤500, release notes
        └── images/
            ├── icon.png              512×512, 32-bit PNG
            ├── featureGraphic.png    1024×500, no alpha
            └── phoneScreenshots/     8 × 1080×1920, no alpha, in listing order
```

| Text | it-IT | en-US | Limit |
|---|---|---|---|
| Title | 27 | 26 | 30 |
| Short description | 70 | 68 | 80 |
| Full description | 2,377 | 2,272 | 4,000 |
| Release notes | 158 | 157 | 500 |

Regenerate the images after new screenshots (`docs/screenshots`) or a new logo:

```bash
python store/make_assets.py
```

Then, if the logo changed, `dart run flutter_launcher_icons` and `dart run flutter_native_splash:create`.

## Blockers before the first upload

1. **Publish the legal pages.** `web/privacy.html` and `web/terms.html` go live with the web app: run the *Deploy web*
   workflow (or `flutter build web` + `firebase deploy --only hosting`). `env/prod.json` already points to them.
   Read them first: they are a draft written from what the code does, not legal advice.
2. **Review account.** Login is mandatory, so Google needs credentials. Create a dedicated email/password account on
   production with a followed trip already set up, and put it only in the Console (*App access*), never in the repo.
3. **Personal developer account?** If created after November 2023, production unlocks only after a closed test with at
   least 12 testers opted in for 14 consecutive days. Start the closed test as soon as possible.
4. **First upload by hand.** The Play API cannot create the app: upload the first `.aab` in the Console. After that the
   *Deploy Android* workflow works (secrets `ANDROID_KEYSTORE_*`, `PLAY_SERVICE_ACCOUNT_JSON`, variable
   `ANDROID_PACKAGE_NAME = com.emilianocesare.veribus`). Enroll in Play App Signing; `veribus-release.jks` becomes the
   upload key: back it up, losing it means a key reset request to Google.
5. **Support email.** It is shown publicly on the listing. `emiliano.cesare.mail@gmail.com` works; a dedicated address
   keeps the personal one out of scrapers.

## Console walkthrough

### Create app
- App name: `Veribus: bus e tram di Roma` · default language: **Italian – it-IT** · App · **Free** (cannot go back to
  paid later).

### Store settings
- Category: **Maps & Navigation**. Tags (up to 5): public transport, maps, navigation, travel, local.
- Email: see blocker 5. Website: `https://github.com/CesareIsHere/veribus` (optional).

### Main store listing
Upload the files from `metadata/android/it-IT`, then *Manage translations › English (United States)* with `en-US`.

### App content

| Section | Answer |
|---|---|
| Privacy policy | `https://veribus-f329e.web.app/privacy.html` |
| App access | *All or some functionality is restricted* → the review account from blocker 2, with: "Sign in with email and password. Any stop in Rome works, e.g. search 'Termini'." |
| Ads | **No** |
| Content rating | Category *All other app types*. Violence, sex, language, drugs, gambling: no. Users interact or exchange content: **no** (profile name and photo are not shown to others). Shares the user's location with other users: no. Digital purchases: no. Expected: PEGI 3 / Everyone. |
| Target audience | **18 and over** (keeps the app out of the Families policy; it does not stop younger users from installing). |
| News app | No |
| Advertising ID | **No** (the merged manifest has no `AD_ID` permission) |
| Government app / Financial features / Health | No / none / none |
| Account deletion | Users can create accounts → URL `https://veribus-f329e.web.app/privacy.html#delete-account`. Deletes all data; nothing is kept. |
| Permissions | Nothing to declare: location is foreground only, the photo picker needs no permission, and the unused geolocator foreground service is removed from the manifest. |

### Data safety

Collects data: **yes**. Shares data: **no** (providers acting for the app are not sharing). Encrypted in transit:
**yes**. Users can request deletion: **yes**.

| Data type | Collected | Required? | Ephemeral? | Purposes |
|---|---|---|---|---|
| Personal info › Email address | yes | required | no | Account management, App functionality |
| Personal info › Name | yes | optional | no | Account management |
| Photos and videos › Photos | yes | optional | no | Account management (profile photo) |
| App activity › Other user-generated content | yes | optional | no | App functionality (followed trips) |
| Device or other IDs | yes | required | no | App functionality (notification token) |
| Location › Approximate location | yes | optional | **yes** | App functionality |

Location is used on the phone and never reaches the backend, but the map downloads the tiles of the area on screen from
OpenFreeMap. Declaring approximate location (ephemeral) is the conservative reading; under-declaring is what gets apps
pulled. If `SENTRY_DSN` is ever set in `env/prod.json`, add *App info and performance › Crash logs / Diagnostics*.

### Release
Internal testing → closed testing (blocker 3) → production, countries: Italy (or all). Release notes:
`changelogs/default.txt`.

## Final check

- [ ] Screenshots match the build being reviewed (they come from the mock data, `env/mock.json`).
- [ ] Screenshots show the **English** UI in both languages: retake them in Italian for the it-IT listing when possible.
- [ ] Privacy and terms pages are live; the support email answers.
- [ ] Name is "Veribus" everywhere: launcher, listing, legal pages. No Atac/RSM logos or names beyond the attribution.
- [ ] Review account signs in on the production build.
- [ ] Listing previewed in Italian and English.
