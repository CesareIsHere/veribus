// Firebase Cloud Messaging, HTTP v1: a service account signs a short-lived OAuth token (RS256, WebCrypto), which
// authorizes `messages:send`. No SDK: the edge runtime has none to spare.
import type { Notice, PushSender, SendResult } from "../core/notify.ts";

export interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

const SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
const TOKEN_URL = "https://oauth2.googleapis.com/token";
/** Android channel the app creates at start (lib/services/push_notifications_service.dart). */
export const ANDROID_CHANNEL = "trips";

const b64url = (data: ArrayBuffer | string) => {
  const bytes = typeof data === "string" ? new TextEncoder().encode(data) : new Uint8Array(data);
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
};

async function signingKey(pem: string): Promise<CryptoKey> {
  const der = Uint8Array.from(
    atob(pem.replace(/-----(BEGIN|END) PRIVATE KEY-----/g, "").replace(/\s/g, "")),
    (c) => c.charCodeAt(0),
  );
  return await crypto.subtle.importKey("pkcs8", der, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"]);
}

/** `json` is the service account file, as it is stored in the FCM_SERVICE_ACCOUNT secret. */
export function fcmPush(json: string, opts: { now?: () => number } = {}): PushSender {
  const account = JSON.parse(json) as ServiceAccount;
  const now = opts.now ?? (() => Math.floor(Date.now() / 1000));
  const key = signingKey(account.private_key);
  let cached: { token: string; expires: number } | null = null;

  async function accessToken(): Promise<string> {
    const t = now();
    if (cached && cached.expires - 60 > t) return cached.token;
    const claims = { iss: account.client_email, scope: SCOPE, aud: TOKEN_URL, iat: t, exp: t + 3600 };
    const unsigned = `${b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }))}.${b64url(JSON.stringify(claims))}`;
    const sig = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", await key, new TextEncoder().encode(unsigned));
    const res = await fetch(TOKEN_URL, {
      method: "POST",
      headers: { "content-type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: `${unsigned}.${b64url(sig)}`,
      }),
      signal: AbortSignal.timeout(8000),
    });
    if (!res.ok) throw new Error(`FCM auth ${res.status}: ${await res.text()}`);
    const body = await res.json() as { access_token: string; expires_in: number };
    cached = { token: body.access_token, expires: t + body.expires_in };
    return cached.token;
  }

  return {
    async send(token: string, notice: Notice): Promise<SendResult> {
      try {
        const res = await fetch(`https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`, {
          method: "POST",
          headers: { "content-type": "application/json", authorization: `Bearer ${await accessToken()}` },
          body: JSON.stringify({
            message: {
              token,
              notification: { title: notice.title, body: notice.body },
              data: notice.data,
              android: { priority: "HIGH", notification: { channel_id: ANDROID_CHANNEL, tag: notice.tag } },
              apns: {
                headers: { "apns-priority": "10" },
                payload: { aps: { sound: "default", "thread-id": notice.tag } },
              },
            },
          }),
          signal: AbortSignal.timeout(8000),
        });
        if (res.ok) {
          await res.body?.cancel();
          return "ok";
        }
        const text = await res.text();
        console.error(`FCM ${res.status}: ${text.slice(0, 300)}`);
        // A dead or malformed token: forget it. (A 400 for anything else is our message: retrying will not fix it.)
        if (res.status === 404 || /UNREGISTERED|registration token|not a valid FCM/i.test(text)) return "invalid";
        if (res.status === 429 || res.status >= 500) return "retry";
        return "failed";
      } catch (e) {
        console.error(`FCM: ${e}`);
        return "retry"; // network, timeout, token endpoint down
      }
    },
  };
}
