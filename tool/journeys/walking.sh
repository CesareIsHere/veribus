#!/usr/bin/env bash
# Walking distances between nearby stops of Rome, routed on OpenStreetMap (tool/journeys/walking.py).
#
#   bash tool/journeys/walking.sh <out dir>         → <out dir>/walking.csv.gz
#
# Needs Docker, osmium-tool and Python 3. Downloads the central Italy extract (Geofabrik), cuts Rome out of it,
# builds an OSRM foot graph, and asks it for the distances. About 10 minutes on a GitHub runner.
set -euo pipefail
cd "$(dirname "$0")/../.."
OUT=$(mkdir -p "$1" && cd "$1" && pwd)
W=$(mktemp -d)
OSRM=ghcr.io/project-osrm/osrm-backend:v5.27.1
GTFS_URL=${GTFS_URL:-https://romamobilita.it/wp-content/uploads/shared/rome_static_gtfs.zip}

curl -fsSL -o "$W/centro.osm.pbf" https://download.geofabrik.de/europe/italy/centro-latest.osm.pbf
# Rome and its outskirts: the whole bus network fits in this box.
osmium extract --bbox 12.20,41.65,12.90,42.15 -o "$W/rome.osm.pbf" "$W/centro.osm.pbf"
docker run --rm -v "$W:/data" "$OSRM" osrm-extract -p /opt/foot.lua /data/rome.osm.pbf
docker run --rm -v "$W:/data" "$OSRM" osrm-partition /data/rome.osrm
docker run --rm -v "$W:/data" "$OSRM" osrm-customize /data/rome.osrm
docker run -d --name veribus-osrm -p 5000:5000 -v "$W:/data" "$OSRM" \
  osrm-routed --algorithm mld --max-table-size 1000 /data/rome.osrm
trap 'docker rm -f veribus-osrm > /dev/null' EXIT
for _ in $(seq 60); do curl -fs "http://localhost:5000/nearest/v1/foot/12.4964,41.9028" > /dev/null && break; sleep 1; done

curl -fsSL -o "$W/gtfs.zip" "$GTFS_URL"
unzip -q -o "$W/gtfs.zip" stops.txt -d "$W"
python3 -I tool/journeys/walking.py "$W/stops.txt" http://localhost:5000 > "$OUT/walking.csv"
gzip -9 -f "$OUT/walking.csv"
echo "Wrote $OUT/walking.csv.gz"
