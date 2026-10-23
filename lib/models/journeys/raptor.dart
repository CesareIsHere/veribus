import 'dart:typed_data';

import 'package:veribus/models/journeys/timetable.dart';

/// A place where a journey starts or ends, seen from a stop: the stop and the seconds of walking between them.
typedef StopAccess = ({int stop, int walk});

sealed class JourneyLeg {
  const JourneyLeg({required this.start, required this.end});

  /// Seconds from the timetable's midnight.
  final int start;
  final int end;
}

/// Walking: from the origin place to a stop ([from] null), between two stops, or from a stop to the destination
/// place ([to] null).
class WalkLeg extends JourneyLeg {
  const WalkLeg({required this.from, required this.to, required super.start, required super.end});

  final int? from;
  final int? to;
}

/// On board [trip] of [route], from its stop at position [board] to the one at position [alight]. [start] and [end]
/// include the [delay] the search was given for the trip (seconds, negative when early).
class RideLeg extends JourneyLeg {
  const RideLeg({
    required this.route,
    required this.trip,
    required this.board,
    required this.alight,
    required this.fromStop,
    required this.toStop,
    required super.start,
    required super.end,
    this.delay = 0,
  });

  final int route;
  final int trip;
  final int board;
  final int alight;
  final int fromStop;
  final int toStop;
  final int delay;
}

/// Realtime applied to the timetable for one search: trips that will not run, and trips running late (positive
/// seconds) or early. A delay moves the whole trip: the feed predicts the next stops only, and a trip late at one
/// stop is late at the next ones.
class Realtime {
  const Realtime({this.removed = const {}, this.delays = const {}});

  final Set<int> removed;
  final Map<int, int> delays;

  bool get isEmpty => removed.isEmpty && delays.isEmpty;
}

class Journey {
  Journey(this.legs);

  final List<JourneyLeg> legs;

  /// When to leave the origin place, and when the destination place is reached.
  int get depart => legs.first.start;
  int get arrive => legs.last.end;
  int get rides => legs.whereType<RideLeg>().length;
}

/// RAPTOR (Delling, Pajor, Werneck: "Round-Based Public Transit Routing", 2012): round k finds the earliest arrival
/// at every stop with k rides, scanning each route at most once. The answer is every journey that is not beaten on
/// both arrival time and number of rides ("01:10 with one change, or 00:58 with two").
///
/// Walking links are followed one at a time from the origin stops and after each round, never chained: like RAPTOR,
/// this assumes that two stops linked through a third are also linked directly, nearly true with links of a few
/// hundred metres. [transferSlack] is added before boarding again after a ride: the minimum time to change.
///
/// When walking beats every ride, the answer is a journey with no rides.
class Raptor {
  Raptor(this.timetable, {this.transferSlack = 180});

  final Timetable timetable;
  final int transferSlack;

  static const _never = 0x3fffffff;

  /// The Pareto-optimal journeys leaving at [departure] or later, with at most [maxRides] rides, fewest rides first.
  /// The origins and destinations are stops with the walk to or from the place: usually those within a few hundred
  /// metres.
  ///
  /// Routes in [blockedRoutes] are never boarded (the traveller does not want the metro, or the night buses).
  ///
  /// With [realtime], removed trips are never taken and delayed ones run at their delayed times. Delays can make a
  /// trip overtake another one of its route: the routes they touch are scanned trip by trip instead of searched.
  List<Journey> search({
    required List<StopAccess> origins,
    required List<StopAccess> destinations,
    required int departure,
    int maxRides = 3,
    Realtime realtime = const Realtime(),
    Set<int> blockedRoutes = const {},
  }) {
    final tt = timetable;
    final n = tt.stopCount;
    final delays = realtime.delays;
    final changed = {
      for (final t in [...realtime.removed, ...delays.keys]) tt.tripRoute[t],
    };
    Int32List never() => Int32List(n)..fillRange(0, n, _never);
    // Per round: the earliest arrival at each stop, and how: on board (trip, board and alight positions) or on foot
    // from a stop reached on board in the same round. Round 0 is the walk from the origin.
    final arrival = [for (var k = 0; k <= maxRides; k++) never()];
    final rideTime = [for (var k = 0; k <= maxRides; k++) never()];
    final rideTrip = [for (var k = 0; k <= maxRides; k++) Int32List(n)];
    final rideBoard = [for (var k = 0; k <= maxRides; k++) Uint16List(n)];
    final rideAlight = [for (var k = 0; k <= maxRides; k++) Uint16List(n)];
    final walkTime = [for (var k = 0; k <= maxRides; k++) never()];
    final walkFrom = [for (var k = 0; k <= maxRides; k++) Int32List(n)];
    final accessWalk = Int32List(n);
    final best = never();
    // The earliest boarding time at each stop with the rides of the previous rounds.
    final ready = never();
    final egress = never();
    for (final d in destinations) {
      if (d.walk < egress[d.stop]) egress[d.stop] = d.walk;
    }
    var target = _never;
    var marked = <int>[];
    final isMarked = Uint8List(n);

    void reach(int k, int stop, int time) {
      arrival[k][stop] = time;
      best[stop] = time;
      if (isMarked[stop] == 0) {
        isMarked[stop] = 1;
        marked.add(stop);
      }
      if (egress[stop] != _never && time + egress[stop] < target) target = time + egress[stop];
    }

    for (final o in origins) {
      final t = departure + o.walk;
      if (t < best[o.stop]) {
        accessWalk[o.stop] = o.walk;
        reach(0, o.stop, t);
      }
    }
    for (final p in List.of(marked)) {
      ready[p] = arrival[0][p];
      for (var j = tt.footStart[p]; j < tt.footStart[p + 1]; j++) {
        final q = tt.footTo[j];
        final t = arrival[0][p] + tt.footSeconds[j];
        if (t < best[q]) {
          walkTime[0][q] = t;
          walkFrom[0][q] = p;
          reach(0, q, t);
          ready[q] = t;
        }
      }
    }

    final routeFrom = Int32List(tt.routeCount)..fillRange(0, tt.routeCount, -1);
    for (var k = 1; k <= maxRides && marked.isNotEmpty; k++) {
      final touched = <int>[];
      for (final p in marked) {
        isMarked[p] = 0;
        for (var j = tt.stopRouteStart[p]; j < tt.stopRouteStart[p + 1]; j++) {
          final r = tt.stopRoutes[j];
          final pos = tt.stopRoutePos[j];
          if (routeFrom[r] == -1) {
            touched.add(r);
            routeFrom[r] = pos;
          } else if (pos < routeFrom[r]) {
            routeFrom[r] = pos;
          }
        }
      }
      marked = [];

      final rode = <int>[];
      for (final r in touched) {
        if (blockedRoutes.contains(r)) {
          routeFrom[r] = -1;
          continue;
        }
        var trip = -1;
        var boardPos = 0;
        final length = tt.routeLength(r);
        final live = changed.contains(r);
        for (var i = routeFrom[r]; i < length; i++) {
          final s = tt.routeStop(r, i);
          if (trip >= 0) {
            final t = live ? tt.time(trip, i) + (delays[trip] ?? 0) : tt.time(trip, i);
            if (t < best[s] && t < target) {
              if (rideTime[k][s] == _never) rode.add(s);
              rideTime[k][s] = t;
              rideTrip[k][s] = trip;
              rideBoard[k][s] = boardPos;
              rideAlight[k][s] = i;
              reach(k, s, t);
            }
          }
          final at = ready[s];
          if (at != _never && (trip < 0 || at <= tt.time(trip, i) + (live ? delays[trip] ?? 0 : 0))) {
            final earlier = live ? _firstLiveTrip(r, i, at, realtime) : _firstTrip(r, i, at);
            if (earlier >= 0 && earlier != trip) {
              trip = earlier;
              boardPos = i;
            }
          }
        }
        routeFrom[r] = -1;
      }

      for (final p in rode) {
        for (var j = tt.footStart[p]; j < tt.footStart[p + 1]; j++) {
          final q = tt.footTo[j];
          final t = rideTime[k][p] + tt.footSeconds[j];
          if (t < best[q] && t < target) {
            walkTime[k][q] = t;
            walkFrom[k][q] = p;
            reach(k, q, t);
          }
        }
      }
      for (final s in marked) {
        ready[s] = arrival[k][s] + transferSlack;
      }
    }

    final journeys = <Journey>[];
    var bestArrival = _never;
    for (var k = 0; k <= maxRides; k++) {
      var end = -1;
      var endTime = bestArrival;
      for (final d in destinations) {
        final t = arrival[k][d.stop];
        if (t != _never && t + d.walk < endTime) {
          end = d.stop;
          endTime = t + d.walk;
        }
      }
      if (end < 0) continue;
      bestArrival = endTime;
      final legs = <JourneyLeg>[WalkLeg(from: end, to: null, start: arrival[k][end], end: endTime)];
      var round = k;
      var stop = end;
      while (round > 0) {
        if (walkTime[round][stop] == arrival[round][stop]) {
          final from = walkFrom[round][stop];
          legs.add(WalkLeg(from: from, to: stop, start: rideTime[round][from], end: walkTime[round][stop]));
          stop = from;
        }
        final trip = rideTrip[round][stop];
        final route = tt.tripRoute[trip];
        final board = rideBoard[round][stop];
        final from = tt.routeStop(route, board);
        final delay = delays[trip] ?? 0;
        legs.add(
          RideLeg(
            route: route,
            trip: trip,
            board: board,
            alight: rideAlight[round][stop],
            fromStop: from,
            toStop: stop,
            start: tt.time(trip, board) + delay,
            end: rideTime[round][stop],
            delay: delay,
          ),
        );
        // The boarding time came from the last earlier round that reached the stop.
        do {
          round--;
        } while (arrival[round][from] == _never);
        stop = from;
      }
      if (walkTime[0][stop] == arrival[0][stop]) {
        final from = walkFrom[0][stop];
        legs.add(WalkLeg(from: from, to: stop, start: arrival[0][from], end: walkTime[0][stop]));
        stop = from;
      }
      legs.add(WalkLeg(from: null, to: stop, start: arrival[0][stop] - accessWalk[stop], end: arrival[0][stop]));
      journeys.add(Journey(_leaveLate(legs.reversed.toList())));
    }
    return journeys;
  }

  /// The first trip of route [r] leaving its [i]-th stop at [at] or later, or -1. Trips of a route never overtake
  /// each other (the import splits the routes where they would), so they are sorted at every stop.
  int _firstTrip(int r, int i, int at) {
    final tt = timetable;
    var lo = tt.routeTripStart[r];
    var hi = tt.routeTripStart[r + 1];
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (tt.time(mid, i) < at) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo < tt.routeTripStart[r + 1] ? lo : -1;
  }

  /// The trip of route [r] leaving its [i]-th stop first at [at] or later with [realtime] applied, or -1.
  int _firstLiveTrip(int r, int i, int at, Realtime realtime) {
    final tt = timetable;
    var best = -1;
    var bestTime = _never;
    for (var t = tt.routeTripStart[r]; t < tt.routeTripStart[r + 1]; t++) {
      if (realtime.removed.contains(t)) continue;
      final time = tt.time(t, i) + (realtime.delays[t] ?? 0);
      if (time >= at && time < bestTime) {
        best = t;
        bestTime = time;
      }
    }
    return best;
  }

  /// The search walks to the first stop as soon as possible; the traveller leaves just in time for the first ride:
  /// the walks before it (to a stop, then along a link to another one) are moved so that the last ends when it leaves.
  static List<JourneyLeg> _leaveLate(List<JourneyLeg> legs) {
    final walks = legs.takeWhile((l) => l is WalkLeg).length;
    if (walks == 0 || walks == legs.length || legs[walks] is! RideLeg) return legs;
    var end = legs[walks].start;
    for (var i = walks - 1; i >= 0; i--) {
      final walk = legs[i] as WalkLeg;
      final seconds = walk.end - walk.start;
      legs[i] = WalkLeg(from: walk.from, to: walk.to, start: end - seconds, end: end);
      end -= seconds;
    }
    return legs;
  }
}
