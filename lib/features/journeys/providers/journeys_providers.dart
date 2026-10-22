import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veribus/core/providers/auto_refresh.dart';
import 'package:veribus/core/providers/network_provider.dart';
import 'package:veribus/core/providers/shared_preferences_provider.dart';
import 'package:veribus/models/journeys/change_reliability.dart';
import 'package:veribus/models/journeys/journey_planner.dart';
import 'package:veribus/models/journeys/raptor.dart';
import 'package:veribus/repositories/journeys/journeys_repository_provider.dart';
import 'package:veribus/repositories/transit/transit_repository_provider.dart';

part 'journeys_providers.g.dart';

/// Home, saved only on the phone ("lat,lon"), like the favorites. Null until the user sets it.
@Riverpod(keepAlive: true)
class HomePlace extends _$HomePlace {
  static const _key = 'home_place';

  @override
  LatLng? build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(_key)?.split(',');
    if (saved == null || saved.length != 2) return null;
    final (lat, lon) = (double.tryParse(saved[0]), double.tryParse(saved[1]));
    return lat == null || lon == null ? null : LatLng(lat, lon);
  }

  Future<void> set(LatLng place) async {
    state = place;
    await ref.read(sharedPreferencesProvider).setString(_key, '${place.latitude},${place.longitude}');
  }

  Future<void> clear() async {
    state = null;
    await ref.read(sharedPreferencesProvider).remove(_key);
  }
}

/// The planner on the timetable of [date] (yyyymmdd), kept for the session. Null when the nightly import did not
/// build that day's timetable.
@Riverpod(keepAlive: true)
Future<JourneyPlanner?> journeyPlanner(Ref ref, int date) async {
  final info = await ref.watch(networkInfoProvider.future);
  final timetable = await ref
      .watch(journeysRepositoryProvider)
      .timetable(info, DateTime(date ~/ 10000, date ~/ 100 % 100, date % 100));
  if (timetable == null) return null;
  final transit = ref.watch(transitRepositoryProvider);
  return JourneyPlanner(timetable, (stops, lines) => transit.arrivals(stops, lineIds: lines));
}

/// The journeys from one place to another leaving now, and the last one of the night when the service ends soon.
typedef PlannedTrip = ({JourneyPlanner planner, List<PlannedJourney> journeys, PlannedJourney? last});

/// Recomputed every minute while the page is open: departures pass and the realtime changes. Null when the
/// timetable of today is not available.
@riverpod
Future<PlannedTrip?> plannedTrip(Ref ref, LatLng from, LatLng to) async {
  final now = DateTime.now();
  final planner = await ref.watch(journeyPlannerProvider(now.year * 10000 + now.month * 100 + now.day).future);
  if (planner == null) return null;
  ref.refreshEvery(const Duration(minutes: 1));
  final journeys = await planner.plan(from: from, to: to, at: now);
  return (planner: planner, journeys: journeys, last: planner.lastJourney(from: from, to: to, at: now));
}

/// A change between two rides of a journey, named by the slots of the history.
typedef ChangeSlots = ({
  String arriveStop,
  String arriveLine,
  int arriveDirection,
  int arriveSlot,
  String leaveStop,
  String leaveLine,
  int leaveDirection,
  int leaveSlot,
  int walk,
  bool weekend,
});

/// The slots of the change from [ride] to [next] in [planner]'s timetable, walking [walk] seconds between them.
ChangeSlots changeSlots(JourneyPlanner planner, RideLeg ride, RideLeg next, int walk) {
  final tt = planner.timetable;
  final weekday = tt.midnight.weekday;
  return (
    arriveStop: tt.stopIds[ride.toStop],
    arriveLine: tt.lineIds[tt.routeLine[ride.route]],
    arriveDirection: tt.routeDirection[ride.route],
    arriveSlot: tt.serviceSeconds(ride.trip, ride.alight),
    leaveStop: tt.stopIds[next.fromStop],
    leaveLine: tt.lineIds[tt.routeLine[next.route]],
    leaveDirection: tt.routeDirection[next.route],
    leaveSlot: tt.serviceSeconds(next.trip, next.board),
    walk: walk,
    weekend: weekday == DateTime.saturday || weekday == DateTime.sunday,
  );
}

/// How often the change worked in the last 30 days of the same kind, from the history of both trips.
@riverpod
Future<ChangeRecord> changeReliability(Ref ref, ChangeSlots c) async {
  final transit = ref.watch(transitRepositoryProvider);
  final (arriving, leaving) = await (
    transit.tripHistory(c.arriveStop, c.arriveLine, c.arriveDirection, c.arriveSlot, weekend: c.weekend),
    transit.tripHistory(c.leaveStop, c.leaveLine, c.leaveDirection, c.leaveSlot, weekend: c.weekend),
  ).wait;
  return changeRecord(
    arriving: arriving,
    leaving: leaving,
    arriveSlot: c.arriveSlot,
    leaveSlot: c.leaveSlot,
    walk: c.walk,
  );
}
