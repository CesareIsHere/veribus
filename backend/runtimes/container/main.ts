// Container runtime (Cloud Run, or local development): a loop that runs one cycle every 10 s and keeps
// the state in memory, still writing it to the database at every cycle. To migrate from the edge runtime:
// start this, then `select cron.unschedule('poller');`.
//
//   DB_URL=postgres://... [SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=...] deno task poller
//
// Without SUPABASE_URL snapshots are archived under ./archive.
import { type Archive, runCycle } from "../../core/cycle.ts";
import type { CycleState } from "../../core/types.ts";
import { healthchecks, rsmFeeds, storageArchive } from "../../adapters/http.ts";
import { postgresStore } from "../../adapters/postgres.ts";

const env = (k: string) => Deno.env.get(k) ?? "";
const localArchive: Archive = {
  async put(feed, fetchedAt, gz) {
    await Deno.mkdir(`archive/${feed}`, { recursive: true });
    await Deno.writeFile(`archive/${feed}/${fetchedAt}.pb.gz`, gz);
    return `${feed}/${fetchedAt}.pb.gz`;
  },
};
const store = postgresStore(env("DB_URL"));
const ports = {
  feeds: rsmFeeds(),
  archive: env("SUPABASE_URL") ? storageArchive(env("SUPABASE_URL"), env("SUPABASE_SERVICE_ROLE_KEY")) : localArchive,
  store,
  clock: { now: () => Math.floor(Date.now() / 1000) },
};
const heartbeat = healthchecks(Deno.env.get("HEALTHCHECKS_URL"));
const owner = crypto.randomUUID();
let state: CycleState | null = null;

while (true) {
  const start = Date.now();
  try {
    if (await store.tryAcquireLease(owner, 25)) {
      state ??= await store.loadState();
      const r = await runCycle(ports, state);
      state = r.state;
      console.log(new Date().toISOString(), JSON.stringify(r.summary));
      await heartbeat.ok(r.summary);
    } else {
      state = null; // someone else is cycling: reload when we get the lease back
    }
  } catch (e) {
    console.error(e);
    state = null;
    await heartbeat.fail(e);
  }
  await new Promise((r) => setTimeout(r, Math.max(0, 10000 - (Date.now() - start))));
}
