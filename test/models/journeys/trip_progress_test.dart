import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:veribus/models/journeys/raptor.dart';
import 'package:veribus/models/journeys/timetable_builder.dart';
import 'package:veribus/models/journeys/trip_progress.dart';

// Stops 1 km apart on a north-south line: A, B, C, D.
final _stops = <GtfsStop>[
  for (final (i, id) in ['A', 'B', 'C', 'D'].indexed) (id: id, name: 'Stop $id', lat: 41.9 + i * 0.009, lon: 12.5),
];
LatLng _at(String stop, {double metres = 0}) {
  final s = _stops.firstWhere((s) => s.id == stop);
  return LatLng(s.lat + metres / 110540, s.lon);
}

void main() {
  final timetable = buildTimetable(
    date: 20261020,
    stops: _stops,
    trips: [
      (
        line: 'X',
        direction: 0,
        headsign: 'X',
        stops: ['A', 'B', 'C', 'D'],
        times: [36000, 36600, 37200, 37800],
        previousDay: false,
      ),
    ],
  );
  final ride = RideLeg(
    route: 0,
    trip: 0,
    board: 0,
    alight: 3,
    fromStop: timetable.stopIds.indexOf('A'),
    toStop: timetable.stopIds.indexOf('D'),
    start: 36000,
    end: 37800,
  );
  final home = _at('D', metres: 300);

  TripView at(LatLng? position, TripState state) =>
      followTrip(timetable: timetable, rides: [ride], destination: home, state: state, position: position);

  test('far from the stop: walking to it, with the distance', () {
    final view = at(_at('A', metres: -400), const TripState());
    expect(view.phase, TripPhase.toStop);
    expect(view.meters, closeTo(400, 20));
  });

  test('at the stop: waiting; the same place without having been there is not "on board"', () {
    final view = at(_at('A', metres: 20), const TripState());
    expect(view.phase, TripPhase.atStop);
    expect(view.state.nearBoard, isTrue);
  });

  test('having been at the stop and then far from it along the route: on board, with the stops left', () {
    var view = at(_at('A', metres: 20), const TripState());
    view = at(_at('B', metres: 30), view.state);
    expect(view.phase, TripPhase.onBoard);
    expect(view.stopsLeft, 2); // B -> C -> D
    view = at(_at('C', metres: 10), view.state);
    expect(view.stopsLeft, 1);
    // The GPS jumping back a stop does not undo what has been passed.
    view = at(_at('B', metres: 10), view.state);
    expect(view.stopsLeft, 1);
  });

  test('walking along the route without having been at the stop is not riding', () {
    final view = at(_at('B', metres: 600), const TripState());
    expect(view.phase, TripPhase.toStop);
  });

  test('at the stop to get off: the ride is done, then the walk to the destination and the arrival', () {
    var view = at(_at('A', metres: 20), const TripState());
    view = at(_at('C', metres: 10), view.state);
    view = at(_at('D', metres: 20), view.state);
    expect(view.phase, TripPhase.toDestination);
    expect(view.ride, isNull);
    view = at(_at('D', metres: 150), view.state);
    expect(view.phase, TripPhase.toDestination);
    view = at(home, view.state);
    expect(view.phase, TripPhase.arrived);
  });

  test('without a position the phase stays what it was', () {
    final view = at(null, const TripState(boarded: true, stopIndex: 1, nearBoard: true));
    expect(view.phase, TripPhase.onBoard);
    expect(view.stopsLeft, 2);
    expect(view.meters, isNull);
  });

  test('a change: after the first ride the next one is waited for', () {
    final second = RideLeg(
      route: 0,
      trip: 0,
      board: 1,
      alight: 3,
      fromStop: timetable.stopIds.indexOf('B'),
      toStop: timetable.stopIds.indexOf('D'),
      start: 36600,
      end: 37800,
    );
    final first = RideLeg(
      route: 0,
      trip: 0,
      board: 0,
      alight: 1,
      fromStop: timetable.stopIds.indexOf('A'),
      toStop: timetable.stopIds.indexOf('B'),
      start: 36000,
      end: 36600,
    );
    TripView step(LatLng p, TripState s) =>
        followTrip(timetable: timetable, rides: [first, second], destination: home, state: s, position: p);
    var view = step(_at('A', metres: 10), const TripState());
    view = step(_at('B', metres: 10), view.state);
    // Got off at B, where the next ride boards right there.
    expect(view.phase, TripPhase.atStop);
    expect(view.state.ride, 1);
    view = step(_at('C', metres: 10), view.state);
    expect(view.phase, TripPhase.onBoard);
    expect(view.stopsLeft, 1);
  });
}
