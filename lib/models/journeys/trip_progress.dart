import 'package:latlong2/latlong.dart';
import 'package:veribus/models/journeys/raptor.dart';
import 'package:veribus/models/journeys/timetable.dart';

/// Where the traveller is in a journey they follow step by step.
enum TripPhase {
  /// Walking to the stop of the first ride.
  toStop,

  /// At the stop, waiting for the bus.
  atStop,

  /// On a vehicle, getting closer to the stop to get off.
  onBoard,

  /// Got off one ride, on the way to the next one.
  changing,

  /// Got off the last ride, walking to the destination.
  toDestination,
  arrived,
}

/// What the tracker remembers between two positions: the position alone cannot tell walking along a bus line from
/// riding on it, so being at the stop and then leaving it is what means "on board".
class TripState {
  const TripState({this.ride = 0, this.nearBoard = false, this.boarded = false, this.stopIndex});

  /// The ride being done or waited for.
  final int ride;

  /// The traveller has been at the boarding stop of [ride].
  final bool nearBoard;
  final bool boarded;

  /// How far along [ride] the vehicle is: the position of its last stop passed in the route.
  final int? stopIndex;

  TripState copyWith({int? ride, bool? nearBoard, bool? boarded, int? stopIndex}) => TripState(
    ride: ride ?? this.ride,
    nearBoard: nearBoard ?? this.nearBoard,
    boarded: boarded ?? this.boarded,
    stopIndex: stopIndex ?? this.stopIndex,
  );
}

/// What to tell the traveller now.
class TripView {
  const TripView({required this.phase, required this.state, this.ride, this.stopsLeft, this.meters});

  final TripPhase phase;
  final TripState state;

  /// The ride the phase is about; null once all are done.
  final RideLeg? ride;

  /// On board: how many stops until the one to get off at.
  final int? stopsLeft;

  /// To the next target: the boarding stop, the destination. Null without a position.
  final double? meters;
}

/// The traveller at the boarding stop is within this many metres of it.
const double boardRadius = 60;

/// Got off: within this many metres of the stop where the ride ends.
const double alightRadius = 80;

/// Having been at the stop, farther than this from it means the bus took the traveller away.
const double leftRadius = 150;

/// Arrived: within this many metres of the destination.
const double arriveRadius = 60;

/// Follows a journey: from the last [state] and the new [position] to what is happening now. Pure, so that the
/// phases can be tested without a phone. Call it with every position and keep the [TripView.state] it returns.
TripView followTrip({
  required Timetable timetable,
  required List<RideLeg> rides,
  required LatLng destination,
  required TripState state,
  required LatLng? position,
}) {
  const distance = Distance();
  LatLng stop(int s) => LatLng(timetable.stopLat[s] / 1e6, timetable.stopLon[s] / 1e6);
  var s = state;
  // A few transitions can chain on one position (got off and, at the next stop right there, boarded).
  for (var guard = 0; guard < 4; guard++) {
    if (s.ride >= rides.length) {
      final meters = position == null ? null : distance(position, destination);
      return TripView(
        phase: meters != null && meters <= arriveRadius ? TripPhase.arrived : TripPhase.toDestination,
        state: s,
        meters: meters,
      );
    }
    final ride = rides[s.ride];
    if (position == null) {
      return TripView(
        phase: s.boarded
            ? TripPhase.onBoard
            : s.ride == 0
            ? TripPhase.toStop
            : TripPhase.changing,
        state: s,
        ride: ride,
        stopsLeft: s.boarded ? ride.alight - (s.stopIndex ?? ride.board) : null,
      );
    }
    // The stop of the ride nearest to the traveller, never behind the last one passed.
    var nearest = s.stopIndex ?? ride.board;
    var nearestMeters = double.infinity;
    for (var i = s.stopIndex ?? ride.board; i <= ride.alight; i++) {
      final m = distance(position, stop(timetable.routeStop(ride.route, i)));
      if (m < nearestMeters) {
        nearest = i;
        nearestMeters = m;
      }
    }
    if (!s.boarded) {
      final toBoard = distance(position, stop(ride.fromStop));
      final near = s.nearBoard || toBoard <= boardRadius;
      // Left the stop having been at it, or already well along the route (the stop was missed by the GPS).
      final left = (s.nearBoard && toBoard > leftRadius) || (nearest > ride.board + 1 && nearestMeters <= 120);
      if (left) {
        s = s.copyWith(nearBoard: true, boarded: true, stopIndex: nearest);
        continue;
      }
      return TripView(
        phase: toBoard <= boardRadius
            ? TripPhase.atStop
            : s.ride == 0
            ? TripPhase.toStop
            : TripPhase.changing,
        state: s.copyWith(nearBoard: near),
        ride: ride,
        meters: toBoard,
      );
    }
    final toAlight = distance(position, stop(ride.toStop));
    if (toAlight <= alightRadius || (nearest >= ride.alight && toAlight <= leftRadius)) {
      s = TripState(ride: s.ride + 1);
      continue;
    }
    final index = nearest > (s.stopIndex ?? ride.board) ? nearest : (s.stopIndex ?? ride.board);
    return TripView(
      phase: TripPhase.onBoard,
      state: s.copyWith(stopIndex: index),
      ride: ride,
      stopsLeft: ride.alight - index,
      meters: toAlight,
    );
  }
  return TripView(phase: TripPhase.toDestination, state: s);
}
