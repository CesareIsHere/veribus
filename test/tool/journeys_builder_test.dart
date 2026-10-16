import 'package:flutter_test/flutter_test.dart';

import '../../tool/journeys/build_timetable.dart';
import '../../tool/journeys/timetable_builder.dart';

void main() {
  test('walking links: within the radius only, longer when an end is a station', () {
    final tt = buildTimetable(
      date: 20261020,
      stops: [
        (id: 'bus', lat: 41.9, lon: 12.5),
        (id: 'metro', lat: 41.9, lon: 12.5 + 100 / 83000),
        (id: 'far', lat: 41.9 + 300 / 110540, lon: 12.5),
      ],
      trips: [
        (line: 'L', headsign: '', stops: ['bus', 'metro', 'far'], times: [0, 60, 120]),
      ],
      stations: {'metro'},
    );
    final bus = tt.stopIndex['bus']!;
    final links = {
      for (var j = tt.footStart[bus]; j < tt.footStart[bus + 1]; j++) tt.stopIds[tt.footTo[j]]: tt.footSeconds[j],
    };
    expect(links.keys, ['metro'], reason: '"far" is 300 m away, over the 250 m radius');
    expect(links['metro'], closeTo(100 * 1.3 / 1.2 + 120, 2));
  });

  test('GTFS fields: quoted commas, doubled quotes, times past midnight', () {
    expect(splitCsv('05000,"TERMINI (MA-MB-FS)",,41.9'), ['05000', 'TERMINI (MA-MB-FS)', '', '41.9']);
    expect(splitCsv('1,"Piazza ""Venezia"", lato B",x'), ['1', 'Piazza "Venezia", lato B', 'x']);
    expect(parseTime('25:10:30'), 25 * 3600 + 10 * 60 + 30);
  });
}
