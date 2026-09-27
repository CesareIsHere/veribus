// Re-runs the engine on archived snapshots (RF-85): same `evaluate` as the poller, fed in feed-timestamp order.
// Prints one CSV line per trip whenever its status or signal changes: the raw material for tuning thresholds
// and for the metrics of the spec (section 14).
//
//   DB_URL=postgres://... deno run -A replay/main.ts <archive dir> > changes.csv
//
// <archive dir> holds vp/ and tu/ snapshots (*.pb.gz) at any depth, e.g. a day copied from the `archive` bucket
// or the ./archive folder of the container runtime. Trip data and thresholds come from DB_URL.
import { decode } from "../core/gtfsrt.ts";
import { evaluate } from "../core/engine.ts";
import type { CycleState, TripPrediction, VehiclePosition } from "../core/types.ts";
import { postgresStore } from "../adapters/postgres.ts";

const dir = Deno.args[0];
if (!dir) throw new Error("usage: replay/main.ts <archive dir>");

async function* files(path: string): AsyncGenerator<string> {
  for await (const e of Deno.readDir(path)) {
    const p = `${path}/${e.name}`;
    if (e.isDirectory) yield* files(p);
    else if (e.name.endsWith(".pb.gz")) yield p;
  }
}

type Step = { ts: number; vp?: VehiclePosition[]; tu?: TripPrediction[] };
const steps: Step[] = [];
for (const feed of ["vp", "tu"] as const) {
  for await (const path of files(`${dir}/${feed}`)) {
    const gz = await Deno.readFile(path);
    const raw = new Uint8Array(
      await new Response(new Blob([gz]).stream().pipeThrough(new DecompressionStream("gzip"))).arrayBuffer(),
    );
    const d = decode(raw);
    steps.push(feed === "vp" ? { ts: d.ts, vp: d.vehicles } : { ts: d.ts, tu: d.trips });
  }
}
steps.sort((a, b) => a.ts - b.ts);

const store = postgresStore(Deno.env.get("DB_URL") ?? "");
const ids = new Set(steps.flatMap((s) => [...(s.vp ?? []), ...(s.tu ?? [])].map((x) => x.tripId)));
const tripInfo = await store.loadTripInfo([...ids]);
const thresholds = await store.loadThresholds();
await store.close();

let state: Pick<CycleState, "vehicles" | "trips"> = { vehicles: new Map(), trips: new Map() };
const last = new Map<string, string>();
console.log("time,trip_id,route_id,status,signal,min");
for (const step of steps) {
  const r = evaluate({ prev: state, vp: step.vp, tu: step.tu, tripInfo, thresholds, now: step.ts });
  state = {
    vehicles: new Map(r.vehicles.map((v) => [v.vehicleId, v])),
    trips: new Map(r.trips.map((t) => [t.tripId, t])),
  };
  for (const t of r.trips) {
    const key = `${t.status},${t.signal?.code ?? ""}`;
    if (last.get(t.tripId) === key) continue;
    last.set(t.tripId, key);
    console.log(`${new Date(step.ts * 1000).toISOString()},${t.tripId},${t.routeId},${key},${t.signal?.min ?? ""}`);
  }
}
