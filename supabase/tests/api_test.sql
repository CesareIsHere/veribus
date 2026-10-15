-- api.arrivals states on the tiny network built by run.sh (trips T1..T5 at stop B in ~14..34 minutes).
-- Each block fails with a message when an assertion does not hold.

create function pg_temp.at_b() returns jsonb language sql as $$
  select jsonb_object_agg(a->>'trip_id', a) from jsonb_array_elements(api.arrivals(array['B'])->'stops'->0->'arrivals') a
$$;
create function pg_temp.check(ok boolean, what text) returns void language plpgsql as $$
begin
  if ok is not true then raise exception 'FAILED: %', what; end if;
end $$;

-- Fresh feeds; T1 confirmed with a moving vehicle, T2 vehicle GPS 3 minutes old, T3 suppressed, T4 canceled.
update live.feed_status set feed_ts = now() - interval '20 seconds';
insert into live.vehicle (vehicle_id, label, trip_id, route_id, lat, lon, gps_at, seq, stop_id) values
  ('V1', '3001', 'T1', 'R1', 41.9, 12.5, now() - interval '30 seconds', 1, 'A'),
  ('V2', '3002', 'T2', 'R1', 41.9, 12.5, now() - interval '3 minutes', 1, 'A');
insert into live.trip_state (trip_id, route_id, vehicle_id, status, signal, pred_seq, pred_ts, suppressed_at) values
  ('T1', 'R1', 'V1', 'confirmed', null, '{2}', array[extract(epoch from now() + interval '14 minutes')::bigint], null),
  ('T2', 'R1', 'V2', 'confirmed', null, '{2}', array[extract(epoch from now() + interval '19 minutes')::bigint], null),
  ('T3', 'R1', 'V3', 'suppressed', '{"code": "S2", "min": 6}', '{2}',
   array[extract(epoch from now() + interval '24 minutes')::bigint], now() - interval '1 minute'),
  ('T4', 'R1', null, 'canceled', '{"code": "S1"}', '{}', '{}', null);

do $$
declare a jsonb := pg_temp.at_b();
begin
  perform pg_temp.check(a->'T1'->>'status' = 'confirmed' and (a->'T1'->>'minutes')::int between 13 and 14, 'T1 confirmed');
  perform pg_temp.check((a->'T1'->>'approximate')::boolean, 'T1 over the threshold is approximate (RF-29b)');
  perform pg_temp.check(a->'T1'->>'stops_away' = '1', 'T1 one stop away');
  perform pg_temp.check(a->'T2'->>'status' = 'uncertain' and a->'T2'->'signal'->>'code' = 'S4', 'T2 old GPS is S4');
  perform pg_temp.check(a->'T3'->>'status' = 'suppressed', 'T3 suppressed stays visible (RF-29)');
  perform pg_temp.check(a->'T4'->>'status' = 'canceled', 'T4 canceled (RF-25)');
  perform pg_temp.check(a->'T5'->>'status' = 'scheduled' and a->'T5'->'minutes' = 'null', 'T5 scheduled, never minutes (RNF-03)');
  perform pg_temp.check(api.arrivals(array['C'])->'stops'->0->'arrivals' = '[]', 'nobody boards at the terminus');
  perform pg_temp.check(api.arrivals(array['B'], array['R1'])->'routes'->0->>'vehicles_in_service' = '2', 'vehicles in service');
  perform pg_temp.check(api.route('R1', 0)->'vehicles'->0->>'index' = '0', 'route detail places vehicles on stops');
  perform pg_temp.check(jsonb_array_length(api.timetable('A', 'R1', (now() at time zone 'Europe/Rome')::date)->0->'departures') = 5, 'timetable');
  perform pg_temp.check(api.network()->>'version' = 'test', 'network version');
  perform pg_temp.check(not exists (select from network.route where route_id = 'M1'), 'metro excluded by the import');
  perform pg_temp.check(not exists (select from network.trip where trip_id = 'T9'), 'trips beyond 7 days not imported');
end $$;

-- Only Trip Updates stopped (SC-11b): no predictions, located vehicles show "N stops away".
update live.feed_status set feed_ts = now() - interval '11 minutes' where feed = 'tu';
do $$
declare a jsonb := pg_temp.at_b();
begin
  perform pg_temp.check(a->'T1'->'time' = 'null' and a->'T1'->>'stops_away' = '1', 'TU stale: T1 stops away, no time');
  perform pg_temp.check(a->'T1'->'signal'->>'code' = 'S6', 'TU stale: T1 flagged late');
end $$;

-- Feeds late (S6), then stale (RF-60): everything becomes scheduled.
update live.feed_status set feed_ts = now() - interval '5 minutes';
do $$ begin
  perform pg_temp.check(pg_temp.at_b()->'T1'->'signal'->>'code' = 'S6', 'late feed is S6');
end $$;
update live.feed_status set feed_ts = now() - interval '11 minutes';
do $$
declare a jsonb := pg_temp.at_b();
begin
  perform pg_temp.check(a->'T1'->>'status' = 'scheduled' and a->'T1'->'vehicle' = 'null', 'stale feed: T1 scheduled');
end $$;

-- Clients reach only the api functions.
do $$ begin
  perform pg_temp.check(not has_function_privilege('anon', 'api.arrivals(text[], text[])', 'execute'), 'anon cannot call api');
  perform pg_temp.check(has_function_privilege('authenticated', 'api.arrivals(text[], text[])', 'execute'), 'users can');
  perform pg_temp.check(not has_function_privilege('authenticated', 'api._feed(timestamptz)', 'execute'), 'helpers private');
  perform pg_temp.check(not has_table_privilege('authenticated', 'live.trip_state', 'select'), 'tables private');
end $$;

-- Delay history: T1's vehicle moves from stop 1 to stop 3, so A and B are passed now (12 and 14 minutes early).
update live.feed_status set feed_ts = now() - interval '20 seconds';
update live.trip_state set last_seq = 1 where trip_id = 'T1';
select history.record(jsonb_build_array(
  jsonb_build_object('trip_id', 'T1', 'status', 'confirmed', 'last_seq', 3, 'seen_at', now()),
  jsonb_build_object('trip_id', 'T2', 'status', 'canceled', 'last_seq', null, 'seen_at', null)));
do $$
declare
  h history.trip_run := (select h from history.trip_run h where trip_id = 'T1');
  b int := (select departure_s from network.stop_time where trip_id = 'T1' and stop_id = 'B');
  today date := (now() at time zone 'Europe/Rome')::date;
  weekend boolean := extract(isodow from today) >= 6;
  days jsonb;
begin
  perform pg_temp.check(h.stop_ids = '{A,B}' and h.delay_s[2] between -900 and -780, 'passages recorded with delay');
  perform pg_temp.check((select canceled and cardinality(stop_ids) = 3 from history.trip_run where trip_id = 'T2'),
    'canceled trip keeps its schedule');
  perform pg_temp.check(pg_temp.at_b()->'T1' is null, 'a passed stop is not an arrival any more');

  -- Two weeks ago it ran 2 minutes late; a week ago the line was tracked but not this trip; the other days no data.
  insert into history.trip_run (service_date, trip_id, route_id, direction_id, stop_ids, dep_s, delay_s)
  values (today - 14, 'OLD', 'R1', 0, '{A,B}', array[b - 120, b + 60], '{100,120}');
  insert into network_meta.route_seen values ('R1', today - 7), ('R1', today - 21);
  days := api.trip_history('B', 'R1', 0, b, weekend);
  perform pg_temp.check(jsonb_array_length(days) = 2, 'history: only recorded days with data');
  perform pg_temp.check(days->0->>'status' = 'not_tracked', 'history: line tracked, trip not');
  perform pg_temp.check(days->1->>'status' = 'ran' and days->1->>'delay_s' = '120', 'history: delay at the stop');
  perform pg_temp.check(api.trip_history('B', 'R1', 0, b, not weekend) = '[]', 'history: weekdays and weekend apart');
end $$;

-- A scheduled trip stays 10 minutes after its time, flagged overdue (missed_grace_min), then goes.
update network.stop_time set departure_s = departure_s - 2400 where trip_id = 'T5';
do $$ begin
  perform pg_temp.check((pg_temp.at_b()->'T5'->>'overdue')::boolean, 'overdue scheduled trip still shown');
end $$;
update network.stop_time set departure_s = departure_s - 600 where trip_id = 'T5';
do $$ begin
  perform pg_temp.check(pg_temp.at_b()->'T5' is null, 'gone after the grace minutes');
end $$;
