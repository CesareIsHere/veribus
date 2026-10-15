-- Delay history: when each tracked trip passed each stop, kept 30 days, so the app can tell what to expect from a
-- trip (stop, line, direction, scheduled time) on weekdays or at the weekend. And arrivals stay on screen for
-- `missed_grace_min` minutes after their time: a bus with no data, or a late one, often passes anyway.
--
-- A row per trip and service day, only for trips seen in realtime: no row on a day the line was tracked means
-- "not tracked". The stops are appended as the vehicle passes them, so the arrays hold only observed stops.
-- Matching is by slot (stop, line, direction, time at the stop), never by trip_id: it changes with the GTFS import.

create schema history;

create table history.trip_run (
  service_date date not null,
  trip_id text not null,
  route_id text not null,
  direction_id smallint not null,
  canceled boolean not null default false,
  -- Parallel arrays: stop, scheduled time (seconds from the service day's midnight), delay in seconds (null when
  -- canceled: the whole schedule is stored, with no times).
  stop_ids text[] not null default '{}',
  dep_s int[] not null default '{}',
  delay_s smallint[] not null default '{}',
  primary key (service_date, trip_id)
);
create index on history.trip_run (route_id, direction_id, service_date);

alter table history.trip_run enable row level security;
create policy poller on history.trip_run to poller using (true) with check (true);
grant usage on schema history to poller;
grant select, insert, update on history.trip_run to poller;

insert into config.setting (key, value) values ('missed_grace_min', '10');

-- Called by the poller with the new trip states, before they replace live.trip_state: the stops between the previous
-- and the new stop sequence of a vehicle have been passed now (at its last GPS fix).
-- ponytail: a stop passed at the first sighting of a trip is not recorded (no previous sequence to compare with).
create function history.record(trips jsonb) returns void
language plpgsql set search_path = '' as $$
begin
  insert into history.trip_run as h (service_date, trip_id, route_id, direction_id, canceled, stop_ids, dep_s, delay_s)
  select x.service_date, x.trip_id, t.route_id, t.direction_id, bool_or(x.canceled),
         array_agg(x.stop_id order by x.seq), array_agg(x.departure_s order by x.seq),
         array_agg(x.delay_s order by x.seq)
  from (
    select n.trip_id, false as canceled, st.seq, st.stop_id, st.departure_s, d.date as service_date,
           least(greatest(extract(epoch from (n.seen_at at time zone 'Europe/Rome')
             - (d.date + st.departure_s * interval '1 second'))::int, -32768), 32767)::smallint as delay_s
    from jsonb_to_recordset(trips) n (trip_id text, last_seq int, seen_at timestamptz)
    join live.trip_state o on o.trip_id = n.trip_id and n.last_seq > o.last_seq
    join network.stop_time st on st.trip_id = n.trip_id and st.seq >= o.last_seq and st.seq < n.last_seq
    -- The service day whose midnight + scheduled time is nearest to the passage (delays stay well under 12 h).
    cross join lateral (select ((n.seen_at at time zone 'Europe/Rome') - st.departure_s * interval '1 second'
                                + interval '12 hours')::date as date) d
    where n.seen_at is not null
    union all
    -- Canceled in this cycle: the whole schedule, so that the slot can be found.
    -- ponytail: the service day comes from now and the first stop, wrong if canceled more than 12 h ahead.
    select n.trip_id, true, st.seq, st.stop_id, st.departure_s,
           ((now() at time zone 'Europe/Rome') - f.departure_s * interval '1 second' + interval '12 hours')::date, null
    from jsonb_to_recordset(trips) n (trip_id text, status text)
    left join live.trip_state o on o.trip_id = n.trip_id
    join network.trip tr on tr.trip_id = n.trip_id
    join network.stop_time f on f.trip_id = n.trip_id and f.seq = tr.first_seq
    join network.stop_time st on st.trip_id = n.trip_id
    where n.status = 'canceled' and o.status is distinct from 'canceled'
  ) x
  join network.trip t on t.trip_id = x.trip_id
  group by x.service_date, x.trip_id, t.route_id, t.direction_id
  on conflict (service_date, trip_id) do update set
    canceled = h.canceled or excluded.canceled,
    -- A canceled trip that had already run part of its route keeps the stops it passed.
    stop_ids = case when excluded.canceled then h.stop_ids else h.stop_ids || excluded.stop_ids end,
    dep_s = case when excluded.canceled then h.dep_s else h.dep_s || excluded.dep_s end,
    delay_s = case when excluded.canceled then h.delay_s else h.delay_s || excluded.delay_s end;
end $$;
revoke all on function history.record(jsonb) from public;
grant execute on function history.record(jsonb) to poller;

select cron.schedule('cleanup-history', '29 3 * * *', $$
  delete from history.trip_run where service_date < current_date - 30;
$$);

-- How a slot went in the last 30 days of the same kind (weekdays or weekend), most recent first:
-- `ran` with the delay at the stop in seconds, `canceled`, or `not_tracked` (the line was tracked that day, this trip
-- was not: it may have passed all the same). Days the slot does not run, or the poller did not, are left out.
create function api.trip_history(stop_id text, route_id text, direction_id int, departure_s int, weekend boolean)
returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  today date := (now() at time zone 'Europe/Rome')::date;
  -- The same slot can move by a couple of minutes between weekday and weekend timetables.
  slack int := 180;
  -- ISO weekdays the slot runs on, from the network (it spans -1..+7 days: every weekday is there).
  runs_on int[];
begin
  select array_agg(distinct extract(isodow from sd.date)::int) into runs_on
  from network.stop_time st
  join network.trip t on t.trip_id = st.trip_id and t.route_id = trip_history.route_id
    and t.direction_id = trip_history.direction_id
  join network.service_day sd on sd.service_id = t.service_id
  where st.stop_id = trip_history.stop_id and abs(st.departure_s - trip_history.departure_s) <= slack;

  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'date', g.day,
      'status', case when r.canceled then 'canceled' when r.delay is null then 'not_tracked' else 'ran' end,
      'delay_s', r.delay
    ) order by g.day desc)
    -- From the first day recorded: before it "not tracked" would only mean "not recorded yet".
    from (select generate_series(greatest(today - 30, coalesce((select min(service_date) from history.trip_run), today)), today - 1,
                                 interval '1 day')::date as day) g
    left join lateral (
      select h.canceled, h.delay_s[p.i] as delay
      from history.trip_run h
      cross join lateral (select array_position(h.stop_ids, trip_history.stop_id) as i) p
      where h.service_date = g.day and h.route_id = trip_history.route_id
        and h.direction_id = trip_history.direction_id
        and p.i is not null and abs(h.dep_s[p.i] - trip_history.departure_s) <= slack
      order by abs(h.dep_s[p.i] - trip_history.departure_s)
      limit 1
    ) r on true
    where (extract(isodow from g.day) >= 6) = trip_history.weekend
      and extract(isodow from g.day)::int = any(runs_on)
      and (r.canceled is not null or exists (
        select from network_meta.route_seen s where s.route_id = trip_history.route_id and s.date = g.day))
  ), '[]');
end $$;

revoke all on function api.trip_history(text, text, int, int, boolean) from public, anon;
grant execute on function api.trip_history(text, text, int, int, boolean) to authenticated;

-- api.arrivals as it was, plus:
--   - every arrival but canceled/suppressed stays `missed_grace_min` after its time, flagged `overdue`, unless the
--     history says the bus has passed the stop;
--   - `departure_s`, the scheduled time at the stop, to ask for the slot's history.
create or replace function api.arrivals(stop_ids text[], route_ids text[] default '{}') returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  at timestamptz := now();
  today date := (at at time zone 'Europe/Rome')::date;
  now_s int := extract(epoch from (at at time zone 'Europe/Rome') - today::timestamp)::int;
  feed jsonb := api._feed(at);
  valid interval := config.get('s2_min')::int * interval '1 minute';
  suppressed_for interval := config.get('suppressed_min')::int * interval '1 minute';
  grace interval := config.get('missed_grace_min')::int * interval '1 minute';
  approx int := api._approx_minutes(at);
begin
  return (
    with candidate as (
      -- ponytail: service-day times are counted from midnight, so on the two DST days they are off by 1h.
      select st.stop_id, st.seq, st.departure_s, d.date as service_date, t.trip_id, t.route_id, t.direction_id,
             t.headsign, (d.date + st.departure_s * interval '1 second') at time zone 'Europe/Rome' as scheduled
      from (values (today), (today - 1)) d (date)
      join network.stop_time st on st.stop_id = any(arrivals.stop_ids)
        and st.departure_s between now_s + (today - d.date) * 86400 - 1800 and now_s + (today - d.date) * 86400 + 3600
      join network.trip t on t.trip_id = st.trip_id and st.seq < t.last_seq  -- nobody boards at the terminus
      join network.service_day sd on sd.service_id = t.service_id and sd.date = d.date
    ), joined as (
      select c.*, ts.trip_id is not null as has_rt, ts.status as rt_status, ts.signal as rt_signal, ts.suppressed_at,
             case when (feed->>'predictions')::boolean
               then to_timestamp(ts.pred_ts[array_position(ts.pred_seq, c.seq)]) end as predicted,
             v.vehicle_id, v.label, v.lat, v.lon, v.gps_at, v.seq as v_seq
      from candidate c
      left join live.trip_state ts on ts.trip_id = c.trip_id
      left join live.vehicle v on v.vehicle_id = ts.vehicle_id and v.trip_id = ts.trip_id and v.gps_at > at - valid
    ), rated as (
      select j.*,
        api._status(feed, has_rt, rt_status, predicted, vehicle_id, rt_signal, gps_at, at) as status
      from joined j
      where (v_seq is null or v_seq <= j.seq)  -- the vehicle has not passed the stop yet
        and not exists (select from history.trip_run h  -- nor did it before vanishing
                        where h.service_date = j.service_date and h.trip_id = j.trip_id and j.stop_id = any(h.stop_ids)
                          and not h.canceled)
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
          when 'canceled' then sort_time >= at - interval '1 minute'
          else sort_time >= at - grace end
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
              'departure_s', k.departure_s,
              'status', k.status,
              -- A confirmed trip with a vehicle but no prediction shows "N stops away", never a time (RF-26).
              'time', case when k.status in ('confirmed', 'uncertain') then k.rt_time else k.sort_time end,
              'minutes', case when k.rt_time is not null then greatest(0, floor(extract(epoch from k.rt_time - at) / 60))::int end,
              'approximate', k.rt_time is not null and k.rt_time > at + approx * interval '1 minute',
              'overdue', k.status not in ('canceled', 'suppressed') and k.sort_time < at,
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
