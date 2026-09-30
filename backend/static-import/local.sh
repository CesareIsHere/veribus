#!/usr/bin/env bash
# Real RSM data in the local Supabase stack (`supabase start`): downloads today's GTFS and runs import.sh inside
# the database container, which has psql, awk, curl and unzip (a Windows host usually has no psql).
#
#   bash backend/static-import/local.sh
set -euo pipefail
export MSYS_NO_PATHCONV=1 # Git Bash: keep container paths as they are
cd "$(dirname "$0")"

project=$(sed -n 's/^project_id = "\(.*\)"/\1/p' ../../supabase/config.toml)
key=$(supabase status -o env | sed -n 's/^SERVICE_ROLE_KEY="\(.*\)"/\1/p')
db=supabase_db_$project

docker exec "$db" rm -rf /tmp/static-import
docker cp . "$db:/tmp/static-import"
docker exec -e DB_URL=postgres://postgres:postgres@127.0.0.1:5432/postgres -e FORCE=1 \
  -e SUPABASE_URL="http://supabase_kong_$project:8000" -e SUPABASE_SERVICE_ROLE_KEY="$key" \
  "$db" bash /tmp/static-import/import.sh
