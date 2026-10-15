// StateStore on Postgres. The state between cycles always lives in the database: it is both the
// poller's output and the handover between runtimes (edge function today, container tomorrow).
import postgres from "npm:postgres@3.4.7";
import type { Commit, PendingState, StateStore, TripInfoCache } from "../core/cycle.ts";
import type { Claim, NotifyStore } from "../core/notify.ts";
import type { CycleState, Feed, FeedMarker, Thresholds, TripInfo, TripState, Vehicle } from "../core/types.ts";

const iso = (s: number | null) => (s == null ? null : new Date(s * 1000).toISOString());
const epoch = (d: Date | null) => (d == null ? null : Math.floor(d.getTime() / 1000));

// deno-lint-ignore no-explicit-any
type Row = Record<string, any>;

/** `{1,2,3}`, how Postgres writes an integer array in text format, as numbers. */
export const numberArray = (text: string | null): number[] =>
  text == null || text === "{}" ? [] : text.slice(1, -1).split(",").map(Number);

const markersOf = (feeds: Row[]) =>
  Object.fromEntries(
    feeds.map((f: Row) => [f.feed, { lastModified: f.last_modified, hash: f.hash, feedTs: epoch(f.feed_ts) }]),
  ) as Record<Feed, FeedMarker>;

export function postgresStore(
  url: string,
  opts: { tripInfoCache?: TripInfoCache } = {},
): StateStore & {
  notify: NotifyStore;
  peek(): Promise<Pick<PendingState, "markers" | "counts">>;
  close(): Promise<void>;
} {
  // Session pooler (5432), not the transaction one (6543): postgres.js pipelines concurrent queries on one connection,
  // and the transaction pooler can route the pieces to different backends ("bind message supplies 3 parameters").
  // fetch_types off: on every new connection postgres.js reads the catalog of array types (~9 KB here, more with
  // extensions), and the edge function opens a connection per call, 8,640 a day: that alone was the whole egress
  // budget of the free plan. Without it arrays are not converted, so the array columns are read as text
  // (`textArray`) and arrays go in as JSON (`jsonb_array_elements_text`).
  const sql = postgres(url, { prepare: false, max: 2, idle_timeout: 20, fetch_types: false });
  // Trips of the active network, by trip id: they do not change until the next import, and reading them for every
  // trip of every cycle was a good part of what the poller read after the vehicles and trips. With a cache (R2: the
  // edge function's workers do not outlive a call) a worker starts with what the last one knew.
  const tripInfo = new Map<string, TripInfo>();
  let tripInfoVersion: string | null = null;
  let tripInfoStored = 0;

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

    /** The markers and the row counts: all a cycle needs to know that nothing changed (see keepState). */
    async peek() {
      const [feeds, [counts]] = await Promise.all([
        sql`select * from live.feed_status`,
        sql`select (select count(*) from live.vehicle)::int as vehicles, (select count(*) from live.trip_state)::int as trips`,
      ]);
      return { markers: markersOf(feeds), counts: { vehicles: counts.vehicles, trips: counts.trips } };
    },

    async loadState() {
      const [feeds, vehicles, trips] = await Promise.all([
        sql`select * from live.feed_status`,
        sql`select * from live.vehicle`,
        sql`select * from live.trip_state`,
      ]);
      return {
        markers: markersOf(feeds),
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
          predSeq: numberArray(t.pred_seq),
          predTs: numberArray(t.pred_ts),
          lastSeq: t.last_seq,
          seenAt: epoch(t.seen_at),
          suppressedAt: epoch(t.suppressed_at),
        }])),
      } satisfies CycleState;
    },

    async loadTripInfo(tripIds) {
      // A new import replaces every trip: what was remembered is no longer true.
      const [version] = await sql`select md5 from network_meta.version order by imported_at desc limit 1`;
      const current: string | null = version?.md5 ?? null;
      if (current !== tripInfoVersion) {
        tripInfo.clear();
        tripInfoVersion = current;
        tripInfoStored = 0;
        if (current && opts.tripInfoCache) {
          try {
            for (const [id, info] of Object.entries(await opts.tripInfoCache.get(current) ?? {})) {
              tripInfo.set(id, info);
            }
            tripInfoStored = tripInfo.size;
          } catch (e) {
            console.error(`trip info cache not read, using the database: ${e}`);
          }
        }
      }
      const missing = tripIds.filter((id) => !tripInfo.has(id));
      if (missing.length > 0) {
        const rows = await sql`
          select trip_id, route_id, first_seq, last_seq from network.trip
          where trip_id = any(array(select jsonb_array_elements_text(${sql.json(missing)})))`;
        for (const r of rows as Row[]) {
          tripInfo.set(r.trip_id, { routeId: r.route_id, firstSeq: r.first_seq, lastSeq: r.last_seq });
        }
      }
      if (current && opts.tripInfoCache && tripInfo.size > tripInfoStored) {
        try {
          await opts.tripInfoCache.put(current, Object.fromEntries(tripInfo));
          tripInfoStored = tripInfo.size;
        } catch (e) {
          console.error(`trip info cache not written: ${e}`);
        }
      }
      return new Map(tripIds.flatMap((id): [string, TripInfo][] => tripInfo.has(id) ? [[id, tripInfo.get(id)!]] : []));
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
          // Before the replace: it compares the new stop sequences with the previous ones.
          await tx.unsafe("select history.record($1::text::jsonb)", [JSON.stringify(trips)]);
          await replace("live.trip_state", trips);
          await tx`insert into network_meta.route_seen (route_id, date)
                   select jsonb_array_elements_text(${
            tx.json(c.result.seenRoutes)
          }), (now() at time zone 'Europe/Rome')::date
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

    notify: {
      async claim() {
        const [{ claims }] = await sql`select notify.claim() as claims`;
        return (claims as Row[]).map((c): Claim => ({
          followId: c.follow_id,
          serviceDate: c.service_date,
          event: c.event,
          kinds: c.kinds,
          minutes: c.minutes,
          eta: Number(c.eta),
          scheduled: Number(c.scheduled),
          realtime: c.realtime,
          route: c.route ?? "",
          stop: c.stop ?? "",
          headsign: c.headsign ?? "",
          devices: c.tokens ?? [],
        }));
      },

      async release(claims) {
        const keys = claims.map((c) => ({ follow_id: c.followId, service_date: c.serviceDate, kinds: c.kinds }));
        await sql`select notify.release(${sql.json(keys)}::jsonb)`;
      },

      async dropTokens(tokens) {
        await sql`select notify.drop_tokens(array(select jsonb_array_elements_text(${sql.json(tokens)})))`;
      },
    },

    close: () => sql.end(),
  };
}
