// The engine: a pure function, no I/O. The poller runs it at every cycle; tests and replays run it on snapshots.
// It computes the signals that need history (S1, S2, S3, S5, suppressed trips); the API adds S4 and S6.
import type {
  CycleState,
  EngineResult,
  Signal,
  Thresholds,
  TripInfo,
  TripPrediction,
  TripState,
  Vehicle,
  VehiclePosition,
} from "./types.ts";

export interface EngineInput {
  prev: Pick<CycleState, "vehicles" | "trips">;
  /** Present only when the feed changed; otherwise the previous state carries on. */
  vp?: VehiclePosition[];
  tu?: TripPrediction[];
  tripInfo: Map<string, TripInfo>;
  thresholds: Thresholds;
  now: number;
}

export function evaluate({ prev, vp, tu, tripInfo, thresholds, now }: EngineInput): EngineResult {
  const valid = (v: { gpsAt: number }) => now - v.gpsAt <= thresholds.s2_min * 60;

  const vehicles = vp
    ? vp.map((p) => updateVehicle(p, prev.vehicles.get(p.vehicleId), thresholds))
    : [...prev.vehicles.values()];
  const lastGps = new Map<string, number>(); // also from vehicles no longer valid: "not transmitting for N min"
  const byTrip = new Map<string, Vehicle>();
  for (const v of vehicles) {
    lastGps.set(v.tripId, Math.max(v.gpsAt, lastGps.get(v.tripId) ?? 0));
    const other = byTrip.get(v.tripId);
    if (valid(v) && (!other || other.gpsAt < v.gpsAt)) byTrip.set(v.tripId, v); // two on a trip: the freshest wins
  }

  const predictions = new Map<string, TripPrediction>();
  if (tu) {
    for (const p of tu) predictions.set(p.tripId, p);
  } else {
    for (const t of prev.trips.values()) {
      if (t.status !== "suppressed" && (t.predSeq.length > 0 || t.status === "canceled")) {
        predictions.set(t.tripId, {
          tripId: t.tripId,
          canceled: t.status === "canceled",
          seq: t.predSeq,
          ts: t.predTs,
        });
      }
    }
  }

  const trips: TripState[] = [];
  for (const tripId of new Set([...predictions.keys(), ...byTrip.keys(), ...prev.trips.keys()])) {
    const info = tripInfo.get(tripId);
    if (!info) continue; // not in the static network (metro, rail, unknown): ignored
    const t = evaluateTrip(
      tripId,
      info,
      predictions.get(tripId),
      byTrip.get(tripId),
      lastGps.get(tripId),
      prev.trips.get(tripId),
      thresholds,
      now,
    );
    if (t) trips.push(t);
  }

  return {
    vehicles: vehicles.filter((v) => valid(v) && tripInfo.has(v.tripId)),
    trips,
    seenRoutes: [...new Set([...byTrip.values()].map((v) => tripInfo.get(v.tripId)?.routeId).filter((r) => r != null))],
  };
}

function updateVehicle(p: VehiclePosition, old: Vehicle | undefined, thresholds: Thresholds): Vehicle {
  const still = old && old.tripId === p.tripId &&
    distance(old.stillLat, old.stillLon, p.lat, p.lon) < thresholds.s3_meters;
  return still
    ? { ...p, stillLat: old.stillLat, stillLon: old.stillLon, stillSince: old.stillSince }
    : { ...p, stillLat: p.lat, stillLon: p.lon, stillSince: p.gpsAt };
}

function evaluateTrip(
  tripId: string,
  info: TripInfo,
  p: TripPrediction | undefined,
  v: Vehicle | undefined,
  lastGps: number | undefined,
  old: TripState | undefined,
  thresholds: Thresholds,
  now: number,
): TripState | null {
  const lastSeq = maxOrNull(old?.lastSeq, v?.seq);
  const base = {
    tripId,
    routeId: info.routeId,
    vehicleId: v?.vehicleId ?? old?.vehicleId ?? null,
    predSeq: p?.seq ?? [],
    predTs: p?.ts ?? [],
    lastSeq,
    seenAt: maxOrNull(old?.seenAt, lastGps),
    suppressedAt: null,
  };

  if (p?.canceled) return { ...base, status: "canceled", signal: { code: "S1" } };

  if (v) {
    const signal = vehicleSignal(v, info, p, thresholds, now);
    return { ...base, status: signal ? "uncertain" : "confirmed", signal };
  }

  // No valid vehicle from here on.
  if (old?.status === "suppressed") {
    return old.suppressedAt! + thresholds.suppressed_min * 60 >= now ? old : null; // RF-29: visible for 5 minutes
  }
  const completed = lastSeq != null &&
    lastSeq - info.firstSeq >= thresholds.completed_ratio * (info.lastSeq - info.firstSeq);
  const s2: Signal = base.seenAt == null ? { code: "S2" } : { code: "S2", min: Math.floor((now - base.seenAt) / 60) };

  if (p) return { ...base, status: "uncertain", signal: s2 }; // prediction without a vehicle
  if (base.vehicleId && !completed) {
    // The vehicle vanished before the end and its predictions with it (measured: always together).
    return { ...base, status: "suppressed", signal: s2, predSeq: old!.predSeq, predTs: old!.predTs, suppressedAt: now };
  }
  return null; // completed, or never seen: nothing to say
}

/** S3 (standing still along the route) or S5 (at the first stop, not left yet). */
function vehicleSignal(
  v: Vehicle,
  info: TripInfo,
  p: TripPrediction | undefined,
  thresholds: Thresholds,
  now: number,
): Signal | null {
  const stillMin = Math.floor((now - v.stillSince) / 60);
  if (v.seq === info.firstSeq) {
    const i = p?.seq.indexOf(info.firstSeq) ?? -1;
    const departure = i >= 0 ? p!.ts[i] : undefined;
    // SC-09a: past its departure time and still there, it becomes "standing still".
    if (departure != null && now - departure >= 60 && stillMin >= 1) {
      return { code: "S3", min: Math.floor((now - Math.max(departure, v.stillSince)) / 60) };
    }
    return departure == null ? { code: "S5" } : { code: "S5", at: departure };
  }
  return stillMin >= thresholds.s3_min ? { code: "S3", min: stillMin } : null;
}

/** Metres between two points (equirectangular: plenty for a few hundred metres). */
export function distance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const rad = Math.PI / 180;
  const x = (lon2 - lon1) * rad * Math.cos(((lat1 + lat2) / 2) * rad);
  const y = (lat2 - lat1) * rad;
  return Math.sqrt(x * x + y * y) * 6371000;
}

function maxOrNull(a: number | null | undefined, b: number | null | undefined): number | null {
  if (a == null) return b ?? null;
  if (b == null) return a;
  return Math.max(a, b);
}
