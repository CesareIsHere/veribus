#!/usr/bin/env bash
# Nightly import of the RSM static GTFS (RF-80, RF-81).
#
#   DB_URL=postgres://... SUPABASE_URL=https://x.supabase.co SUPABASE_SERVICE_ROLE_KEY=... ./import.sh
#
# DB_URL: session pooler (GitHub runners have no IPv6 for the direct connection).
# GTFS_DIR=<dir> imports an already unzipped feed; FORCE=1 imports even if the md5 is unchanged.
# IN_PLACE=1 drops the active network before building the new one, so the database never holds two of them
# (Supabase free plan, 500 MB): the API is down for about a minute, and if the import fails there is no network
# until the next successful run (it gives up RF-81, "keep the previous version"). Leave it off on Pro.
# Without SUPABASE_URL the network JSON is left in ./network.json instead of Storage.
set -euo pipefail
cd "$(dirname "$0")"

GTFS_URL=${GTFS_URL:-https://romamobilita.it/wp-content/uploads/shared/rome_static_gtfs.zip}
# Supabase cancels long statements (statement_timeout): the import turns it off in every session it opens.
psql() { command psql "$DB_URL" -v ON_ERROR_STOP=1 -q -c "set statement_timeout = 0" "$@"; }

if [ -z "${GTFS_DIR:-}" ]; then
  MD5=$(curl -fsSL "$GTFS_URL.md5" | cut -d' ' -f1)
  LAST=$(psql -Atc "select md5 from network_meta.version order by imported_at desc limit 1")
  if [ "$MD5" = "$LAST" ] && [ -z "${FORCE:-}" ]; then echo "GTFS unchanged ($MD5)"; exit 0; fi
  GTFS_DIR=$(mktemp -d)
  curl -fsSL -o "$GTFS_DIR/gtfs.zip" "$GTFS_URL"
  unzip -q "$GTFS_DIR/gtfs.zip" -d "$GTFS_DIR"
else
  MD5=${MD5:-$(cat "$GTFS_DIR"/*.txt | md5sum | cut -d' ' -f1)}
fi
echo "Importing $MD5"

# Raw staging for the small files: one text column per CSV header field, so column order never matters.
{
  echo "drop schema if exists network_staging cascade; create schema network_staging;"
  for f in "$GTFS_DIR"/*.txt; do
    [ "$(basename "$f")" = stop_times.txt ] && continue
    t=$(basename "$f" .txt)
    cols=$(head -1 "$f" | tr -d '\r' | sed 's/^\xEF\xBB\xBF//; s/,/" text, "/g')
    echo "create table network_staging.\"$t\" (\"$cols\" text);"
    echo "\\copy network_staging.\"$t\" from '$f' with (format csv, header true)"
  done
  echo "\\i keep.sql"
} | psql -f -
KEEP=$(mktemp)
psql -Atc "copy network_staging.keep to stdout" > "$KEEP"

if [ -n "${IN_PLACE:-}" ]; then psql -c "drop schema if exists network cascade"; fi
# stop_times (5 million rows, most of the space) streams filtered and typed straight into its final table.
psql -c "drop schema if exists network_import cascade; create schema network_import;
         create table network_import.stop_time (trip_id text, seq int, stop_id text, departure_s int);"
awk -f stop_times.awk "$KEEP" "$GTFS_DIR/stop_times.txt" | psql -c "\\copy network_import.stop_time from stdin with (format csv)"
psql -f transform.sql

# The file goes up before the swap: the app never sees a version it cannot download.
psql -At -v md5="$MD5" -f export.sql > network.json
if [ -n "${SUPABASE_URL:-}" ]; then
  curl -fsS -X POST "$SUPABASE_URL/storage/v1/object/network/v$MD5.json" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" -H "Content-Type: application/json" \
    -H "Cache-Control: max-age=31536000" -H "x-upsert: true" --data-binary @network.json > /dev/null
  rm network.json
fi

psql -v md5="$MD5" -f swap.sql
echo "Active: $MD5"
