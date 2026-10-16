# Journeys ("Torna a casa") — prototype tools

Tools for the journey planner prototype: RAPTOR on the phone over one day of the network. The analysis behind it
(the problem, the options weighed, the measurements and what RAPTOR does not solve) is in Notion, *App Bus Roma →
Percorsi "Torna a casa": analisi, misure e RAPTOR*.

The engine lives in the app: `lib/models/journeys/timetable.dart` (the compact timetable of a day and its binary
format) and `lib/models/journeys/raptor.dart` (the search). Tests: `test/models/journeys/`, `test/tool/journeys_builder_test.dart`.

| Script | What it does |
|---|---|
| `build_timetable.dart` | Unzipped GTFS + day → the binary timetable the phone would download |
| `bench.dart` | Times the search on a real timetable, 10 nightlife areas × a 1 km grid, and prints the coverage |
| `coverage.py` | Reference measure of coverage by number of changes, scanning every trip (slow, simple) |
| `network_stats.py` | Trips, patterns, overtaking trips and stop pairs within walking distance |

```bash
curl -fsSL -o gtfs.zip https://romamobilita.it/wp-content/uploads/shared/rome_static_gtfs.zip && unzip -q gtfs.zip -d gtfs
dart run tool/journeys/build_timetable.dart gtfs 20261020 tt.bin
dart compile exe tool/journeys/bench.dart -o bench && ./bench tt.bin     # AOT, as in a release build
python3 -I tool/journeys/coverage.py gtfs [--no-metro] [--rides 3]       # needs numpy and pandas
python3 -I tool/journeys/network_stats.py gtfs 20261020
```

## Prototype results (GTFS of 16/10/2026, Tuesday 20/10)

- **Size**: 8,249 stops, 1,059 routes (982 stop patterns, split where trips overtake and with the previous night's
  trips past midnight), 39,392 trips, 1.19 M stop times, 41,304 walking links (250 m): **2.93 MB, 0.68 MB gzipped**.
  Built in 16 s; decoded on the phone side in 10 ms.
- **Speed** (AOT, Xeon 2.1 GHz, 2,903 searches per moment, up to 3 rides): 21:30 p50 2.2 ms, p95 3.5 ms, max 13.5 ms;
  00:30 p50 1.6 ms, p95 2.7 ms. A low-end phone is expected 5–10× slower: still far under the 300 ms target, to be
  confirmed on a device.
- **Coverage** within 75 minutes with at most 1 / 2 / 3 rides: 27% / 74% / 86% at 21:30, 21% / 51% / 55% at 00:30.
  Close to `coverage.py` (which also caps the wait at a change at 30 minutes, so it finds a little less).

## Known limits of the prototype

- Walking is a straight line × 1.3: across the Tiber or a railway it can be badly wrong. Real walking distances from
  OpenStreetMap, computed once per night for the pairs of stops within the radius, are the planned fix.
- Walking links are not chained (A→B→C on foot), as RAPTOR assumes they are transitively closed: nearly true at 250 m.
- Scheduled times only: realtime delays and cancellations are not applied yet. With delays, trips can overtake each
  other inside a route, so the binary search for the first trip must become a scan on the routes with delays.
- Results are every journey not beaten on arrival and number of rides: filtering out odd ones (a change to gain a
  minute, a 35-minute wait at night) and the reliability of a change (from `history.trip_run`) are still to do.
- The timetable is built from the GTFS here; in production the nightly import will produce it next to the network file.
