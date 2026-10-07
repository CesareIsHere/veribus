-- Followed trips: what notify.claim sends, once, and what api.my_follows shows. Runs after api_test.sql on the tiny
-- network of run.sh: trips T1..T5 of line R1 reach stop B in ~14, 19, 24, 29, 34 minutes.

create function pg_temp.check(ok boolean, what text) returns void language plpgsql as $$
begin
  if ok is not true then raise exception 'FAILED: %', what; end if;
end $$;
create function pg_temp.dep(trip text) returns int language sql as $$
  select departure_s from network.stop_time where trip_id = trip and stop_id = 'B'
$$;
-- The live state of a trip: vehicle located now, predicted to reach B in `minutes`.
create function pg_temp.live(trip text, vehicle text, minutes int, status text default 'confirmed',
                             signal jsonb default null) returns void language plpgsql as $$
#variable_conflict use_variable
begin
  delete from live.trip_state where trip_id = trip;
  delete from live.vehicle where vehicle_id = vehicle;
  if status <> 'canceled' then
    insert into live.vehicle (vehicle_id, label, trip_id, route_id, lat, lon, gps_at, seq, stop_id)
    values (vehicle, '3001', trip, 'R1', 41.9, 12.5, now() - interval '20 seconds', 1, 'A');
  end if;
  insert into live.trip_state (trip_id, route_id, vehicle_id, status, signal, pred_seq, pred_ts, suppressed_at)
  values (trip, 'R1', case when status = 'canceled' then null else vehicle end, status, signal, '{2}',
          array[extract(epoch from now() + minutes * interval '1 minute')::bigint],
          case when status = 'suppressed' then now() - interval '1 minute' end);
end $$;
create function pg_temp.events(kind text default null) returns jsonb language sql as $$
  select coalesce(jsonb_agg(e), '[]') from jsonb_array_elements(notify.claim()) e where kind is null or e->>'event' = kind
$$;

delete from live.vehicle;
delete from live.trip_state;
update live.feed_status set feed_ts = now() - interval '20 seconds';

delete from auth.users where id in ('00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000a2');
insert into auth.users (id) values ('00000000-0000-0000-0000-0000000000a1'), ('00000000-0000-0000-0000-0000000000a2');
insert into public.push_tokens (user_id, token, locale) values ('00000000-0000-0000-0000-0000000000a1', 'tok-a1', 'en');
-- a2 has no device registered: nothing is claimed for them.

insert into public.trip_follow (id, user_id, stop_id, route_id, direction_id, departure_s, days, lead_min) values
  ('f0000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000000a1', 'B', 'R1', 0, pg_temp.dep('T1'),
   '{1,2,3,4,5,6,7}', '{15,10,5}'),
  ('f0000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-0000000000a1', 'B', 'R1', 0, pg_temp.dep('T2'),
   '{1,2,3,4,5,6,7}', '{15,10,5}'),
  ('f0000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-0000000000a1', 'B', 'R1', 0, pg_temp.dep('T4'),
   '{1,2,3,4,5,6,7}', '{5}'),
  ('f0000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-0000000000a1', 'B', 'R1', 0, pg_temp.dep('T3'),
   '{1,2,3,4,5,6,7}', '{5}'),
  -- the right trip, but not on today's weekday
  ('f0000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-0000000000a1', 'B', 'R1', 0, pg_temp.dep('T5'),
   array[(extract(isodow from now() at time zone 'Europe/Rome')::int % 7 + 1)::smallint], '{40}'),
  -- the right trip, but the user has no device
  ('f0000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-0000000000a2', 'B', 'R1', 0, pg_temp.dep('T1'),
   '{1,2,3,4,5,6,7}', '{15}');

-- T1 is ~14 min away: only the 15 min notice is due.
select pg_temp.live('T1', 'V1', 14);
do $$
declare e jsonb := pg_temp.events('lead');
begin
  perform pg_temp.check(jsonb_array_length(e) = 1, 'one lead notice (14 min away): ' || e::text);
  perform pg_temp.check(e->0->>'follow_id' = 'f0000000-0000-0000-0000-000000000001', 'for the followed trip');
  perform pg_temp.check(e->0->'kinds' = '["lead:15"]', 'the 15 min notice, nothing skipped');
  perform pg_temp.check((e->0->>'minutes')::int between 13 and 14, 'minutes to go');
  perform pg_temp.check((e->0->>'realtime')::boolean, 'from the prediction');
  perform pg_temp.check(e->0->>'route' = '64' and e->0->>'stop' = 'Beta', 'names from the network');
  perform pg_temp.check(e->0->'tokens' = '[{"token": "tok-a1", "locale": "en"}]', 'the user''s device and language');
end $$;
-- Each notice goes out once.
do $$ begin
  perform pg_temp.check(pg_temp.events('lead') = '[]', 'not again');
end $$;

-- The bus gets closer: the 10 min notice, then the 5 min one.
select pg_temp.live('T1', 'V1', 9);
do $$
declare e jsonb := pg_temp.events('lead');
begin
  perform pg_temp.check(jsonb_array_length(e) = 1 and e->0->'kinds' = '["lead:10"]', '10 min notice: ' || e::text);
end $$;
select pg_temp.live('T1', 'V1', 4);
do $$
declare e jsonb := pg_temp.events('lead');
begin
  perform pg_temp.check(jsonb_array_length(e) = 1 and e->0->'kinds' = '["lead:5"]', '5 min notice: ' || e::text);
  perform pg_temp.check(pg_temp.events('lead') = '[]', 'nothing more');
end $$;

-- The bus passed the stop: no notice, even if one was still due.
update live.vehicle set seq = 3 where vehicle_id = 'V1';
select pg_temp.live('T2', 'V2', 19);
update live.vehicle set seq = 3 where vehicle_id = 'V2';
update live.trip_state set pred_ts = array[extract(epoch from now() + interval '3 minutes')::bigint] where trip_id = 'T2';
do $$ begin
  perform pg_temp.check(pg_temp.events('lead') = '[]', 'a vehicle that has passed the stop is not announced');
end $$;

-- Several notices due at once (new follow, app off): only the nearest is sent, the others are recorded as done.
select pg_temp.live('T2', 'V2', 3);
do $$
declare e jsonb := pg_temp.events('lead');
begin
  perform pg_temp.check(jsonb_array_length(e) = 1 and e->0->'kinds' @> '["lead:5", "lead:10", "lead:15"]'
    and e->0->>'event' = 'lead', 'catch-up sends one notice: ' || e::text);
  perform pg_temp.check(pg_temp.events() = '[]', 'catch-up: the skipped ones are not sent later');
end $$;

-- Without realtime the schedule decides, and the notice says so.
delete from live.trip_state where trip_id = 'T1';
delete from public.trip_follow_sent where follow_id = 'f0000000-0000-0000-0000-000000000001';
update public.trip_follow set lead_min = '{30}' where id = 'f0000000-0000-0000-0000-000000000001';
do $$
declare e jsonb := pg_temp.events('lead');
begin
  perform pg_temp.check(jsonb_array_length(e) = 1 and not (e->0->>'realtime')::boolean, 'scheduled notice: ' || e::text);
end $$;

-- A canceled trip: one notice. A vehicle that vanished: one notice.
select pg_temp.live('T4', 'V4', 29, 'canceled');
select pg_temp.live('T3', 'V3', 24, 'suppressed', '{"code": "S2", "min": 6}');
do $$
declare e jsonb := pg_temp.events();
begin
  perform pg_temp.check(e @> '[{"event": "canceled", "follow_id": "f0000000-0000-0000-0000-000000000003"}]', 'canceled: ' || e::text);
  perform pg_temp.check(e @> '[{"event": "lost", "follow_id": "f0000000-0000-0000-0000-000000000004"}]', 'lost: ' || e::text);
  perform pg_temp.check(not exists (select from jsonb_array_elements(e) x where x->>'event' = 'lead'
    and x->>'follow_id' in ('f0000000-0000-0000-0000-000000000003', 'f0000000-0000-0000-0000-000000000004')),
    'no "bus arriving" for a canceled or lost trip');
  perform pg_temp.check(pg_temp.events() = '[]', 'once');
end $$;

-- A vehicle that vanished after passing the stop: nothing to warn about.
update live.trip_state set last_seq = 3 where trip_id = 'T3';
delete from public.trip_follow_sent where follow_id = 'f0000000-0000-0000-0000-000000000004';
do $$ begin
  perform pg_temp.check(pg_temp.events('lost') = '[]', 'no "lost" for a trip already past the stop');
end $$;

-- Standing still: reported once; reported again only after it moved.
select pg_temp.live('T1', 'V1', 12, 'confirmed', '{"code": "S3", "min": 6}');
do $$
declare e jsonb := pg_temp.events('still');
begin
  perform pg_temp.check(jsonb_array_length(e) = 1 and (e->0->>'minutes')::int = 6, 'standing still: ' || e::text);
  perform pg_temp.check(pg_temp.events('still') = '[]', 'standing still: once');
end $$;
select pg_temp.live('T1', 'V1', 12);
do $$ begin perform pg_temp.check(pg_temp.events('still') = '[]', 'moving: nothing'); end $$;
select pg_temp.live('T1', 'V1', 12, 'confirmed', '{"code": "S3", "min": 5}');
do $$ begin
  perform pg_temp.check(jsonb_array_length(pg_temp.events('still')) = 1, 'standing still again after moving');
end $$;

-- Sending failed: the record is taken back and the next cycle tries again.
delete from public.trip_follow_sent where follow_id = 'f0000000-0000-0000-0000-000000000001' and kind like 'lead:%';
select pg_temp.live('T1', 'V1', 12);
do $$
declare first jsonb := (select jsonb_agg(e) from jsonb_array_elements(notify.claim()) e where e->>'event' = 'lead');
        again jsonb;
begin
  perform pg_temp.check(first is not null, 'a notice to retry');
  perform notify.release(first);
  again := pg_temp.events('lead');
  perform pg_temp.check(again = first, 'released notices come back');
end $$;

-- A weekday the trip does not run on, a disabled follow: nothing.
update public.trip_follow set enabled = false where id = 'f0000000-0000-0000-0000-000000000001';
delete from public.trip_follow_sent;
select pg_temp.live('T5', 'V5', 4);
do $$
declare e jsonb := pg_temp.events();
begin
  perform pg_temp.check(not exists (select from jsonb_array_elements(e) x
    where x->>'follow_id' in ('f0000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000005',
                              'f0000000-0000-0000-0000-000000000006')), 'disabled, other weekday, no device: nothing');
end $$;

-- The user's view: their follows with today's state.
set role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000000a1', false);
do $$
declare f jsonb := api.my_follows();
begin
  perform pg_temp.check(jsonb_array_length(f) = 5, 'my follows: ' || f::text);
  perform pg_temp.check(f @> '[{"id": "f0000000-0000-0000-0000-000000000003", "today": {"status": "canceled", "signal": {"code": "S1"}}}]', 'today: canceled with its reason');
  perform pg_temp.check(f @> '[{"id": "f0000000-0000-0000-0000-000000000002", "lead_min": [15, 10, 5], "days": [1, 2, 3, 4, 5, 6, 7]}]',
    'configuration');
  perform pg_temp.check((select x->'today' from jsonb_array_elements(f) x where x->>'id' = 'f0000000-0000-0000-0000-000000000002')
    ->>'status' = 'confirmed', 'today: confirmed');
end $$;
-- Clients reach their own rows only, and never the notifier.
do $$
begin
  perform pg_temp.check((select count(*) from public.trip_follow) = 5, 'RLS: only my follows');
  begin
    perform notify.claim();
    raise exception 'FAILED: users can call notify.claim';
  exception when insufficient_privilege then null;
  end;
  begin
    perform 1 from public.trip_follow_sent;
    raise exception 'FAILED: users can read what was sent';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.trip_follow (stop_id, route_id, direction_id, departure_s, days, lead_min)
    values ('B', 'R1', 0, 100, '{1}', '{1,2,3,4}');
    raise exception 'FAILED: four lead times accepted';
  exception when check_violation then null;
  end;
end $$;
-- At most 30 follows per user, and saving one that exists is not a new one.
do $$
begin
  for i in 1..30 loop
    begin
      insert into public.trip_follow (stop_id, route_id, direction_id, departure_s, days, lead_min)
      values ('B', 'R1', 0, 1000 + i, '{1}', '{5}');
    exception when others then
      perform pg_temp.check(sqlstate = '54000' and sqlerrm = 'Too many followed trips', 'limit error');
      perform pg_temp.check(i > 20, 'the limit comes after 30 rows in total');
      insert into public.trip_follow (stop_id, route_id, direction_id, departure_s, days, lead_min)
      values ('B', 'R1', 0, 1001, '{2}', '{10}')
      on conflict (user_id, stop_id, route_id, direction_id, departure_s) do update set days = excluded.days;
      perform pg_temp.check((select days from public.trip_follow where departure_s = 1001) = '{2}', 'edit at the limit');
      return;
    end;
  end loop;
  raise exception 'FAILED: no limit on follows';
end $$;

-- A device token belongs to one user at a time.
select api.register_push_token('tok-shared', 'it');
do $$ begin
  perform pg_temp.check((select user_id from public.push_tokens where token = 'tok-shared') = '00000000-0000-0000-0000-0000000000a1', 'token of a1');
end $$;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000000a2', false);
select api.register_push_token('tok-shared', 'en');
do $$ begin
  perform pg_temp.check((select count(*) from public.push_tokens where token = 'tok-shared') = 1, 'a2 sees its own row now');
end $$;
reset role;
do $$ begin
  perform pg_temp.check((select array_agg(user_id::text || locale) from public.push_tokens where token = 'tok-shared')
    = array['00000000-0000-0000-0000-0000000000a2en'], 'the token moved to the user who signed in on the device');
end $$;
