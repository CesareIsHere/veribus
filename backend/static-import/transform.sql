-- network_staging (raw CSV) -> network_import (filtered, typed). Run by import.sh.
-- Keeps bus (3) and tram (0) of every agency: the realtime feeds cover all of them
-- (measured 26/09: Atac, TROIANI, BIS, SAP and TUSCIA all have vehicles). Metro and rail are out.
\set ON_ERROR_STOP on

do $$
declare f text;
begin
  foreach f in array array['stops', 'routes', 'trips', 'stop_times', 'shapes', 'calendar_dates'] loop
    if to_regclass('network_staging.' || f) is null then raise exception 'Incomplete GTFS: missing %.txt', f; end if;
  end loop;
end $$;

drop schema if exists network_import cascade;
create schema network_import;

create function network_import.seconds(t text) returns int immutable language sql as $$
  select split_part(t, ':', 1)::int * 3600 + split_part(t, ':', 2)::int * 60 + split_part(t, ':', 3)::int
$$;

create table network_import.route as
select route_id, route_short_name as name, case route_type when '0' then 'tram' else 'bus' end as kind,
       route_short_name like 'n%' as night, agency_id as agency
from network_staging.routes where route_type in ('0', '3');
alter table network_import.route add primary key (route_id);

-- Trips without times are dropped, as Roma mobile does.
create table network_import.stop_time as
select st.trip_id, st.stop_sequence::int as seq, st.stop_id,
       network_import.seconds(coalesce(nullif(st.arrival_time, ''), st.departure_time)) as arrival_s,
       network_import.seconds(coalesce(nullif(st.departure_time, ''), st.arrival_time)) as departure_s
from network_staging.stop_times st
join network_staging.trips t using (trip_id)
join network_import.route r on r.route_id = t.route_id
where coalesce(nullif(st.departure_time, ''), st.arrival_time) <> '';
alter table network_import.stop_time add primary key (trip_id, seq);
create index on network_import.stop_time (stop_id, departure_s);

create table network_import.trip as
select t.trip_id, t.route_id, t.direction_id::int as direction_id, t.service_id, t.trip_headsign as headsign,
       t.shape_id, s.first_seq, s.last_seq, s.stop_count
from network_staging.trips t
join (select trip_id, min(seq) as first_seq, max(seq) as last_seq, count(*)::int as stop_count
      from network_import.stop_time group by trip_id) s using (trip_id);
alter table network_import.trip add primary key (trip_id);
create index on network_import.trip (route_id, direction_id);

create table network_import.stop as
select stop_id, stop_name as name, stop_lat::float8 as lat, stop_lon::float8 as lon
from network_staging.stops s
where exists (select from network_import.stop_time st where st.stop_id = s.stop_id);
alter table network_import.stop add primary key (stop_id);

-- No calendar.txt in this feed (measured): service days come only from calendar_dates.
-- ponytail: exception_type 2 is ignored; handle it if a calendar.txt ever shows up.
create table network_import.service_day as
select distinct service_id, to_date(date, 'YYYYMMDD') as date
from network_staging.calendar_dates where exception_type = '1';
alter table network_import.service_day add primary key (date, service_id);

-- Main path per route and direction: the stop pattern with most trips (spec, section 15).
create table network_import.route_path as
with pattern as (
  select t.route_id, t.direction_id, t.headsign, t.shape_id, array_agg(st.stop_id order by st.seq) as stop_ids
  from network_import.trip t join network_import.stop_time st using (trip_id)
  group by t.trip_id, t.route_id, t.direction_id, t.headsign, t.shape_id
), ranked as (
  select route_id, direction_id, stop_ids,
         mode() within group (order by headsign) as headsign,
         mode() within group (order by shape_id) as shape_id,
         row_number() over (partition by route_id, direction_id order by count(*) desc) as rn
  from pattern group by route_id, direction_id, stop_ids
)
select r.route_id, r.direction_id, r.headsign, r.stop_ids,
       (select jsonb_agg(jsonb_build_array(round(s.shape_pt_lat::numeric, 5), round(s.shape_pt_lon::numeric, 5))
                         order by s.shape_pt_sequence::int)
        from network_staging.shapes s where s.shape_id = r.shape_id) as shape
from ranked r where rn = 1;
alter table network_import.route_path add primary key (route_id, direction_id);

-- Sanity checks (RF-81). A failure aborts the import and keeps the active version.
do $$
declare
  n_stops int := (select count(*) from network_import.stop);
  n_trips int := (select count(*) from network_import.trip);
  prev network_meta.version;
begin
  if not exists (select from network_import.service_day where date = (now() at time zone 'Europe/Rome')::date) then
    raise exception 'No service today';
  end if;
  select * into prev from network_meta.version order by imported_at desc limit 1;
  if prev is not null and (n_stops < prev.stops * 0.8 or n_trips < prev.trips * 0.8) then
    raise exception 'Network collapsed: % stops (was %), % trips (was %)', n_stops, prev.stops, n_trips, prev.trips;
  end if;
end $$;

do $$
declare t text;
begin
  for t in select tablename from pg_tables where schemaname = 'network_import' loop
    execute format('alter table network_import.%I enable row level security', t);
    execute format('create policy poller on network_import.%I for select to poller using (true)', t);
    execute format('grant select on network_import.%I to poller', t);
  end loop;
end $$;
