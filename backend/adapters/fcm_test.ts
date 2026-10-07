import { assert, assertEquals } from "jsr:@std/assert@1";
import { fcmPush, fcmPushFromEnv } from "./fcm.ts";

async function serviceAccount() {
  const { privateKey } = await crypto.subtle.generateKey(
    { name: "RSASSA-PKCS1-v1_5", modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: "SHA-256" },
    true,
    ["sign", "verify"],
  );
  const der = new Uint8Array(await crypto.subtle.exportKey("pkcs8", privateKey));
  const pem = `-----BEGIN PRIVATE KEY-----\n${btoa(String.fromCharCode(...der))}\n-----END PRIVATE KEY-----\n`;
  return JSON.stringify({
    project_id: "veribus-test",
    client_email: "push@veribus-test.iam.gserviceaccount.com",
    private_key: pem,
  });
}

const notice = {
  title: "Linea 64: tra 10 min",
  body: "Venezia verso Termini",
  tag: "f1",
  data: { type: "trip", link: "/trips" },
};

function fakeFetch(sendStatus: number, sendBody = "{}") {
  const calls: { url: string; init: RequestInit }[] = [];
  const original = globalThis.fetch;
  globalThis.fetch = ((url: string, init: RequestInit) => {
    calls.push({ url, init });
    if (url.startsWith("https://oauth2.googleapis.com/")) {
      return Promise.resolve(Response.json({ access_token: "ya29.token", expires_in: 3600 }));
    }
    return Promise.resolve(new Response(sendBody, { status: sendStatus }));
  }) as typeof fetch;
  return { calls, restore: () => (globalThis.fetch = original) };
}

Deno.test("signs a JWT with the service account, sends the notice to the v1 endpoint, reuses the access token", async () => {
  const f = fakeFetch(200);
  try {
    const push = fcmPush(await serviceAccount(), { now: () => 1000 });
    assertEquals(await push.send("tok-1", notice), "ok");
    assertEquals(await push.send("tok-2", notice), "ok");
    assertEquals(f.calls.length, 3); // one token request, two sends

    const form = f.calls[0].init.body as URLSearchParams;
    assertEquals(form.get("grant_type"), "urn:ietf:params:oauth:grant-type:jwt-bearer");
    const [header, claims, signature] = form.get("assertion")!.split(".");
    assertEquals(JSON.parse(atob(header)), { alg: "RS256", typ: "JWT" });
    const c = JSON.parse(atob(claims));
    assertEquals([c.iss, c.scope, c.aud, c.exp - c.iat], [
      "push@veribus-test.iam.gserviceaccount.com",
      "https://www.googleapis.com/auth/firebase.messaging",
      "https://oauth2.googleapis.com/token",
      3600,
    ]);
    assert(signature.length > 100);

    assertEquals(f.calls[1].url, "https://fcm.googleapis.com/v1/projects/veribus-test/messages:send");
    assertEquals((f.calls[1].init.headers as Record<string, string>).authorization, "Bearer ya29.token");
    const message = JSON.parse(f.calls[1].init.body as string).message;
    assertEquals(message.token, "tok-1");
    assertEquals(message.notification, { title: notice.title, body: notice.body });
    assertEquals(message.data, notice.data);
    assertEquals(message.android.notification, { channel_id: "trips", tag: "f1" });
    assertEquals(message.android.priority, "HIGH");
  } finally {
    f.restore();
  }
});

Deno.test("the access token is renewed before it expires", async () => {
  const f = fakeFetch(200);
  let t = 1000;
  try {
    const push = fcmPush(await serviceAccount(), { now: () => t });
    await push.send("a", notice);
    t += 3600 - 30; // less than a minute left
    await push.send("b", notice);
    assertEquals(f.calls.filter((c) => c.url.startsWith("https://oauth2")).length, 2);
  } finally {
    f.restore();
  }
});

Deno.test("FCM errors are told apart: dead token, try again, give up", async () => {
  const account = await serviceAccount();
  for (
    const [status, body, expected] of [
      [404, '{"error":{"status":"NOT_FOUND","details":[{"errorCode":"UNREGISTERED"}]}}', "invalid"],
      [400, '{"error":{"message":"The registration token is not a valid FCM registration token"}}', "invalid"],
      [400, '{"error":{"message":"Invalid JSON payload"}}', "failed"],
      // A wrong project id is a 404 too: not a reason to forget every token.
      [404, '{"error":{"code":404,"message":"Requested entity was not found.","status":"NOT_FOUND"}}', "failed"],
      [403, "{}", "retry"],
      [429, "{}", "retry"],
      [503, "{}", "retry"],
    ] as const
  ) {
    const f = fakeFetch(status, body);
    const quiet = console.error;
    console.error = () => {};
    try {
      assertEquals(await fcmPush(account).send("tok", notice), expected, `${status} ${body}`);
    } finally {
      console.error = quiet;
      f.restore();
    }
  }
});

Deno.test("a network failure is a retry", async () => {
  const original = globalThis.fetch;
  globalThis.fetch = (() => Promise.reject(new TypeError("connection reset"))) as typeof fetch;
  const quiet = console.error;
  console.error = () => {};
  try {
    assertEquals(await fcmPush(await serviceAccount()).send("tok", notice), "retry");
  } finally {
    console.error = quiet;
    globalThis.fetch = original;
  }
});

Deno.test("a missing or malformed service account means no sender, not a crash", () => {
  const quiet = console.error;
  console.error = () => {};
  try {
    assertEquals(fcmPushFromEnv(undefined), null);
    assertEquals(fcmPushFromEnv(""), null);
    assertEquals(fcmPushFromEnv("not json"), null);
    assert(fcmPushFromEnv('{"project_id":"p","client_email":"e","private_key":"k"}') !== null); // checked at the first send
  } finally {
    console.error = quiet;
  }
});

Deno.test("a bad private key fails the send as a retry, with no unhandled rejection", async () => {
  const quiet = console.error;
  console.error = () => {};
  try {
    const push = fcmPush(
      JSON.stringify({
        project_id: "p",
        client_email: "e",
        private_key: "-----BEGIN PRIVATE KEY-----\nAAAA\n-----END PRIVATE KEY-----",
      }),
    );
    assertEquals(await push.send("tok", notice), "retry");
  } finally {
    console.error = quiet;
  }
});

Deno.test("sends in parallel ask Google for the access token once", async () => {
  const f = fakeFetch(200);
  try {
    const push = fcmPush(await serviceAccount(), { now: () => 1000 });
    const results = await Promise.all([push.send("a", notice), push.send("b", notice), push.send("c", notice)]);
    assertEquals(results, ["ok", "ok", "ok"]);
    assertEquals(f.calls.filter((c) => c.url.startsWith("https://oauth2")).length, 1);
  } finally {
    f.restore();
  }
});
