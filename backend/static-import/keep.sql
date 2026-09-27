-- Trips worth importing: bus (3) and tram (0) with service from yesterday to 7 days ahead. Yesterday's trips
-- (`late`) matter only after midnight: stop_times.awk drops their earlier stops. Trips repeat weekly, so a month
-- would keep the same rows as a week (measured 27/09: 3.34 M stop times either way, 4.86 M for the whole feed).
\set ON_ERROR_STOP on

do $$
declare f text;
begin
  foreach f in array array['stops', 'routes', 'trips', 'shapes', 'calendar_dates'] loop
    if to_regclass('network_staging.' || f) is null then raise exception 'Incomplete GTFS: missing %.txt', f; end if;
  end loop;
end $$;

create table network_staging.keep as
select t.trip_id, max(c.day) = -1 as late
from network_staging.trips t
join network_staging.routes r using (route_id)
join (
  select service_id, to_date(date, 'YYYYMMDD') - (now() at time zone 'Europe/Rome')::date as day
  from network_staging.calendar_dates where exception_type = '1'
) c on c.service_id = t.service_id and c.day between -1 and 7
where r.route_type in ('0', '3')
group by t.trip_id;
