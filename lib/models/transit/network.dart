import 'package:latlong2/latlong.dart';

/// Network data downloaded once per version (RF-11): stops and lines, searched and filtered on the phone.
/// Parsed from the compact JSON written by backend/static-import/export.sql.
class Network {
  Network.fromJson(Map<String, dynamic> json)
    : version = json['version'] as String,
      stops = [for (final s in json['stops'] as List) Stop._fromRow(s as List)],
      lines = {for (final l in json['routes'] as List) (l as List)[0] as String: Line._fromRow(l)} {
    stopById = {for (final s in stops) s.id: s};
  }

  final String version;
  final List<Stop> stops;
  final Map<String, Line> lines;
  late final Map<String, Stop> stopById;

  static const _distance = Distance();

  /// Stops within 500 m sorted by distance, widened to 1 km when there are none (RF-03).
  List<({Stop stop, double meters})> nearby(LatLng from, {int max = 10}) {
    for (final radius in [500, 1000]) {
      final found = [
        for (final s in stops)
          if (_distance(from, s.position) case final m when m <= radius) (stop: s, meters: m),
      ]..sort((a, b) => a.meters.compareTo(b.meters));
      if (found.isNotEmpty) return found.take(max).toList();
    }
    return const [];
  }

  /// Lines and stops matching [query] (RF-10): a line whose name matches exactly comes first,
  /// a stop code matches exactly, names match by prefix or substring ignoring case and accents.
  ({List<Line> lines, List<Stop> stops}) search(String query, {int max = 20}) {
    final q = normalize(query.trim());
    if (q.isEmpty) return (lines: const [], stops: const []);
    // Prefix match, shortest name first: "64" puts 64 before 640.
    final matchingLines = lines.values.where((l) => normalize(l.name).startsWith(q)).toList()
      ..sort((a, b) => a.name.length.compareTo(b.name.length));
    final byCode = stopById[query.trim()];
    final named = stops.where((s) => s != byCode && s.searchName.contains(q)).toList()
      ..sort((a, b) => (b.searchName.startsWith(q) ? 1 : 0) - (a.searchName.startsWith(q) ? 1 : 0));
    return (lines: matchingLines.take(max).toList(), stops: [?byCode, ...named].take(max).toList());
  }

  /// Lowercase without accents, so "Città" matches "citta".
  static String normalize(String s) => s.toLowerCase().replaceAllMapped(
    RegExp('[àáèéìíòóùú]'),
    (m) => const {
      'à': 'a',
      'á': 'a',
      'è': 'e',
      'é': 'e',
      'ì': 'i',
      'í': 'i',
      'ò': 'o',
      'ó': 'o',
      'ù': 'u',
      'ú': 'u',
    }[m[0]]!,
  );
}

/// A stop ("palina"): its public code is its id (measured: stop_code == stop_id).
class Stop {
  Stop({required this.id, required this.name, required this.position, required this.lineIds})
    : searchName = Network.normalize(name);

  factory Stop._fromRow(List<dynamic> r) => Stop(
    id: r[0] as String,
    name: r[1] as String,
    position: LatLng((r[2] as num).toDouble(), (r[3] as num).toDouble()),
    lineIds: (r[4] as List).cast<String>(),
  );

  final String id;
  final String name;
  final LatLng position;
  final List<String> lineIds;
  final String searchName;
}

enum LineKind { bus, tram }

class Line {
  Line({required this.id, required this.name, required this.kind, required this.night, required this.directions});

  factory Line._fromRow(List<dynamic> r) => Line(
    id: r[0] as String,
    name: r[1] as String,
    kind: LineKind.values.byName(r[2] as String),
    night: r[3] as bool,
    directions: [for (final d in r[4] as List) (id: (d as List)[0] as int, headsign: d[1] as String)],
  );

  final String id;
  final String name;
  final LineKind kind;
  final bool night;
  final List<({int id, String headsign})> directions;

  /// "Stazione Trastevere ⇄ Termini", or the single headsign of a circular line.
  String get ends => directions.map((d) => d.headsign).toSet().join(' ⇄ ');
}

/// Active network version and remote configuration, from `api.network` (RNF-06, RNF-08, RF-35).
class NetworkInfo {
  NetworkInfo.fromJson(Map<String, dynamic> json)
    : version = json['version'] as String,
      path = json['path'] as String,
      minAppVersion = json['min_app_version'] as String,
      tileUrl = json['tile_url'] as String,
      noRealtime = {...(json['no_realtime'] as List).cast<String>()};

  final String version;
  final String path;
  final String minAppVersion;
  final String tileUrl;

  /// Lines that never transmit vehicle positions (e.g. 8BUS, 5BUS).
  final Set<String> noRealtime;
}
