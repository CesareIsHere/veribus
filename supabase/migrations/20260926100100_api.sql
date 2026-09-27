-- API for the app: PL/pgSQL functions in schema `api`, called as PostgREST RPC by signed-in users.
-- PL/pgSQL (not BEGIN ATOMIC) so that names resolve at call time and follow the `network` swap.
-- Signals that depend on the reading instant are computed here (S4, S6, RF-60, RF-29b);
-- the ones that need history come from the poller (S1, S2, S3, S5). Priority: S1 S2 S3 S4 S6 S5.

create schema api;
grant usage on schema api to authenticated;

-- Private helpers (not executable by clients) ------------------------------------------------------

create function api._active(periods jsonb, at timestamptz) returns boolean
language sql immutable set search_path = '' as $$
  select jsonb_array_length(periods) = 0 or exists (
    select from jsonb_array_elements(periods) p
    where coalesce((p->>0)::bigint, 0) <= extract(epoch from at)
      and coalesce((p->>1)::bigint, 9999999999) >= extract(epoch from at)
  )
$$;

create function api._alert(a live.alert) returns jsonb
language sql immutable set search_path = '' as $$
  select jsonb_build_object('id', a.alert_id, 'severity', a.severity, 'title', a.title, 'body', a.body,
    'route_ids', a.route_ids, 'stop_ids', a.stop_ids, 'general', a.general)
$$;

-- Age of the realtime data: ok, late (S6) or stale (RF-60: everything becomes scheduled).
create function api._feed(at timestamptz) returns jsonb
language plpgsql stable set search_path = '' as $$
declare
  age int := extract(epoch from at - (select min(feed_ts) from live.feed_status where feed in ('vp', 'tu')))::int;
begin
  return jsonb_build_object('age_s', age, 'status', case
    when age is null or age > config.get('rf60_min')::int * 60 then 'stale'
    when age > config.get('s6_min')::int * 60 then 'late'
    else 'ok' end);
end $$;

-- Minutes beyond which a prediction is shown as approximate (RF-29b), by time band.
create function api._approx_minutes(at timestamptz) returns int
language sql stable set search_path = '' as $$
  select case when exists (
    select from jsonb_array_elements(config.get('peak_hours')) h
    where (at at time zone 'Europe/Rome')::time between (h->>0)::time and (h->>1)::time
  ) then (config.get('approx_min')->>'peak')::int else (config.get('approx_min')->>'off_peak')::int end
$$;

-- Final signal of a trip: the poller's (S2, S3, S5) combined with S4 and S6, by priority.
create function api._signal(poller jsonb, gps_at timestamptz, feed jsonb, at timestamptz) returns jsonb
language sql stable set search_path = '' as $$
  select case
    when poller->>'code' in ('S1', 'S2', 'S3') then poller
    when gps_at < at - config.get('s4_min')::int * interval '1 minute'
      then jsonb_build_object('code', 'S4', 'min', floor(extract(epoch from at - gps_at) / 60)::int)
    when feed->>'status' = 'late' then jsonb_build_object('code', 'S6')
    else poller end
$$;

-- Public functions ---------------------------------------------------------------------------------

-- Network version and remote config (RNF-08, RF-35). The app downloads `path` from the `network`
-- Storage bucket when `version` differs from the one it has.
create function api.network() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  md5 text := (select v.md5 from network_meta.version v order by imported_at desc limit 1);
  days int := config.get('no_realtime_days')::int;
  today date := (now() at time zone 'Europe/Rome')::date;
begin
  return jsonb_build_object(
    'version', md5,
    'path', 'v' || md5 || '.json',
    'min_app_version', config.get('min_app_version'),
    'tile_url', config.get('tile_url'),
    -- Routes never tracked in the last N days, once the poller has been observing that long.
    'no_realtime', case when (select min(date) from network_meta.route_seen) <= today - days then coalesce((
      select jsonb_agg(r.route_id order by r.route_id) from network.route r
      where not exists (select from network_meta.route_seen s where s.route_id = r.route_id and s.date > today - days)
    ), '[]') else '[]' end
  );
end $$;

-- Arrivals at one or more stops in the next 60 minutes, plus vehicles in service for `route_ids`
-- (favorites, nearby list). Response shape: README, "API".
create function api.arrivals(stop_ids text[], route_ids text[] default '{}') returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  at timestamptz := now();
  today date := (at at time zone 'Europe/Rome')::date;
  now_s int := extract(epoch from (at at time zone 'Europe/Rome') - today::timestamp)::int;
  feed jsonb := api._feed(at);
  valid interval := config.get('s2_min')::int * interval '1 minute';
  suppressed_for interval := config.get('suppressed_min')::int * interval '1 minute';
  approx int := api._approx_minutes(at);
begin
  return (
    with candidate as (
      -- ponytail: service-day times are counted from midnight, so on the two DST days they are off by 1h.
      select st.stop_id, st.seq, t.trip_id, t.route_id, t.direction_id, t.headsign,
             (d.date + st.departure_s * interval '1 second') at time zone 'Europe/Rome' as scheduled
      from (values (today), (today - 1)) d (date)
      join network.stop_time st on st.stop_id = any(arrivals.stop_ids)
        and st.departure_s between now_s + (today - d.date) * 86400 - 1800 and now_s + (today - d.date) * 86400 + 3600
      join network.trip t on t.trip_id = st.trip_id and st.seq < t.last_seq  -- nobody boards at the terminus
      join network.service_day sd on sd.service_id = t.service_id and sd.date = d.date
    ), joined as (
      select c.*, ts.trip_id is not null as has_rt, ts.status as rt_status, ts.signal as rt_signal, ts.suppressed_at,
             to_timestamp(ts.pred_ts[array_position(ts.pred_seq, c.seq)]) as predicted,
             v.vehicle_id, v.label, v.lat, v.lon, v.gps_at, v.seq as v_seq
      from candidate c
      left join live.trip_state ts on ts.trip_id = c.trip_id
      left join live.vehicle v on v.vehicle_id = ts.vehicle_id and v.trip_id = ts.trip_id and v.gps_at > at - valid
    ), rated as (
      select j.*,
        case
          when feed->>'status' = 'stale' or not has_rt then 'scheduled'
          when rt_status in ('canceled', 'suppressed') then rt_status
          when predicted is null and vehicle_id is null then 'scheduled'
          when api._signal(rt_signal, gps_at, feed, at) is null then 'confirmed'
          else 'uncertain'
        end as status
      from joined j
      where v_seq is null or v_seq <= j.seq  -- the vehicle has not passed the stop yet
    ), timed as (
      select r.*,
        case when status in ('confirmed', 'uncertain') then predicted end as rt_time,
        coalesce(case when status in ('confirmed', 'uncertain', 'suppressed') then predicted end, scheduled) as sort_time
      from rated r
    ), kept as (
      select t.*, row_number() over (
          partition by stop_id, route_id, direction_id, status in ('suppressed', 'canceled') order by sort_time) as n
      from timed t
      where sort_time <= at + interval '60 minutes'
        and case status
          when 'suppressed' then suppressed_at > at - suppressed_for
          when 'scheduled' then scheduled >= at
          else sort_time >= at - interval '1 minute' end
    )
    select jsonb_build_object(
      'computed_at', at,
      'feed', feed,
      'stops', coalesce((
        select jsonb_agg(jsonb_build_object(
          'stop_id', s.stop_id,
          'alerts', coalesce((
            select jsonb_agg(al.alert_id) from live.alert al
            where api._active(al.periods, at) and (al.general or s.stop_id = any(al.stop_ids) or al.route_ids && (
              select array_agg(distinct t.route_id) from network.stop_time st join network.trip t using (trip_id)
              where st.stop_id = s.stop_id))
          ), '[]'),
          'arrivals', coalesce((
            select jsonb_agg(jsonb_build_object(
              'trip_id', k.trip_id, 'route_id', k.route_id, 'direction_id', k.direction_id, 'headsign', k.headsign,
              'status', k.status,
              -- A confirmed trip with a vehicle but no prediction shows "N stops away", never a time (RF-26).
              'time', case when k.status in ('confirmed', 'uncertain') then k.rt_time else k.sort_time end,
              'minutes', case when k.rt_time is not null then greatest(0, floor(extract(epoch from k.rt_time - at) / 60))::int end,
              'approximate', k.rt_time is not null and k.rt_time > at + approx * interval '1 minute',
              'signal', case k.status when 'canceled' then '{"code": "S1"}'::jsonb
                                      when 'suppressed' then k.rt_signal
                                      when 'uncertain' then api._signal(k.rt_signal, k.gps_at, feed, at) end,
              'stops_away', case when k.vehicle_id is not null then k.seq - k.v_seq end,
              'vehicle', case when k.vehicle_id is not null and k.status <> 'scheduled' then jsonb_build_object(
                'id', k.vehicle_id, 'label', k.label, 'lat', k.lat, 'lon', k.lon, 'gps_at', k.gps_at) end
            ) order by k.sort_time)
            from kept k where k.stop_id = s.stop_id and (k.n <= 3 or k.status in ('suppressed', 'canceled'))
          ), '[]')
        ))
        from unnest(arrivals.stop_ids) s (stop_id)
      ), '[]'),
      'alerts', coalesce((
        select jsonb_agg(api._alert(al)) from live.alert al
        where api._active(al.periods, at) and (al.general or al.stop_ids && arrivals.stop_ids or al.route_ids && (
          select array_agg(distinct t.route_id) from network.stop_time st join network.trip t using (trip_id)
          where st.stop_id = any(arrivals.stop_ids)))
      ), '[]'),
      'routes', coalesce((
        select jsonb_agg(jsonb_build_object('route_id', r.route_id, 'vehicles_in_service',
          (select count(*) from live.vehicle v where v.route_id = r.route_id and v.gps_at > at - valid)))
        from unnest(arrivals.route_ids) r (route_id)
      ), '[]')
    )
  );
end $$;

-- Route detail (RF-30..34): main path of a direction, vehicles on it, alerts, next departure if idle.
create function api.route(route_id text, direction_id int) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  at timestamptz := now();
  today date := (at at time zone 'Europe/Rome')::date;
  now_s int := extract(epoch from (at at time zone 'Europe/Rome') - today::timestamp)::int;
  feed jsonb := api._feed(at);
  valid interval := config.get('s2_min')::int * interval '1 minute';
  p record;  -- not network.route_path: that type is dropped and recreated at every swap
  vehicles jsonb;
begin
  select * into p from network.route_path rp where rp.route_id = route.route_id and rp.direction_id = route.direction_id;
  if p is null then return null; end if;

  select coalesce(jsonb_agg(jsonb_build_object(
      'id', v.vehicle_id, 'label', v.label, 'lat', v.lat, 'lon', v.lon, 'gps_at', v.gps_at,
      'index', array_position(p.stop_ids, v.stop_id) - 1,
      'signal', api._signal(case when ts.signal->>'code' = 'S3' then ts.signal end, v.gps_at, feed, at)
    ) order by array_position(p.stop_ids, v.stop_id)), '[]')
  into vehicles
  from live.vehicle v
  join network.trip t on t.trip_id = v.trip_id and t.direction_id = route.direction_id
  left join live.trip_state ts on ts.trip_id = v.trip_id
  where v.route_id = route.route_id and v.gps_at > at - valid and feed->>'status' <> 'stale';

  return jsonb_build_object(
    'route_id', p.route_id, 'direction_id', p.direction_id, 'headsign', p.headsign,
    'stops', to_jsonb(p.stop_ids), 'shape', p.shape, 'vehicles', vehicles, 'feed', feed,
    'alerts', coalesce((select jsonb_agg(api._alert(al)) from live.alert al
                        where api._active(al.periods, at) and (al.general or route.route_id = any(al.route_ids))), '[]'),
    -- RF-34: with nobody in service, the next scheduled departure from the first stop.
    'next_departure', case when jsonb_array_length(vehicles) = 0 then (
      select min((d.date + st.departure_s * interval '1 second') at time zone 'Europe/Rome')
      from (values (today), (today + 1)) d (date)
      join network.service_day sd on sd.date = d.date
      join network.trip t on t.service_id = sd.service_id and t.route_id = route.route_id
        and t.direction_id = route.direction_id
      join network.stop_time st on st.trip_id = t.trip_id and st.seq = t.first_seq
      where st.departure_s + (d.date - today) * 86400 >= now_s
    ) end
  );
end $$;

-- Scheduled times of a route at a stop for one service day (RF-28), in seconds from midnight
-- (values over 86400 belong to the following night).
create function api.timetable(stop_id text, route_id text, day date) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  return (select coalesce(jsonb_agg(jsonb_build_object('direction_id', x.direction_id, 'headsign', x.headsign,
    'departures', x.departures) order by x.direction_id), '[]')
  from (
    select t.direction_id, mode() within group (order by t.headsign) as headsign,
           jsonb_agg(st.departure_s order by st.departure_s) as departures
    from network.stop_time st
    join network.trip t on t.trip_id = st.trip_id and t.route_id = timetable.route_id
    join network.service_day sd on sd.service_id = t.service_id and sd.date = timetable.day
    where st.stop_id = timetable.stop_id and st.seq < t.last_seq
    group by t.direction_id
  ) x);
end $$;

-- Active alerts on the network in scope, most severe first (RF-50).
create function api.alerts() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  return (select coalesce(jsonb_agg(api._alert(a) order by a.severity desc, a.title), '[]')
    from live.alert a
    where api._active(a.periods, now())
      and (a.general or exists (select from network.route r where r.route_id = any(a.route_ids))
           or exists (select from network.stop s where s.stop_id = any(a.stop_ids))));
end $$;

revoke all on all functions in schema api from public, anon;
grant execute on function api.network(), api.arrivals(text[], text[]), api.route(text, int),
  api.timetable(text, text, date), api.alerts() to authenticated;
