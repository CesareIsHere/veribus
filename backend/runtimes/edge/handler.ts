// Supabase Edge Function runtime: pg_cron calls it every 10 s (supabase/migrations/*_poller_cron.sql).
// Each invocation takes the lease, reloads the state from the database and runs one cycle.
import { runCycle } from "../../core/cycle.ts";
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
const heartbeat = healthchecks(Deno.env.get("HEALTHCHECKS_URL"));
// Notices for followed trips; without the FCM service account nobody is notified and the poller is unchanged.
const push = fcmPushFromEnv(env("FCM_SERVICE_ACCOUNT"));

export async function handler(req: Request): Promise<Response> {
  const secret = env("POLLER_SECRET");
  if (!secret || req.headers.get("authorization") !== `Bearer ${secret}`) return new Response(null, { status: 401 });

  const owner = crypto.randomUUID();
  // The previous cycle is still running (or the container runtime owns the poller): skip this turn.
  if (!await store.tryAcquireLease(owner, 25)) return Response.json({ skipped: true }, { status: 202 });
  try {
    const { summary } = await runCycle(ports, await store.loadState());
    await heartbeat.ok(summary);
    // The state is committed: the notices read it. A failure here must not fail the cycle.
    const notices = push ? await runNotifier({ store: store.notify, push }).catch((e) => console.error(e)) : null;
    return Response.json({ ...summary, notices });
  } catch (e) {
    console.error(e);
    await heartbeat.fail(e);
    return Response.json({ error: String(e) }, { status: 500 });
  } finally {
    await store.releaseLease(owner);
  }
}
