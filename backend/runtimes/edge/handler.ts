// Supabase Edge Function runtime: pg_cron calls it every 10 s (supabase/migrations/*_poller_cron.sql).
// Each invocation takes the lease and runs one cycle. The vehicles and trips of the previous cycle stay in memory
// while the worker lives (core/cycle.ts, keepState): reading them from the database every 10 s was ~4.6 GB a day of
// egress through the pooler, and the free plan includes 5 GB a month.
import { keepState, runCycle } from "../../core/cycle.ts";
import { healthchecks, r2Archive, rsmFeeds } from "../../adapters/http.ts";
import { postgresStore } from "../../adapters/postgres.ts";
import { fcmPushFromEnv } from "../../adapters/fcm.ts";
import { runNotifier } from "../../core/notify.ts";

const env = (k: string) => Deno.env.get(k) ?? "";
const store = postgresStore(env("POLLER_DB_URL") || env("SUPABASE_DB_URL"));
const ports = {
  feeds: rsmFeeds(),
  archive: r2Archive({
    accountId: env("R2_ACCOUNT_ID"),
    accessKeyId: env("R2_ACCESS_KEY_ID"),
    secretAccessKey: env("R2_SECRET_ACCESS_KEY"),
    bucket: env("R2_BUCKET"),
  }),
  store,
  clock: { now: () => Math.floor(Date.now() / 1000) },
};
const state = keepState(store);
const heartbeat = healthchecks(Deno.env.get("HEALTHCHECKS_URL"));
// Notices for followed trips; without the FCM service account nobody is notified and the poller is unchanged.
const push = fcmPushFromEnv(env("FCM_SERVICE_ACCOUNT"));

export async function handler(req: Request): Promise<Response> {
  const secret = env("POLLER_SECRET");
  if (!secret || req.headers.get("authorization") !== `Bearer ${secret}`) return new Response(null, { status: 401 });

  const owner = crypto.randomUUID();
  // The previous cycle is still running (or the container runtime owns the poller): skip this turn.
  if (!await store.tryAcquireLease(owner, 25)) {
    state.forget(); // someone else is cycling: what is in memory may be behind
    return Response.json({ skipped: true }, { status: 202 });
  }
  try {
    const cycle = await runCycle(ports, await state.start());
    state.end(cycle.state);
    const summary = cycle.summary;
    await heartbeat.ok(summary);
    // The state is committed: the notices read it. A failure here must not fail the cycle.
    const notices = push ? await runNotifier({ store: store.notify, push }).catch((e) => console.error(e)) : null;
    return Response.json({ ...summary, notices });
  } catch (e) {
    state.forget();
    console.error(e);
    await heartbeat.fail(e);
    return Response.json({ error: String(e) }, { status: 500 });
  } finally {
    await store.releaseLease(owner);
  }
}
