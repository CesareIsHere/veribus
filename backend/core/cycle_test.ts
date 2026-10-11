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

Deno.test("sameState compares the data (hash and time of vp and tu) and the number of rows, not the HTTP headers or the alerts", () => {
  const mem = emptyState();
  mem.markers.vp = { lastModified: "t0", hash: "h", feedTs: 5 };
  const db = { markers: structuredClone(mem.markers), counts: { vehicles: 0, trips: 0 } };
  assert(sameState(mem, db));
  assert(!sameState(mem, { ...db, counts: { vehicles: 1, trips: 0 } }));
  assert(!sameState(mem, { ...db, markers: { ...db.markers, vp: { ...db.markers.vp, hash: "other" } } }));
  assert(!sameState(mem, { ...db, markers: { ...db.markers, tu: { ...db.markers.tu, feedTs: 7 } } }));
  // Last-Modified moves on identical content, and the alerts feed does not touch the vehicles and trips.
  assert(sameState(mem, { ...db, markers: { ...db.markers, vp: { ...db.markers.vp, lastModified: "t9" } } }));
  assert(sameState(mem, { ...db, markers: { ...db.markers, sa: { lastModified: "x", hash: "alerts", feedTs: 99 } } }));
});

/** A store whose database has a state, and a snapshot in a variable. */
function keeperWith(db: { markers: CycleState["markers"]; counts: { vehicles: number; trips: number } }) {
  const calls = { peek: 0, loadState: 0, get: 0, put: 0 };
  const box: { snapshot: CycleState | null; failGet: boolean; failPut: boolean } = {
    snapshot: null,
    failGet: false,
    failPut: false,
  };
  const keeper = keepState(
    {
      peek: () => (calls.peek++, Promise.resolve(db)),
      loadState: () => (calls.loadState++, Promise.resolve(emptyState())),
    },
    {
      get: () => {
        calls.get++;
        return box.failGet ? Promise.reject(new Error("R2 down")) : Promise.resolve(box.snapshot);
      },
      put: (state) => {
        calls.put++;
        if (box.failPut) return Promise.reject(new Error("R2 down"));
        box.snapshot = state;
        return Promise.resolve();
      },
    },
  );
  return { keeper, calls, box, setDb: (d: typeof db) => (db = d) };
}

const stateWith = (hash: string, n = 2): CycleState => {
  const s = emptyState();
  s.markers.vp = { lastModified: "t", hash, feedTs: 10 };
  s.markers.tu = { lastModified: "t", hash, feedTs: 10 };
  for (let i = 0; i < n; i++) {
    s.vehicles.set(`V${i}`, {
      vehicleId: `V${i}`,
      label: null,
      tripId: `T${i}`,
      routeId: "R",
      lat: 1,
      lon: 2,
      gpsAt: 3,
      seq: 1,
      stopId: null,
      stillLat: 1,
      stillLon: 2,
      stillSince: 3,
    });
    s.trips.set(`T${i}`, {
      tripId: `T${i}`,
      routeId: "R",
      vehicleId: `V${i}`,
      status: "confirmed",
      signal: null,
      predSeq: [1],
      predTs: [5],
      lastSeq: 1,
      seenAt: 3,
      suppressedAt: null,
    });
  }
  return s;
};
const dbOf = (s: CycleState) => ({ markers: s.markers, counts: { vehicles: s.vehicles.size, trips: s.trips.size } });

Deno.test("keepState: a fresh worker takes the state from the snapshot when the database agrees, and reads Postgres only if not", async () => {
  const saved = stateWith("h1");
  const k = keeperWith(dbOf(saved));
  k.box.snapshot = saved;

  // The database says what the snapshot says: no state read from Postgres, the markers are the database's.
  const start = await k.keeper.start();
  assert("vehicles" in start);
  assertEquals(k.keeper.source, "snapshot");
  assertEquals(k.calls.loadState, 0);
  assertEquals((start as CycleState).vehicles.size, 2);

  // The snapshot is older than the database (a cycle wrote the database, then died before the snapshot): lazy start.
  const newer = stateWith("h2");
  const k2 = keeperWith(dbOf(newer));
  k2.box.snapshot = saved;
  assertEquals("load" in await k2.keeper.start(), true);
  assertEquals(k2.keeper.source, "database");

  // No snapshot yet, or the snapshot cannot be read: also the database, and the cycle goes on.
  const k3 = keeperWith(dbOf(saved));
  assertEquals("load" in await k3.keeper.start(), true);
  const k4 = keeperWith(dbOf(saved));
  k4.box.snapshot = saved;
  k4.box.failGet = true;
  const quiet = console.error;
  console.error = () => {};
  try {
    assertEquals("load" in await k4.keeper.start(), true);
  } finally {
    console.error = quiet;
  }
});

Deno.test("keepState: the snapshot is written only when the vehicles or trips changed, and a failure to write is not a failure", async () => {
  const before = stateWith("h1");
  const k = keeperWith(dbOf(before));
  k.box.snapshot = before;
  await k.keeper.start(); // from the snapshot
  assertEquals(k.calls.put, 0);

  // A cycle with no news (only Last-Modified or the alerts moved): nothing to write.
  const quietCycle = {
    ...before,
    markers: { ...before.markers, sa: { lastModified: "x", hash: "alerts", feedTs: 1 } },
  };
  await k.keeper.end(quietCycle);
  assertEquals(k.calls.put, 0);

  // A cycle with news: written once.
  const after = stateWith("h2", 3);
  await k.keeper.end(after);
  assertEquals(k.calls.put, 1);
  assertEquals(k.box.snapshot, after);
  await k.keeper.end(after);
  assertEquals(k.calls.put, 1);

  // Not known (the cycle did not read the vehicles and trips): nothing to write and nothing kept.
  await k.keeper.end({ markers: after.markers, counts: { vehicles: 3, trips: 3 }, load: () => Promise.resolve(after) });

  // R2 refuses the write: the cycle is not failed, and the next worker will read Postgres.
  const k2 = keeperWith(dbOf(before));
  k2.box.failPut = true;
  const quiet = console.error;
  console.error = () => {};
  try {
    await k2.keeper.end(after); // does not throw
  } finally {
    console.error = quiet;
  }
  assertEquals(k2.calls.put, 1);
});

Deno.test("keepState: the memory of a living worker is used before the snapshot; after a failure the snapshot is", async () => {
  const s = stateWith("h1");
  const k = keeperWith(dbOf(s));
  await k.keeper.end(s); // this worker ran a cycle that left `s`
  assertEquals((await k.keeper.start() as CycleState).vehicles.size, 2);
  assertEquals(k.keeper.source, "memory");
  assertEquals(k.calls.get, 0);

  k.keeper.forget();
  await k.keeper.start(); // the snapshot `end` wrote: the database still agrees with it
  assertEquals(k.keeper.source, "snapshot");
  assertEquals(k.calls.get, 1);
});
