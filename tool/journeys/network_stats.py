"""The sizes RAPTOR works with, for one day of an unzipped GTFS (16 Oct 2026 analysis).

    python3 -I tool/journeys/network_stats.py <unzipped GTFS dir> [yyyymmdd]

Trips, stop patterns (RAPTOR routes before splitting), stop times, patterns where a later trip overtakes an earlier
one (they must be split), and how many pairs of stops lie within 200, 300 and 400 m (walking links).
"""
import math
import sys

import numpy as np
import pandas as pd


def main():
    gtfs = sys.argv[1]
    day = sys.argv[2] if len(sys.argv) > 2 else '20261020'
    routes = pd.read_csv(f'{gtfs}/routes.txt', dtype=str)
    routes = routes[routes.route_type.isin(['0', '1', '3'])]
    trips = pd.read_csv(f'{gtfs}/trips.txt', dtype=str, usecols=['route_id', 'service_id', 'trip_id'])
    trips = trips[trips.route_id.isin(set(routes.route_id))]
    cal = pd.read_csv(f'{gtfs}/calendar_dates.txt', dtype=str)
    services = set(cal[(cal.exception_type == '1') & (cal.date == day)].service_id)
    today = set(trips[trips.service_id.isin(services)].trip_id)

    st = pd.read_csv(f'{gtfs}/stop_times.txt', dtype=str,
                     usecols=['trip_id', 'arrival_time', 'departure_time', 'stop_id', 'stop_sequence'])
    st = st[st.trip_id.isin(today)]
    print('arrival different from departure:', round(float((st.arrival_time != st.departure_time).mean()), 4))
    st['seq'] = st.stop_sequence.astype(int)
    st = st.sort_values(['trip_id', 'seq'])
    hms = st.departure_time.str.split(':', expand=True).astype(int)
    st['t'] = hms[0] * 3600 + hms[1] * 60 + hms[2]
    pattern = st.groupby('trip_id').stop_id.agg(tuple)
    times = {k: g.values for k, g in st.groupby('trip_id').t}
    print(day, 'trips', len(pattern), 'patterns', pattern.nunique(), 'stop times', len(st))

    overtaking = 0
    groups = pattern.groupby(pattern)
    for _, g in groups:
        runs = sorted((times[t] for t in g.index), key=lambda a: a[0])
        if any((b < a).any() for a, b in zip(runs, runs[1:])):
            overtaking += 1
    print('patterns where a trip overtakes another:', overtaking, 'of', groups.ngroups)

    stops = pd.read_csv(f'{gtfs}/stops.txt', dtype=str)
    stops = stops[stops.stop_id.isin(set(st.stop_id))]
    x = stops.stop_lon.astype(float).values * math.cos(math.radians(41.9)) * 111320
    y = stops.stop_lat.astype(float).values * 110540
    for radius in (200, 300, 400):
        pairs = sum(int((np.hypot(x - x[i], y - y[i]) <= radius).sum()) - 1 for i in range(len(x)))
        print(f'stops {len(x)}, ordered pairs within {radius} m: {pairs}')


if __name__ == '__main__':
    main()
