-- Atomic swap: network_import becomes network. The api functions are PL/pgSQL and resolve
-- names at every call, so they follow the swap (never use BEGIN ATOMIC bodies there).
\set ON_ERROR_STOP on
begin;
drop schema if exists network cascade;
alter schema network_import rename to network;
grant usage on schema network to poller;
insert into network_meta.version (md5, stops, trips)
values (:'md5', (select count(*) from network.stop), (select count(*) from network.trip))
on conflict (md5) do update set imported_at = now(), stops = excluded.stops, trips = excluded.trips;
commit;
drop schema network_staging cascade;
