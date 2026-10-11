-- The poller connects as the `poller` role, not as an owner: every statement it runs (backend/adapters/postgres.ts)
-- must be allowed to that role. Tests run as the owner by default, which is how a missing grant got to production.
-- Nothing here changes data: the statements that write are filtered to match no rows.
set role poller;

select count(*) from live.lease;
update live.lease set owner = 'x', expires_at = now() where name = 'poller' and false;
select * from live.feed_status;
select (select count(*) from live.vehicle)::int, (select count(*) from live.trip_state)::int;
select * from live.vehicle;
select * from live.trip_state;
select md5 from network_meta.version order by imported_at desc limit 1;
select trip_id, route_id, first_seq, last_seq from network.trip
  where trip_id = any(array(select jsonb_array_elements_text('["T1", "T2"]'::jsonb)));
select key, value from config.setting;
update live.feed_status set hash = hash where false;
insert into live.snapshot (feed, feed_ts, hash, bytes, outcome, path) select 'vp', now(), 'h', 1, 'ok', 'p' where false;
delete from live.vehicle where false;
delete from live.trip_state where false;
delete from live.alert where false;
insert into network_meta.route_seen (route_id, date)
  select jsonb_array_elements_text('["R1"]'::jsonb), (now() at time zone 'Europe/Rome')::date on conflict do nothing;
select notify.claim();

reset role;
