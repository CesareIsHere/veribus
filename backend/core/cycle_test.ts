// A cycle on real snapshots (26/09/2026) with in-memory ports.
import { assert, assertEquals } from "jsr:@std/assert@1";
import { type Commit, keepState, type PendingState, type Ports, runCycle, sameState } from "./cycle.ts";
import type { CycleState, Feed } from "./types.ts";

const body = (f: Feed) => Deno.readFileSync(new URL(`./testdata/${f}.pb`, import.meta.url));

Deno.test("first cycle archives and applies all feeds; the next one downloads nothing", async () => {
  const commits: Commit[] = [];
  const archived: string[] = [];
  const ports: Ports = {
    feeds: {
      fetchIfChanged: (f, prev) =>
        Promise.resolve(prev.lastModified === "t0" ? null : { lastModified: "t0", body: body(f) }),
    },
    archive: {
      put: (f) => {
        archived.push(f);
        return Promise.resolve(`${f}/x.pb.gz`);
      },
    },
    store: {
      tryAcquireLease: () => Promise.resolve(true),
      releaseLease: () => Promise.resolve(),
      loadState: () => Promise.reject(new Error("unused")),
      // Every trip is "in the network": the engine keeps them all.
      loadTripInfo: (ids) => Promise.resolve(new Map(ids.map((id) => [id, { routeId: id, firstSeq: 1, lastSeq: 40 }]))),
      loadThresholds: () =>
        Promise.resolve({ s2_min: 5, s3_meters: 30, s3_min: 5, suppressed_min: 5, completed_ratio: 0.9 }),
      commit: (c) => Promise.resolve(void commits.push(c)),
    },
    clock: { now: () => 1790419130 },
  };
  const empty = { lastModified: null, hash: null, feedTs: null };
  const initial: CycleState = { markers: { vp: empty, tu: empty, sa: empty }, vehicles: new Map(), trips: new Map() };

  const first = await runCycle(ports, initial);
  assertEquals(first.summary.fetched, ["vp", "tu", "sa"]);
  assertEquals(archived, ["vp", "tu", "sa"]);
  assert(first.summary.vehicles > 900, `vehicles: ${first.summary.vehicles}`);
  assert(first.summary.trips > 900, `trips: ${first.summary.trips}`);
  assert(commits[0].alerts!.length > 100);
  assertEquals(new Set(commits[0].result!.trips.map((t) => t.tripId)).size, commits[0].result!.trips.length); // deduped

  const second = await runCycle(ports, first.state);
  assertEquals(second.summary.fetched, []);
  assertEquals(commits[1].result, null);
});

// The cycle only reads the vehicles and trips when a feed brings news; the edge runtime keeps them in memory between
// cycles (every read of them is ~0.5 MB of egress, and a cycle runs every 10 s).

const empty = { lastModified: null, hash: null, feedTs: null };
const emptyState = (): CycleState => ({
  markers: { vp: empty, tu: empty, sa: empty },
  vehicles: new Map(),
  trips: new Map(),
});

/** Ports where the feeds answer `news` (a new Last-Modified and content) or nothing. */
function portsWith(commits: Commit[], news: boolean): Ports {
  return {
    feeds: {
      fetchIfChanged: (f, prev) => Promise.resolve(news && !prev.hash ? { lastModified: "t0", body: body(f) } : null),
    },
    archive: { put: (f) => Promise.resolve(`${f}/x.pb.gz`) },
    store: {
      tryAcquireLease: () => Promise.resolve(true),
      releaseLease: () => Promise.resolve(),
      loadState: () => Promise.reject(new Error("the cycle must not read the state itself")),
      loadTripInfo: (ids) => Promise.resolve(new Map(ids.map((id) => [id, { routeId: id, firstSeq: 1, lastSeq: 40 }]))),
      loadThresholds: () =>
        Promise.resolve({ s2_min: 5, s3_meters: 30, s3_min: 5, suppressed_min: 5, completed_ratio: 0.9 }),
      commit: (c) => Promise.resolve(void commits.push(c)),
    },
    clock: { now: () => 1790419130 },
  };
}

function pending(markers = emptyState().markers, counts = { vehicles: 1300, trips: 1280 }) {
  const calls = { load: 0 };
  const state: PendingState = {
    markers,
    counts,
    load: () => {
      calls.load++;
      return Promise.resolve({ markers, vehicles: new Map(), trips: new Map() });
    },
  };
  return { state, calls };
}

Deno.test("a cycle with no news never reads the vehicles and trips, and reports the counts it was given", async () => {
  const commits: Commit[] = [];
  const p = pending({ vp: { lastModified: "t0", hash: "h1", feedTs: 10 }, tu: empty, sa: empty });
  const r = await runCycle(portsWith(commits, false), p.state);
  assertEquals(p.calls.load, 0);
  assertEquals(commits[0].result, null);
  assertEquals([r.summary.vehicles, r.summary.trips], [1300, 1280]);
  assertEquals("load" in r.state, true); // still not read: the next cycle can skip it too
});

Deno.test("a cycle with news reads the vehicles and trips once and gives the same result as with them in hand", async () => {
  const commitsLazy: Commit[] = [];
  const commitsEager: Commit[] = [];
  const p = pending();
  const lazy = await runCycle(portsWith(commitsLazy, true), p.state);
  const eager = await runCycle(portsWith(commitsEager, true), emptyState());
  assertEquals(p.calls.load, 1);
  assertEquals(lazy.summary, eager.summary);
  assertEquals(commitsLazy[0].result, commitsEager[0].result);
  assertEquals("vehicles" in lazy.state, true); // known now: it can be kept
});

Deno.test("sameState compares the markers and the number of rows", () => {
  const mem = emptyState();
  mem.markers.vp = { lastModified: "t0", hash: "h", feedTs: 5 };
  const db = { markers: structuredClone(mem.markers), counts: { vehicles: 0, trips: 0 } };
  assert(sameState(mem, db));
  assert(!sameState(mem, { ...db, counts: { vehicles: 1, trips: 0 } }));
  assert(!sameState(mem, { ...db, markers: { ...db.markers, vp: { ...db.markers.vp, hash: "other" } } }));
  assert(!sameState(mem, { ...db, markers: { ...db.markers, tu: { ...db.markers.tu, feedTs: 7 } } }));
});

Deno.test("keepState: the database is asked for a few hundred bytes, the state only when memory is out of date", async () => {
  const commits: Commit[] = [];
  let db = { markers: emptyState().markers, counts: { vehicles: 0, trips: 0 } };
  const reads = { peek: 0, loadState: 0 };
  const keeper = keepState({
    peek: () => (reads.peek++, Promise.resolve(db)),
    loadState: () => (reads.loadState++, Promise.resolve(emptyState())),
  });

  // 1. Nothing in memory: lazy start; the news make the cycle read the state once (through `load`).
  const first = await keeper.start();
  assertEquals("load" in first, true);
  const ran = await runCycle(portsWith(commits, true), first);
  assertEquals(reads.loadState, 1); // the news made the cycle call `load`, and nothing else did
  keeper.end(ran.state);
  const kept = ran.state as CycleState;
  db = { markers: structuredClone(kept.markers), counts: { vehicles: kept.vehicles.size, trips: kept.trips.size } };

  // 2. The database says what memory says: the very same state comes back, nothing is read.
  assert(await keeper.start() === kept);
  assertEquals(reads.loadState, 1); // still the one read of step 1

  // 3. Someone else wrote (other markers) or a row was lost: the memory is dropped.
  db = { ...db, markers: { ...db.markers, vp: { ...db.markers.vp, hash: "someone else" } } };
  assertEquals("load" in await keeper.start(), true);
  db = { markers: structuredClone(kept.markers), counts: { vehicles: kept.vehicles.size, trips: kept.trips.size } };
  assertEquals("load" in await keeper.start(), true); // and it does not come back by itself

  // 4. After a failure the memory is not trusted, even if the database agrees.
  keeper.end(kept);
  assert(await keeper.start() === kept);
  keeper.forget();
  assertEquals("load" in await keeper.start(), true);
});
