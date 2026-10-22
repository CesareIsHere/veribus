#!/usr/bin/env bash
# API test on the bare supabase/postgres image: migrations, a tiny GTFS generated around "now", api_test.sql.
#
#   docker run -d --name vb-test -e POSTGRES_PASSWORD=postgres -v "$PWD:/repo" supabase/postgres:17.6.1.177 \
#     -c config_file=/etc/postgresql/postgresql.conf
#   docker exec vb-test bash /repo/supabase/tests/run.sh
set -euo pipefail
cd /repo
export DB_URL=postgres://postgres:postgres@localhost:5432/postgres
# Over TCP: the image's init runs a temporary socket-only server (roles already there), then restarts it.
until psql "$DB_URL" -Atc "select 1 from pg_roles where rolname = 'authenticated'" 2>/dev/null | grep -q 1; do
  sleep 1
done

psql -U supabase_admin -d postgres -v ON_ERROR_STOP=1 -q -f supabase/tests/stub_storage.sql
psql -U supabase_admin -d postgres -qc "grant all on storage.buckets, storage.objects to postgres"
for f in supabase/migrations/*.sql; do psql "$DB_URL" -v ON_ERROR_STOP=1 -q -f "$f"; done

# One route, three stops, trips T1..T5 departing from stop A at now + 10, 15, 20, 25, 30 minutes.
# The clock is the database's (the tests compare with now()), read once. In the hour after midnight the trips belong to
# yesterday's service day, with times past 24:00 as in a real feed: the tests move trips up to 50 minutes back, and a
# scheduled time is never before the service day's midnight.
G=$(mktemp -d)
epoch=$(psql "$DB_URL" -Atc "select extract(epoch from now())::bigint")
day=$(TZ=Europe/Rome date -d "@$((epoch - 3600))" +%Y%m%d)
read -r h m today <<< "$(TZ=Europe/Rome date -d "@$epoch" '+%-H %-M %Y%m%d')"
now=$((h * 3600 + m * 60 + (today == day ? 0 : 86400)))
hms() { printf '%02d:%02d:00' $(($1 / 3600)) $(($1 % 3600 / 60)); }
echo "stop_id,stop_name,stop_lat,stop_lon" > "$G/stops.txt"
printf 'A,Alfa,41.90,12.50\nB,Beta,41.91,12.50\nC,Gamma,41.92,12.50\n' >> "$G/stops.txt"
printf 'route_id,agency_id,route_short_name,route_type\nR1,OP1,64,3\nM1,OP1,MA,1\n' > "$G/routes.txt"
echo "shape_id,shape_pt_lat,shape_pt_lon,shape_pt_sequence" > "$G/shapes.txt"
printf 'S1,41.90,12.50,1\nS1,41.92,12.50,2\n' >> "$G/shapes.txt"
echo "service_id,date,exception_type" > "$G/calendar_dates.txt"
echo "WK,$day,1" >> "$G/calendar_dates.txt"
[ "$today" = "$day" ] || echo "WK,$today,1" >> "$G/calendar_dates.txt"  # the import wants service today
echo "LATER,$(TZ=Europe/Rome date -d "@$((epoch + 20 * 86400))" +%Y%m%d),1" >> "$G/calendar_dates.txt"
echo "route_id,service_id,trip_id,trip_headsign,direction_id,shape_id" > "$G/trips.txt"
echo "trip_id,arrival_time,departure_time,stop_id,stop_sequence" > "$G/stop_times.txt"
for i in 1 2 3 4 5; do
  t=$((now + (i + 1) * 300))
  echo "R1,WK,T$i,Gamma,0,S1" >> "$G/trips.txt"
  for s in 1 2 3; do echo "T$i,$(hms $((t + s * 120))),$(hms $((t + s * 120))),$(echo ABC | cut -c$s),$s" >> "$G/stop_times.txt"; done
done
echo "R1,LATER,T9,Gamma,0,S1" >> "$G/trips.txt"  # outside the 7-day window: must not be imported
echo "T9,08:00:00,08:00:00,A,1" >> "$G/stop_times.txt"
GTFS_DIR=$G MD5=test bash backend/static-import/import.sh > /dev/null 2>&1

psql "$DB_URL" -v ON_ERROR_STOP=1 -q -f supabase/tests/api_test.sql
psql "$DB_URL" -v ON_ERROR_STOP=1 -q -f supabase/tests/notify_test.sql
# As supabase_admin: the postgres role of the image may not SET ROLE to the poller.
psql -U supabase_admin -d postgres -v ON_ERROR_STOP=1 -q -f supabase/tests/poller_test.sql > /dev/null
echo "API tests passed"
