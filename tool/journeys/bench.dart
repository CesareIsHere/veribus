// Times RAPTOR on a real timetable, from 10 nightlife areas of Rome to a 1 km grid within 10 km of the centre.
//
//   dart run tool/journeys/bench.dart <timetable.bin>
//   dart compile exe tool/journeys/bench.dart -o bench && ./bench <timetable.bin>      (AOT, as in a release app)
import 'dart:io';
import 'dart:math' as math;

import 'package:veribus/models/journeys/raptor.dart';
import 'package:veribus/models/journeys/timetable.dart';

import 'package:veribus/models/journeys/timetable_builder.dart' show WalkRules, meters;

const origins = {
  'Trastevere': (41.8891, 12.4699),
  "Campo de' Fiori": (41.8956, 12.4722),
  'Monti': (41.8955, 12.4925),
  'San Lorenzo': (41.8975, 12.5135),
  'Pigneto': (41.8885, 12.5285),
  'Testaccio': (41.8775, 12.4760),
  'Ostiense': (41.8710, 12.4800),
  'Prati': (41.9070, 12.4610),
  'Flaminio': (41.9110, 12.4760),
  'Termini': (41.9010, 12.5010),
};
const centre = (41.8933, 12.4829);

void main(List<String> args) {
  var watch = Stopwatch()..start();
  final tt = Timetable.decode(File(args.single).readAsBytesSync());
  print('Decoded ${tt.tripCount} trips in ${watch.elapsedMilliseconds} ms; RSS ${ProcessInfo.currentRss ~/ 1e6} MB');

  const walk = WalkRules();
  List<StopAccess> around(double lat, double lon, double radius) => [
    for (var s = 0; s < tt.stopCount; s++)
      if (meters(lat, lon, tt.stopLat[s] / 1e6, tt.stopLon[s] / 1e6) case final m when m <= radius)
        (stop: s, walk: walk.seconds(m)),
  ];
  final cells = <(double, double, List<StopAccess>)>[];
  for (var dy = -10000; dy <= 10000; dy += 1000) {
    for (var dx = -10000; dx <= 10000; dx += 1000) {
      if (math.sqrt(dx * dx + dy * dy) > 10000) continue;
      final lat = centre.$1 + dy / 110540;
      final lon = centre.$2 + dx / (111320 * math.cos(41.9 * math.pi / 180));
      final stops = around(lat, lon, 600);
      if (stops.isNotEmpty) cells.add((lat, lon, stops));
    }
  }

  final raptor = Raptor(tt);
  for (final (label, departure) in [('21:30', 21 * 3600 + 1800), ('00:30', 24 * 3600 + 1800)]) {
    final micros = <int>[];
    final within75 = [0, 0, 0, 0];
    var pairs = 0;
    for (final (lat, lon) in origins.values) {
      final from = around(lat, lon, 500);
      for (final (cLat, cLon, to) in cells) {
        if (meters(lat, lon, cLat, cLon) < 1500) continue;
        pairs++;
        watch = Stopwatch()..start();
        final journeys = raptor.search(origins: from, destinations: to, departure: departure);
        micros.add(watch.elapsedMicroseconds);
        for (var k = 0; k <= 3; k++) {
          if (journeys.any((j) => j.rides <= k && j.arrive - departure <= 75 * 60)) within75[k]++;
        }
      }
    }
    micros.sort();
    String ms(double q) => (micros[((micros.length - 1) * q).round()] / 1000).toStringAsFixed(1);
    String share(int n) => '${(100 * n / pairs).round()}%';
    print(
      '$label: $pairs searches, ms p50 ${ms(0.5)} p95 ${ms(0.95)} max ${ms(1)}; within 75 min with at most '
      '0/1/2/3 rides: ${within75.map(share).join(' / ')}; RSS ${ProcessInfo.currentRss ~/ 1e6} MB',
    );
  }
}
