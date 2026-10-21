import 'dart:math' as math;
import 'dart:typed_data';

import 'package:veribus/models/journeys/timetable.dart';

/// A stop as read from stops.txt.
typedef GtfsStop = ({String id, String name, double lat, double lon});

/// A line as read from routes.txt: the name shown and the GTFS route type (`Timetable.bus`, tram or metro).
typedef GtfsLine = ({String name, int type});

/// A trip of the day: its line, direction, headsign, stops and the departure time at each (seconds from the
/// timetable's midnight). `previousDay`: a trip of the previous service day, after midnight.
typedef GtfsTrip = ({
  String line,
  int direction,
  String headsign,
  List<String> stops,
  List<int> times,
  bool previousDay,
});

/// Walking between stops: straight line × [walkFactor] at [walkSpeed] m/s, up to [radius] metres. [stationPenalty]
/// seconds are added for each end that is a station (stairs and corridors: metro platforms are underground).
///
/// With the distances along the streets (tool/journeys/walking.py), a link takes them at [walkSpeed] instead, and a link
/// longer than [maxRouteMeters] on foot, or with no way at all, is dropped: across the Tiber, 150 m apart can be a
/// bridge away.
class WalkRules {
  const WalkRules({
    this.radius = 250,
    this.walkFactor = 1.3,
    this.walkSpeed = 1.2,
    this.stationPenalty = 120,
    this.maxRouteMeters = 400,
  });

  final double radius;
  final double walkFactor;
  final double walkSpeed;
  final int stationPenalty;
  final int maxRouteMeters;

  int seconds(double meters) => (meters * walkFactor / walkSpeed).round();
}

/// Builds the [Timetable] of one day from its trips: groups them into routes by stop sequence, splits a route where a
/// later trip would overtake an earlier one (RAPTOR needs trips sorted at every stop), and links stops within
/// walking distance. Only stops served by a trip are kept. Stops served by the metro count as stations. A line
/// missing from [lines] is a bus named after its id. [walkingMeters]: metres on foot by `from|to` stop ids, -1 for no
/// way; pairs missing from it fall back to the straight line.
Timetable buildTimetable({
  required int date,
  required List<GtfsStop> stops,
  required List<GtfsTrip> trips,
  Map<String, GtfsLine> lines = const {},
  WalkRules walk = const WalkRules(),
  Map<String, int> walkingMeters = const {},
}) {
  GtfsLine lineOf(String id) => lines[id] ?? (name: id, type: Timetable.bus);
  final used = {for (final t in trips) ...t.stops};
  final kept = [
    for (final s in stops)
      if (used.contains(s.id)) s,
  ];
  final index = {for (var i = 0; i < kept.length; i++) kept[i].id: i};
  if (kept.length > 0xffff) throw StateError('Too many stops for 16-bit indexes: ${kept.length}');

  // Routes: same line and stop sequence, then split so that no trip overtakes another.
  final patterns = <String, List<GtfsTrip>>{};
  for (final t in trips) {
    if (t.stops.length < 2) continue;
    (patterns['${t.line}|${t.direction}|${t.stops.join(',')}'] ??= []).add(t);
  }
  final routes = <List<GtfsTrip>>[];
  for (final group in patterns.values) {
    group.sort((a, b) => a.times.first.compareTo(b.times.first));
    final split = <List<GtfsTrip>>[];
    for (final t in group) {
      final fits = split.where((r) => _follows(r.last, t)).firstOrNull;
      if (fits != null) {
        fits.add(t);
      } else {
        split.add([t]);
      }
    }
    routes.addAll(split);
  }

  final lineIds = {for (final r in routes) r.first.line}.toList()..sort();
  final lineIndex = {for (var i = 0; i < lineIds.length; i++) lineIds[i]: i};
  final routeStopStart = Uint32List(routes.length + 1);
  final routeTripStart = Uint32List(routes.length + 1);
  for (var r = 0; r < routes.length; r++) {
    routeStopStart[r + 1] = routeStopStart[r] + routes[r].first.stops.length;
    routeTripStart[r + 1] = routeTripStart[r] + routes[r].length;
  }
  final routeStops = Uint16List(routeStopStart.last);
  final tripDeparture = Int32List(routeTripStart.last);
  final offsets = <int>[];
  var t = 0;
  for (var r = 0; r < routes.length; r++) {
    final first = routes[r].first;
    for (var i = 0; i < first.stops.length; i++) {
      routeStops[routeStopStart[r] + i] = index[first.stops[i]]!;
    }
    for (final trip in routes[r]) {
      tripDeparture[t++] = trip.times.first;
      for (final time in trip.times) {
        final offset = time - trip.times.first;
        if (offset < 0 || offset > 0xffff) throw StateError('Trip times out of range: ${trip.times}');
        offsets.add(offset);
      }
    }
  }

  final stations = {
    for (final t in trips)
      if (lineOf(t.line).type == Timetable.metro)
        for (final s in t.stops) index[s]!,
  };
  final foot = _footpaths(kept, stations, walk, walkingMeters);
  return Timetable(
    date: date,
    stopIds: [for (final s in kept) s.id],
    stopNames: [for (final s in kept) s.name],
    stopLat: Int32List.fromList([for (final s in kept) (s.lat * 1e6).round()]),
    stopLon: Int32List.fromList([for (final s in kept) (s.lon * 1e6).round()]),
    lineIds: lineIds,
    lineNames: [for (final l in lineIds) lineOf(l).name],
    lineTypes: Uint8List.fromList([for (final l in lineIds) lineOf(l).type]),
    routeLine: Uint16List.fromList([for (final r in routes) lineIndex[r.first.line]!]),
    routeDirection: Uint8List.fromList([for (final r in routes) r.first.direction]),
    routeHeadsign: [for (final r in routes) r.first.headsign],
    routeStopStart: routeStopStart,
    routeTripStart: routeTripStart,
    routeStops: routeStops,
    tripDeparture: tripDeparture,
    tripOffsets: Uint16List.fromList(offsets),
    tripPreviousDay: Uint8List.fromList([
      for (final r in routes)
        for (final t in r)
          if (t.previousDay) 1 else 0,
    ]),
    footStart: foot.start,
    footTo: foot.to,
    footSeconds: foot.seconds,
  );
}

/// Whether [next] (departing later) stays behind [previous] at every stop.
bool _follows(GtfsTrip previous, GtfsTrip next) {
  for (var i = 0; i < next.times.length; i++) {
    if (next.times[i] < previous.times[i]) return false;
  }
  return true;
}

/// Metres between two points, on a flat projection (good to a few metres over a city).
double meters(double lat1, double lon1, double lat2, double lon2) {
  final x = (lon2 - lon1) * math.cos((lat1 + lat2) / 2 * math.pi / 180) * 111320;
  final y = (lat2 - lat1) * 110540;
  return math.sqrt(x * x + y * y);
}

({Uint32List start, Uint16List to, Uint16List seconds}) _footpaths(
  List<GtfsStop> stops,
  Set<int> stations,
  WalkRules walk,
  Map<String, int> walkingMeters,
) {
  // A grid of cells as wide as the radius: neighbours are in the 3×3 cells around a stop.
  final cellLat = walk.radius / 110540;
  final cellLon = walk.radius / 80000; // a degree of longitude is ~83 km at Rome: cells a bit wider than the radius
  final cells = <(int, int), List<int>>{};
  (int, int) cellOf(GtfsStop s) => ((s.lat / cellLat).floor(), (s.lon / cellLon).floor());
  for (var i = 0; i < stops.length; i++) {
    (cells[cellOf(stops[i])] ??= []).add(i);
  }
  final start = Uint32List(stops.length + 1);
  final to = <int>[];
  final seconds = <int>[];
  for (var i = 0; i < stops.length; i++) {
    final a = stops[i];
    final (cy, cx) = cellOf(a);
    final near = <(int, int)>[];
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        for (final j in cells[(cy + dy, cx + dx)] ?? const <int>[]) {
          if (j == i) continue;
          final d = meters(a.lat, a.lon, stops[j].lat, stops[j].lon);
          if (d > walk.radius) continue;
          final routed = walkingMeters['${a.id}|${stops[j].id}'];
          if (routed != null && (routed < 0 || routed > walk.maxRouteMeters)) continue;
          final penalty =
              (stations.contains(i) ? walk.stationPenalty : 0) + (stations.contains(j) ? walk.stationPenalty : 0);
          final seconds = routed == null ? walk.seconds(d) : (routed / walk.walkSpeed).round();
          near.add((j, seconds + penalty));
        }
      }
    }
    near.sort((x, y) => x.$1.compareTo(y.$1));
    for (final (j, s) in near) {
      to.add(j);
      seconds.add(s);
    }
    start[i + 1] = to.length;
  }
  return (start: start, to: Uint16List.fromList(to), seconds: Uint16List.fromList(seconds));
}
