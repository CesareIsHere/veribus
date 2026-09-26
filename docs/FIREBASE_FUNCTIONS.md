# Cloud Functions for Firebase

How to add server-side logic to an app built on this template. The template ships without a
`functions/` folder: create it only when the app needs one of the cases below.

Versions this guide assumes (September 2026): `firebase-functions` 7.x, `firebase-admin` 14.x
(needs Node 22), Flutter `cloud_functions` 6.x. Everything is 2nd gen (Cloud Run based).

## When to use a function

| Use a function for | Keep it in the app |
|---|---|
| Logic that needs privileges the user must not have (write another user's data, grant credits) | Plain CRUD on the user's own data: Firestore + `firestore.rules` is enough |
| Secrets and third-party APIs (payments, exchange rates, email) | Anything that only needs the user's own token |
| Reacting to events: new document, user deleted, schedule | UI state, validation for UX (repeat it on the server if it matters) |
| Sending push to other users/devices (FCM Admin) | Local notifications |
| Webhooks from other services (RevenueCat, Stripe) | |

## 1. Setup

```bash
firebase init functions      # TypeScript + ESLint; creates functions/ and the "functions" entry in firebase.json
cd functions && npm install firebase-functions@^7 firebase-admin@^14
```

In `functions/package.json` set `"engines": { "node": "22" }`. Put the shared options and the Admin SDK
init in `functions/src/index.ts`, and one file per area (`users.ts`, `transactions.ts`...) re-exported from it:

```ts
import { setGlobalOptions } from "firebase-functions/v2";
import { initializeApp } from "firebase-admin/app";

initializeApp();

// Same region as Firestore. maxInstances caps cost if something loops or gets abused.
setGlobalOptions({ region: "europe-west1", maxInstances: 10 });

export * from "./users";
export * from "./transactions";
```

Add `functions/lib/` and `functions/node_modules/` to `.gitignore` (the `functions/.gitignore` created by
`firebase init` already does it).

## 2. Configuration and secrets

`functions.config()` was **removed in v7**. Use parameters:

```ts
import { defineSecret, defineString } from "firebase-functions/params";

const exchangeApiKey = defineSecret("EXCHANGE_API_KEY"); // firebase functions:secrets:set EXCHANGE_API_KEY
const supportEmail = defineString("SUPPORT_EMAIL");       // functions/.env or .env.<projectId>
```

Secrets must be listed in the function's `secrets` option and are read with `.value()` inside the handler,
never at module load. Never commit `.env.*` files that contain real values; secrets go only in Secret Manager.

## 3. Callable functions (app → server)

Callables are the default way for the app to call the server: the Firebase ID token and the App Check
token are attached and verified for you.

```ts
// functions/src/transactions.ts
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";

const exchangeApiKey = defineSecret("EXCHANGE_API_KEY");

export const convertAmount = onCall(
  // enforceAppCheck: turn on once the app uses firebase_app_check (recommended in production).
  { secrets: [exchangeApiKey], enforceAppCheck: false },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first.");

    // request.data is untrusted input: check every field.
    const { amount, from, to } = request.data as Record<string, unknown>;
    if (!Number.isInteger(amount) || typeof from !== "string" || typeof to !== "string") {
      throw new HttpsError("invalid-argument", "amount (cents), from and to are required.");
    }

    const rate = await fetchRate(from, to, exchangeApiKey.value());
    return { amount: Math.round((amount as number) * rate) };
  },
);
```

Throw `HttpsError` for expected errors (its `code` reaches the app); any other exception becomes
`internal` and its details stay in the logs.

### Calling it from Flutter

Follow the template's layering: the SDK is used **only in a repository**, the UI and notifiers see an interface.

1. `flutter pub add cloud_functions`.
2. `lib/repositories/exchange/` with `i_exchange_repository.dart`, a mock, the Firebase implementation
   and `exchange_repository_provider.dart` (same shape as `repositories/transactions/`).
3. Mark Firebase-only code (`// backend:firebase` or a `// feature:<name>` marker) and list the files and
   the `cloud_functions` package in `tool/features.json`, so `tool/setup.dart` can remove them.

```dart
class FirebaseExchangeRepository implements IExchangeRepository {
  FirebaseExchangeRepository({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFunctions _functions;

  @override
  Future<int> convert({required int amount, required String from, required String to}) async {
    try {
      final result = await _functions.httpsCallable('convertAmount').call<Object?>({
        'amount': amount,
        'from': from,
        'to': to,
      });
      return (result.data! as Map)['amount'] as int;
    } on FirebaseFunctionsException catch (e) {
      throw switch (e.code) {
        'unauthenticated' => const UnauthorizedFailure(),
        'unavailable' || 'deadline-exceeded' => const NetworkFailure(),
        'invalid-argument' => const ServerFailure(statusCode: 400),
        _ => UnknownFailure(e),
      };
    }
  }
}
```

The region must match the one in `setGlobalOptions`. For local development, point the SDK at the
emulator in `main.dart` (inside the `// firebase:start` block, only when `!AppConfig.isProd`):
`FirebaseFunctions.instanceFor(region: 'europe-west1').useFunctionsEmulator('localhost', 5001);`

## 4. Event triggers

Triggers run on their own. They can fire **more than once** for the same event, so make them idempotent
(set values, don't increment blindly) and never write to the path that triggers them, or they loop.

**Clean up a deleted user.** The app's `deleteAccount()` removes only the Auth user. This removes their
data too (`users/{uid}` with its subcollections, and the avatar):

```ts
// functions/src/users.ts
import { onUserDeleted } from "firebase-functions/v2/identity";
import { getFirestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";

export const cleanupDeletedUser = onUserDeleted(async (event) => {
  const uid = event.data.uid;
  const db = getFirestore();
  await db.recursiveDelete(db.doc(`users/${uid}`));
  await getStorage().bucket().deleteFiles({ prefix: `users/${uid}/` });
});
```

**Send a push from the server.** The app stores FCM tokens in `users/{uid}.pushTokens` and opens
`data.route` when a notification is tapped:

```ts
// functions/src/transactions.ts
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

export const notifyLargeExpense = onDocumentCreated("users/{uid}/transactions/{id}", async (event) => {
  const tx = event.data?.data();
  if (!tx || tx.type !== "expense" || tx.amount < 50_000) return;

  const user = await getFirestore().doc(`users/${event.params.uid}`).get();
  const tokens: string[] = user.get("pushTokens") ?? [];
  if (tokens.length === 0) return;

  const res = await getMessaging().sendEachForMulticast({
    tokens,
    notification: { title: "Large expense", body: `${tx.title}: €${(tx.amount / 100).toFixed(2)}` },
    data: { route: `/transactions/${event.params.id}` },
  });

  // Remove tokens of uninstalled apps.
  const dead = tokens.filter(
    (_, i) => res.responses[i].error?.code === "messaging/registration-token-not-registered",
  );
  if (dead.length > 0) await user.ref.update({ pushTokens: FieldValue.arrayRemove(...dead) });
});
```

Other useful triggers: `onSchedule` (`firebase-functions/v2/scheduler`) for periodic jobs,
`beforeUserCreated` (`v2/identity`) to block or enrich sign-ups (needs Identity Platform).

## 5. Webhooks (other services → server)

Use `onRequest` and verify the caller before doing anything. Example for RevenueCat (feature `payments`),
which sends the secret you configure as the `Authorization` header:

```ts
import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

const revenueCatAuth = defineSecret("REVENUECAT_WEBHOOK_AUTH");

export const revenueCatWebhook = onRequest({ secrets: [revenueCatAuth] }, async (req, res) => {
  if (req.method !== "POST" || req.get("authorization") !== revenueCatAuth.value()) {
    res.sendStatus(401);
    return;
  }
  const event = req.body.event; // app_user_id = the uid passed to Purchases.logIn by the app
  await getFirestore().doc(`users/${event.app_user_id}`).set(
    { premium: event.type !== "EXPIRATION", premiumUpdatedAt: FieldValue.serverTimestamp() },
    { merge: true },
  );
  res.sendStatus(200);
});
```

Fields written only by functions (like `premium`) must be read-only for clients: tighten
`firestore.rules` so users can't write them.

## 6. Test, deploy, CI

```bash
firebase emulators:start --only functions,firestore,auth   # local run, with the app pointed at the emulators
firebase deploy --only functions                            # or --only functions:convertAmount
```

- Unit tests: `firebase-functions-test` + Jest/Vitest inside `functions/`.
- CI: add a job that runs `npm ci && npm run lint && npm run build` in `functions/` on PRs. To deploy from
  `deploy_web.yml`, add `firebase deploy --only functions --project ${{ vars.FIREBASE_PROJECT_ID }}` with
  the same service account (it needs the *Cloud Functions Admin* and *Service Account User* roles).
- Watch cost: keep `maxInstances`, avoid `minInstances` unless cold starts are a real problem.

## Security checklist

- Check `request.auth` in every callable and validate every field of `request.data`.
- Turn on `enforceAppCheck` for callables once the app sends App Check tokens.
- Secrets only via `defineSecret`, never in code, `.env` committed files or the app.
- Admin SDK bypasses `firestore.rules`: the function is the rule, so check ownership (`uid`) yourself.
- Idempotent triggers, no writes to the triggering path.

## Supabase equivalent

With `BACKEND=supabase` the same role is played by **Edge Functions** (Deno/TypeScript):
`supabase functions new <name>`, secrets with `supabase secrets set`, called from a repository with
`Supabase.instance.client.functions.invoke('<name>', body: {...})` (the user's JWT is attached).
Database triggers and scheduled jobs can stay in SQL (`supabase/migrations`, `pg_cron`), and privileged
single-statement actions can be `security definer` SQL functions, like `delete_account()`.
