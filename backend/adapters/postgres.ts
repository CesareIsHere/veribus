// StateStore on Postgres. The state between cycles always lives in the database: it is both the
// poller's output and the handover between runtimes (edge function today, container tomorrow).
import postgres from "npm:postgres@3.4.7";
import type { Commit, StateStore } from "../core/cycle.ts";
import type { CycleState, Feed, FeedMarker, Thresholds, TripInfo, TripState, Vehicle } from "../core/types.ts";

const iso = (s: number | null) => (s == null ? null : new Date(s * 1000).toISOString());
const epoch = (d: Date | null) => (d == null ? null : Math.floor(d.getTime() / 1000));

// deno-lint-ignore no-explicit-any
type Row = Record<string, any>;

export function postgresStore(url: string): StateStore & { close(): Promise<void> } {
  // prepare: false for the transaction pooler.
  const sql = postgres(url, { prepare: false, max: 2, idle_timeout: 20 });

  return {
    async tryAcquireLease(owner, seconds) {
      const rows = await sql`
        update live.lease set owner = ${owner}, expires_at = now() + ${seconds} * interval '1 second'
        where name = 'poller' and (expires_at < now() or owner = ${owner}) returning name`;
      return rows.length > 0;
    },

    async releaseLease(owner) {
      await sql`update live.lease set expires_at = '-infinity' where name = 'poller' and owner = ${owner}`;
    },

    async loadState() {
      const [feeds, vehicles, trips] = await Promise.all([
        sql`select * from live.feed_status`,
        sql`select * from live.vehicle`,
        sql`select * from live.trip_state`,
      ]);
      return {
        markers: Object.fromEntries(
          feeds.map((f: Row) => [f.feed, { lastModified: f.last_modified, hash: f.hash, feedTs: epoch(f.feed_ts) }]),
        ) as Record<Feed, FeedMarker>,
        vehicles: new Map(vehicles.map((v: Row): [string, Vehicle] => [v.vehicle_id, {
          vehicleId: v.vehicle_id,
          label: v.label,
          tripId: v.trip_id,
          routeId: v.route_id,
          lat: v.lat,
          lon: v.lon,
          gpsAt: epoch(v.gps_at)!,
          seq: v.seq,
          stopId: v.stop_id,
          stillLat: v.still_lat,
          stillLon: v.still_lon,
          stillSince: epoch(v.still_since)!,
        }])),
        trips: new Map(trips.map((t: Row): [string, TripState] => [t.trip_id, {
          tripId: t.trip_id,
          routeId: t.route_id,
          vehicleId: t.vehicle_id,
          status: t.status,
          signal: t.signal,
          predSeq: t.pred_seq,
          predTs: t.pred_ts.map(Number),
          lastSeq: t.last_seq,
          seenAt: epoch(t.seen_at),
          suppressedAt: epoch(t.suppressed_at),
        }])),
      } satisfies CycleState;
    },

    async loadTripInfo(tripIds) {
      const rows = await sql`
        select trip_id, route_id, first_seq, last_seq from network.trip where trip_id = any(${tripIds})`;
      return new Map(rows.map((r: Row): [string, TripInfo] => [r.trip_id, {
        routeId: r.route_id,
        firstSeq: r.first_seq,
        lastSeq: r.last_seq,
      }]));
    },

    async loadThresholds() {
      const rows = await sql`select key, value from config.setting`;
      return Object.fromEntries(rows.map((r: Row) => [r.key, r.value])) as Thresholds;
    },

    async commit(c: Commit) {
      // Whole-table replace in one transaction: ~1.300 rows each, idempotent and simple.
      await sql.begin(async (tx) => {
        // `table` is always one of our constants, never input.
        const replace = async (table: string, rows: unknown[]) => {
          await tx.unsafe(`delete from ${table}`);
          await tx.unsafe(
            `insert into ${table} select * from jsonb_populate_recordset(null::${table}, $1::text::jsonb)`,
            [
              JSON.stringify(rows),
            ],
          );
        };
        for (const [feed, m] of Object.entries(c.markers)) {
          const error = c.errors.find((e) => e.feed === feed)?.error ?? null;
          await tx`
            update live.feed_status set last_modified = ${m.lastModified}, hash = ${m.hash}, feed_ts = ${iso(m.feedTs)},
              ok_at = case when ${error}::text is null then now() else ok_at end,
              error = coalesce(${error}, error),
              error_at = case when ${error}::text is null then error_at else now() end
            where feed = ${feed}`;
        }
        for (const s of c.snapshots) {
          await tx`insert into live.snapshot (feed, feed_ts, hash, bytes, outcome, path)
                   values (${s.feed}, ${iso(s.feedTs)}, ${s.hash}, ${s.bytes}, ${s.outcome}, ${s.path})`;
        }
        if (c.result) {
          const vehicles = c.result.vehicles.map((v) => ({
            vehicle_id: v.vehicleId,
            label: v.label,
            trip_id: v.tripId,
            route_id: v.routeId,
            lat: v.lat,
            lon: v.lon,
            gps_at: iso(v.gpsAt),
            seq: v.seq,
            stop_id: v.stopId,
            still_lat: v.stillLat,
            still_lon: v.stillLon,
            still_since: iso(v.stillSince),
          }));
          const trips = c.result.trips.map((t) => ({
            trip_id: t.tripId,
            route_id: t.routeId,
            vehicle_id: t.vehicleId,
            status: t.status,
            signal: t.signal,
            pred_seq: t.predSeq,
            pred_ts: t.predTs,
            last_seq: t.lastSeq,
            seen_at: iso(t.seenAt),
            suppressed_at: iso(t.suppressedAt),
          }));
          await replace("live.vehicle", vehicles);
          await replace("live.trip_state", trips);
          await tx`insert into network_meta.route_seen (route_id, date)
                   select unnest(${c.result.seenRoutes}::text[]), (now() at time zone 'Europe/Rome')::date
                   on conflict do nothing`;
        }
        if (c.alerts) {
          const alerts = c.alerts.map((a) => ({
            alert_id: a.id,
            severity: a.severity,
            periods: a.periods,
            title: a.title,
            body: a.body,
            route_ids: a.routeIds,
            stop_ids: a.stopIds,
            general: a.general,
          }));
          await replace("live.alert", alerts);
        }
      });
    },

    close: () => sql.end(),
  };
}
