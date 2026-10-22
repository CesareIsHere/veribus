import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veribus/core/utils/app_failure.dart';
import 'package:veribus/models/journeys/place.dart';

part 'place_search_service.g.dart';

/// Addresses and places by name: Photon (OpenStreetMap data, no account or key; https://photon.komoot.io), the
/// same data as the map. Only the typed text is sent: the search leans towards the centre of Rome, never towards the
/// user's position (RNF-04).
class PlaceSearchService {
  PlaceSearchService([http.Client? client]) : _client = client ?? http.Client();

  final http.Client _client;

  static const _url = 'https://photon.komoot.io/api/';
  static const _centre = LatLng(41.8933, 12.4829);

  /// The area the network serves (lon, lat, lon, lat): a Via Appia in another town is never the one meant.
  static const _bbox = '12.20,41.60,12.90,42.15';

  /// The address under [point] (the pin of the map), or null when there is none or the service does not answer: the
  /// caller then shows no address, never an error.
  Future<Place?> reverse(LatLng point) async {
    final uri = Uri.parse('${_url}reverse')
        .replace(queryParameters: {'lat': '${point.latitude}', 'lon': '${point.longitude}', 'limit': '1'});
    try {
      final response = await _client.get(uri, headers: {'User-Agent': 'Veribus'}).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return null;
      return parsePhoton(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>).firstOrNull;
    } on Exception {
      return null;
    }
  }

  Future<List<Place>> search(String query) async {
    final uri = Uri.parse(_url).replace(
      queryParameters: {
        'q': query,
        'limit': '10',
        'lat': '${_centre.latitude}',
        'lon': '${_centre.longitude}',
        'bbox': _bbox,
      },
    );
    final http.Response response;
    try {
      response = await _client.get(uri, headers: {'User-Agent': 'Veribus'}).timeout(const Duration(seconds: 8));
    } on Exception {
      throw const NetworkFailure();
    }
    if (response.statusCode != 200) throw ServerFailure(statusCode: response.statusCode);
    return parsePhoton(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
  }
}

/// Closer than this, two results with the same name are one place (a square, its pieces of street, its monument).
const _sameMeters = 200;

/// Photon's GeoJSON → places, the same place found more than once shown once.
List<Place> parsePhoton(Map<String, dynamic> json) {
  final places = <Place>[];
  for (final feature in (json['features'] as List).cast<Map<String, dynamic>>()) {
    final p = (feature['properties'] as Map).cast<String, dynamic>();
    final [lon, lat] = ((feature['geometry'] as Map)['coordinates'] as List).cast<num>();
    final street = [p['street'], p['housenumber']].nonNulls.join(' ');
    final name = (p['name'] as String?) ?? (street.isEmpty ? null : street);
    if (name == null) continue;
    final city = p['city'] as String?;
    final detail = {
      if (street.isNotEmpty && street != name) street,
      ?(p['locality'] ?? p['district']) as String?,
      if (city != null && city != 'Roma') city,
    }.join(', ');
    final point = LatLng(lat.toDouble(), lon.toDouble());
    final same = places.any(
      (p) => p.name.toLowerCase() == name.toLowerCase() && const Distance()(p.point, point) < _sameMeters,
    );
    if (!same) places.add(Place(name: name, detail: detail, point: point));
  }
  return places;
}

@Riverpod(keepAlive: true)
PlaceSearchService placeSearchService(Ref ref) => PlaceSearchService();
