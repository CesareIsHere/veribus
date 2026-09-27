// GTFS-Realtime protobuf -> plain core types.
import GtfsRealtimeBindings from "npm:gtfs-realtime-bindings@1.1.1";
import type { Alert, TripPrediction, VehiclePosition } from "./types.ts";

const { FeedMessage, Alert: PbAlert } = GtfsRealtimeBindings.transit_realtime;

// protobufjs gives uint64 as Long objects: Number() goes through their toString.
const num = (x: unknown): number | null => (x == null ? null : Number(x));

export interface Decoded {
  ts: number;
  vehicles: VehiclePosition[];
  trips: TripPrediction[];
  alerts: Alert[];
}

type Translated = { translation?: { text?: string | null; language?: string | null }[] | null } | null | undefined;
const italian = (s: Translated) =>
  (s?.translation?.find((x) => x.language === "it") ?? s?.translation?.[0])?.text ?? null;

export function decode(body: Uint8Array): Decoded {
  const msg = FeedMessage.decode(body);
  const ts = num(msg.header.timestamp) ?? 0;
  const vehicles: VehiclePosition[] = [];
  // Trip Updates carries a few duplicated trip_ids per snapshot (measured, identical): the last one wins.
  const trips = new Map<string, TripPrediction>();
  const alerts: Alert[] = [];

  for (const e of msg.entity) {
    const v = e.vehicle;
    if (v?.trip?.tripId && v.position && (v.vehicle?.id || v.vehicle?.label)) {
      vehicles.push({
        vehicleId: String(v.vehicle.id ?? v.vehicle.label),
        label: v.vehicle.label ?? null,
        tripId: v.trip.tripId,
        routeId: v.trip.routeId ?? null,
        lat: v.position.latitude,
        lon: v.position.longitude,
        gpsAt: num(v.timestamp) ?? ts,
        seq: v.currentStopSequence ?? null,
        stopId: v.stopId ?? null,
      });
    }

    const t = e.tripUpdate;
    if (t?.trip?.tripId) {
      const seq: number[] = [];
      const times: number[] = [];
      for (const u of t.stopTimeUpdate ?? []) {
        const time = num(u.arrival?.time) ?? num(u.departure?.time);
        if (u.stopSequence != null && time != null && u.scheduleRelationship !== 1 /* SKIPPED */) {
          seq.push(u.stopSequence);
          times.push(time);
        }
      }
      trips.set(t.trip.tripId, { tripId: t.trip.tripId, canceled: t.trip.scheduleRelationship === 3, seq, ts: times });
    }

    const a = e.alert;
    if (a && !e.isDeleted) {
      const entities = a.informedEntity ?? [];
      alerts.push({
        id: e.id,
        severity: severity(a.effect ?? PbAlert.Effect.UNKNOWN_EFFECT),
        periods: (a.activePeriod ?? []).map((p) => [num(p.start) || null, num(p.end) || null]),
        title: italian(a.headerText),
        body: italian(a.descriptionText),
        routeIds: [...new Set(entities.map((x) => x.routeId).filter((x): x is string => !!x))],
        stopIds: [...new Set(entities.map((x) => x.stopId).filter((x): x is string => !!x))],
        general: entities.some((x) => !x.routeId && !x.stopId && !x.trip && x.routeType == null),
      });
    }
  }
  return { ts, vehicles, trips: [...trips.values()], alerts };
}

/** 2 interruption, 1 reduced service, 0 informative (RF-52, as in Roma mobile). */
function severity(effect: number): 0 | 1 | 2 {
  const E = PbAlert.Effect;
  if (effect === E.NO_SERVICE) return 2;
  if ([E.REDUCED_SERVICE, E.SIGNIFICANT_DELAYS, E.MODIFIED_SERVICE, E.OTHER_EFFECT].includes(effect)) return 1;
  return 0;
}
