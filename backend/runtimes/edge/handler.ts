// Supabase Edge Function runtime: pg_cron calls it every 10 s (supabase/migrations/*_poller_cron.sql).
// Each invocation takes the lease, reloads the state from the database and runs one cycle.
import { runCycle } from "../../core/cycle.ts";
import { healthchecks, rsmFeeds, storageArchive } from "../../adapters/http.ts";
import { postgresStore } from "../../adapters/postgres.ts";

const env = (k: string) => Deno.env.get(k) ?? "";
const store = postgresStore(env("POLLER_DB_URL") || env("SUPABASE_DB_URL"));
const ports = {
  feeds: rsmFeeds(),
  archive: storageArchive(env("SUPABASE_URL"), env("SUPABASE_SERVICE_ROLE_KEY")),
  store,
  clock: { now: () => Math.floor(Date.now() / 1000) },
};
const heartbeat = healthchecks(Deno.env.get("HEALTHCHECKS_URL"));

export async function handler(req: Request): Promise<Response> {
  const secret = env("POLLER_SECRET");
  if (!secret || req.headers.get("authorization") !== `Bearer ${secret}`) return new Response(null, { status: 401 });

  const owner = crypto.randomUUID();
  // The previous cycle is still running (or the container runtime owns the poller): skip this turn.
  if (!await store.tryAcquireLease(owner, 25)) return Response.json({ skipped: true }, { status: 202 });
  try {
    const { summary } = await runCycle(ports, await store.loadState());
    await heartbeat.ok(summary);
    return Response.json(summary);
  } catch (e) {
    console.error(e);
    await heartbeat.fail(e);
    return Response.json({ error: String(e) }, { status: 500 });
  } finally {
    await store.releaseLease(owner);
  }
}
