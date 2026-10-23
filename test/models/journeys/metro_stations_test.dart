import 'package:flutter_test/flutter_test.dart';
import 'package:veribus/models/journeys/metro_stations.dart';
import 'package:veribus/models/journeys/timetable.dart';
import 'package:veribus/models/journeys/timetable_builder.dart';

int _hm(int h, [int m = 0]) => h * 3600 + m * 60;

void main() {
  // Metro A between TERMINI and BARBERINI, a train every 5 minutes from 10:00 to 11:00 in each direction; a bus at
  // BARBERINI that must not be taken for a station.
  final timetable = buildTimetable(
    date: 20261020,
    stops: [
      (id: 'T1', name: 'Termini', lat: 41.9009, lon: 12.5016),
      (id: 'T2', name: 'TERMINI', lat: 41.9011, lon: 12.5018),
      (id: 'B1', name: 'Barberini', lat: 41.9036, lon: 12.4887),
      (id: 'BUS', name: 'Bus stop', lat: 41.9040, lon: 12.4890),
    ],
    lines: const {'MEA': (name: 'A', type: Timetable.metro), '64': (name: '64', type: Timetable.bus)},
    trips: [
      for (var m = 0; m <= 60; m += 5) ...[
        (
          line: 'MEA',
          direction: 0,
          headsign: 'Battistini',
          stops: ['T1', 'B1'],
          times: [_hm(10, m), _hm(10, m + 3)],
          previousDay: false,
        ),
        (
          line: 'MEA',
          direction: 1,
          headsign: 'Anagnina',
          stops: ['B1', 'T2'],
          times: [_hm(10, m + 1), _hm(10, m + 4)],
          previousDay: false,
        ),
      ],
      (
        line: '64',
        direction: 0,
        headsign: 'Termini',
        stops: ['BUS', 'T1'],
        times: [_hm(10), _hm(10, 9)],
        previousDay: false,
      ),
    ],
  );

  test('stations of the metro only, the platforms of one name in one place, with how often the line passes', () {
    final stations = metroStations(timetable, DateTime(2026, 10, 20, 10));
    expect(stations.map((s) => s.name), ['Barberini', 'Termini']);
    final termini = stations.last;
    expect(termini.lines.map((l) => l.line), ['A']);
    expect(termini.lines.single.everyMinutes, 5);
    // The platforms (41.9009 and 41.9011) are one point between them.
    expect(termini.point.latitude, closeTo(41.9010, 0.0001));
  });

  test('no trains in the next hour: the line is there, the gap is not known', () {
    final stations = metroStations(timetable, DateTime(2026, 10, 20, 15));
    expect(stations.first.lines.single.line, 'A');
    expect(stations.first.lines.single.everyMinutes, isNull);
  });
}
