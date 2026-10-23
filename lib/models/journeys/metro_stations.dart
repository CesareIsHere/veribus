import 'package:latlong2/latlong.dart';
import 'package:veribus/models/journeys/timetable.dart';

/// A metro line at a station, with how often it passes now: the median gap between trains in the next hour, in each
/// direction (null when fewer than two trains pass). From the timetable, not in real time.
typedef MetroLineAt = ({String line, int? everyMinutes});

typedef MetroStation = ({String name, LatLng point, List<MetroLineAt> lines});

/// The metro stations of [timetable]: the stops of the metro lines, the platforms of one station (same name) in one
/// place, with the lines that serve it and how often they pass from [now] on.
List<MetroStation> metroStations(Timetable timetable, DateTime now) {
  final nowSeconds = now.difference(timetable.midnight).inSeconds;
  const window = 3600;
  final stations = <String, ({String name, List<LatLng> points, Map<String, Map<int, List<int>>> trains})>{};
  for (var r = 0; r < timetable.routeCount; r++) {
    final line = timetable.routeLine[r];
    if (timetable.lineTypes[line] != Timetable.metro) continue;
    final lineName = timetable.lineNames[line];
    for (var i = 0; i < timetable.routeLength(r); i++) {
      final stop = timetable.routeStop(r, i);
      final name = timetable.stopNames[stop];
      final station = stations.putIfAbsent(name.toLowerCase(), () => (name: name, points: [], trains: {}));
      final point = LatLng(timetable.stopLat[stop] / 1e6, timetable.stopLon[stop] / 1e6);
      if (!station.points.contains(point)) station.points.add(point);
      final direction = station.trains
          .putIfAbsent(lineName, () => {})
          .putIfAbsent(timetable.routeDirection[r], () => []);
      for (var t = timetable.routeTripStart[r]; t < timetable.routeTripStart[r + 1]; t++) {
        final at = timetable.serviceSeconds(t, i);
        if (at >= nowSeconds && at <= nowSeconds + window) direction.add(at);
      }
    }
  }
  return [
    for (final s in stations.values)
      (
        name: s.name,
        point: LatLng(
          s.points.map((p) => p.latitude).reduce((a, b) => a + b) / s.points.length,
          s.points.map((p) => p.longitude).reduce((a, b) => a + b) / s.points.length,
        ),
        lines: [
          for (final MapEntry(key: line, value: directions) in s.trains.entries)
            (line: line, everyMinutes: _every([for (final times in directions.values) ..._gaps(times)])),
        ]..sort((a, b) => a.line.compareTo(b.line)),
      ),
  ]..sort((a, b) => a.name.compareTo(b.name));
}

List<int> _gaps(List<int> times) {
  final sorted = [...times]..sort();
  return [for (var i = 1; i < sorted.length; i++) sorted[i] - sorted[i - 1]];
}

/// The median of the [gaps] in seconds, in minutes, at least one; null without any.
int? _every(List<int> gaps) {
  if (gaps.isEmpty) return null;
  final sorted = [...gaps]..sort();
  return (sorted[sorted.length ~/ 2] / 60).round().clamp(1, 120);
}
