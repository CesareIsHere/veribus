// Builds the RAPTOR timetable of one day from an unzipped GTFS (prototype: the nightly import will produce it).
//
//   dart run tool/journeys/build_timetable.dart <gtfs dir> <yyyymmdd> <out.bin> [--no-metro]
//
// Keeps bus (3), tram (0) and metro (1), like the app minus rail. The day's trips are kept whole; the previous day's
// trips that run past midnight are kept from their first stop after it, so the file answers queries from 00:00.
import 'dart:convert';
import 'dart:io';

import 'package:veribus/models/journeys/timetable.dart';

import 'timetable_builder.dart';

Future<void> main(List<String> args) async {
  if (args.length < 3) {
    stderr.writeln('Usage: dart run tool/journeys/build_timetable.dart <gtfs dir> <yyyymmdd> <out.bin> [--no-metro]');
    exit(64);
  }
  final dir = args[0];
  final date = args[1];
  final types = {'0', '3', if (!args.contains('--no-metro')) '1'};
  final watch = Stopwatch()..start();

  final routes = {
    for (final r in readCsv('$dir/routes.txt'))
      if (types.contains(r['route_type'])) r['route_id']!: r['route_type']!,
  };
  final previous = _previousDay(date);
  final services = <String, Set<String>>{};
  for (final c in readCsv('$dir/calendar_dates.txt')) {
    if (c['exception_type'] == '1') (services[c['date']!] ??= {}).add(c['service_id']!);
  }
  final today = services[date] ?? const {};
  final yesterday = services[previous] ?? const {};
  final trips = <String, ({String line, String headsign, bool late})>{};
  for (final t in readCsv('$dir/trips.txt')) {
    final route = t['route_id']!;
    if (!routes.containsKey(route)) continue;
    final service = t['service_id'];
    // A trip can run on both days: today's whole run wins over yesterday's tail.
    if (today.contains(service)) {
      trips[t['trip_id']!] = (line: route, headsign: t['trip_headsign'] ?? '', late: false);
    } else if (yesterday.contains(service)) {
      trips[t['trip_id']!] = (line: route, headsign: t['trip_headsign'] ?? '', late: true);
    }
  }

  final rows = <String, List<(int, String, int)>>{};
  final lines = File('$dir/stop_times.txt').openRead().transform(utf8.decoder).transform(const LineSplitter());
  Map<String, int>? header;
  await for (final line in lines) {
    final fields = splitCsv(line);
    if (header == null) {
      header = {for (var i = 0; i < fields.length; i++) fields[i].replaceFirst('\uFEFF', ''): i};
      continue;
    }
    final col = header;
    final id = fields[col['trip_id']!];
    final trip = trips[id];
    if (trip == null) continue;
    final departure = fields[col['departure_time']!];
    final time = departure.isNotEmpty ? departure : fields[col['arrival_time']!];
    if (time.isEmpty) continue; // trips without times are dropped, as the import does
    var seconds = parseTime(time);
    if (trip.late) {
      if (seconds < 86400) continue;
      seconds -= 86400;
    }
    (rows[id] ??= []).add((int.parse(fields[col['stop_sequence']!]), fields[col['stop_id']!], seconds));
  }

  final gtfsTrips = <GtfsTrip>[];
  for (final MapEntry(key: id, value: stops) in rows.entries) {
    stops.sort((a, b) => a.$1.compareTo(b.$1));
    final trip = trips[id]!;
    gtfsTrips.add((
      line: trip.line,
      headsign: trip.headsign,
      stops: [for (final s in stops) s.$2],
      times: [for (final s in stops) s.$3],
    ));
  }
  final metroLines = {
    for (final MapEntry(:key, :value) in routes.entries)
      if (value == '1') key,
  };
  final stations = {
    for (final t in gtfsTrips)
      if (metroLines.contains(t.line)) ...t.stops,
  };
  final stops = [
    for (final s in readCsv('$dir/stops.txt'))
      (id: s['stop_id']!, lat: double.parse(s['stop_lat']!), lon: double.parse(s['stop_lon']!)),
  ];

  final timetable = buildTimetable(date: int.parse(date), stops: stops, trips: gtfsTrips, stations: stations);
  final bytes = timetable.encode();
  File(args[2]).writeAsBytesSync(bytes);
  final gzipped = gzip.encode(bytes).length;
  print(
    'Wrote ${args[2]} in ${watch.elapsed.inSeconds} s: ${timetable.stopCount} stops, ${timetable.routeCount} routes, '
    '${timetable.tripCount} trips, ${timetable.tripOffsets.length} stop times, ${timetable.footTo.length} walking links; '
    '${_mb(bytes.length)} MB, ${_mb(gzipped)} MB gzipped',
  );
  // The file must read back to the same timetable.
  final again = Timetable.decode(bytes);
  if (again.tripCount != timetable.tripCount || again.times.last != timetable.times.last) {
    throw StateError('The timetable does not decode back');
  }
}

String _mb(int bytes) => (bytes / 1e6).toStringAsFixed(2);

String _previousDay(String yyyymmdd) {
  final d = DateTime.utc(
    int.parse(yyyymmdd.substring(0, 4)),
    int.parse(yyyymmdd.substring(4, 6)),
    int.parse(yyyymmdd.substring(6, 8)),
  ).subtract(const Duration(days: 1));
  return '${d.year}${'${d.month}'.padLeft(2, '0')}${'${d.day}'.padLeft(2, '0')}';
}

/// "25:10:00" → seconds from midnight (GTFS times go past 24:00).
int parseTime(String hms) {
  final p = hms.trim().split(':');
  return int.parse(p[0]) * 3600 + int.parse(p[1]) * 60 + int.parse(p[2]);
}

/// The rows of a small CSV file as maps by header name.
Iterable<Map<String, String>> readCsv(String path) sync* {
  final lines = const LineSplitter().convert(File(path).readAsStringSync());
  final header = splitCsv(lines.first.replaceFirst('﻿', ''));
  for (final line in lines.skip(1)) {
    if (line.isEmpty) continue;
    final fields = splitCsv(line);
    yield {for (var i = 0; i < header.length && i < fields.length; i++) header[i]: fields[i]};
  }
}

/// One CSV line: commas inside double quotes do not split, `""` is a quote.
List<String> splitCsv(String line) {
  if (!line.contains('"')) return line.replaceAll('\r', '').split(',');
  final out = <String>[];
  final field = StringBuffer();
  var quoted = false;
  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (quoted) {
      if (c == '"' && i + 1 < line.length && line[i + 1] == '"') {
        field.write('"');
        i++;
      } else if (c == '"') {
        quoted = false;
      } else {
        field.write(c);
      }
    } else if (c == '"') {
      quoted = true;
    } else if (c == ',') {
      out.add(field.toString());
      field.clear();
    } else if (c != '\r') {
      field.write(c);
    }
  }
  out.add(field.toString());
  return out;
}
