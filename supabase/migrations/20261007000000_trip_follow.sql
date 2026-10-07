-- Followed trips: the user picks the exact trips of a stop (a line, a direction, the scheduled time at the stop), on
-- the days of the week they want, and is notified N minutes before the bus passes (up to 3 notices per trip) and when
-- something happens to it (canceled, standing still, vehicle lost).
--
-- A follow is identified by what stays true when the GTFS is reimported (stop, line, direction, time at the stop), not
-- by trip_id: every day it is resolved to that day's trip. The server side is `notify.claim`, called by the poller after
-- each cycle (backend/core/notify.ts); the app reads `api.my_follows`.
-- Every policy uses `(select auth.uid())`: evaluated once per query, not per row.

create table public.trip_follow (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  stop_id text not null,
  route_id text not null,
  direction_id smallint not null check (direction_id in (0, 1)),
  -- Scheduled time at the stop, in seconds from the service day's midnight (past 24 h: after midnight).
  departure_s int not null check (departure_s between 0 and 172799),
  -- ISO weekdays (1 Monday .. 7 Sunday) of the service day the trip runs on.
  days smallint[] not null check (cardinality(days) between 1 and 7 and 1 <= all (days) and 7 >= all (days)),
  -- Minutes before the bus passes at which to notify: up to three, e.g. {15, 10, 5}.
  lead_min smallint[] not null check (cardinality(lead_min) between 1 and 3 and 1 <= all (lead_min) and 60 >= all (lead_min)),
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  unique (user_id, stop_id, route_id, direction_id, departure_s)
);
create index on public.trip_follow (user_id);

alter table public.trip_follow enable row level security;

create policy "Users manage their followed trips" on public.trip_follow
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

revoke all on public.trip_follow from anon;
grant select, insert, update, delete on public.trip_follow to authenticated;

-- A user cannot follow without bound: the poller looks at every follow at each cycle.
create function public.trip_follow_limit() returns trigger
language plpgsql set search_path = '' as $$
begin
  -- Saving a follow that exists (an upsert) is an edit, whatever the count.
  if exists (select from public.trip_follow f
             where f.user_id = new.user_id and f.stop_id = new.stop_id and f.route_id = new.route_id
               and f.direction_id = new.direction_id and f.departure_s = new.departure_s) then
    return new;
  end if;
  if (select count(*) from public.trip_follow where user_id = new.user_id) >= 30 then
    raise exception 'Too many followed trips' using errcode = 'P0001';
  end if;
  return new;
end $$;

create trigger trip_follow_limit before insert on public.trip_follow
  for each row execute function public.trip_follow_limit();

-- What was already notified, per follow and service day: `lead:15`, `canceled`, `still`, `lost`. Written only by
-- notify.claim (no policy: clients cannot read or write it).
create table public.trip_follow_sent (
  follow_id uuid not null references public.trip_follow (id) on delete cascade,
  service_date date not null,
  kind text not null,
  sent_at timestamptz not null default now(),
  primary key (follow_id, service_date, kind)
);
alter table public.trip_follow_sent enable row level security;
revoke all on public.trip_follow_sent from anon, authenticated;

-- Notices are written in the language of the device that registered the token.
alter table public.push_tokens add column locale text not null default 'it';
alter table public.push_tokens add column updated_at timestamptz not null default now();

create policy "Users update their push tokens' language" on public.push_tokens
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- A token is one device: when it registers for a user it stops belonging to anyone else (someone signed out, or the
-- session expired, and another user signed in on the same phone).
create function api.register_push_token(token text, locale text) returns void
language plpgsql security definer set search_path = '' as $$
#variable_conflict use_column
begin
  if (select auth.uid()) is null then raise exception 'Not signed in' using errcode = '28000'; end if;
  delete from public.push_tokens p where p.token = register_push_token.token and p.user_id <> (select auth.uid());
  insert into public.push_tokens (user_id, token, locale, updated_at)
  values ((select auth.uid()), register_push_token.token, register_push_token.locale, now())
  on conflict (user_id, token) do update set locale = excluded.locale, updated_at = now();
end $$;

revoke all on function api.register_push_token(text, text) from public, anon;
grant execute on function api.register_push_token(text, text) to authenticated;

-- Today's state of each followed trip -------------------------------------------------------------

create schema notify;

-- The followed trips of today (and of the service day that started yesterday, for times past midnight), resolved to
-- their trip, with the live state computed like api.arrivals: same status rules, same signals.
-- Only trips whose scheduled time is within [-45 min, +2 h] have a row: the rest is not news yet (or any more).
-- `only_user` limits it to one user (api.my_follows); null for all (notify.claim).
create function notify._state(at timestamptz, only_user uuid default null)
returns table (
  follow_id uuid, user_id uuid, service_date date, trip_id text, route_id text, direction_id smallint,
  stop_id text, headsign text, lead_min smallint[], scheduled timestamptz, predicted timestamptz,
  status text, signal jsonb, vehicle_id text, passed boolean, still_min int
)
language plpgsql stable security definer set search_path = '' as $$
#variable_conflict use_column
declare
  today date := (at at time zone 'Europe/Rome')::date;
  feed jsonb := api._feed(at);
  valid interval := config.get('s2_min')::int * interval '1 minute';
begin
  return query
  with candidate as (
    -- ponytail: like api.arrivals, service-day times are counted from midnight: off by 1 h on the two DST days.
    select distinct on (f.id, d.date)
      f.id as fid, f.user_id as uid, d.date as sdate, t.trip_id as tid, f.route_id as rid, f.direction_id as did,
      f.stop_id as sid, t.headsign as hs, f.lead_min as leads, st.seq,
      (d.date + st.departure_s * interval '1 second') at time zone 'Europe/Rome' as sched
    from public.trip_follow f
    cross join (values (today), (today - 1)) d (date)
    join network.stop_time st on st.stop_id = f.stop_id and st.departure_s = f.departure_s
    join network.trip t on t.trip_id = st.trip_id and t.route_id = f.route_id and t.direction_id = f.direction_id
      and st.seq < t.last_seq  -- nobody boards at the terminus
    join network.service_day sd on sd.service_id = t.service_id and sd.date = d.date
    left join live.trip_state ts on ts.trip_id = t.trip_id
    where f.enabled and (only_user is null or f.user_id = only_user)
      and extract(isodow from d.date)::int = any (f.days)
      and (d.date + st.departure_s * interval '1 second') at time zone 'Europe/Rome'
        between at - interval '45 minutes' and at + interval '2 hours'
    -- Two trips at the same time on the same stop and line (rare): the one with realtime data.
    order by f.id, d.date, (ts.trip_id is not null) desc, t.trip_id
  ), joined as (
    select c.*, ts.trip_id is not null as has_rt, ts.status as rt_status, ts.signal as rt_signal,
           case when (feed->>'predictions')::boolean
             then to_timestamp(ts.pred_ts[array_position(ts.pred_seq, c.seq)]) end as pred,
           v.vehicle_id as vid, v.gps_at, v.seq as v_seq, ts.last_seq as t_seq
    from candidate c
    left join live.trip_state ts on ts.trip_id = c.tid
    left join live.vehicle v on v.vehicle_id = ts.vehicle_id and v.trip_id = ts.trip_id and v.gps_at > at - valid
  )
  select j.fid, j.uid, j.sdate, j.tid, j.rid, j.did, j.sid, j.hs, j.leads, j.sched, j.pred,
    case
      when feed->>'status' = 'stale' or not j.has_rt then 'scheduled'
      when j.rt_status in ('canceled', 'suppressed') then j.rt_status
      when j.pred is null and j.vid is null then 'scheduled'
      when api._signal(j.rt_signal, j.gps_at, feed, at) is null then 'confirmed'
      else 'uncertain'
    end,
    case when j.rt_status in ('canceled', 'suppressed') then j.rt_signal
         when j.vid is not null then api._signal(j.rt_signal, j.gps_at, feed, at) end,
    j.vid,
    -- Past the stop: by the vehicle's position, or by the last one seen of a trip whose vehicle vanished.
    coalesce(greatest(j.v_seq, j.t_seq) > j.seq, false),  -- greatest ignores nulls
    case when j.vid is not null and j.rt_signal->>'code' = 'S3' then (j.rt_signal->>'min')::int end
  from joined j;
end $$;

-- What to notify now. Each notice is recorded as sent in the same statement (at most once), and returned with the
-- device tokens of the user; notify.release takes the record back when sending failed, so the next cycle retries.
--   lead      the bus is `minutes` away (ETA from the realtime prediction, the schedule otherwise: `realtime`)
--   canceled  the trip was canceled
--   still     the vehicle has been standing still for `minutes` (S3); again after it has moved
--   lost      the vehicle vanished before the end of the trip (suppressed)
-- With several lead times due at once (the app was off, the follow is new) only the nearest is sent, the others
-- are recorded as sent without a notice.
create function notify.claim(at timestamptz default now()) returns jsonb
language plpgsql security definer set search_path = '' as $$
#variable_conflict use_column
declare
  result jsonb;
begin
  -- One claim at a time: a cycle that outlives the poller's lease must not claim what the next one is claiming.
  perform pg_advisory_xact_lock(hashtext('notify.claim'));

  -- A vehicle that moved again can be reported standing still again.
  delete from public.trip_follow_sent s
  using notify._state(at) st
  where s.follow_id = st.follow_id and s.service_date = st.service_date and s.kind = 'still' and st.still_min is null;

  with s as (
    select st.*,
      case when st.status in ('confirmed', 'uncertain') and st.predicted is not null
           then st.predicted else st.scheduled end as eta
    from notify._state(at) st
    where exists (select from public.push_tokens p where p.user_id = st.user_id)
  ), due as (
    -- (follow, day) × lead time already reached, not notified yet.
    select s.follow_id, s.service_date, m as lead, s.eta
    from s cross join lateral unnest(s.lead_min) m
    where s.status not in ('canceled', 'suppressed') and not s.passed
      and s.eta <= at + m * interval '1 minute' and s.eta > at - interval '1 minute'
      and not exists (select from public.trip_follow_sent x
                      where x.follow_id = s.follow_id and x.service_date = s.service_date and x.kind = 'lead:' || m)
  ), nearest as (
    select distinct on (follow_id, service_date) follow_id, service_date, lead, eta
    from due order by follow_id, service_date, lead
  ), events as (
    select n.follow_id, n.service_date, 'lead' as event, 'lead:' || n.lead as kind,
           (select array_agg('lead:' || d.lead) from due d
            where d.follow_id = n.follow_id and d.service_date = n.service_date) as kinds
    from nearest n
    union all
    select s.follow_id, s.service_date, 'canceled', 'canceled', array['canceled'] from s where s.status = 'canceled'
    union all
    select s.follow_id, s.service_date, 'still', 'still', array['still']
    from s where s.still_min is not null and not s.passed and s.status <> 'canceled'
    union all
    select s.follow_id, s.service_date, 'lost', 'lost', array['lost'] from s where s.status = 'suppressed' and not s.passed
  ), fresh as (
    select e.* from events e
    where not exists (select from public.trip_follow_sent x
                      where x.follow_id = e.follow_id and x.service_date = e.service_date and x.kind = e.kind)
  ), recorded as (
    insert into public.trip_follow_sent (follow_id, service_date, kind)
    select f.follow_id, f.service_date, k from fresh f cross join lateral unnest(f.kinds) k
    on conflict do nothing
    returning follow_id
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'follow_id', f.follow_id, 'service_date', f.service_date, 'event', f.event, 'kinds', to_jsonb(f.kinds),
    'minutes', case f.event
      when 'lead' then greatest(0, floor(extract(epoch from s.eta - at) / 60))::int
      when 'still' then s.still_min end,
    'eta', extract(epoch from s.eta)::bigint, 'scheduled', extract(epoch from s.scheduled)::bigint,
    'realtime', s.status in ('confirmed', 'uncertain') and s.predicted is not null,
    'route', (select r.name from network.route r where r.route_id = s.route_id),
    'stop', (select p.name from network.stop p where p.stop_id = s.stop_id),
    'headsign', s.headsign,
    'tokens', (select jsonb_agg(jsonb_build_object('token', p.token, 'locale', p.locale))
               from public.push_tokens p where p.user_id = s.user_id)
  )), '[]')
  into result
  from fresh f
  join s on s.follow_id = f.follow_id and s.service_date = f.service_date;
  return coalesce(result, '[]');
end $$;

-- Sending failed for every device of the user: take the record back, the next cycle tries again.
create function notify.release(claims jsonb) returns void
language sql security definer set search_path = '' as $$
  delete from public.trip_follow_sent s
  using jsonb_array_elements(claims) c
  where s.follow_id = (c->>'follow_id')::uuid and s.service_date = (c->>'service_date')::date
    and s.kind in (select jsonb_array_elements_text(c->'kinds'))
$$;

-- Tokens FCM reported as no longer valid (app uninstalled, token rotated).
create function notify.drop_tokens(tokens text[]) returns void
language sql security definer set search_path = '' as $$
  delete from public.push_tokens where token = any (tokens)
$$;

-- The poller (and only it) runs the notifier; the app reads its follows with api.my_follows.
revoke all on all functions in schema notify from public, anon, authenticated;
grant usage on schema notify to poller;
grant execute on function notify.claim(timestamptz), notify.release(jsonb), notify.drop_tokens(text[]) to poller;

-- The user's follows with how today's trip is doing (while it is within [-45 min, +2 h] of its time), for the
-- "followed trips" page. Same fields as an arrival: status, time (predicted or scheduled), minutes (realtime only).
create function api.my_follows() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  at timestamptz := now();
begin
  return coalesce((
    with s as (select * from notify._state(at, (select auth.uid())))
    select jsonb_agg(jsonb_build_object(
      'id', f.id, 'stop_id', f.stop_id, 'route_id', f.route_id, 'direction_id', f.direction_id,
      'departure_s', f.departure_s, 'days', to_jsonb(f.days), 'lead_min', to_jsonb(f.lead_min),
      'enabled', f.enabled,
      'today', (
        select jsonb_build_object(
          'status', x.status,
          'time', case when x.status in ('confirmed', 'uncertain') and x.predicted is not null
                       then x.predicted else x.scheduled end,
          'minutes', case when x.status in ('confirmed', 'uncertain') and x.predicted is not null
                          then greatest(0, floor(extract(epoch from x.predicted - at) / 60))::int end,
          'signal', x.signal)
        from s x where x.follow_id = f.id order by x.service_date desc limit 1)
    ) order by f.stop_id, f.route_id, f.departure_s)
    from public.trip_follow f where f.user_id = (select auth.uid())
  ), '[]');
end $$;

revoke all on function api.my_follows() from public, anon;
grant execute on function api.my_follows() to authenticated;

select cron.schedule('cleanup-follows', '23 3 * * *', $$
  delete from public.trip_follow_sent where service_date < current_date - 3;
$$);
