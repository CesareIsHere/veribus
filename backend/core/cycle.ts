// One realtime cycle (spec SC-14, D-04). It knows nothing about who calls it or where state lives:
// the runtimes (edge function today, container tomorrow) plug the ports in.
import { decode, type Decoded } from "./gtfsrt.ts";
import { evaluate } from "./engine.ts";
import type { Alert, CycleState, EngineResult, Feed, FeedMarker, Snapshot, Thresholds, TripInfo } from "./types.ts";
import { FEEDS } from "./types.ts";

export interface FeedSource {
  /** HEAD, then GET only when Last-Modified changed; null when unchanged. */
  fetchIfChanged(feed: Feed, prev: FeedMarker): Promise<{ lastModified: string | null; body: Uint8Array } | null>;
}

export interface Archive {
  /** Stores the gzipped raw snapshot, returns its path (RF-83). */
  put(feed: Feed, fetchedAt: number, gz: Uint8Array): Promise<string>;
}

export interface Commit {
  now: number;
  markers: Record<Feed, FeedMarker>;
  snapshots: Snapshot[];
  errors: { feed: Feed; error: string }[];
  result: EngineResult | null;
  alerts: Alert[] | null;
}

export interface StateStore {
  tryAcquireLease(owner: string, seconds: number): Promise<boolean>;
  releaseLease(owner: string): Promise<void>;
  loadState(): Promise<CycleState>;
  loadTripInfo(tripIds: string[]): Promise<Map<string, TripInfo>>;
  loadThresholds(): Promise<Thresholds>;
  /** Writes everything in one transaction. */
  commit(c: Commit): Promise<void>;
}

export interface Ports {
  feeds: FeedSource;
  archive: Archive;
  store: StateStore;
  clock: { now(): number };
}

export interface CycleSummary {
  fetched: Feed[];
  vehicles: number;
  trips: number;
  errors: string[];
  /** Feeds whose content has not changed for more than 10 minutes (RSM stopped, RF-86). */
  stale: Feed[];
}

export async function runCycle(ports: Ports, state: CycleState): Promise<{ state: CycleState; summary: CycleSummary }> {
  const now = ports.clock.now();
  const markers = structuredClone(state.markers);
  const snapshots: Snapshot[] = [];
  const errors: Commit["errors"] = [];
  const fresh: Partial<Record<Feed, Decoded>> = {};

  for (const feed of FEEDS) {
    try {
      const f = await ports.feeds.fetchIfChanged(feed, markers[feed]);
      if (!f) continue;
      const hash = await sha1(f.body);
      // Last-Modified changes even on identical content (measured 82/143): the hash decides.
      if (hash === markers[feed].hash) {
        markers[feed].lastModified = f.lastModified;
        continue;
      }
      const snap: Snapshot = { feed, feedTs: null, hash, bytes: f.body.length, outcome: "ok", path: null };
      snapshots.push(snap);
      snap.path = await ports.archive.put(feed, now, await gzip(f.body));
      let decoded: Decoded;
      try {
        decoded = decode(f.body);
      } catch (e) {
        snap.outcome = "error"; // SC-14a: archived, the previous state stays valid
        errors.push({ feed, error: `decode: ${e}` });
        continue;
      }
      snap.feedTs = decoded.ts;
      if (markers[feed].feedTs != null && decoded.ts < markers[feed].feedTs!) {
        snap.outcome = "stale"; // SC-14b
        continue;
      }
      markers[feed] = { lastModified: f.lastModified, hash, feedTs: decoded.ts };
      fresh[feed] = decoded;
    } catch (e) {
      errors.push({ feed, error: String(e) });
    }
  }

  let result: EngineResult | null = null;
  if (fresh.vp || fresh.tu) {
    const ids = new Set([
      ...[...(fresh.vp?.vehicles ?? state.vehicles.values())].map((v) => v.tripId),
      ...(fresh.tu?.trips ?? []).map((t) => t.tripId),
      ...state.trips.keys(),
    ]);
    result = evaluate({
      prev: state,
      vp: fresh.vp?.vehicles,
      tu: fresh.tu?.trips,
      tripInfo: await ports.store.loadTripInfo([...ids]),
      thresholds: await ports.store.loadThresholds(),
      now,
    });
  }

  await ports.store.commit({ now, markers, snapshots, errors, result, alerts: fresh.sa?.alerts ?? null });

  const next: CycleState = result
    ? {
      markers,
      vehicles: new Map(result.vehicles.map((v) => [v.vehicleId, v])),
      trips: new Map(result.trips.map((t) => [t.tripId, t])),
    }
    : { ...state, markers };
  return {
    state: next,
    summary: {
      fetched: Object.keys(fresh) as Feed[],
      vehicles: next.vehicles.size,
      trips: next.trips.size,
      errors: errors.map((e) => `${e.feed}: ${e.error}`),
      stale: FEEDS.filter((f) => f !== "sa" && markers[f].feedTs != null && now - markers[f].feedTs! > 600),
    },
  };
}

async function sha1(data: Uint8Array): Promise<string> {
  const d = await crypto.subtle.digest("SHA-1", data as BufferSource);
  return [...new Uint8Array(d)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

async function gzip(data: Uint8Array): Promise<Uint8Array> {
  const stream = new Blob([data as BlobPart]).stream().pipeThrough(new CompressionStream("gzip"));
  return new Uint8Array(await new Response(stream).arrayBuffer());
}
