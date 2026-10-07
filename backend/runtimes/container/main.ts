// Container runtime (Cloud Run, or local development): a loop that runs one cycle every 10 s and keeps
// the state in memory, still writing it to the database at every cycle. To migrate from the edge runtime:
// start this, then `select cron.unschedule('poller');`.
//
//   DB_URL=postgres://... [R2_ACCOUNT_ID=... R2_ACCESS_KEY_ID=... R2_SECRET_ACCESS_KEY=... R2_BUCKET=...] deno task poller
//
// Without R2_ACCOUNT_ID snapshots are archived under ./archive, with the same layout.
// With FCM_SERVICE_ACCOUNT (the service account JSON) it also sends the notices for followed trips after each cycle.
import { type Archive, runCycle } from "../../core/cycle.ts";
import type { CycleState } from "../../core/types.ts";
import { archivePath, healthchecks, r2Archive, rsmFeeds } from "../../adapters/http.ts";
import { postgresStore } from "../../adapters/postgres.ts";
import { fcmPush } from "../../adapters/fcm.ts";
import { runNotifier } from "../../core/notify.ts";

const env = (k: string) => Deno.env.get(k) ?? "";
const localArchive: Archive = {
  async put(feed, fetchedAt, gz) {
    const path = archivePath(feed, fetchedAt);
    await Deno.mkdir(`archive/${path.slice(0, path.lastIndexOf("/"))}`, { recursive: true });
    await Deno.writeFile(`archive/${path}`, gz);
    return path;
  },
};
const store = postgresStore(env("DB_URL"));
const ports = {
  feeds: rsmFeeds(),
  archive: env("R2_ACCOUNT_ID")
    ? r2Archive({
      accountId: env("R2_ACCOUNT_ID"),
      accessKeyId: env("R2_ACCESS_KEY_ID"),
      secretAccessKey: env("R2_SECRET_ACCESS_KEY"),
      bucket: env("R2_BUCKET"),
    })
    : localArchive,
  store,
  clock: { now: () => Math.floor(Date.now() / 1000) },
};
const heartbeat = healthchecks(Deno.env.get("HEALTHCHECKS_URL"));
const push = env("FCM_SERVICE_ACCOUNT") ? fcmPush(env("FCM_SERVICE_ACCOUNT")) : null;
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
      if (push) {
        const notices = await runNotifier({ store: store.notify, push }).catch((e) => console.error(e));
        if (notices?.claimed) console.log(new Date().toISOString(), "notices", JSON.stringify(notices));
      }
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
