import 'dart:convert';

import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veribus/core/providers/auto_refresh.dart';
import 'package:veribus/core/providers/network_provider.dart';
import 'package:veribus/core/providers/shared_preferences_provider.dart';
import 'package:veribus/models/journeys/change_reliability.dart';
import 'package:veribus/models/journeys/journey_planner.dart';
import 'package:veribus/models/journeys/place.dart';
import 'package:veribus/models/journeys/raptor.dart';
import 'package:veribus/repositories/journeys/journeys_repository_provider.dart';
import 'package:veribus/repositories/transit/transit_repository_provider.dart';
import 'package:veribus/services/place_search_service.dart';

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

/// Where the journeys page plans to: null is home. Back to home every time the page is opened again.
@riverpod
class JourneyDestination extends _$JourneyDestination {
  @override
  Place? build() => null;

  void set(Place place) => state = place.isHome ? null : place;
}

/// The last places chosen as destination, newest first, saved only on the phone like home.
@Riverpod(keepAlive: true)
class RecentPlaces extends _$RecentPlaces {
  static const _key = 'recent_places';
  static const _max = 5;

  /// Closer than this, two places are the same one found twice.
  static const _sameMeters = 50.0;

  @override
  List<Place> build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(_key);
    if (saved == null) return const [];
    try {
      return [for (final p in jsonDecode(saved) as List) Place.fromJson(p as Map<String, dynamic>)];
    } on Object {
      return const []; // an older or broken list is forgotten, not a crash
    }
  }

  Future<void> add(Place place) async {
    if (place.isHome) return;
    state = [
      place,
      ...state.where((p) => p.name != place.name && const Distance()(p.point, place.point) > _sameMeters),
    ].take(_max).toList();
    await ref.read(sharedPreferencesProvider).setString(_key, jsonEncode([for (final p in state) p.toJson()]));
  }
}

/// Addresses and places matching [query], from the place search service.
@riverpod
Future<List<Place>> placeSearch(Ref ref, String query) => ref.watch(placeSearchServiceProvider).search(query);

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

/// The streets a line runs along in one direction (its main path), for the journey map. Asked once: it does not move.
@riverpod
Future<List<LatLng>> lineShape(Ref ref, String lineId, int directionId) async =>
    (await ref.watch(transitRepositoryProvider).line(lineId, directionId))?.shape ?? const [];

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
