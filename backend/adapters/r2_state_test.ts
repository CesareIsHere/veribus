import { assertEquals, assertRejects } from "jsr:@std/assert@1";
import { r2StateSnapshot, r2TripInfoCache } from "./http.ts";
import type { CycleState } from "../core/types.ts";

const env = { accountId: "acct", accessKeyId: "k", secretAccessKey: "s", bucket: "archive" };

/** An object store in a Map: the same URL answers a GET with what a PUT stored. */
function fakeR2() {
  const objects = new Map<string, Uint8Array>();
  const calls: string[] = [];
  const fetch = (url: string, init: RequestInit): Promise<Response> => {
    calls.push(`${init.method ?? "GET"} ${url}`);
    if (init.method === "PUT") {
      objects.set(url, new Uint8Array(init.body as Uint8Array));
      return Promise.resolve(new Response(null, { status: 200 }));
    }
    const found = objects.get(url);
    return Promise.resolve(found ? new Response(found as BodyInit) : new Response("not found", { status: 404 }));
  };
  return { fetch, objects, calls };
}

const state: CycleState = {
  markers: {
    vp: { lastModified: null, hash: "h", feedTs: 1 },
    tu: { lastModified: null, hash: "h", feedTs: 1 },
    sa: { lastModified: null, hash: null, feedTs: null },
  },
  vehicles: new Map(),
  trips: new Map(),
};

Deno.test("the state goes to one object of the bucket and comes back; nothing there is null, not an error", async () => {
  const r2 = fakeR2();
  const snapshot = r2StateSnapshot(env, { fetch: r2.fetch });
  assertEquals(await snapshot.get(), null);
  await snapshot.put(state);
  assertEquals((await snapshot.get())?.markers, state.markers);
  assertEquals(r2.calls, [
    "GET https://acct.r2.cloudflarestorage.com/archive/state/poller.json.gz",
    "PUT https://acct.r2.cloudflarestorage.com/archive/state/poller.json.gz",
    "GET https://acct.r2.cloudflarestorage.com/archive/state/poller.json.gz",
  ]);
});

Deno.test("an R2 error is thrown (the caller falls back to the database), and trip info is kept per version", async () => {
  const broken = r2StateSnapshot(env, { fetch: () => Promise.resolve(new Response("denied", { status: 403 })) });
  await assertRejects(() => broken.get(), Error, "HTTP 403");

  const r2 = fakeR2();
  const cache = r2TripInfoCache(env, { fetch: r2.fetch });
  assertEquals(await cache.get("v1"), null);
  await cache.put("v1", { T1: { routeId: "64", firstSeq: 1, lastSeq: 40 } });
  assertEquals(await cache.get("v1"), { T1: { routeId: "64", firstSeq: 1, lastSeq: 40 } });
  assertEquals(await cache.get("v2"), null); // a new import: the old entries do not apply
});
