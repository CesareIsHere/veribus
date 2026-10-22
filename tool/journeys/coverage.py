"""How many evening and night trips home public transport covers, by number of changes (16 Oct 2026 analysis).

    python3 -I tool/journeys/coverage.py <unzipped GTFS dir> [--no-metro] [--rides 3]

From 10 nightlife areas to a 1 km grid within 10 km of the centre (cells with a stop within 600 m, at least 1.5 km
away), at four moments. Walk at most 500 m to the first stop and 600 m from the last, board within 40 minutes, wait
at most 30 minutes at a change, change within 200 m with 3 minutes of slack, straight line x 1.3 at 1.2 m/s.
Scheduled times only (no delays, no cancellations); every cell weighs the same, whatever its population.

The scan is round-based like RAPTOR but goes over every trip: slow (a few minutes) and simple, as a reference.
Results of the GTFS of 16/10/2026 are in Notion ("Percorsi 'Torna a casa': analisi, misure e RAPTOR").
"""
import argparse
import collections
import math

import numpy as np
import pandas as pd

ORIGINS = {
    'Trastevere': (41.8891, 12.4699), "Campo de' Fiori": (41.8956, 12.4722), 'Monti': (41.8955, 12.4925),
    'San Lorenzo': (41.8975, 12.5135), 'Pigneto': (41.8885, 12.5285), 'Testaccio': (41.8775, 12.4760),
    'Ostiense': (41.8710, 12.4800), 'Prati': (41.9070, 12.4610), 'Flaminio': (41.9110, 12.4760),
    'Termini': (41.9010, 12.5010),
}
CENTRE = (41.8933, 12.4829)
WALK = 1.3 / 1.2  # seconds per straight-line metre
MOMENTS = [  # label, service day, next day, departure (seconds from the service day's midnight)
    ('Tue 21:30', '20261020', '20261021', 21.5 * 3600),
    ('Tue 00:30', '20261020', '20261021', 24.5 * 3600),
    ('Fri 22:30', '20261016', '20261017', 22.5 * 3600),
    ('Fri 01:30', '20261016', '20261017', 25.5 * 3600),
]


def dist(lat1, lon1, lat2, lon2):
    x = (lon2 - lon1) * math.cos(math.radians(41.9)) * 111320
    y = (lat2 - lat1) * 110540
    return np.hypot(x, y)


def load(gtfs):
    routes = pd.read_csv(f'{gtfs}/routes.txt', dtype=str)
    routes = routes[routes.route_type.isin(['0', '1', '3'])]
    rtype = dict(zip(routes.route_id, routes.route_type))
    trips = pd.read_csv(f'{gtfs}/trips.txt', dtype=str, usecols=['route_id', 'service_id', 'trip_id'])
    trips = trips[trips.route_id.isin(rtype)]
    cal = pd.read_csv(f'{gtfs}/calendar_dates.txt', dtype=str)
    cal = cal[cal.exception_type == '1']
    stops = pd.read_csv(f'{gtfs}/stops.txt', dtype=str, usecols=['stop_id', 'stop_lat', 'stop_lon'])
    st = pd.read_csv(f'{gtfs}/stop_times.txt', dtype=str,
                     usecols=['trip_id', 'departure_time', 'stop_id', 'stop_sequence'])
    st = st[st.trip_id.isin(set(trips.trip_id))]
    hms = st.departure_time.str.split(':', expand=True).astype(float)
    st['t'] = (hms[0] * 3600 + hms[1] * 60 + hms[2]).astype(int)
    st['seq'] = st.stop_sequence.astype(int)
    st = st.sort_values(['trip_id', 'seq'])
    sid = {s: i for i, s in enumerate(stops.stop_id)}
    by_trip = {tid: (np.array([sid[s] for s in g.stop_id]), g.t.values) for tid, g in st.groupby('trip_id', sort=False)}
    services = collections.defaultdict(set)
    for s, d in zip(cal.service_id, cal.date):
        services[d].add(s)
    return dict(
        lat=stops.stop_lat.astype(float).values, lon=stops.stop_lon.astype(float).values, by_trip=by_trip,
        services=services, metro={t for t, r in zip(trips.trip_id, trips.route_id) if rtype[r] == '1'},
        trip_service=dict(zip(trips.trip_id, trips.service_id)),
    )


def footpaths(lat, lon, radius=200):
    foot = [[] for _ in range(len(lat))]
    for i in range(len(lat)):
        d = dist(lat[i], lon[i], lat, lon)
        for j in np.nonzero(d <= radius)[0]:
            foot[i].append((j, d[j] * WALK))
    return foot


def active(net, day, next_day, metro):
    """Trips of `day` as they are, trips of `next_day` shifted by 24 h (the night after midnight)."""
    out = []
    for tid, (ss, tt) in net['by_trip'].items():
        if not metro and tid in net['metro']:
            continue
        service = net['trip_service'][tid]
        if service in net['services'][day]:
            out.append((ss, tt))
        if service in net['services'][next_day]:
            out.append((ss, tt + 86400))
    return out


def cells(lat, lon):
    out = []
    for dy in range(-10000, 10001, 1000):
        for dx in range(-10000, 10001, 1000):
            if math.hypot(dx, dy) > 10000:
                continue
            clat = CENTRE[0] + dy / 110540
            clon = CENTRE[1] + dx / (111320 * math.cos(math.radians(41.9)))
            d = dist(clat, clon, lat, lon)
            near = np.nonzero(d <= 600)[0]
            if len(near):
                out.append((clat, clon, near, d[near] * WALK))
    return out


def coverage(net, foot, grid, trips, start, rides, max_wait=1800, slack=180):
    trips = [x for x in trips if x[1][-1] >= start and x[1][0] <= start + 3 * 3600]
    lat, lon = net['lat'], net['lon']
    rows = []
    for o_lat, o_lon in ORIGINS.values():
        d = dist(o_lat, o_lon, lat, lon)
        ready = np.full(len(lat), np.inf)
        near = np.nonzero(d <= 500)[0]
        ready[near] = start + d[near] * WALK
        best = np.full(len(lat), np.inf)
        arrivals = []
        for r in range(rides):
            for ss, tt in trips:
                wait_ok = (tt - start <= max_wait + 600) if r == 0 else (tt - ready[ss] <= max_wait)
                ok = (ready[ss] <= tt) & wait_ok
                if ok.any():
                    k = np.argmax(ok)
                    np.minimum.at(best, ss[k + 1:], tt[k + 1:])
            arrivals.append(best.copy())
            ready = np.full(len(lat), np.inf)
            for i in np.nonzero(np.isfinite(best))[0]:
                for j, w in foot[i]:
                    ready[j] = min(ready[j], best[i] + w + slack)
        for c_lat, c_lon, stops, walk in grid:
            if dist(o_lat, o_lon, c_lat, c_lon) < 1500:
                continue  # walking distance: not a transit question
            rows.append([np.min(a[stops] + walk) for a in arrivals])
    minutes = (np.array(rows) - start) / 60
    out = {}
    for cap in (75, 90):
        for r in range(rides):
            out[f'{r} changes <= {cap} min'] = round(float((minutes[:, r] <= cap).mean()), 3)
    out['none within 3 h'] = round(float((~(minutes[:, -1] <= 180)).mean()), 3)
    return out


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('gtfs')
    parser.add_argument('--no-metro', action='store_true')
    parser.add_argument('--rides', type=int, default=3, help='at most this many rides (changes + 1)')
    args = parser.parse_args()
    net = load(args.gtfs)
    foot = footpaths(net['lat'], net['lon'])
    grid = cells(net['lat'], net['lon'])
    for label, day, next_day, start in MOMENTS:
        result = coverage(net, foot, grid, active(net, day, next_day, not args.no_metro), start, args.rides)
        print(label, 'without metro' if args.no_metro else 'with metro', result, flush=True)


if __name__ == '__main__':
    main()
