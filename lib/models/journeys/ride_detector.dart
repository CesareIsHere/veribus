import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:veribus/models/journeys/timetable.dart';
import 'package:veribus/models/journeys/timetable_builder.dart';

/// Where the phone was, and when.
typedef Fix = ({LatLng point, DateTime at});

/// A trip the traveller seems to be on: where it is in its route and how far it is from them.
class BoardedTrip {
  const BoardedTrip({
    required this.trip,
    required this.route,
    required this.next,
    required this.meters,
    required this.lateSeconds,
  });

  final int trip;
  final int route;

  /// Position in the route of the next stop of the trip.
  final int next;

  /// Metres between the traveller and the trip, where its timetable puts it.
  final double meters;

  /// Seconds the trip seems to be late (negative when early).
  final int lateSeconds;
}

/// Which trips could the traveller be on? A phone that moves faster than anyone walks, near a trip that its timetable
/// puts there (allowing for a delay) and going the same way, is on that trip. Pure: positions, timetable, clock.
///
/// The trips are by increasing distance. With [moving] the traveller must have been moving at the speed of a vehicle
/// (the automatic detection); without it the position alone counts, for the traveller who says "I am on a bus" while it
/// stands at a stop.
List<BoardedTrip> detectTrips({
  required Timetable timetable,
  required List<Fix> fixes,
  required DateTime now,
  bool moving = true,
  double maxMeters = 120,
  int limit = 4,
}) {
  if (fixes.isEmpty) return const [];
  final last = fixes.last;
  double? heading;
  if (moving) {
    // The fixes of the last minute: far enough, fast enough.
    final recent = fixes.where((f) => now.difference(f.at).inSeconds <= 60).toList();
    if (recent.length < 2) return const [];
    final first = recent.first;
    final seconds = last.at.difference(first.at).inSeconds;
    final distance = meters(first.point.latitude, first.point.longitude, last.point.latitude, last.point.longitude);
    if (seconds < 8 || distance / seconds < _vehicleSpeed || distance < 40) return const [];
    heading = _bearing(first.point, last.point);
  }
  final tt = timetable;
  final nowSeconds = now.difference(tt.midnight).inSeconds;
  final found = <BoardedTrip>[];
  for (var r = 0; r < tt.routeCount; r++) {
    final length = tt.routeLength(r);
    for (var t = tt.routeTripStart[r]; t < tt.routeTripStart[r + 1]; t++) {
      // Only the trips running now, a late one included.
      if (tt.time(t, 0) > nowSeconds + _maxEarly || tt.time(t, length - 1) < nowSeconds - _maxLate) continue;
      BoardedTrip? best;
      for (var late = -_maxEarly; late <= _maxLate; late += _step) {
        final at = nowSeconds - late;
        final i = _segment(tt, t, length, at);
        if (i < 0) continue;
        final from = _stop(tt, r, i);
        final to = _stop(tt, r, i + 1);
        final span = tt.time(t, i + 1) - tt.time(t, i);
        final fraction = span <= 0 ? 0.0 : (at - tt.time(t, i)) / span;
        final point = LatLng(
          from.latitude + (to.latitude - from.latitude) * fraction,
          from.longitude + (to.longitude - from.longitude) * fraction,
        );
        final distance = meters(last.point.latitude, last.point.longitude, point.latitude, point.longitude);
        if (distance > maxMeters || (best != null && distance >= best.meters)) continue;
        if (heading != null && _turn(heading, _bearing(from, to)) > _maxTurn) continue;
        best = BoardedTrip(trip: t, route: r, next: i + 1, meters: distance, lateSeconds: late);
      }
      if (best != null) found.add(best);
    }
  }
  found.sort((a, b) => a.meters.compareTo(b.meters));
  return found.take(limit).toList();
}

/// Sure enough to follow it without asking: the nearest trip is close, and no other line is nearly as close.
BoardedTrip? sureTrip(Timetable timetable, List<BoardedTrip> trips) {
  if (trips.isEmpty || trips.first.meters > _sureMeters) return null;
  final first = trips.first;
  final other = trips.skip(1).where((t) => timetable.routeLine[t.route] != timetable.routeLine[first.route]);
  return other.isNotEmpty && other.first.meters < first.meters + _sureGap ? null : first;
}

/// Faster than anyone walks (m/s): 3 is 11 km/h.
const double _vehicleSpeed = 3;

/// How early or late a trip can be, and the step between the delays tried (seconds).
const int _maxEarly = 240;
const int _maxLate = 900;
const int _step = 60;

/// Heading of the traveller and of the segment of the trip may differ by this much (degrees).
const double _maxTurn = 60;

const double _sureMeters = 70;
const double _sureGap = 50;

LatLng _stop(Timetable tt, int route, int i) {
  final s = tt.routeStop(route, i);
  return LatLng(tt.stopLat[s] / 1e6, tt.stopLon[s] / 1e6);
}

/// The segment of [trip] (between its stop i and i + 1) the timetable says it is on at [at], or -1.
int _segment(Timetable tt, int trip, int length, int at) {
  if (at < tt.time(trip, 0) || at >= tt.time(trip, length - 1)) return -1;
  for (var i = 0; i < length - 1; i++) {
    if (at < tt.time(trip, i + 1)) return i;
  }
  return -1;
}

double _bearing(LatLng a, LatLng b) {
  final dx = (b.longitude - a.longitude) * math.cos((a.latitude + b.latitude) / 2 * math.pi / 180);
  final dy = b.latitude - a.latitude;
  return math.atan2(dx, dy) * 180 / math.pi;
}

double _turn(double a, double b) {
  final d = (a - b).abs() % 360;
  return d > 180 ? 360 - d : d;
}
