# Journeys ("Go home")

The journey planner runs on the phone: RAPTOR over one day of the network, metro included. The analysis behind it
(the problem, the options weighed, the measurements and the limits) is in Notion, *App Bus Roma → Percorsi "Torna a
casa": analisi, misure e RAPTOR*.

| Where | What |
|---|---|
| `lib/models/journeys/timetable.dart` | One service day as RAPTOR scans it, and its compact binary format (`Timetable._version`) |
| `lib/models/journeys/timetable_builder.dart` | Builds a timetable from trips: routes split where trips overtake, walking links |
| `lib/models/journeys/raptor.dart` | The search, with an optional realtime layer (removed and delayed trips) |
| `lib/models/journeys/journey_planner.dart` | Plans with the realtime of `api.arrivals`, filters, options, last journey, next trip |
| `lib/models/journeys/change_reliability.dart` | How often a change worked, from the history of both trips |
| `lib/repositories/journeys/` | Downloads and caches the day's timetable; the mock builds one around Termini |
| `lib/features/journeys/` | Home on the phone, the "Go home" list and the journey page |
| `tool/journeys/build_timetable.dart` | GTFS → one file per day, run by `backend/static-import/import.sh` |
| `tool/journeys/walking.py`, `walking.sh` | Distances on foot between nearby stops (OpenStreetMap + OSRM), weekly in `.github/workflows/walking.yml` |
| `tool/journeys/bench.dart` | Times the search on a real timetable and prints the coverage |
| `tool/journeys/coverage.py`, `network_stats.py` | The measurements of the analysis (Python, numpy + pandas) |

```bash
curl -fsSL -o gtfs.zip https://romamobilita.it/wp-content/uploads/shared/rome_static_gtfs.zip && unzip -q gtfs.zip -d gtfs
dart run tool/journeys/build_timetable.dart gtfs out 20261020 8 [--walking=walking.csv.gz]   # out/2026102x.bin
dart compile exe tool/journeys/bench.dart -o bench && ./bench out/20261020.bin    # AOT, as in a release build
python3 -I tool/journeys/coverage.py gtfs [--no-metro] [--rides 3]
python3 -I tool/journeys/network_stats.py gtfs 20261020
```

## How it works

- **Weekly**: `walking.yml` cuts Rome out of the Geofabrik central Italy extract, builds an OSRM foot graph and
  measures on foot every pair of stops within 250 m as the crow flies; `journeys/walking.csv.gz` goes to Storage.
  Measured on 21/10: 42,096 pairs, all reachable, 2,782 (6.6%) longer than 400 m on foot, so dropped (the river, the
  railways, the big roads). About 2 minutes.
- **Nightly**: the import builds today and the next 7 days, with those distances (a link takes the routed metres at
  1.2 m/s; pairs not measured, such as a new stop, keep the straight line × 1.3), gzips them and uploads them to the `network` bucket as
  `journeys/v<md5>/<yyyymmdd>.bin.gz`, before the swap. A failed build or upload warns and the network import goes on.
- **On the phone**: the timetable of the day is downloaded once and kept in the app support folder. A search walks to
  the stops within 500 m (600 m at home, twice that when there are none), runs RAPTOR with up to 3 rides, asks
  `api.arrivals` for the trips of the next hour it proposes (matched by slot: line and scheduled time at the boarding
  stop), leaves out canceled and suppressed trips, moves late ones and searches again (at most 3 times).
- **Results**: the fastest journey with fewest rides, plus one with more rides only when it saves 5 minutes per extra
  ride; three departures; the last journey when the service ends within four hours.

## Measured (GTFS of 16/10/2026, Tuesday 20/10)

- **Size**: 8,249 stops, 1,458 routes, 40,509 trips, 1.21 M stop times, 41,304 walking links (250 m):
  **3.2 MB, 0.75 MB gzipped** (Sunday 0.57 MB). Eight days build in about 16 s; a day decodes in 12 ms.
- **Speed** (AOT, Xeon 2.1 GHz, 2,903 searches per moment, up to 3 rides): 21:30 p50 2.5 ms, p95 4.0 ms;
  00:30 p50 1.8 ms, p95 3.0 ms. A low-end phone is expected 5–10× slower: still far under 300 ms, to be confirmed on
  a device.
- **Coverage** within 75 minutes with at most 1 / 2 / 3 rides, from 10 nightlife areas to a 1 km grid:
  27% / 74% / 86% at 21:30, 21% / 51% / 55% at 00:30. At night the limit is the network, not the planner.

## Known limits

- Walking from the user to the first stop and from the last stop home is still the straight line × 1.3 (measured on
  the phone, where there is no street graph).
- Walking links are not chained (A→B→C on foot), as RAPTOR assumes them transitively closed: nearly true at 250 m.
- A delay moves the whole trip by the delay predicted at the boarding stop; beyond the next hour times are scheduled.
- No rail (FL, Roma-Lido, Roma-Viterbo): it is not in the RSM feed. The metro has no realtime.
- The "Go home" page needs a timetable for today: without it (import failed) it says so and offers Google Maps.
