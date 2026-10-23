import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:veribus/models/journeys/journey_planner.dart';
import 'package:veribus/models/journeys/raptor.dart';
import 'package:veribus/models/journeys/timetable.dart';
import 'package:veribus/models/journeys/timetable_builder.dart';
import 'package:veribus/models/transit/live.dart';

// Stops 1 km apart on a north-south line; places sit 50 m from a stop.
final _stops = <GtfsStop>[
  for (final (i, id) in ['A', 'B', 'C', 'D'].indexed) (id: id, name: 'Stop $id', lat: 41.9 + i * 0.009, lon: 12.5),
];
LatLng _near(String stop) {
  final s = _stops.firstWhere((s) => s.id == stop);
  return LatLng(s.lat + 50 / 110540, s.lon);
}

int _hm(String hhmm) => int.parse(hhmm.substring(0, 2)) * 3600 + int.parse(hhmm.substring(3)) * 60;
DateTime _at(String hhmm) => DateTime(2026, 10, 20).add(Duration(seconds: _hm(hhmm)));

GtfsTrip _trip(String line, List<String> stops, List<String> times) => (
  line: line,
  direction: 0,
  headsign: line,
  stops: stops,
  times: [for (final t in times) _hm(t)],
  previousDay: false,
);

Timetable _timetable(List<GtfsTrip> trips) => buildTimetable(date: 20261020, stops: _stops, trips: trips);

/// `api.arrivals` with the given arrivals per stop: (line, scheduled hh:mm at the stop, status, predicted hh:mm).
ArrivalsSource _realtime(Map<String, List<(String, String, String, String?)>> byStop, {List<List<String>>? calls}) =>
    (stopIds, lineIds) async {
      calls?.add(stopIds);
      return Arrivals.fromJson({
        'computed_at': _at('09:50').toUtc().toIso8601String(),
        'feed': {'status': 'ok'},
        'stops': [
          for (final id in stopIds)
            {
              'stop_id': id,
              'alerts': <String>[],
              'arrivals': [
                for (final (line, slot, status, predicted) in byStop[id] ?? const <(String, String, String, String?)>[])
                  {
                    'trip_id': '$line-$slot',
                    'route_id': line,
                    'direction_id': 0,
                    'departure_s': _hm(slot),
                    'status': status,
                    'time': predicted == null ? null : _at(predicted).toUtc().toIso8601String(),
                  },
              ],
            },
        ],
        'alerts': <Map<String, dynamic>>[],
        'routes': <Map<String, dynamic>>[],
      });
    };

String _describe(Timetable tt, PlannedJourney p) => p.rides
    .map(
      (r) =>
          '${tt.lineNames[tt.routeLine[r.route]]}@${(tt.time(r.trip, r.board) ~/ 60 % 60).toString().padLeft(2, '0')}',
    )
    .join(' ');

void main() {
  test('boards where the traveller stands, not at an earlier stop of the same trip that calls here later', () async {
    // The trip calls at M, then at G (400 m on), then at D. The traveller is at G: walking back to M to board the same
    // bus three minutes earlier only to ride past G again gets there at the same time, with a walk for nothing.
    final tt = buildTimetable(
      date: 20261020,
      stops: [
        (id: 'M', name: 'Stop M', lat: 41.9000, lon: 12.5),
        (id: 'G', name: 'Stop G', lat: 41.9036, lon: 12.5),
        (id: 'D', name: 'Stop D', lat: 41.9200, lon: 12.5),
      ],
      trips: [
        _trip('64', ['M', 'G', 'D'], ['10:10', '10:13', '10:30']),
      ],
    );
    final planner = JourneyPlanner(tt, _realtime(const {}));
    const from = LatLng(41.9036 + 10 / 110540, 12.5);
    const to = LatLng(41.9200 + 10 / 110540, 12.5);
    final journey = (await planner.plan(from: from, to: to, at: _at('10:00'), options: 1)).first;
    final ride = journey.rides.single;
    expect(tt.stopNames[ride.fromStop], 'Stop G');
    expect(ride.start, _hm('10:13'));
    final walk = journey.journey.legs.first as WalkLeg;
    expect(walk.end - walk.start, lessThan(60));
    // Same arrival as boarding earlier.
    expect(journey.journey.arrive, lessThan(_hm('10:34')));
  });

  test('boards where the traveller stands even when the earlier stop of the trip is reached through a link', () async {
    // Real data of the 769 on Via Ostiense: the trip calls at Matteucci, Mercati Generali and then Garbatella. The
    // traveller stands at Garbatella; Matteucci is beyond the 500 m of the origins and only reached from Mercati
    // Generali along a link between stops: boarding there is a walk back along the line for the same arrival.
    final tt = buildTimetable(
      date: 20261020,
      stops: [
        (id: 'MAT', name: 'OSTIENSE/MATTEUCCI', lat: 41.872955, lon: 12.480215),
        (id: 'MER', name: 'OSTIENSE/MERCATI GENERALI', lat: 41.871443, lon: 12.479912),
        (id: 'GAR', name: 'OSTIENSE/GARBATELLA', lat: 41.867993, lon: 12.479338),
        (id: 'DST', name: 'GROTTA PERFETTA/P. MIRANDOLA', lat: 41.84707, lon: 12.488202),
      ],
      trips: [
        _trip('769', ['MAT', 'MER', 'GAR', 'DST'], ['12:41', '12:42', '12:44', '12:55']),
      ],
    );
    final planner = JourneyPlanner(tt, _realtime(const {}));
    const from = LatLng(41.8680, 12.4794);
    final journey = (await planner.plan(
      from: from,
      to: const LatLng(41.8475, 12.4880),
      at: _at('12:29'),
      options: 1,
    )).first;
    final ride = journey.rides.single;
    expect(tt.stopNames[ride.fromStop], 'OSTIENSE/GARBATELLA');
    expect(ride.start, _hm('12:44'));
    final walked = journey.journey.legs.takeWhile((l) => l is WalkLeg).fold(0, (sum, l) => sum + l.end - l.start);
    expect(walked, lessThan(120));
  });

  test('a canceled trip is left out: the journey takes the next one, and keeps its status', () async {
    final tt = _timetable([
      _trip('64', ['A', 'B', 'C'], ['10:00', '10:10', '10:20']),
      _trip('64', ['A', 'B', 'C'], ['10:12', '10:22', '10:32']),
    ]);
    final planner = JourneyPlanner(
      tt,
      _realtime({
        'A': [('64', '10:00', 'canceled', '10:00'), ('64', '10:12', 'confirmed', '10:13')],
      }),
    );
    final journeys = await planner.plan(from: _near('A'), to: _near('C'), at: _at('09:50'), options: 1);
    final ride = journeys.single.rides.single;
    expect(_describe(tt, journeys.single), '64@12');
    expect(journeys.single.realtimeOf(ride)?.status, ArrivalStatus.confirmed);
    expect(ride.delay, 60, reason: 'predicted a minute late');
    expect(ride.end, _hm('10:33'));
  });

  test('a late first bus misses the change: the later connection is proposed', () async {
    final tt = _timetable([
      _trip('X', ['A', 'B'], ['10:00', '10:10']),
      _trip('Y', ['B', 'C'], ['10:15', '10:25']),
      _trip('Y', ['B', 'C'], ['10:30', '10:40']),
    ]);
    final onTime = await JourneyPlanner(tt, _realtime({})).plan(from: _near('A'), to: _near('C'), at: _at('09:50'));
    expect(_describe(tt, onTime.first), 'X@00 Y@15');
    final late = await JourneyPlanner(
      tt,
      _realtime({
        'A': [('X', '10:00', 'confirmed', '10:05')],
      }),
    ).plan(from: _near('A'), to: _near('C'), at: _at('09:50'));
    expect(
      _describe(tt, late.first),
      'X@00 Y@30',
      reason: 'arriving at 10:15, the 10:15 leaves before the 3-minute change',
    );
  });

  test('a change is proposed only when it saves at least 5 minutes per extra ride', () async {
    List<GtfsTrip> trips(String expressArrival) => [
      _trip('slow', ['A', 'B', 'C', 'D'], ['10:00', '10:20', '10:40', '11:00']),
      _trip('fast', ['A', 'B'], ['10:01', '10:10']),
      _trip('express', ['B', 'D'], ['10:15', expressArrival]),
    ];
    Future<List<String>> plan(String expressArrival) async {
      final tt = _timetable(trips(expressArrival));
      final journeys = await JourneyPlanner(
        tt,
        _realtime({}),
      ).plan(from: _near('A'), to: _near('D'), at: _at('09:55'), options: 1);
      return [for (final j in journeys) _describe(tt, j)];
    }

    expect(await plan('10:58'), ['slow@00'], reason: 'two minutes earlier: not worth a change');
    expect(await plan('10:40'), unorderedEquals(['slow@00', 'fast@01 express@15']));
  });

  test('several options, each with its own first trip, earliest first', () async {
    final tt = _timetable([
      for (final m in ['00', '15', '30', '45']) _trip('64', ['A', 'B'], ['10:$m', '10:${int.parse(m) + 9}']),
    ]);
    final calls = <List<String>>[];
    final journeys = await JourneyPlanner(
      tt,
      _realtime({}, calls: calls),
    ).plan(from: _near('A'), to: _near('B'), at: _at('09:58'));
    expect([for (final j in journeys) _describe(tt, j)], ['64@00', '64@15', '64@30']);
    expect(calls, isNotEmpty, reason: 'the trips of the next hour are asked to the realtime');
  });

  test('the last journey of the night, and none while the service goes on', () {
    final tt = _timetable([
      for (final h in ['22', '23']) _trip('n7', ['A', 'B'], ['$h:10', '$h:20']),
      _trip('n7', ['A', 'B'], ['23:50', '23:59']),
    ]);
    final planner = JourneyPlanner(tt, _realtime({}));
    final last = planner.lastJourney(from: _near('A'), to: _near('B'), at: _at('22:00'))!;
    expect(_describe(tt, last), 'n7@50');
    expect(last.journey.depart, lessThan(_hm('23:50')), reason: 'leave in time to walk to the stop');
    expect(planner.lastJourney(from: _near('A'), to: _near('B'), at: _at('22:00'), horizon: 3600), isNull);
  });

  test('the next trip of the same line after a ride, for a missed change', () async {
    final tt = _timetable([
      _trip('8', ['A', 'B', 'C'], ['10:00', '10:10', '10:20']),
      _trip('8', ['A', 'B', 'C'], ['10:20', '10:30', '10:40']),
      _trip('8', ['B', 'C'], ['10:25', '10:35']),
      _trip('9', ['B', 'C'], ['10:12', '10:22']),
    ]);
    final journey = (await JourneyPlanner(
      tt,
      _realtime({}),
    ).plan(from: _near('B'), to: _near('C'), at: _at('10:05'), options: 1)).single;
    final ride = journey.rides.single;
    expect(_describe(tt, journey), '8@10');
    expect(JourneyPlanner(tt, _realtime({})).nextDeparture(ride), _hm('10:25'), reason: 'a short run of the 8 counts');
  });

  test('no stop near the places: no journey', () async {
    final tt = _timetable([
      _trip('64', ['A', 'B'], ['10:00', '10:10']),
    ]);
    const far = LatLng(42.5, 13);
    expect(await JourneyPlanner(tt, _realtime({})).plan(from: far, to: _near('B'), at: _at('09:00')), isEmpty);
  });

  test('the realtime layer: a removed trip is never taken, a delay moves the times', () {
    final tt = _timetable([
      _trip('64', ['A', 'B'], ['10:00', '10:10']),
      _trip('64', ['A', 'B'], ['10:05', '10:15']),
    ]);
    final raptor = Raptor(tt);
    List<StopAccess> at(String id) => [(stop: tt.stopIndex[id]!, walk: 0)];
    final first = tt.routeTripStart[0];
    final removed = raptor.search(
      origins: at('A'),
      destinations: at('B'),
      departure: _hm('09:59'),
      realtime: Realtime(removed: {first}),
    );
    expect(removed.single.arrive, _hm('10:15'));
    final late = raptor.search(
      origins: at('A'),
      destinations: at('B'),
      departure: _hm('09:59'),
      realtime: Realtime(delays: {first: 600}),
    );
    expect(late.single.arrive, _hm('10:15'), reason: 'the 10:00 now arrives at 10:20: the 10:05 overtakes it');
  });

  test('the metro and the night buses can be left out: the planner takes the slower way that is left', () async {
    final trips = [
      _trip('M', ['A', 'D'], ['10:00', '10:10']),
      _trip('N', ['A', 'D'], ['10:00', '10:15']),
      _trip('B', ['A', 'D'], ['10:02', '10:30']),
    ];
    final timetable = buildTimetable(
      date: 20261020,
      stops: _stops,
      trips: trips,
      lines: {
        'M': (name: 'A', type: Timetable.metro),
        'N': (name: 'n1', type: Timetable.bus),
        'B': (name: '40', type: Timetable.bus),
      },
    );
    final planner = JourneyPlanner(timetable, _realtime(const {}));
    Future<String> fastest(JourneyFilter filter) async {
      final plan = await planner.plan(from: _near('A'), to: _near('D'), at: _at('09:55'), options: 1, filter: filter);
      return _describe(timetable, plan.first);
    }

    expect(await fastest(allTransport), 'A@00');
    expect(await fastest((metro: false, night: true)), 'n1@00');
    expect(await fastest((metro: false, night: false)), '40@02');
    expect(
      planner.lastJourney(from: _near('A'), to: _near('D'), at: _at('09:55'), filter: (metro: false, night: false)),
      isNotNull,
    );
  });
}
