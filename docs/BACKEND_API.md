# REST backend contract

What `BACKEND=rest` expects from your API (`API_BASE_URL`). Everything is JSON.
Errors should return an HTTP status and, optionally, `{ "message": "..." }`:
the message is shown to the user as-is (so localize it server-side or omit it).

## Session

Login, register, social and refresh all return:

```json
{
  "accessToken": "jwt...",
  "refreshToken": "opaque-or-jwt",
  "user": { "id": "42", "email": "a@b.com", "displayName": "Ada", "photoUrl": null, "emailVerified": true }
}
```

Authenticated requests carry `Authorization: Bearer <accessToken>`.
On `401` the app calls `/auth/refresh` once and retries the request.
If the refresh fails, the user is signed out.

| Method | Path | Body | Notes |
|---|---|---|---|
| POST | `/auth/login` | `{ email, password }` | → session |
| POST | `/auth/register` | `{ email, password, displayName? }` | → session |
| POST | `/auth/social` | `{ provider: "google"\|"apple", token, nonce?, displayName? }` | Verify the Google ID token / Apple identity token server-side (Apple: sha256(nonce) must match). → session |
| POST | `/auth/refresh` | `{ refreshToken }` | → session (rotate the refresh token) |
| POST | `/auth/forgot-password` | `{ email }` | Always 2xx (don't leak which emails exist). Email a link to `https://<your-domain>/reset-password?token=...` |
| POST | `/auth/reset-password` | `{ token, password }` | 2xx on success |

## Current user

| Method | Path | Body | Response |
|---|---|---|---|
| PATCH | `/me` | `{ displayName }` | user |
| POST | `/me/avatar` | multipart, field `file` (jpeg) | user |
| DELETE | `/me` | – | 2xx; delete the account and its data |
| POST | `/devices` | `{ token, platform }` | 2xx; stores the FCM token for the user |

## Transactions (demo app)

A transaction: `{ "id": "42", "title": "Groceries", "amount": 4599, "category": "groceries", "date": "2026-09-20T10:30:00Z", "note": null }`.
`amount` is in cents and always positive; the category decides whether it is income or expense
(`salary`, `freelance`, `gift`, `otherIncome` are income, everything else is an expense).

| Method | Path | Body / query | Response |
|---|---|---|---|
| GET | `/transactions` | `?limit=20&cursor=<opaque>&type=income\|expense` | `{ "data": [...], "nextCursor": "abc" \| null }`, newest first |
| GET | `/transactions` | `?from=<ISO>&to=<ISO>&limit=1000` (from inclusive, to exclusive) | same shape, used for monthly summaries |
| GET | `/transactions/{id}` | – | transaction |
| POST | `/transactions` | transaction without `id` | created transaction |
| PUT | `/transactions/{id}` | transaction without `id` | updated transaction |
| DELETE | `/transactions/{id}` | – | 2xx |

All of them only see the signed-in user's data.
