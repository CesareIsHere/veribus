import 'package:latlong2/latlong.dart';
import 'package:veribus/models/journeys/raptor.dart';
import 'package:veribus/models/journeys/timetable.dart';
import 'package:veribus/models/journeys/timetable_builder.dart';
import 'package:veribus/models/transit/live.dart';

/// What the traveller leaves out: the metro, the night buses.
typedef JourneyFilter = ({bool metro, bool night});

const JourneyFilter allTransport = (metro: true, night: true);

/// Realtime arrivals at stops for lines, as `api.arrivals` gives them (the next 60 minutes).
typedef ArrivalsSource = Future<Arrivals> Function(List<String> stopIds, List<String> lineIds);

/// A journey with what the realtime says about its rides: the arrival of each ride's trip at its boarding stop, when
/// the API has one (trips in the next hour).
class PlannedJourney {
  PlannedJourney(this.journey, this.realtime);

  final Journey journey;
  final Map<int, Arrival> realtime;

  List<RideLeg> get rides => journey.legs.whereType<RideLeg>().toList();
  Arrival? realtimeOf(RideLeg ride) => realtime[ride.trip];
}

/// Plans journeys home (or anywhere) on one day's [Timetable], with the realtime of the trips it proposes:
/// canceled and suppressed trips are left out, late ones run at their predicted time, then the search runs again.
///
/// The journeys kept are the fastest with fewest rides, plus one with more rides only when it arrives at least
/// [minGainPerRide] seconds earlier per extra ride: a change to gain a minute is not worth proposing.
class JourneyPlanner {
  JourneyPlanner(
    this.timetable,
    this.arrivals, {
    this.transferSlack = 180,
    this.maxRides = 3,
    this.minGainPerRide = 300,
    this.walk = const WalkRules(),
  }) : _raptor = Raptor(timetable, transferSlack: transferSlack);

  final Timetable timetable;
  final ArrivalsSource arrivals;
  final int transferSlack;
  final int maxRides;
  final int minGainPerRide;
  final WalkRules walk;
  final Raptor _raptor;
  final _blockedCache = <JourneyFilter, Set<int>>{};

  /// The routes [filter] leaves out: the metro lines, the night buses (`n1`).
  Set<int> _blocked(JourneyFilter filter) => filter == allTransport
      ? const {}
      : _blockedCache.putIfAbsent(filter, () {
          final tt = timetable;
          return {
            for (var r = 0; r < tt.routeCount; r++)
              if (tt.lineTypes[tt.routeLine[r]] == Timetable.metro
                  ? !filter.metro
                  : !filter.night && RegExp(r'^[nN]\d').hasMatch(tt.lineNames[tt.routeLine[r]]))
                r,
          };
        });

  /// How many times the search runs again with new realtime before it settles.
  static const _realtimeRounds = 3;

  /// The realtime window of `api.arrivals`: trips boarding later than this have no prediction yet.
  static const int _realtimeAhead = 60 * 60;

  /// Seconds from the timetable's midnight.
  int secondsOf(DateTime at) => at.difference(timetable.midnight).inSeconds;
  DateTime timeOf(int seconds) => timetable.midnight.add(Duration(seconds: seconds));

  /// Stops within [radius] metres of [place] with the walk to them, widened to twice the radius when there are none.
  List<StopAccess> stopsAround(LatLng place, {double radius = 500}) {
    for (final r in [radius, radius * 2]) {
      final found = <StopAccess>[
        for (var s = 0; s < timetable.stopCount; s++)
          if (meters(place.latitude, place.longitude, timetable.stopLat[s] / 1e6, timetable.stopLon[s] / 1e6)
              case final m when m <= r)
            (stop: s, walk: walk.seconds(m)),
      ];
      if (found.isNotEmpty) return found;
    }
    return const [];
  }

  /// Up to [options] journeys from [from] to [to] leaving at [at] or later, each with a different first trip,
  /// earliest departure first.
  Future<List<PlannedJourney>> plan({
    required LatLng from,
    required LatLng to,
    required DateTime at,
    int options = 3,
    JourneyFilter filter = allTransport,
  }) async {
    final origins = stopsAround(from);
    final destinations = stopsAround(to, radius: 600);
    if (origins.isEmpty || destinations.isEmpty) return const [];
    final now = secondsOf(at);
    final live = _Live();
    final found = <PlannedJourney>[];
    final seen = <String>{};
    var departure = now;
    for (var option = 0; option < options; option++) {
      final journeys = await _searchLive(origins, destinations, departure, now, live, _blocked(filter));
      final rides = journeys.where((j) => j.rides > 0).toList();
      for (final j in journeys) {
        final key = j.legs.whereType<RideLeg>().map((r) => r.trip).join(',');
        if (seen.add(key)) found.add(PlannedJourney(j, live.arrivalsFor(j)));
      }
      if (rides.isEmpty) break;
      // The next option leaves just too late for this one's first trip.
      departure = rides.map((j) => j.depart).reduce((a, b) => a < b ? a : b) + 60;
    }
    return found..sort((a, b) => a.journey.depart.compareTo(b.journey.depart));
  }

  /// The last journey still leaving within [horizon] seconds of [at], when the service ends within it: "leave by
  /// 00:52 for the last bus". Null when journeys keep running past the horizon, or when there is none at all.
  /// Scheduled times only: the last trips are hours away, beyond any prediction.
  PlannedJourney? lastJourney({
    required LatLng from,
    required LatLng to,
    required DateTime at,
    int horizon = 4 * 3600,
    JourneyFilter filter = allTransport,
  }) {
    final origins = stopsAround(from);
    final destinations = stopsAround(to, radius: 600);
    if (origins.isEmpty || destinations.isEmpty) return null;
    Journey? first(int departure) => _sensible(
      _boardHere(
        _raptor.search(
          origins: origins,
          destinations: destinations,
          departure: departure,
          maxRides: maxRides,
          blockedRoutes: _blocked(filter),
        ),
        origins,
        departure,
      ),
    ).where((j) => j.rides > 0).firstOrNull;
    final now = secondsOf(at);
    if (first(now + horizon) != null) return null;
    var found = first(now);
    if (found == null) return null;
    // Leaving later only loses trips: binary search on the minute of departure.
    var lo = now;
    var hi = now + horizon;
    while (hi - lo > 60) {
      final mid = (lo + hi) ~/ 2;
      final j = first(mid);
      if (j != null) {
        found = j;
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return PlannedJourney(found!, const {});
  }

  /// The trip of the same line and direction after [ride] at its boarding stop: what to take if it is missed.
  /// Its scheduled time there, or null.
  int? nextDeparture(RideLeg ride) {
    final tt = timetable;
    final line = tt.routeLine[ride.route];
    final direction = tt.routeDirection[ride.route];
    final after = tt.time(ride.trip, ride.board);
    int? next;
    for (var j = tt.stopRouteStart[ride.fromStop]; j < tt.stopRouteStart[ride.fromStop + 1]; j++) {
      final r = tt.stopRoutes[j];
      if (tt.routeLine[r] != line || tt.routeDirection[r] != direction) continue;
      final pos = tt.stopRoutePos[j];
      // Only stops further on: the rest of the ride must still be there.
      if (pos + 1 >= tt.routeLength(r)) continue;
      for (var t = tt.routeTripStart[r]; t < tt.routeTripStart[r + 1]; t++) {
        final time = tt.time(t, pos);
        if (t != ride.trip && time > after && (next == null || time < next)) next = time;
      }
    }
    return next;
  }

  Future<List<Journey>> _searchLive(
    List<StopAccess> origins,
    List<StopAccess> destinations,
    int departure,
    int now,
    _Live live,
    Set<int> blocked,
  ) async {
    var journeys = <Journey>[];
    for (var round = 0; round < _realtimeRounds; round++) {
      journeys = _sensible(
        _boardHere(
          _raptor.search(
            origins: origins,
            destinations: destinations,
            departure: departure,
            maxRides: maxRides,
            realtime: live.realtime(),
            blockedRoutes: blocked,
          ),
          origins,
          departure,
        ),
      );
      final unknown = [
        for (final j in journeys)
          for (final r in j.legs.whereType<RideLeg>())
            if (!live.asked.contains(r.trip) && r.start - r.delay <= now + _realtimeAhead) r,
      ];
      if (unknown.isEmpty) break;
      if (!await _ask(unknown, live)) break;
    }
    return journeys;
  }

  /// Asks the realtime of [rides] at their boarding stops; true when it changes the search.
  Future<bool> _ask(List<RideLeg> rides, _Live live) async {
    final tt = timetable;
    final stops = {for (final r in rides) tt.stopIds[r.fromStop]}.toList();
    final lines = {for (final r in rides) tt.lineIds[tt.routeLine[r.route]]}.toList();
    final result = await arrivals(stops, lines);
    var changed = false;
    for (final r in rides) {
      live.asked.add(r.trip);
      final line = tt.lineIds[tt.routeLine[r.route]];
      final slot = tt.serviceSeconds(r.trip, r.board);
      final match = (result.byStop[tt.stopIds[r.fromStop]] ?? const <Arrival>[])
          .where((a) => a.lineId == line && a.departureSeconds == slot)
          .firstOrNull;
      if (match == null) continue;
      live.arrivals[r.trip] = match;
      switch (match.status) {
        case ArrivalStatus.canceled || ArrivalStatus.suppressed:
          live.removed.add(r.trip);
          changed = true;
        case ArrivalStatus.confirmed || ArrivalStatus.uncertain when match.time != null:
          final delay = secondsOf(match.time!.toLocal()) - tt.time(r.trip, r.board);
          if (delay != 0) {
            live.delays[r.trip] = delay;
            changed = true;
          }
        case _:
      }
    }
    return changed;
  }

  /// The search reaches a stop the soonest it can and keeps the first way it found: when the first trip calls at an
  /// origin stop and, later, at another one that is nearer to the traveller, both give the same arrival, and the
  /// farther one can come out (a walk back along the line to board the bus three minutes earlier, then ride it past the
  /// stop the traveller started from). The traveller boards at the nearest stop of that trip they can still reach
  /// before it leaves, [departure] being the earliest they can set off.
  List<Journey> _boardHere(List<Journey> journeys, List<StopAccess> origins, int departure) {
    final tt = timetable;
    return [
      for (final j in journeys)
        if (j.legs case [final WalkLeg access, final RideLeg ride, ...final rest] when access.from == null)
          () {
            var walk = access.end - access.start;
            var position = ride.board;
            var boards = ride.start;
            for (var i = ride.board + 1; i < ride.alight; i++) {
              final stop = tt.routeStop(ride.route, i);
              for (final o in origins) {
                final at = tt.time(ride.trip, i) + ride.delay;
                if (o.stop == stop && o.walk < walk && at >= departure + o.walk) {
                  walk = o.walk;
                  position = i;
                  boards = at;
                }
              }
            }
            if (position == ride.board) return j;
            final stop = tt.routeStop(ride.route, position);
            return Journey([
              WalkLeg(from: null, to: stop, start: boards - walk, end: boards),
              RideLeg(
                route: ride.route,
                trip: ride.trip,
                board: position,
                alight: ride.alight,
                fromStop: stop,
                toStop: ride.toStop,
                start: boards,
                end: ride.end,
                delay: ride.delay,
              ),
              ...rest,
            ]);
          }()
        else
          j,
    ];
  }

  /// Fewest rides first; a journey with more rides stays only if it arrives [minGainPerRide] earlier per extra ride.
  List<Journey> _sensible(List<Journey> pareto) {
    final kept = <Journey>[];
    for (final j in pareto) {
      if (kept case [..., final last] when last.arrive - j.arrive < minGainPerRide * (j.rides - last.rides)) continue;
      kept.add(j);
    }
    return kept;
  }
}

/// What the realtime said so far during one plan.
class _Live {
  final asked = <int>{};
  final arrivals = <int, Arrival>{};
  final removed = <int>{};
  final delays = <int, int>{};

  Realtime realtime() => Realtime(removed: {...removed}, delays: {...delays});

  Map<int, Arrival> arrivalsFor(Journey j) => {for (final r in j.legs.whereType<RideLeg>()) r.trip: ?arrivals[r.trip]};
}
