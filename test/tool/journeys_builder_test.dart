import 'package:flutter_test/flutter_test.dart';
import 'package:veribus/models/journeys/timetable.dart';
import 'package:veribus/models/journeys/timetable_builder.dart';

import '../../tool/journeys/build_timetable.dart';

void main() {
  test('walking links: within the radius only, longer when an end is a metro station', () {
    final tt = buildTimetable(
      date: 20261020,
      stops: [
        (id: 'bus', name: 'Bus stop', lat: 41.9, lon: 12.5),
        (id: 'metro', name: 'Station', lat: 41.9, lon: 12.5 + 100 / 83000),
        (id: 'far', name: 'Far', lat: 41.9 + 300 / 110540, lon: 12.5),
      ],
      trips: [
        (line: 'L', direction: 0, headsign: '', stops: ['bus', 'far'], times: [0, 60], previousDay: false),
        (line: 'MEA', direction: 1, headsign: '', stops: ['metro', 'far'], times: [0, 60], previousDay: false),
      ],
      lines: {'MEA': (name: 'A', type: Timetable.metro)},
    );
    final bus = tt.stopIndex['bus']!;
    final links = {
      for (var j = tt.footStart[bus]; j < tt.footStart[bus + 1]; j++) tt.stopIds[tt.footTo[j]]: tt.footSeconds[j],
    };
    expect(links.keys, ['metro'], reason: '"far" is 300 m away, over the 250 m radius');
    expect(links['metro'], closeTo(100 * 1.3 / 1.2 + 120, 2));
  });

  test('distances along the streets replace the straight line; links long on foot, or with no way, are dropped', () {
    // Three stops 100 m apart as the crow flies: one is across the river (no way on foot), one a 600 m detour.
    final stops = <GtfsStop>[
      (id: 'a', name: 'A', lat: 41.9, lon: 12.5),
      (id: 'b', name: 'B', lat: 41.9, lon: 12.5 + 100 / 83000),
      (id: 'c', name: 'C', lat: 41.9 + 100 / 110540, lon: 12.5),
      (id: 'd', name: 'D', lat: 41.9 - 100 / 110540, lon: 12.5),
    ];
    final tt = buildTimetable(
      date: 20261020,
      stops: stops,
      trips: [
        (
          line: 'L',
          direction: 0,
          headsign: '',
          stops: ['a', 'b', 'c', 'd'],
          times: [0, 60, 120, 180],
          previousDay: false,
        ),
      ],
      walkingMeters: {'a|b': 130, 'a|c': -1, 'a|d': 600},
    );
    final a = tt.stopIndex['a']!;
    final links = {
      for (var j = tt.footStart[a]; j < tt.footStart[a + 1]; j++) tt.stopIds[tt.footTo[j]]: tt.footSeconds[j],
    };
    expect(links, {'b': (130 / 1.2).round()});
    // The other way round was not measured: the straight line × 1.3.
    final c = tt.stopIndex['c']!;
    final back = [for (var j = tt.footStart[c]; j < tt.footStart[c + 1]; j++) tt.stopIds[tt.footTo[j]]];
    expect(back, contains('a'));
  });

  test('names, line types, directions and previous-day trips survive the binary format', () {
    final tt = Timetable.decode(
      buildTimetable(
        date: 20261020,
        stops: [
          (id: 'a', name: 'Termini', lat: 41.9, lon: 12.5),
          (id: 'b', name: 'Vittorio Emanuele', lat: 41.91, lon: 12.5),
        ],
        trips: [
          (line: 'MEA', direction: 1, headsign: 'Anagnina', stops: ['a', 'b'], times: [600, 720], previousDay: true),
          (line: '64', direction: 0, headsign: 'S. Pietro', stops: ['a', 'b'], times: [900, 1200], previousDay: false),
        ],
        lines: {'MEA': (name: lineName('MEA', Timetable.metro), type: Timetable.metro)},
      ).encode(),
    );
    expect(tt.stopNames, ['Termini', 'Vittorio Emanuele']);
    expect([for (var r = 0; r < tt.routeCount; r++) tt.lineNames[tt.routeLine[r]]], unorderedEquals(['A', '64']));
    final metro = tt.lineIds.indexOf('MEA');
    expect(tt.lineTypes[metro], Timetable.metro);
    expect(tt.lineTypes[tt.lineIds.indexOf('64')], Timetable.bus);
    final route = [for (var r = 0; r < tt.routeCount; r++) r].firstWhere((r) => tt.routeLine[r] == metro);
    expect(tt.routeDirection[route], 1);
    expect(tt.routeHeadsign[route], 'Anagnina');
    final trip = tt.routeTripStart[route];
    expect(tt.tripPreviousDay[trip], 1);
    expect(tt.serviceSeconds(trip, 0), 600 + 86400, reason: 'the history counts from its own service day');
    expect(tt.midnight, DateTime(2026, 10, 20));
  });

  test('GTFS fields: quoted commas, doubled quotes, times past midnight, metro names', () {
    expect(splitCsv('05000,"TERMINI (MA-MB-FS)",,41.9'), ['05000', 'TERMINI (MA-MB-FS)', '', '41.9']);
    expect(splitCsv('1,"Piazza ""Venezia"", lato B",x'), ['1', 'Piazza "Venezia", lato B', 'x']);
    expect(parseTime('25:10:30'), 25 * 3600 + 10 * 60 + 30);
    expect(lineName('MEB1', Timetable.metro), 'B1');
    expect(lineName('ME', Timetable.bus), 'ME');
  });
}
