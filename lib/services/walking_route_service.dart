import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'walking_route_service.g.dart';

/// The way on foot between two points along the streets: the foot profile of the OSRM server of the OpenStreetMap
/// Germany association (FOSSGIS, https://routing.openstreetmap.de), the same data as the map. Free and keyless, with
/// fair use and no guarantee.
///
/// The points are rounded to about 11 m before they are sent, which is all a street needs, and the callers draw the exact
/// position at both ends. It only draws: the minutes of a journey stay those of the planner.
class WalkingRouteService {
  WalkingRouteService([http.Client? client]) : _client = client ?? http.Client();

  final http.Client _client;

  static const _url = 'https://routing.openstreetmap.de/routed-foot/route/v1/foot/';

  /// Decimals of a coordinate that are sent: 4 is about 11 m.
  static const _decimals = 4;

  /// The path from [from] to [to], or an empty list when the service does not answer or finds none: the caller then
  /// draws the straight line, never an error.
  Future<List<LatLng>> route(LatLng from, LatLng to) async {
    String pair(LatLng p) => '${p.longitude.toStringAsFixed(_decimals)},${p.latitude.toStringAsFixed(_decimals)}';
    final uri = Uri.parse('$_url${pair(from)};${pair(to)}?overview=full&geometries=geojson');
    try {
      final response = await _client.get(uri, headers: {'User-Agent': 'Veribus'}).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return const [];
      return parseOsrm(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
    } on Exception {
      // Timeout, no network, unexpected body.
      return const [];
    }
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
WalkingRouteService walkingRouteService(Ref ref) => WalkingRouteService();
