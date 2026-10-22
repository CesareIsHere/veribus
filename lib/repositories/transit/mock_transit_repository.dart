import 'package:veribus/models/transit/live.dart';
import 'package:veribus/models/transit/network.dart';
import 'package:veribus/repositories/transit/i_transit_repository.dart';

/// A few stops around Termini whose arrivals show every status, so the app runs with no server at all.
class MockTransitRepository implements ITransitRepository {
  static const List<List<Object>> _stops = [
    [
      '05000',
      'TERMINI (MA-MB-FS)',
      41.90131,
      12.50043,
      ['64', '170', '40'],
    ],
    [
      '70100',
      'NAZIONALE/QUIRINALE',
      41.89968,
      12.49042,
      ['64', '170', '40'],
    ],
    [
      '70001',
      'VENEZIA',
      41.89630,
      12.48250,
      ['64', '170', '40', '8BUS', 'n11'],
    ],
    [
      '74901',
      'CAVOUR',
      41.89584,
      12.49478,
      ['75', 'n11'],
    ],
    [
      '76301',
      'MANIN',
      41.90063,
      12.50273,
      ['75', '8BUS'],
    ],
    [
      '70102',
      'REPUBBLICA',
      41.90250,
      12.49600,
      ['64', '170', '40'],
    ],
    [
      '74902',
      'S. MARIA MAGGIORE',
      41.89750,
      12.49850,
      ['75', 'n11'],
    ],
    [
      '70103',
      'VIMINALE',
      41.89900,
      12.49350,
      ['64', '170', '40', '8BUS'],
    ],
  ];

  /// The demo stops (id, name, lat, lon, lines), shared with the mock journey planner.
  static List<List<Object>> get demoStops => _stops;

  /// Now, down to the minute.
  static DateTime mockMinute() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour, now.minute);
  }

  /// Edge cases on purpose: CAVOUR has stale realtime data (RF-60), MANIN no arrivals in the next hour.
  static const _staleStop = '74901';
  static const _emptyStop = '76301';
  static const List<List<Object>> _lines = [
    ['64', '64', 'bus', false, 'P.ZA STAZIONE S. PIETRO (FL)', 'TERMINI (MA-MB-FS)'],
    ['170', '170', 'bus', false, 'AGRICOLTURA', 'TERMINI (MA-MB-FS)'],
    ['40', '40', 'bus', false, 'BORGO S. ANGELO', 'TERMINI (MA-MB-FS)'],
    ['75', '75', 'bus', false, 'POERIO/MARINO', 'INDIPENDENZA'],
    ['8BUS', '8BUS', 'bus', false, 'GIANICOLENSE/CASALETTO', 'ASTALLI/VENEZIA'],
    ['n11', 'n11', 'bus', true, 'GROTTE CELONI (MC)', 'P.ZA VENEZIA'],
  ];

  @override
  Future<NetworkInfo> networkInfo() async => NetworkInfo.fromJson({
    'version': 'mock',
    'path': 'vmock.json',
    'min_app_version': '0.1.0',
    'no_realtime': ['8BUS'],
  });

  @override
  Future<Network> network(NetworkInfo info) async => Network.fromJson({
    'version': 'mock',
    'stops': _stops,
    'routes': [
      for (final l in _lines)
        [
          ...l.take(4),
          [
            [0, l[4]],
            [1, l[5]],
          ],
        ],
    ],
  });

  @override
  Future<Arrivals> arrivals(List<String> stopIds, {List<String> lineIds = const []}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now().toUtc();
    String at(int minutes) => now.add(Duration(minutes: minutes)).toIso8601String();
    // Slots on the minute: the mock journey timetable (MockJourneysRepository) puts its trips on the same minutes.
    final local = mockMinute();
    final midnight = DateTime(local.year, local.month, local.day);
    // `noTime`: a located vehicle with no prediction, "N stops away" (RF-26). Negative minutes: overdue.
    Map<String, dynamic> arrival(
      String line,
      String status,
      int minutes, {
      Map<String, dynamic>? signal,
      bool noTime = false,
    }) => {
      'sort': minutes,
      'trip_id': '$line-$minutes',
      'route_id': line,
      'direction_id': 1,
      'headsign': _lines.firstWhere((l) => l[0] == line)[5],
      'departure_s': local.add(Duration(minutes: minutes)).difference(midnight).inSeconds,
      'overdue': minutes < 0,
      'status': status,
      'time': noTime ? null : at(minutes),
      'minutes': !noTime && (status == 'confirmed' || status == 'uncertain') ? minutes : null,
      'approximate': !noTime && minutes > 10,
      'signal': signal,
      'stops_away': status == 'scheduled' ? null : 3,
      'vehicle': status == 'scheduled'
          ? null
          : {'id': 'v$line', 'label': '3001', 'lat': 41.8985, 'lon': 12.4870, 'gps_at': now.toIso8601String()},
    };
    final stale = stopIds.length == 1 && stopIds.single == _staleStop;
    List<Map<String, dynamic>> stopArrivals(String id) {
      if (id == _emptyStop) return const [];
      final lines = (_stops.firstWhere((s) => s[0] == id, orElse: () => _stops.first)[4] as List).cast<String>();
      final list = [
        for (final (i, line) in lines.indexed)
          ...switch (i) {
            _ when stale => [arrival(line, 'scheduled', 6 + i * 5)],
            _ when line == '8BUS' => [arrival(line, 'scheduled', 12), arrival(line, 'scheduled', 27)],
            0 => [
              arrival(line, 'scheduled', -6),
              arrival(line, 'confirmed', 4),
              arrival(line, 'confirmed', 14),
              arrival(line, 'confirmed', 21, noTime: true),
            ],
            1 => [
              arrival(line, 'uncertain', 7, signal: {'code': 'S3', 'min': 8}),
              arrival(line, 'suppressed', 9, signal: {'code': 'S2', 'min': 6}),
            ],
            2 => [
              arrival(line, 'uncertain', 11, signal: {'code': 'S5', 'at': now.millisecondsSinceEpoch ~/ 1000 + 600}),
              arrival(line, 'canceled', 18, signal: {'code': 'S1'}),
            ],
            _ => [
              arrival(line, 'uncertain', 2, signal: {'code': 'S4', 'min': 3}),
              arrival(line, 'scheduled', 33),
            ],
          },
      ];
      // The API sorts by time; "N stops away" (no time) sorts by its scheduled slot.
      return list..sort((a, b) => (a['sort'] as int).compareTo(b['sort'] as int));
    }

    return Arrivals.fromJson({
      'computed_at': now.toIso8601String(),
      'feed': {'status': stale ? 'stale' : 'ok', 'age_s': stale ? 900 : 20},
      'stops': [
        for (final id in stopIds)
          {
            'stop_id': id,
            'alerts': id == '70001' ? ['a1'] : <String>[],
            'arrivals': stopArrivals(id),
          },
      ],
      'alerts': [
        {
          'id': 'a1',
          'severity': 1,
          'title': 'Linea 40 deviata',
          'body': 'Per lavori in via Nazionale la linea 40 non transita in piazza Venezia.',
          'route_ids': ['40'],
          'stop_ids': <String>[],
          'general': false,
        },
      ],
      'routes': [
        for (final l in lineIds) {'route_id': l, 'vehicles_in_service': l == '8BUS' ? 0 : 7},
      ],
    });
  }

  @override
  Future<LineDetail?> line(String lineId, int directionId) async {
    final stops = _stops.where((s) => (s[4] as List).contains(lineId)).map((s) => s[0]).toList();
    final idle = lineId == '8BUS' || lineId == 'n11';
    final now = DateTime.now().toUtc();
    return LineDetail.fromJson({
      'headsign': _lines.firstWhere((l) => l[0] == lineId)[directionId == 0 ? 4 : 5],
      'stops': directionId == 0 ? stops.reversed.toList() : stops,
      'shape': [
        for (final s in _stops.where((s) => stops.contains(s[0]))) [s[2], s[3]],
      ],
      'vehicles': idle
          ? <Map<String, dynamic>>[]
          : [
              {
                'id': 'v1',
                'label': '3104',
                'lat': 41.8990,
                'lon': 12.4880,
                'gps_at': now.toIso8601String(),
                'index': 1,
              },
              {
                'id': 'v2',
                'label': '2871',
                'lat': 41.8966,
                'lon': 12.4830,
                'gps_at': now.toIso8601String(),
                'index': 2,
                'signal': {'code': 'S3', 'min': 8},
              },
            ],
      'alerts': <Map<String, dynamic>>[],
      'next_departure': idle ? now.add(const Duration(hours: 5)).toIso8601String() : null,
      'variant_stops': lineId == '64' ? [_staleStop] : <String>[],
      'feed': {'status': 'ok'},
    });
  }

  @override
  Future<List<TimetableDirection>> timetable(String stopId, String lineId, DateTime day) async => [
    TimetableDirection.fromJson({
      'direction_id': 1,
      'headsign': _lines.firstWhere((l) => l[0] == lineId)[5],
      'departures': [for (var s = 5 * 3600 + 1800; s <= 23 * 3600 + 2040; s += 900) s],
    }),
  ];

  @override
  Future<List<ServiceAlert>> alerts() async => [
    ServiceAlert.fromJson({
      'id': 'a2',
      'severity': 2,
      'title': 'Sciopero 3 ottobre',
      'body': 'Venerdì 3 ottobre possibili interruzioni del servizio dalle 8:30 alle 17.',
      'route_ids': <String>[],
    }),
    ServiceAlert.fromJson({
      'id': 'a1',
      'severity': 1,
      'title': 'Linea 40 deviata',
      'body': 'Per lavori in via Nazionale la linea 40 non transita in piazza Venezia.',
      'route_ids': ['40'],
    }),
  ];

  @override
  Future<List<TripDay>> tripHistory(
    String stopId,
    String lineId,
    int directionId,
    int departureSeconds, {
    required bool weekend,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // A mixed record: mostly a few minutes late, a day not tracked, one canceled.
    const delays = [120, 240, null, 60, 300, -45, 180, 420, 90, -1, 150, 200];
    return [
      for (final (i, d) in delays.indexed)
        TripDay.fromJson({
          'date': today.subtract(Duration(days: (i + 1) * (weekend ? 3 : 1))).toIso8601String().substring(0, 10),
          'status': switch (d) {
            null => 'not_tracked',
            -1 => 'canceled',
            _ => 'ran',
          },
          'delay_s': d == null || d == -1 ? null : d,
        }),
    ];
  }
}
