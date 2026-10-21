// Builds the RAPTOR timetables of consecutive days from an unzipped GTFS: one file per day, `<out dir>/<yyyymmdd>.bin`.
//
//   dart run tool/journeys/build_timetable.dart <gtfs dir> <out dir> <first yyyymmdd> [days, default 1]
//
// Run by backend/static-import/import.sh for today and the 7 days after (the window the import keeps). Keeps bus (3),
// tram (0) and metro (1): the metro is not in the app's network file, it serves only journeys. The day's trips are
// kept whole; the previous day's trips that run past midnight are kept from their first stop after it, so a file
// answers queries from 00:00 of its day.
import 'dart:convert';
import 'dart:io';

import 'package:veribus/models/journeys/timetable.dart';

import 'timetable_builder.dart';

Future<void> main(List<String> args) async {
  if (args.length < 3) {
    stderr.writeln('Usage: dart run tool/journeys/build_timetable.dart <gtfs dir> <out dir> <first yyyymmdd> [days]');
    exit(64);
  }
  final dir = args[0];
  final out = Directory(args[1])..createSync(recursive: true);
  final first = _date(args[2]);
  final dates = [for (var i = 0; i < (args.length > 3 ? int.parse(args[3]) : 1); i++) first.add(Duration(days: i))];
  final watch = Stopwatch()..start();

  final lines = <String, GtfsLine>{};
  for (final r in readCsv('$dir/routes.txt')) {
    final type = int.parse(r['route_type']!);
    if (type != Timetable.tram && type != Timetable.metro && type != Timetable.bus) continue;
    lines[r['route_id']!] = (name: lineName(r['route_short_name'] ?? r['route_id']!, type), type: type);
  }
  final services = <String, Set<String>>{};
  for (final c in readCsv('$dir/calendar_dates.txt')) {
    if (c['exception_type'] == '1') (services[c['date']!] ??= {}).add(c['service_id']!);
  }
  final wanted = {
    for (final d in [first.subtract(const Duration(days: 1)), ...dates]) ...?services[_key(d)],
  };
  final trips = <String, ({String line, int direction, String headsign, String service})>{};
  for (final t in readCsv('$dir/trips.txt')) {
    if (!lines.containsKey(t['route_id']) || !wanted.contains(t['service_id'])) continue;
    trips[t['trip_id']!] = (
      line: t['route_id']!,
      direction: int.tryParse(t['direction_id'] ?? '') ?? 0,
      headsign: t['trip_headsign'] ?? '',
      service: t['service_id']!,
    );
  }

  // Per trip: stop_sequence, stop, seconds, flattened.
  final rows = <String, List<Object>>{};
  Map<String, int>? header;
  final input = File('$dir/stop_times.txt').openRead().transform(utf8.decoder).transform(const LineSplitter());
  await for (final line in input) {
    final fields = splitCsv(line);
    if (header == null) {
      header = {for (var i = 0; i < fields.length; i++) fields[i].replaceFirst('\uFEFF', ''): i};
      continue;
    }
    final col = header;
    final id = fields[col['trip_id']!];
    if (!trips.containsKey(id)) continue;
    final departure = fields[col['departure_time']!];
    final time = departure.isNotEmpty ? departure : fields[col['arrival_time']!];
    if (time.isEmpty) continue; // trips without times are dropped, as the import does
    (rows[id] ??= []).addAll([int.parse(fields[col['stop_sequence']!]), fields[col['stop_id']!], parseTime(time)]);
  }
  final stops = [
    for (final s in readCsv('$dir/stops.txt'))
      (
        id: s['stop_id']!,
        name: s['stop_name'] ?? '',
        lat: double.parse(s['stop_lat']!),
        lon: double.parse(s['stop_lon']!),
      ),
  ];

  for (final day in dates) {
    final today = services[_key(day)] ?? const <String>{};
    final yesterday = services[_key(day.subtract(const Duration(days: 1)))] ?? const <String>{};
    final dayTrips = <GtfsTrip>[];
    for (final MapEntry(key: id, value: flat) in rows.entries) {
      final trip = trips[id]!;
      // A service can run on both days: today's whole run first, then yesterday's tail if it also ran yesterday.
      for (final previousDay in [false, true]) {
        if (!(previousDay ? yesterday : today).contains(trip.service)) continue;
        final run = [
          for (var i = 0; i < flat.length; i += 3)
            if (!previousDay || (flat[i + 2] as int) >= 86400)
              (
                seq: flat[i] as int,
                stop: flat[i + 1] as String,
                time: (flat[i + 2] as int) - (previousDay ? 86400 : 0),
              ),
        ]..sort((a, b) => a.seq.compareTo(b.seq));
        dayTrips.add((
          line: trip.line,
          direction: trip.direction,
          headsign: trip.headsign,
          stops: [for (final r in run) r.stop],
          times: [for (final r in run) r.time],
          previousDay: previousDay,
        ));
      }
    }
    final timetable = buildTimetable(date: int.parse(_key(day)), stops: stops, trips: dayTrips, lines: lines);
    final bytes = timetable.encode();
    final again = Timetable.decode(bytes);
    if (again.tripCount != timetable.tripCount || again.times.last != timetable.times.last) {
      throw StateError('The timetable of ${_key(day)} does not decode back');
    }
    File('${out.path}/${_key(day)}.bin').writeAsBytesSync(bytes);
    print(
      '${_key(day)}: ${timetable.stopCount} stops, ${timetable.routeCount} routes, ${timetable.tripCount} trips, '
      '${timetable.tripOffsets.length} stop times, ${timetable.footTo.length} walking links; '
      '${_mb(bytes.length)} MB, ${_mb(gzip.encode(bytes).length)} MB gzipped (${watch.elapsed.inSeconds} s)',
    );
  }
}

/// The name people know: the metro lines are MEA, MEB, MEB1, MEC in the GTFS and A, B, B1, C on the signs.
String lineName(String shortName, int type) =>
    type == Timetable.metro && shortName.startsWith('ME') ? shortName.substring(2) : shortName;

DateTime _date(String yyyymmdd) => DateTime.utc(
  int.parse(yyyymmdd.substring(0, 4)),
  int.parse(yyyymmdd.substring(4, 6)),
  int.parse(yyyymmdd.substring(6)),
);

String _key(DateTime d) => '${d.year}${'${d.month}'.padLeft(2, '0')}${'${d.day}'.padLeft(2, '0')}';

String _mb(int bytes) => (bytes / 1e6).toStringAsFixed(2);

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
