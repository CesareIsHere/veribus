"""Walking distances between nearby stops, along the streets (OpenStreetMap, routed by OSRM with the foot profile).

    python3 -I tool/journeys/walking.py <stops.txt> <OSRM url> [radius metres, default 250] > walking.csv

For every stop, the stops within the radius as the crow flies, then the distance on foot to each of them in one OSRM
`table` request. Output: `from_stop,to_stop,metres`, with -1 when OSRM finds no way on foot. The journey timetables
(tool/journeys/build_timetable.dart --walking) use it instead of the straight line × 1.3, and drop the links that are
long on foot: two stops facing each other across the Tiber are 150 m apart and a bridge away.

Run weekly by .github/workflows/walking.yml (tool/journeys/walking.sh). Standard library only.
"""
import csv
import json
import math
import sys
import urllib.request


def metres(a, b):
    x = (b[1] - a[1]) * math.cos(math.radians((a[0] + b[0]) / 2)) * 111320
    y = (b[0] - a[0]) * 110540
    return math.hypot(x, y)


def read_stops(path):
    with open(path, newline='', encoding='utf-8-sig') as f:
        return [(r['stop_id'], float(r['stop_lat']), float(r['stop_lon'])) for r in csv.DictReader(f)]


def neighbours(stops, radius):
    """Pairs (i, [j...]) of stops within `radius` metres, from a grid of cells as wide as the radius."""
    cell_lat = radius / 110540
    cell_lon = radius / 80000  # a degree of longitude is ~83 km at Rome: cells a bit wider than the radius
    cells = {}
    for i, (_, lat, lon) in enumerate(stops):
        cells.setdefault((math.floor(lat / cell_lat), math.floor(lon / cell_lon)), []).append(i)
    for i, (_, lat, lon) in enumerate(stops):
        cy, cx = math.floor(lat / cell_lat), math.floor(lon / cell_lon)
        near = [
            j
            for dy in (-1, 0, 1)
            for dx in (-1, 0, 1)
            for j in cells.get((cy + dy, cx + dx), ())
            if j != i and metres((lat, lon), stops[j][1:]) <= radius
        ]
        if near:
            yield i, sorted(near)


def table(osrm, points):
    """Distances on foot from the first point to the others, None where there is no way."""
    coords = ';'.join(f'{lon:.6f},{lat:.6f}' for lat, lon in points)
    url = f'{osrm}/table/v1/foot/{coords}?sources=0&annotations=distance'
    with urllib.request.urlopen(url, timeout=60) as r:
        body = json.load(r)
    if body.get('code') != 'Ok':
        raise RuntimeError(f'OSRM: {body.get("code")} {body.get("message", "")}')
    return body['distances'][0][1:]


def main():
    stops = read_stops(sys.argv[1])
    osrm = sys.argv[2].rstrip('/')
    radius = float(sys.argv[3]) if len(sys.argv) > 3 else 250
    out = csv.writer(sys.stdout, lineterminator='\n')
    out.writerow(['from_stop', 'to_stop', 'metres'])
    pairs = unreachable = longer = 0
    for i, near in neighbours(stops, radius):
        distances = table(osrm, [stops[i][1:]] + [stops[j][1:] for j in near])
        for j, d in zip(near, distances):
            pairs += 1
            if d is None:
                unreachable += 1
            elif d > 400:
                longer += 1
            out.writerow([stops[i][0], stops[j][0], -1 if d is None else round(d)])
    print(f'{len(stops)} stops, {pairs} pairs within {radius:.0f} m: {unreachable} with no way on foot, '
          f'{longer} longer than 400 m on foot', file=sys.stderr)


if __name__ == '__main__':
    main()
