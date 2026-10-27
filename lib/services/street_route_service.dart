import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veribus/core/utils/app_failure.dart';

part 'street_route_service.g.dart';

/// Paths along the streets from the OSRM server of the OpenStreetMap Germany association (FOSSGIS,
/// https://routing.openstreetmap.de), the same data as the map. Free and keyless, with fair use (a request a second)
/// and no guarantee. It only draws: the minutes of a journey stay those of the planner.
///
/// [route] is the way on foot between two points. [drive] is the way by road through a sequence of stops, for the
/// buses whose path the app does not have (a variant of a line): the car profile is the nearest thing to a bus.
///
/// An answer that says "no way" is an empty list. A request that did not get an answer (no network, a timeout, the
/// server busy or down) throws: it is not an answer, and whoever keeps the result must not keep that.
class StreetRouteService {
  StreetRouteService([http.Client? client, this.pause = const Duration(milliseconds: 400)])
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Between two requests: the server asks for one a second at most, and a journey draws several walks at once.
  final Duration pause;
  Future<void> _queue = Future.value();

  static const _base = 'https://routing.openstreetmap.de/';

  /// Decimals of a coordinate that are sent: 4 is about 11 m.
  static const _decimals = 4;

  /// The most stops one request carries.
  static const maxStops = 60;

  static String pair(LatLng p) => '${p.longitude.toStringAsFixed(_decimals)},${p.latitude.toStringAsFixed(_decimals)}';

  /// The path on foot from [from] to [to]; the callers draw the exact position at both ends. Empty when there is no
  /// way. Throws when the service did not answer.
  Future<List<LatLng>> route(LatLng from, LatLng to) => _get('routed-foot/route/v1/foot/${pair(from)};${pair(to)}');

  /// The path by road through [stops], in order. Empty when there is no way. Throws when the service did not answer.
  Future<List<LatLng>> drive(List<LatLng> stops) => stops.length < 2 || stops.length > maxStops
      ? Future.value(const [])
      : _get('routed-car/route/v1/driving/${stops.map(pair).join(';')}');

  Future<List<LatLng>> _get(String path) async {
    final uri = Uri.parse('$_base$path?overview=full&geometries=geojson');
    final http.Response response;
    try {
      response = await _send(uri);
    } on Exception {
      throw const NetworkFailure(); // no network, a timeout
    }
    // Busy (429) or down (5xx): try again later. Anything else the server says is its answer.
    if (response.statusCode == 429 || response.statusCode >= 500) throw ServerFailure(statusCode: response.statusCode);
    if (response.statusCode != 200) return const [];
    try {
      return parseOsrm(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
    } on Object {
      return const []; // not an OSRM answer
    }
  }

  /// One request at a time, with a pause after each.
  Future<http.Response> _send(Uri uri) {
    final answer = _queue.then(
      (_) => _client.get(uri, headers: {'User-Agent': 'Veribus'}).timeout(const Duration(seconds: 8)),
    );
    Future<void> wait(Object? _) => pause == Duration.zero ? Future.value() : Future<void>.delayed(pause);
    _queue = answer.then<void>(wait, onError: wait);
    return answer;
  }
}

/// The points of the first route of an OSRM answer (`geometries=geojson`), or none.
List<LatLng> parseOsrm(Map<String, dynamic> json) {
  final routes = json['routes'];
  if (json['code'] != 'Ok' || routes is! List || routes.isEmpty) return const [];
  final coordinates = ((routes.first as Map<String, dynamic>)['geometry'] as Map<String, dynamic>)['coordinates'];
  return [
    for (final c in (coordinates as List).cast<List<dynamic>>())
      LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
  ];
}

@Riverpod(keepAlive: true)
StreetRouteService streetRouteService(Ref ref) => StreetRouteService();
