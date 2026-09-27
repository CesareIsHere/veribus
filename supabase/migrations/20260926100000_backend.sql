-- Realtime backend (README, "Backend"):
--   network       GTFS network, rebuilt and swapped by backend/static-import (tables are created there)
--   network_meta  imported versions and routes seen in realtime (outside the swap)
--   live          realtime state written by the poller
--   config        thresholds read by poller and api at every call (RNF-06)
-- Only the `api` schema is exposed; tables here have RLS on and are reachable only through it.

create schema if not exists network;
create schema network_meta;
create schema live;
create schema config;

create table network_meta.version (
  md5 text primary key,
  imported_at timestamptz not null default now(),
  stops int not null,
  trips int not null
);

-- One row per route and day with at least one tracked vehicle (RF-35).
create table network_meta.route_seen (
  route_id text not null,
  date date not null,
  primary key (route_id, date)
);

create table live.feed_status (
  feed text primary key check (feed in ('vp', 'tu', 'sa')),
  last_modified text,
  hash text,
  feed_ts timestamptz,
  ok_at timestamptz,
  error text,
  error_at timestamptz
);
insert into live.feed_status (feed) values ('vp'), ('tu'), ('sa');

create table live.vehicle (
  vehicle_id text primary key,
  label text,
  trip_id text,
  route_id text,
  lat double precision not null,
  lon double precision not null,
  gps_at timestamptz not null,
  seq int,
  stop_id text,
  -- Where and since when the vehicle has been standing still (S3).
  still_lat double precision,
  still_lon double precision,
  still_since timestamptz
);
create index on live.vehicle (route_id);

-- One row per trip seen in realtime; no row means "scheduled".
-- Predictions per stop are two parallel arrays (stop_sequence, epoch seconds).
create table live.trip_state (
  trip_id text primary key,
  route_id text,
  vehicle_id text,
  status text not null check (status in ('confirmed', 'uncertain', 'canceled', 'suppressed')),
  signal jsonb,
  pred_seq int[] not null default '{}',
  pred_ts bigint[] not null default '{}',
  last_seq int,
  seen_at timestamptz,
  suppressed_at timestamptz
);

create table live.alert (
  alert_id text primary key,
  severity smallint not null,
  periods jsonb not null default '[]',
  title text,
  body text,
  route_ids text[] not null default '{}',
  stop_ids text[] not null default '{}',
  general boolean not null default false
);

create table live.snapshot (
  id bigint generated always as identity primary key,
  feed text not null,
  fetched_at timestamptz not null default now(),
  feed_ts timestamptz,
  hash text,
  bytes int,
  outcome text not null,
  path text
);
create index on live.snapshot (feed, fetched_at);

create table live.lease (
  name text primary key,
  owner text,
  expires_at timestamptz not null default '-infinity'
);
insert into live.lease (name) values ('poller');

create table config.setting (
  key text primary key,
  value jsonb not null
);
insert into config.setting (key, value) values
  ('s2_min', '5'),
  ('s3_meters', '30'),
  ('s3_min', '5'),
  ('s4_min', '2'),
  ('s6_min', '3'),
  ('rf60_min', '10'),
  ('approx_min', '{"peak": 6, "off_peak": 10}'),
  ('peak_hours', '[["07:00", "09:30"], ["17:00", "19:30"]]'),
  ('suppressed_min', '5'),
  ('completed_ratio', '0.9'),
  ('no_realtime_days', '3'),
  ('min_app_version', '"0.1.0"'),  -- the pubspec version the first release ships with
  -- Map tiles stay configurable until the provider is chosen (spec, section 11).
  ('tile_url', '"https://tile.openstreetmap.org/{z}/{x}/{y}.png"');

create function config.get(k text) returns jsonb
language sql stable set search_path = '' as $$
  select value from config.setting where key = k
$$;

-- The poller writes only realtime state (least privilege, spec section 11).
-- Enable it with: alter role poller with login password '...';
-- Read access to `network` is granted by the import at every swap.
do $$ begin
  if not exists (select from pg_roles where rolname = 'poller') then create role poller nologin; end if;
end $$;
grant usage on schema network, network_meta, live, config to poller;
grant select on all tables in schema config to poller;
grant select, insert, update, delete on all tables in schema live to poller;
grant select, insert, update on network_meta.route_seen to poller;
grant usage on all sequences in schema live to poller;

do $$
declare t record;
begin
  for t in select schemaname, tablename from pg_tables where schemaname in ('network_meta', 'live', 'config') loop
    execute format('alter table %I.%I enable row level security', t.schemaname, t.tablename);
    execute format('create policy poller on %I.%I to poller using (true) with check (true)', t.schemaname, t.tablename);
  end loop;
end $$;

-- Storage: network data for the app (public) and the raw snapshot archive (private).
insert into storage.buckets (id, name, public) values ('network', 'network', true), ('archive', 'archive', false)
on conflict (id) do nothing;
