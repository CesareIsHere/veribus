// One test per signal (RF-84).
import { assertEquals } from "jsr:@std/assert@1";
import { evaluate } from "./engine.ts";
import type { Thresholds, TripInfo, TripPrediction, TripState, Vehicle, VehiclePosition } from "./types.ts";

const NOW = 1_790_000_000;
const thresholds: Thresholds = { s2_min: 5, s3_meters: 30, s3_min: 5, suppressed_min: 5, completed_ratio: 0.9 };
const tripInfo = new Map<string, TripInfo>([["T", { routeId: "64", firstSeq: 1, lastSeq: 21 }]]);

const pos = (o: Partial<VehiclePosition> = {}): VehiclePosition => ({
  vehicleId: "V",
  label: "3001",
  tripId: "T",
  routeId: "64",
  lat: 41.9,
  lon: 12.5,
  gpsAt: NOW - 30,
  seq: 5,
  stopId: "S5",
  ...o,
});
const vehicle = (o: Partial<Vehicle> = {}): Vehicle => ({
  ...pos(),
  stillLat: 41.9,
  stillLon: 12.5,
  stillSince: NOW - 30,
  ...o,
});
const pred = (o: Partial<TripPrediction> = {}): TripPrediction => ({
  tripId: "T",
  canceled: false,
  seq: [6, 7],
  ts: [NOW + 120, NOW + 240],
  ...o,
});
const state = (o: Partial<TripState> = {}): TripState => ({
  tripId: "T",
  routeId: "64",
  vehicleId: "V",
  status: "confirmed",
  signal: null,
  predSeq: [6, 7],
  predTs: [NOW + 120, NOW + 240],
  lastSeq: 5,
  seenAt: NOW - 30,
  suppressedAt: null,
  ...o,
});

function run(o: { vehicles?: Vehicle[]; trips?: TripState[]; vp?: VehiclePosition[]; tu?: TripPrediction[] }) {
  const prev = {
    vehicles: new Map((o.vehicles ?? []).map((v) => [v.vehicleId, v])),
    trips: new Map((o.trips ?? []).map((t) => [t.tripId, t])),
  };
  return evaluate({ prev, vp: o.vp, tu: o.tu, tripInfo, thresholds, now: NOW });
}

Deno.test("moving vehicle with prediction: confirmed", () => {
  const r = run({ vp: [pos()], tu: [pred()] });
  assertEquals(r.trips[0].status, "confirmed");
  assertEquals(r.trips[0].signal, null);
  assertEquals(r.seenRoutes, ["64"]);
});

Deno.test("S1: canceled trip", () => {
  const r = run({ vp: [], tu: [pred({ canceled: true })] });
  assertEquals(r.trips[0].status, "canceled");
  assertEquals(r.trips[0].signal, { code: "S1" });
});

Deno.test("S2: prediction but the vehicle stopped transmitting", () => {
  const r = run({ trips: [state({ seenAt: NOW - 8 * 60 })], vp: [pos({ gpsAt: NOW - 7 * 60 })], tu: [pred()] });
  assertEquals(r.trips[0].status, "uncertain");
  assertEquals(r.trips[0].signal, { code: "S2", min: 7 });
  assertEquals(r.vehicles, []);
});

Deno.test("S2: vehicle and predictions vanish mid-route: suppressed for 5 minutes, then gone (RF-29)", () => {
  const r = run({ trips: [state()], vp: [], tu: [] });
  assertEquals(r.trips[0].status, "suppressed");
  assertEquals(r.trips[0].suppressedAt, NOW);
  assertEquals(r.trips[0].predTs, [NOW + 120, NOW + 240]); // last known times stay visible
  const later = run({ trips: [state({ status: "suppressed", suppressedAt: NOW - 6 * 60 })], vp: [], tu: [] });
  assertEquals(later.trips, []);
});

Deno.test("a trip that vanishes near its end is completed, not suppressed", () => {
  const r = run({ trips: [state({ lastSeq: 20 })], vp: [], tu: [] });
  assertEquals(r.trips, []);
});

Deno.test("S3: standing still for more than 5 minutes along the route", () => {
  const r = run({ vehicles: [vehicle({ stillSince: NOW - 8 * 60 })], vp: [pos({ lat: 41.90005 })], tu: [pred()] });
  assertEquals(r.trips[0].status, "uncertain");
  assertEquals(r.trips[0].signal, { code: "S3", min: 8 });
});

Deno.test("moving more than 30 m resets the standing-still clock", () => {
  const r = run({ vehicles: [vehicle({ stillSince: NOW - 8 * 60 })], vp: [pos({ lat: 41.901 })], tu: [pred()] });
  assertEquals(r.trips[0].status, "confirmed");
  assertEquals(r.vehicles[0].stillSince, NOW - 30);
});

Deno.test("S5: at the first stop, not left yet", () => {
  const r = run({ vp: [pos({ seq: 1 })], tu: [pred({ seq: [1, 2], ts: [NOW + 300, NOW + 400] })] });
  assertEquals(r.trips[0].signal, { code: "S5", at: NOW + 300 });
});

Deno.test("S5 becomes S3 when the departure time has passed (SC-09a)", () => {
  const r = run({
    vehicles: [vehicle({ seq: 1, stillSince: NOW - 10 * 60 })],
    vp: [pos({ seq: 1 })],
    tu: [pred({ seq: [1, 2], ts: [NOW - 4 * 60, NOW + 60] })],
  });
  assertEquals(r.trips[0].signal, { code: "S3", min: 4 });
});

Deno.test("unchanged feeds carry the previous state on (RF-26: vehicle without prediction stays confirmed)", () => {
  const r = run({ vehicles: [vehicle()], trips: [state({ predSeq: [], predTs: [] })] });
  assertEquals(r.trips[0].status, "confirmed");
  assertEquals(r.trips[0].predSeq, []);
});

Deno.test("trips outside the static network are ignored", () => {
  const r = run({ vp: [pos({ tripId: "METRO" })], tu: [pred({ tripId: "METRO" })] });
  assertEquals(r.trips, []);
  assertEquals(r.vehicles, []);
});
