import 'package:latlong2/latlong.dart';

// Realtime data from the `api` schema functions (supabase/migrations/*_api.sql). The server decides what is
// true (status + signal codes); the app decides how to say it (features/stop/components/arrival_tile.dart).

enum ArrivalStatus { confirmed, uncertain, scheduled, canceled, suppressed }

enum FeedStatus { ok, late, stale }

/// Why an arrival is uncertain, canceled or suppressed (spec section 5.3).
class Signal {
  Signal.fromJson(Map<String, dynamic> json)
    : code = json['code'] as String,
      minutes = json['min'] as int?,
      departure = _epoch(json['at']);

  final String code;
  final int? minutes;

  /// S5: scheduled departure from the first stop.
  final DateTime? departure;
}

class VehicleInfo {
  VehicleInfo.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      label = json['label'] as String?,
      position = LatLng((json['lat'] as num).toDouble(), (json['lon'] as num).toDouble()),
      gpsAt = DateTime.parse(json['gps_at'] as String),
      index = json['index'] as int?,
      signal = _signal(json['signal']);

  final String id;

  /// Fleet number painted on the vehicle.
  final String? label;
  final LatLng position;
  final DateTime gpsAt;

  /// Route detail only: index of the stop the vehicle is at or heading to.
  final int? index;

  /// Route detail only: S3 / S4.
  final Signal? signal;
}

class Arrival {
  Arrival.fromJson(Map<String, dynamic> json)
    : tripId = json['trip_id'] as String,
      lineId = json['route_id'] as String,
      directionId = json['direction_id'] as int,
      headsign = json['headsign'] as String? ?? '',
      status = ArrivalStatus.values.byName(json['status'] as String),
      time = json['time'] == null ? null : DateTime.parse(json['time'] as String),
      minutes = json['minutes'] as int?,
      approximate = json['approximate'] as bool? ?? false,
      signal = _signal(json['signal']),
      stopsAway = json['stops_away'] as int?,
      vehicle = json['vehicle'] == null ? null : VehicleInfo.fromJson(json['vehicle'] as Map<String, dynamic>);

  final String tripId;
  final String lineId;
  final int directionId;
  final String headsign;
  final ArrivalStatus status;

  /// Predicted time (confirmed/uncertain), scheduled time otherwise. Null for "N stops away" (RF-26).
  final DateTime? time;

  /// Only for realtime predictions: a scheduled time never becomes minutes (RNF-03).
  final int? minutes;
  final bool approximate;
  final Signal? signal;
  final int? stopsAway;
  final VehicleInfo? vehicle;
}

class ServiceAlert {
  ServiceAlert.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      severity = json['severity'] as int,
      title = json['title'] as String? ?? '',
      body = json['body'] as String? ?? '',
      lineIds = (json['route_ids'] as List).cast<String>();

  final String id;

  /// 2 interruption, 1 reduced service, 0 informative (RF-52).
  final int severity;
  final String title;
  final String body;
  final List<String> lineIds;
}

/// `api.arrivals`: arrivals per stop, the alerts that concern them, vehicles in service per line.
class Arrivals {
  Arrivals.fromJson(Map<String, dynamic> json)
    : computedAt = DateTime.parse(json['computed_at'] as String),
      feed = FeedStatus.values.byName((json['feed'] as Map)['status'] as String),
      byStop = {
        for (final s in json['stops'] as List)
          (s as Map)['stop_id'] as String: [
            for (final a in s['arrivals'] as List) Arrival.fromJson(a as Map<String, dynamic>),
          ],
      },
      alertIdsByStop = {
        for (final s in json['stops'] as List) (s as Map)['stop_id'] as String: (s['alerts'] as List).cast<String>(),
      },
      alerts = {
        for (final a in json['alerts'] as List)
          (a as Map)['id'] as String: ServiceAlert.fromJson(a as Map<String, dynamic>),
      },
      vehiclesInService = {
        for (final r in json['routes'] as List) (r as Map)['route_id'] as String: r['vehicles_in_service'] as int,
      };

  final DateTime computedAt;
  final FeedStatus feed;
  final Map<String, List<Arrival>> byStop;
  final Map<String, List<String>> alertIdsByStop;
  final Map<String, ServiceAlert> alerts;
  final Map<String, int> vehiclesInService;

  List<ServiceAlert> alertsAt(String stopId) => [
    for (final id in alertIdsByStop[stopId] ?? const <String>[]) ?alerts[id],
  ];
}

/// `api.route`: main path of one direction with the vehicles on it.
class LineDetail {
  LineDetail.fromJson(Map<String, dynamic> json)
    : headsign = json['headsign'] as String,
      stopIds = (json['stops'] as List).cast<String>(),
      shape = [
        for (final p in json['shape'] as List? ?? const [])
          LatLng(((p as List)[0] as num).toDouble(), (p[1] as num).toDouble()),
      ],
      vehicles = [for (final v in json['vehicles'] as List) VehicleInfo.fromJson(v as Map<String, dynamic>)],
      alerts = [for (final a in json['alerts'] as List) ServiceAlert.fromJson(a as Map<String, dynamic>)],
      nextDeparture = json['next_departure'] == null ? null : DateTime.parse(json['next_departure'] as String),
      feed = FeedStatus.values.byName((json['feed'] as Map)['status'] as String);

  final String headsign;
  final List<String> stopIds;
  final List<LatLng> shape;
  final List<VehicleInfo> vehicles;
  final List<ServiceAlert> alerts;

  /// RF-34: set only when no vehicle is in service.
  final DateTime? nextDeparture;
  final FeedStatus feed;
}

/// `api.timetable`: departures of one direction, in seconds from the service day's midnight (can exceed 24 h).
class TimetableDirection {
  TimetableDirection.fromJson(Map<String, dynamic> json)
    : directionId = json['direction_id'] as int,
      headsign = json['headsign'] as String,
      departures = (json['departures'] as List).cast<int>();

  final int directionId;
  final String headsign;
  final List<int> departures;
}

DateTime? _epoch(Object? s) => s == null ? null : DateTime.fromMillisecondsSinceEpoch((s as int) * 1000);

Signal? _signal(Object? json) => json == null ? null : Signal.fromJson(json as Map<String, dynamic>);
