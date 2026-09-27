#!/usr/bin/env bash
# Nightly import of the RSM static GTFS (RF-80, RF-81).
#
#   DB_URL=postgres://... SUPABASE_URL=https://x.supabase.co SUPABASE_SERVICE_ROLE_KEY=... ./import.sh
#
# DB_URL: session pooler (GitHub runners have no IPv6 for the direct connection).
# GTFS_DIR=<dir> imports an already unzipped feed; FORCE=1 imports even if the md5 is unchanged.
# Without SUPABASE_URL the network JSON is left in ./network.json instead of Storage.
set -euo pipefail
cd "$(dirname "$0")"

GTFS_URL=${GTFS_URL:-https://romamobilita.it/wp-content/uploads/shared/rome_static_gtfs.zip}
psql() { command psql "$DB_URL" -v ON_ERROR_STOP=1 -q "$@"; }

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

# Raw staging: one text column per CSV header field, so column order never matters.
{
  echo "drop schema if exists network_staging cascade; create schema network_staging;"
  for f in "$GTFS_DIR"/*.txt; do
    t=$(basename "$f" .txt)
    cols=$(head -1 "$f" | tr -d '\r' | sed 's/^\xEF\xBB\xBF//; s/,/" text, "/g')
    echo "create table network_staging.\"$t\" (\"$cols\" text);"
    echo "\\copy network_staging.\"$t\" from '$f' with (format csv, header true)"
  done
} | psql

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
