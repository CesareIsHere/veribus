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

/**
 * What the database says about the previous cycle without the vehicles and trips: the feed markers and how many rows
 * there are. A few hundred bytes, against ~0.5 MB for the vehicles and trips themselves.
 */
export interface PendingState {
  markers: Record<Feed, FeedMarker>;
  counts: { vehicles: number; trips: number };
  /** Reads the vehicles and trips: called only when a feed brings news. */
  load(): Promise<CycleState>;
}

const isPending = (s: CycleState | PendingState): s is PendingState => "load" in s;

/**
 * A cycle that changes nothing (the feeds did not move: two out of three cycles at one every 10 s) needs only the
 * markers, so a [PendingState] does not read the vehicles and trips until a feed brings news. The cycle returns a
 * [PendingState] again when it did not need them.
 */
export function runCycle(ports: Ports, state: CycleState): Promise<{ state: CycleState; summary: CycleSummary }>;
export function runCycle(
  ports: Ports,
  state: CycleState | PendingState,
): Promise<{ state: CycleState | PendingState; summary: CycleSummary }>;
export async function runCycle(
  ports: Ports,
  state: CycleState | PendingState,
): Promise<{ state: CycleState | PendingState; summary: CycleSummary }> {
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
    const prev = isPending(state) ? await state.load() : state;
    const ids = new Set([
      ...[...(fresh.vp?.vehicles ?? prev.vehicles.values())].map((v) => v.tripId),
      ...(fresh.tu?.trips ?? []).map((t) => t.tripId),
      ...prev.trips.keys(),
    ]);
    result = evaluate({
      prev,
      vp: fresh.vp?.vehicles,
      tu: fresh.tu?.trips,
      tripInfo: await ports.store.loadTripInfo([...ids]),
      thresholds: await ports.store.loadThresholds(),
      now,
    });
  }

  await ports.store.commit({ now, markers, snapshots, errors, result, alerts: fresh.sa?.alerts ?? null });

  const next: CycleState | PendingState = result
    ? {
      markers,
      vehicles: new Map(result.vehicles.map((v) => [v.vehicleId, v])),
      trips: new Map(result.trips.map((t) => [t.tripId, t])),
    }
    : { ...state, markers };
  const size = isPending(next) ? next.counts : { vehicles: next.vehicles.size, trips: next.trips.size };
  return {
    state: next,
    summary: {
      fetched: Object.keys(fresh) as Feed[],
      vehicles: size.vehicles,
      trips: size.trips,
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

/**
 * What identifies the vehicles and trips: the hash and timestamp of the two feeds they come from. Not the alerts feed
 * (it changes the alerts, not the vehicles) and not Last-Modified (the HTTP header changes on identical content).
 */
const dataKey = (markers: Record<Feed, FeedMarker>) =>
  (["vp", "tu"] as const).map((f) => `${markers[f]?.hash ?? ""}@${markers[f]?.feedTs ?? ""}`).join("|");

/** The same data in memory and in the database: same feeds behind them, same number of rows. */
export function sameState(memory: CycleState, db: Pick<PendingState, "markers" | "counts">): boolean {
  return dataKey(memory.markers) === dataKey(db.markers) && memory.vehicles.size === db.counts.vehicles &&
    memory.trips.size === db.counts.trips;
}

/** The state outside the database, for a runtime whose memory does not last (see keepState). */
export interface StateSnapshot {
  /** The last state written, or null when there is none. Throws on a failure: the caller reads the database. */
  get(): Promise<CycleState | null>;
  put(state: CycleState): Promise<void>;
}

/** Where the state a cycle started from came from. */
export type StateSource = "memory" | "snapshot" | "database";

/**
 * The state between cycles for a runtime that has no process of its own (the edge function: a worker per call, gone
 * five seconds later, so memory alone never helps). The vehicles and trips are looked for, in this order:
 *
 * 1. in memory, while the worker lives;
 * 2. in the snapshot (R2 for the edge function): the last state this poller wrote, after each cycle that changed it;
 * 3. in the database, only if a feed brings news.
 *
 * The first two are used only if the database still says the same (the feed markers and row counts: a few hundred
 * bytes to ask), so another runtime writing, a missing or older snapshot or a manual change all end in the database.
 * Reading the vehicles and trips from Postgres at every cycle was ~4.6 GB a day of egress through the pooler.
 */
export function keepState(
  store: { peek(): Promise<Pick<PendingState, "markers" | "counts">>; loadState(): Promise<CycleState> },
  snapshot?: StateSnapshot,
) {
  let memory: CycleState | null = null;
  /** The data the snapshot holds, as of the last read or write. */
  let saved: string | null = null;
  let source: StateSource = "database";
  return {
    /** Where the state of the cycle in progress came from. */
    get source(): StateSource {
      return source;
    },
    /** What the next cycle starts from. The markers are always the database's: Last-Modified moves on its own. */
    async start(): Promise<CycleState | PendingState> {
      const db = await store.peek();
      if (memory && sameState(memory, db)) {
        source = "memory";
        return memory = { ...memory, markers: db.markers };
      }
      memory = null;
      if (snapshot) {
        try {
          const found = await snapshot.get();
          if (found && sameState(found, db)) {
            saved = dataKey(found.markers);
            source = "snapshot";
            return memory = { ...found, markers: db.markers };
          }
        } catch (e) {
          console.error(`state snapshot not read, using the database: ${e}`);
        }
      }
      source = "database";
      return { ...db, load: () => store.loadState() };
    },
    /** What the cycle ended with. Written to the snapshot when its data changed; a failure there only costs a read. */
    async end(state: CycleState | PendingState): Promise<void> {
      if (isPending(state)) {
        memory = null;
        return;
      }
      memory = state;
      if (snapshot && dataKey(state.markers) !== saved) {
        try {
          await snapshot.put(state);
          saved = dataKey(state.markers);
        } catch (e) {
          saved = null;
          console.error(`state snapshot not written: ${e}`);
        }
      }
    },
    /** After a failure the memory may not match what was committed. */
    forget(): void {
      memory = null;
    },
  };
}

/** Static data of the trips of the active network, kept between workers (see postgresStore). */
export interface TripInfoCache {
  /** What was stored for this network version, or null. Throws on a failure: the caller reads the database. */
  get(version: string): Promise<Record<string, TripInfo> | null>;
  put(version: string, entries: Record<string, TripInfo>): Promise<void>;
}
