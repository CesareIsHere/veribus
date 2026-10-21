import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:veribus/models/journeys/raptor.dart';
import 'package:veribus/models/journeys/timetable.dart';

import '../../../tool/journeys/timetable_builder.dart';

/// Stops on a line 1 km apart (no walking between them), unless placed by [near]: 100 m east of another stop.
List<GtfsStop> _stops(List<String> ids, {Map<String, String> near = const {}}) {
  final out = <GtfsStop>[];
  for (final (i, id) in ids.indexed) {
    final base = near[id];
    final at = base == null ? null : out.firstWhere((s) => s.id == base);
    out.add(
      at == null
          ? (id: id, name: id, lat: 41.9 + i * 0.009, lon: 12.5)
          : (id: id, name: id, lat: at.lat, lon: at.lon + 100 / 83000),
    );
  }
  return out;
}

int _hm(String hhmm) => int.parse(hhmm.substring(0, 2)) * 3600 + int.parse(hhmm.substring(3)) * 60;

GtfsTrip _trip(String line, List<String> stops, List<String> times) => (
  line: line,
  direction: 0,
  headsign: line,
  stops: stops,
  times: [for (final t in times) _hm(t)],
  previousDay: false,
);

/// The legs of a journey as text: "walk>A 64:A-C walk>place".
String _describe(Timetable tt, Journey j) => j.legs
    .map(
      (l) => switch (l) {
        RideLeg() => '${tt.lineIds[tt.routeLine[l.route]]}:${tt.stopIds[l.fromStop]}-${tt.stopIds[l.toStop]}',
        WalkLeg(:final from, :final to) =>
          'walk${from == null ? '' : tt.stopIds[from]}>${to == null ? '' : tt.stopIds[to]}',
      },
    )
    .join(' ');

List<Journey> _search(Timetable tt, String from, String to, String at, {int maxRides = 3, int slack = 180}) =>
    Raptor(tt, transferSlack: slack).search(
      origins: [(stop: tt.stopIndex[from]!, walk: 60)],
      destinations: [(stop: tt.stopIndex[to]!, walk: 120)],
      departure: _hm(at),
      maxRides: maxRides,
    );

void main() {
  group('Raptor', () {
    test('a direct trip: leave just in time, ride, walk to the destination', () {
      final tt = buildTimetable(
        date: 20261020,
        stops: _stops(['A', 'B', 'C']),
        trips: [
          _trip('64', ['A', 'B', 'C'], ['10:00', '10:10', '10:20']),
        ],
      );
      final journeys = _search(tt, 'A', 'C', '09:50');
      expect(journeys, hasLength(1));
      expect(_describe(tt, journeys.single), 'walk>A 64:A-C walkC>');
      expect(journeys.single.depart, _hm('09:59'));
      expect(journeys.single.arrive, _hm('10:22'));
      expect(journeys.single.rides, 1);
    });

    test('a trip already gone is not caught: the next one is', () {
      final tt = buildTimetable(
        date: 20261020,
        stops: _stops(['A', 'B']),
        trips: [
          _trip('64', ['A', 'B'], ['10:00', '10:10']),
          _trip('64', ['A', 'B'], ['10:30', '10:40']),
        ],
      );
      expect(_search(tt, 'A', 'B', '10:00').single.arrive, _hm('10:42'), reason: '1 minute of walking to A');
    });

    test('a change at the same stop needs the transfer slack', () {
      final tt = buildTimetable(
        date: 20261020,
        stops: _stops(['A', 'B', 'C']),
        trips: [
          _trip('64', ['A', 'B'], ['10:00', '10:10']),
          _trip('8', ['B', 'C'], ['10:12', '10:20']),
          _trip('8', ['B', 'C'], ['10:14', '10:22']),
        ],
      );
      final journey = _search(tt, 'A', 'C', '09:55').single;
      expect(_describe(tt, journey), 'walk>A 64:A-B 8:B-C walkC>');
      expect(journey.arrive, _hm('10:24'), reason: 'the 10:12 leaves 2 minutes after arriving: under 3 of slack');
      expect(_search(tt, 'A', 'C', '09:55', slack: 60).single.arrive, _hm('10:22'));
    });

    test('a change on foot to a stop nearby', () {
      final tt = buildTimetable(
        date: 20261020,
        stops: _stops(['A', 'B', 'B2', 'C'], near: {'B2': 'B'}),
        trips: [
          _trip('64', ['A', 'B'], ['10:00', '10:10']),
          _trip('8', ['B2', 'C'], ['10:20', '10:30']),
        ],
      );
      final journey = _search(tt, 'A', 'C', '09:55').single;
      expect(_describe(tt, journey), 'walk>A 64:A-B walkB>B2 8:B2-C walkC>');
    });

    test('every journey not beaten on both arrival and rides, fewest rides first', () {
      final tt = buildTimetable(
        date: 20261020,
        stops: _stops(['A', 'B', 'C', 'D']),
        trips: [
          _trip('slow', ['A', 'B', 'C', 'D'], ['10:00', '10:30', '10:50', '11:10']),
          _trip('fast', ['A', 'B'], ['10:01', '10:10']),
          _trip('express', ['B', 'D'], ['10:15', '10:30']),
        ],
      );
      final journeys = _search(tt, 'A', 'D', '09:55');
      expect(
        [for (final j in journeys) _describe(tt, j)],
        ['walk>A slow:A-D walkD>', 'walk>A fast:A-B express:B-D walkD>'],
      );
      expect(_search(tt, 'A', 'D', '09:55', maxRides: 1).single.rides, 1);
    });

    test('no service: no journey', () {
      final tt = buildTimetable(
        date: 20261020,
        stops: _stops(['A', 'B']),
        trips: [
          _trip('64', ['A', 'B'], ['10:00', '10:10']),
        ],
      );
      expect(_search(tt, 'A', 'B', '10:30'), isEmpty);
      expect(_search(tt, 'B', 'A', '09:00'), isEmpty, reason: 'the line runs the other way');
    });

    test('a trip overtaking an earlier one goes to its own route, and is found', () {
      final tt = buildTimetable(
        date: 20261020,
        stops: _stops(['A', 'B', 'C']),
        trips: [
          _trip('64', ['A', 'B', 'C'], ['10:00', '10:30', '11:00']),
          _trip('64', ['A', 'B', 'C'], ['10:05', '10:15', '10:25']),
        ],
      );
      expect(tt.routeCount, 2);
      expect(_search(tt, 'A', 'C', '09:58').single.arrive, _hm('10:27'));
    });

    test('a timetable read back from its bytes gives the same answers', () {
      final tt = buildTimetable(
        date: 20261020,
        stops: _stops(['A', 'B', 'B2', 'C'], near: {'B2': 'B'}),
        trips: [
          _trip('64', ['A', 'B'], ['10:00', '10:10']),
          _trip('8', ['B2', 'C'], ['10:20', '10:30']),
        ],
      );
      final again = Timetable.decode(tt.encode());
      expect(again.date, 20261020);
      expect(again.stopIds, tt.stopIds);
      expect(again.footTo, tt.footTo);
      expect(again.times, tt.times);
      expect(_describe(again, _search(again, 'A', 'C', '09:55').single), 'walk>A 64:A-B walkB>B2 8:B2-C walkC>');
    });

    test('same earliest arrivals as scanning every trip in every round, on random networks', () {
      for (var seed = 0; seed < 1000; seed++) {
        final random = Random(seed);
        final ids = [for (var i = 0; i < 12; i++) 'S$i'];
        // Clusters of stops: all linked on foot inside a cluster (as RAPTOR assumes), none across clusters.
        final stops = [
          for (final id in ids)
            (
              id: id,
              name: id,
              lat: 41.9 + random.nextInt(4) * 0.02 + random.nextDouble() * 0.0005,
              lon: 12.5 + random.nextDouble() * 0.0005,
            ),
        ];
        final trips = <GtfsTrip>[];
        for (var line = 0; line < 6; line++) {
          final path = (List.of(ids)..shuffle(random)).take(2 + random.nextInt(5)).toList();
          final hops = [for (var i = 1; i < path.length; i++) 60 + random.nextInt(600)];
          for (var trip = 0; trip < 1 + random.nextInt(5); trip++) {
            var t = 36000 + random.nextInt(7200);
            trips.add((
              line: 'L$line',
              direction: 0,
              headsign: '',
              stops: path,
              times: [t, for (final h in hops) t += h],
              previousDay: false,
            ));
          }
        }
        final tt = buildTimetable(date: 20261020, stops: stops, trips: trips);
        final from = random.nextInt(tt.stopCount);
        final to = random.nextInt(tt.stopCount);
        final departure = 36000 + random.nextInt(3600);
        final slack = random.nextInt(300);
        final journeys = Raptor(
          tt,
          transferSlack: slack,
        ).search(origins: [(stop: from, walk: 0)], destinations: [(stop: to, walk: 0)], departure: departure);
        final expected = _bruteForce(tt, from, to, departure, slack, 3);
        for (var k = 0; k <= 3; k++) {
          final got = journeys.where((j) => j.rides <= k).map((j) => j.arrive).fold(1 << 30, min);
          expect(got, expected[k], reason: 'seed $seed, at most $k rides');
        }
        for (final j in journeys) {
          _expectConsistent(tt, j, slack, departure);
        }
      }
    });
  });
}

/// Earliest arrival at [to] with at most k rides, for k = 0..[rounds], by scanning every trip in every round: the
/// definition RAPTOR computes faster.
List<int> _bruteForce(Timetable tt, int from, int to, int departure, int slack, int rounds) {
  const never = 1 << 30;
  var ready = List.filled(tt.stopCount, never)..[from] = departure;
  for (var j = tt.footStart[from]; j < tt.footStart[from + 1]; j++) {
    ready[tt.footTo[j]] = departure + tt.footSeconds[j];
  }
  final best = List.of(ready);
  final out = [best[to]];
  for (var k = 1; k <= rounds; k++) {
    final rode = List.filled(tt.stopCount, never);
    for (var r = 0; r < tt.routeCount; r++) {
      for (var t = tt.routeTripStart[r]; t < tt.routeTripStart[r + 1]; t++) {
        var onBoard = false;
        for (var i = 0; i < tt.routeLength(r); i++) {
          final s = tt.routeStop(r, i);
          if (onBoard) rode[s] = min(rode[s], tt.time(t, i));
          if (ready[s] <= tt.time(t, i)) onBoard = true;
        }
      }
    }
    final reached = List.of(rode);
    for (var s = 0; s < tt.stopCount; s++) {
      if (rode[s] == never) continue;
      for (var j = tt.footStart[s]; j < tt.footStart[s + 1]; j++) {
        reached[tt.footTo[j]] = min(reached[tt.footTo[j]], rode[s] + tt.footSeconds[j]);
      }
    }
    ready = [for (var s = 0; s < tt.stopCount; s++) min(ready[s], reached[s] == never ? never : reached[s] + slack)];
    for (var s = 0; s < tt.stopCount; s++) {
      best[s] = min(best[s], reached[s]);
    }
    out.add(best[to]);
  }
  return out;
}

/// Legs follow each other in time, rides are real trips, changes leave the slack, walks take their link's time.
void _expectConsistent(Timetable tt, Journey j, int slack, int departure) {
  expect(j.depart, greaterThanOrEqualTo(departure));
  JourneyLeg? previous;
  for (final leg in j.legs) {
    expect(leg.end, greaterThanOrEqualTo(leg.start));
    if (previous != null) expect(leg.start, greaterThanOrEqualTo(previous.end));
    if (leg is RideLeg) {
      expect(tt.routeStop(leg.route, leg.board), leg.fromStop);
      expect(tt.routeStop(leg.route, leg.alight), leg.toStop);
      expect(leg.start, tt.time(leg.trip, leg.board));
      expect(leg.end, tt.time(leg.trip, leg.alight));
      if (previous != null && previous is! WalkLeg) expect(leg.start - previous.end, greaterThanOrEqualTo(slack));
    }
    if (leg case WalkLeg(:final int from, :final int to)) {
      final j = [for (var i = tt.footStart[from]; i < tt.footStart[from + 1]; i++) i]
          .firstWhere((i) => tt.footTo[i] == to);
      expect(leg.end - leg.start, tt.footSeconds[j]);
    }
    previous = leg;
  }
}
