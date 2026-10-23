import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:veribus/models/journeys/ride_detector.dart';
import 'package:veribus/models/journeys/timetable_builder.dart';

// Stops 1 km apart on a north-south street, a trip leaving A at 10:00 every 10 minutes between stops.
final _stops = <GtfsStop>[
  for (final (i, id) in ['A', 'B', 'C', 'D'].indexed) (id: id, name: 'Stop $id', lat: 41.9 + i * 0.009, lon: 12.5),
];

int _hm(String hhmm) => int.parse(hhmm.substring(0, 2)) * 3600 + int.parse(hhmm.substring(3)) * 60;

GtfsTrip _trip(String line, List<String> stops, List<String> times, {int direction = 0}) => (
  line: line,
  direction: direction,
  headsign: line,
  stops: stops,
  times: [for (final t in times) _hm(t)],
  previousDay: false,
);

/// The position on the street at [fraction] of the way from A (0) to D (1).
LatLng _on(double fraction) => LatLng(41.9 + fraction * 0.027, 12.5);

DateTime _at(String hhmm, [int seconds = 0]) => DateTime(2026, 10, 20).add(Duration(seconds: _hm(hhmm) + seconds));

/// Fixes every 4 seconds along the street, ending at `toFraction` of the way at `end`.
List<Fix> _drive(DateTime end, double toFraction, {double speed = 8, bool north = true}) {
  final out = <Fix>[];
  final step = speed * 4 / 3000; // fraction of the street per fix
  for (var k = 12; k >= 0; k--) {
    final fraction = north ? toFraction - k * step : toFraction + k * step;
    out.add((point: _on(fraction), at: end.subtract(Duration(seconds: 4 * k))));
  }
  return out;
}

void main() {
  final tt = buildTimetable(
    date: 20261020,
    stops: _stops,
    trips: [
      _trip('64', ['A', 'B', 'C', 'D'], ['10:00', '10:10', '10:20', '10:30']),
      _trip('64', ['A', 'B', 'C', 'D'], ['10:12', '10:22', '10:32', '10:42']),
      _trip('64', ['D', 'C', 'B', 'A'], ['10:00', '10:10', '10:20', '10:30'], direction: 1),
    ],
  );

  test('a phone moving along the line where its timetable puts the trip is on that trip, at the next stop', () {
    // 10:15: halfway between B (10:10) and C (10:20), driving north.
    final now = _at('10:15');
    final trips = detectTrips(timetable: tt, fixes: _drive(now, 0.5), now: now);
    expect(trips, isNotEmpty);
    final best = trips.first;
    expect(tt.stopNames[tt.routeStop(best.route, best.next)], 'Stop C');
    expect(best.meters, lessThan(60));
    expect(tt.routeDirection[best.route], 0);
    expect(sureTrip(tt, trips), isNotNull);
  });

  test('a late trip is found too, with its delay', () {
    // The same place at 10:18: the 10:10-10:20 trip is 3 minutes late.
    final now = _at('10:18');
    final trips = detectTrips(timetable: tt, fixes: _drive(now, 0.5), now: now);
    expect(trips.first.lateSeconds, closeTo(180, 60));
  });

  test('someone walking, standing or going the other way is not on the trip', () {
    final now = _at('10:15');
    // On foot: 1.4 m/s.
    expect(detectTrips(timetable: tt, fixes: _drive(now, 0.5, speed: 1.4), now: now), isEmpty);
    // Standing at a stop: all fixes the same.
    expect(
      detectTrips(
        timetable: tt,
        fixes: [for (var k = 12; k >= 0; k--) (point: _on(0.333), at: now.subtract(Duration(seconds: 4 * k)))],
        now: now,
      ),
      isEmpty,
    );
    // Driving south at the place of the northbound trip, with no southbound trip there at that time.
    final south = detectTrips(timetable: tt, fixes: _drive(now, 0.5, north: false), now: now);
    expect(south.every((t) => tt.routeDirection[t.route] == 1), isTrue);
  });

  test('where the traveller stands counts when they say they are on a bus', () {
    final now = _at('10:15');
    final fixes = [(point: _on(0.5), at: now)];
    expect(detectTrips(timetable: tt, fixes: fixes, now: now), isEmpty);
    expect(detectTrips(timetable: tt, fixes: fixes, now: now, moving: false, maxMeters: 300), isNotEmpty);
  });
}
