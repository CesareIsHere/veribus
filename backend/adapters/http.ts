// HTTP adapters: RSM feeds, Supabase Storage archive, Healthchecks.io heartbeat.
import type { Archive, CycleSummary, FeedSource } from "../core/cycle.ts";
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

/** archive/{feed}/YYYY/MM/DD/hhmmss.pb.gz in the private `archive` bucket. */
export function storageArchive(supabaseUrl: string, serviceKey: string): Archive {
  return {
    async put(feed, fetchedAt, gz) {
      const t = new Date(fetchedAt * 1000).toISOString(); // 2026-09-26T10:45:40.000Z
      const path = `${feed}/${t.slice(0, 4)}/${t.slice(5, 7)}/${t.slice(8, 10)}/${
        t.slice(11, 19).replaceAll(":", "")
      }.pb.gz`;
      const res = await fetch(`${supabaseUrl}/storage/v1/object/archive/${path}`, {
        method: "POST",
        headers: { Authorization: `Bearer ${serviceKey}`, "Content-Type": "application/gzip", "x-upsert": "true" },
        body: gz as BodyInit,
      });
      if (!res.ok) throw new Error(`archive: HTTP ${res.status} ${await res.text()}`);
      return path;
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
