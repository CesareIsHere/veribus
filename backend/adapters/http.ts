// HTTP adapters: RSM feeds, R2 archive, Healthchecks.io heartbeat.
import { AwsClient } from "npm:aws4fetch@1.0.20";
import type { Archive, CycleSummary, FeedSource, StateSnapshot, TripInfoCache } from "../core/cycle.ts";
import { decodeState, decodeTripInfo, encodeState, encodeTripInfo } from "../core/snapshot.ts";
import type { Feed } from "../core/types.ts";

const RSM = "https://romamobilita.it/wp-content/uploads/shared";
const URLS: Record<Feed, string> = {
  vp: `${RSM}/rome_rtgtfs_vehicle_positions_feed.pb`,
  tu: `${RSM}/rome_rtgtfs_trip_updates_feed.pb`,
  sa: `${RSM}/rome_rtgtfs_service_alerts_feed.pb`,
};

export function rsmFeeds(): FeedSource {
  return {
    async fetchIfChanged(feed, prev) {
      const head = await fetch(URLS[feed], { method: "HEAD", signal: AbortSignal.timeout(5000) });
      await head.body?.cancel();
      const lastModified = head.headers.get("last-modified");
      if (lastModified && lastModified === prev.lastModified) return null;
      const res = await fetch(URLS[feed], { signal: AbortSignal.timeout(10000) });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return {
        lastModified: res.headers.get("last-modified") ?? lastModified,
        body: new Uint8Array(await res.arrayBuffer()),
      };
    },
  };
}

/** {feed}/YYYY/MM/DD/hhmmss.pb.gz: one folder per day, as the spec asks (RF-83). */
export function archivePath(feed: Feed, fetchedAt: number): string {
  const t = new Date(fetchedAt * 1000).toISOString(); // 2026-09-26T10:45:40.000Z
  return `${feed}/${t.slice(0, 4)}/${t.slice(5, 7)}/${t.slice(8, 10)}/${t.slice(11, 19).replaceAll(":", "")}.pb.gz`;
}

/** Raw snapshots on Cloudflare R2 (S3 API): ~1 GB a day would not fit Supabase Storage on the free plan.
 * Retention (30 days) is an R2 lifecycle rule on the bucket, not code. */
export function r2Archive(
  env: { accountId: string; accessKeyId: string; secretAccessKey: string; bucket: string },
): Archive {
  const aws = new AwsClient({
    accessKeyId: env.accessKeyId,
    secretAccessKey: env.secretAccessKey,
    service: "s3",
    region: "auto",
  });
  return {
    async put(feed, fetchedAt, gz) {
      const path = archivePath(feed, fetchedAt);
      const res = await aws.fetch(`https://${env.accountId}.r2.cloudflarestorage.com/${env.bucket}/${path}`, {
        method: "PUT",
        headers: { "Content-Type": "application/gzip" },
        body: gz as BodyInit,
      });
      if (!res.ok) throw new Error(`archive: HTTP ${res.status} ${await res.text()}`);
      return path;
    },
  };
}

type R2Env = { accountId: string; accessKeyId: string; secretAccessKey: string; bucket: string };

/** One object of the bucket: read (null when it does not exist) and overwritten. */
function r2Object(
  env: R2Env,
  key: string,
  opts: { fetch?: (url: string, init: RequestInit) => Promise<Response> } = {},
) {
  const aws = new AwsClient({
    accessKeyId: env.accessKeyId,
    secretAccessKey: env.secretAccessKey,
    service: "s3",
    region: "auto",
  });
  const url = `https://${env.accountId}.r2.cloudflarestorage.com/${env.bucket}/${key}`;
  const send = opts.fetch ?? ((u: string, init: RequestInit) => aws.fetch(u, init));
  return {
    async get(): Promise<Uint8Array | null> {
      const res = await send(url, { signal: AbortSignal.timeout(8000) });
      if (res.status === 404) {
        await res.body?.cancel();
        return null;
      }
      if (!res.ok) throw new Error(`R2 ${key}: HTTP ${res.status} ${await res.text()}`);
      return new Uint8Array(await res.arrayBuffer());
    },
    async put(body: Uint8Array): Promise<void> {
      const res = await send(url, {
        method: "PUT",
        headers: { "Content-Type": "application/gzip" },
        body: body as BodyInit,
        signal: AbortSignal.timeout(8000),
      });
      if (!res.ok) throw new Error(`R2 ${key}: HTTP ${res.status} ${await res.text()}`);
      await res.body?.cancel();
    },
  };
}

/**
 * The poller's state in R2 (`state/poller.json.gz`, overwritten after each cycle that changed it). The edge runtime
 * has no memory between calls and reading the state back from Postgres counts as egress; this does not.
 */
export function r2StateSnapshot(env: R2Env, opts: Parameters<typeof r2Object>[2] = {}): StateSnapshot {
  const object = r2Object(env, "state/poller.json.gz", opts);
  return {
    async get() {
      const bytes = await object.get();
      return bytes ? await decodeState(bytes) : null;
    },
    async put(state) {
      await object.put(await encodeState(state));
    },
  };
}

/** The static data of the trips seen so far, per network version (`state/trip_info.json.gz`). */
export function r2TripInfoCache(env: R2Env, opts: Parameters<typeof r2Object>[2] = {}): TripInfoCache {
  const object = r2Object(env, "state/trip_info.json.gz", opts);
  return {
    async get(version) {
      const bytes = await object.get();
      return bytes ? await decodeTripInfo(bytes, version) : null;
    },
    async put(version, entries) {
      await object.put(await encodeTripInfo(version, entries));
    },
  };
}

/** Dead man's switch outside Supabase (RF-86): silence for 5 minutes sends an email. */
export function healthchecks(url: string | undefined) {
  const ping = (suffix: string, body: unknown) =>
    url
      ? fetch(`${url}${suffix}`, { method: "POST", body: JSON.stringify(body), signal: AbortSignal.timeout(5000) })
        .then((r) => r.body?.cancel(), () => {})
      : Promise.resolve();
  return {
    ok: (s: CycleSummary) => ping(s.stale.length || s.errors.length ? "/fail" : "", s),
    fail: (e: unknown) => ping("/fail", String(e)),
  };
}
