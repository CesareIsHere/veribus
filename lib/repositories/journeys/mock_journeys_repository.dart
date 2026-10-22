import 'package:veribus/models/journeys/timetable.dart';
import 'package:veribus/models/journeys/timetable_builder.dart';
import 'package:veribus/models/transit/network.dart';
import 'package:veribus/repositories/journeys/i_journeys_repository.dart';
import 'package:veribus/repositories/transit/mock_transit_repository.dart';

/// A timetable for the demo stops around Termini, plus four stations of metro A. Built around now so that some trips
/// meet the mock arrivals: from TERMINI the 64 is confirmed, the 170 suppressed and the 40 canceled (the planner
/// must leave the last two out).
class MockJourneysRepository implements IJourneysRepository {
  // Line, direction, headsign, stops, first trip in minutes from now at the first stop, minutes between trips.
  static const _routes = <(String, int, String, List<String>, int, int)>[
    ('64', 1, 'P.ZA STAZIONE S. PIETRO (FL)', ['05000', '70102', '70103', '70100', '70001'], 4, 10),
    ('64', 0, 'TERMINI (MA-MB-FS)', ['70001', '70100', '70103', '70102', '05000'], 6, 10),
    ('170', 1, 'AGRICOLTURA', ['05000', '70102', '70103', '70100', '70001'], 9, 15),
    ('170', 0, 'TERMINI (MA-MB-FS)', ['70001', '70100', '70103', '70102', '05000'], 3, 15),
    ('40', 1, 'BORGO S. ANGELO', ['05000', '70102', '70100', '70001'], 18, 12),
    ('40', 0, 'TERMINI (MA-MB-FS)', ['70001', '70100', '70102', '05000'], 8, 12),
    ('75', 1, 'POERIO/MARINO', ['76301', '74902', '74901'], 5, 12),
    ('75', 0, 'INDIPENDENZA', ['74901', '74902', '76301'], 11, 12),
    ('8BUS', 1, 'GIANICOLENSE/CASALETTO', ['76301', '70103', '70001'], 12, 15),
    ('n11', 1, 'GROTTE CELONI (MC)', ['74902', '74901', '70001'], 20, 30),
    ('MEA', 0, 'Battistini', ['MA-VE', 'MA-TE', 'MA-RE', 'MA-BA', 'MA-SP'], 2, 5),
    ('MEA', 1, 'Anagnina', ['MA-SP', 'MA-BA', 'MA-RE', 'MA-TE', 'MA-VE'], 3, 5),
  ];

  static const _stations = <GtfsStop>[
    (id: 'MA-TE', name: 'Termini', lat: 41.90097, lon: 12.49987),
    (id: 'MA-RE', name: 'Repubblica', lat: 41.90255, lon: 12.49624),
    (id: 'MA-BA', name: 'Barberini', lat: 41.90369, lon: 12.48858),
    (id: 'MA-SP', name: 'Spagna', lat: 41.90650, lon: 12.48260),
    (id: 'MA-VE', name: 'Vittorio Emanuele', lat: 41.89450, lon: 12.50426),
  ];

  @override
  Future<Timetable?> timetable(NetworkInfo info, DateTime day) async {
    final now = MockTransitRepository.mockMinute();
    final midnight = DateTime(day.year, day.month, day.day);
    final nowSeconds = now.difference(midnight).inSeconds;
    final trips = <GtfsTrip>[];
    for (final (line, direction, headsign, stops, first, every) in _routes) {
      final hop = line == 'MEA' ? 120 : 180; // seconds between two stops
      // Trips every few minutes from three hours before now to three hours after, on the same minutes as the mock
      // arrivals at the first stop.
      for (var start = nowSeconds + first * 60 - 3 * 3600; start < nowSeconds + 3 * 3600; start += every * 60) {
        if (start < 0) continue;
        trips.add((
          line: line,
          direction: direction,
          headsign: headsign,
          stops: stops,
          times: [for (var i = 0; i < stops.length; i++) start + i * hop],
          previousDay: false,
        ));
      }
    }
    return buildTimetable(
      date: day.year * 10000 + day.month * 100 + day.day,
      stops: [
        for (final s in MockTransitRepository.demoStops)
          (id: s[0] as String, name: s[1] as String, lat: s[2] as double, lon: s[3] as double),
        ..._stations,
      ],
      trips: trips,
      lines: const {'MEA': (name: 'A', type: Timetable.metro)},
    );
  }
}
