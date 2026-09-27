// A cycle on real snapshots (26/09/2026) with in-memory ports.
import { assert, assertEquals } from "jsr:@std/assert@1";
import { type Commit, type Ports, runCycle } from "./cycle.ts";
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
