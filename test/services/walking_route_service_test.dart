import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:veribus/features/journeys/providers/journeys_providers.dart';
import 'package:veribus/services/walking_route_service.dart';

const _answer = <String, dynamic>{
  'code': 'Ok',
  'routes': [
    {
      'geometry': {
        'coordinates': [
          [12.500274, 41.901016],
          [12.499973, 41.900739],
          [12.4975, 41.8993],
        ],
      },
    },
  ],
};

void main() {
  test('the path along the streets, as latitude and longitude', () {
    final points = parseOsrm(_answer);
    expect(points, hasLength(3));
    expect(points.first, const LatLng(41.901016, 12.500274));
    expect(parseOsrm({'code': 'NoRoute', 'routes': <Object>[]}), isEmpty);
  });

  test('asks the foot profile with the points rounded to about 11 m; nothing when the service fails', () async {
    late Uri asked;
    final service = WalkingRouteService(
      MockClient((request) async {
        asked = request.url;
        return http.Response.bytes(utf8.encode(jsonEncode(_answer)), 200);
      }),
    );
    final route = await service.route(const LatLng(41.9010123, 12.5003456), const LatLng(41.8993, 12.4975));
    expect(route, hasLength(3));
    expect(asked.path, contains('routed-foot'));
    expect(asked.path, endsWith('12.5003,41.9010;12.4975,41.8993'));
    expect(asked.queryParameters['geometries'], 'geojson');

    final down = WalkingRouteService(MockClient((_) async => http.Response('', 429)));
    expect(await down.route(const LatLng(41.9, 12.5), const LatLng(41.8, 12.4)), isEmpty);
    final offline = WalkingRouteService(MockClient((_) async => throw http.ClientException('offline')));
    expect(await offline.route(const LatLng(41.9, 12.5), const LatLng(41.8, 12.4)), isEmpty);
  });

  test('a walk is drawn along the streets with the exact ends, or straight when there is no route', () {
    const from = LatLng(41.9, 12.5);
    const to = LatLng(41.8, 12.4);
    const street = [LatLng(41.9001, 12.5001), LatLng(41.8001, 12.4001)];
    expect(walkLine(from, to, street), [from, ...street, to]);
    expect(walkLine(from, to, const []), [from, to]);
    expect(walkLine(from, to, null), [from, to]);
  });
}
