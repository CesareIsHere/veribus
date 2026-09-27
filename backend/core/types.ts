// Types shared by the core. Times are epoch seconds.

export type Feed = "vp" | "tu" | "sa";
export const FEEDS: Feed[] = ["vp", "tu", "sa"];

/** What we know about the last accepted snapshot of a feed. */
export interface FeedMarker {
  lastModified: string | null;
  hash: string | null;
  feedTs: number | null;
}

/** A vehicle from Vehicle Positions. */
export interface VehiclePosition {
  vehicleId: string;
  label: string | null;
  tripId: string;
  routeId: string | null;
  lat: number;
  lon: number;
  gpsAt: number;
  seq: number | null;
  stopId: string | null;
}

/** A trip from Trip Updates: predictions as parallel arrays (stop_sequence, time). */
export interface TripPrediction {
  tripId: string;
  canceled: boolean;
  seq: number[];
  ts: number[];
}

/** A service alert, severity mapped from `effect` like Roma mobile (RF-52). */
export interface Alert {
  id: string;
  severity: 0 | 1 | 2;
  periods: [number | null, number | null][];
  title: string | null;
  body: string | null;
  routeIds: string[];
  stopIds: string[];
  general: boolean;
}

/** Vehicle state kept between cycles: `still*` is where and since when it stands still (S3). */
export interface Vehicle extends VehiclePosition {
  stillLat: number;
  stillLon: number;
  stillSince: number;
}

export type TripStatus = "confirmed" | "uncertain" | "canceled" | "suppressed";

export interface Signal {
  code: "S1" | "S2" | "S3" | "S5";
  min?: number;
  at?: number;
}

/** Trip state kept between cycles. No row means "scheduled". */
export interface TripState {
  tripId: string;
  routeId: string;
  vehicleId: string | null;
  status: TripStatus;
  signal: Signal | null;
  predSeq: number[];
  predTs: number[];
  lastSeq: number | null;
  seenAt: number | null;
  suppressedAt: number | null;
}

/** Static data of a trip, from `network.trip`. */
export interface TripInfo {
  routeId: string;
  firstSeq: number;
  lastSeq: number;
}

/** Thresholds from `config.setting` (RNF-06). */
export interface Thresholds {
  s2_min: number;
  s3_meters: number;
  s3_min: number;
  suppressed_min: number;
  completed_ratio: number;
}

export interface CycleState {
  markers: Record<Feed, FeedMarker>;
  vehicles: Map<string, Vehicle>;
  trips: Map<string, TripState>;
}

export interface EngineResult {
  vehicles: Vehicle[];
  trips: TripState[];
  /** Routes with at least one tracked vehicle (RF-35). */
  seenRoutes: string[];
}

export interface Snapshot {
  feed: Feed;
  feedTs: number | null;
  hash: string;
  bytes: number;
  outcome: "ok" | "error" | "stale";
  path: string | null;
}
