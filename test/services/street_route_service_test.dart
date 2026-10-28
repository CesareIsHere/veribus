import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:veribus/core/utils/app_failure.dart';
import 'package:veribus/features/journeys/providers/journeys_providers.dart';
import 'package:veribus/services/street_route_service.dart';

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

  test('asks the foot profile with the points rounded to about 11 m', () async {
    late Uri asked;
    final service = StreetRouteService(
      MockClient((request) async {
        asked = request.url;
        return http.Response.bytes(utf8.encode(jsonEncode(_answer)), 200);
      }),
      Duration.zero,
    );
    final route = await service.route(const LatLng(41.9010123, 12.5003456), const LatLng(41.8993, 12.4975));
    expect(route, hasLength(3));
    expect(asked.path, contains('routed-foot'));
    expect(asked.path, endsWith('12.5003,41.9010;12.4975,41.8993'));
    expect(asked.queryParameters['geometries'], 'geojson');
  });

  test('asks the car profile through the stops in order, and not for too many or too few', () async {
    final asked = <Uri>[];
    final service = StreetRouteService(
      MockClient((request) async {
        asked.add(request.url);
        return http.Response.bytes(utf8.encode(jsonEncode(_answer)), 200);
      }),
      Duration.zero,
    );
    final stops = [for (var i = 0; i < 3; i++) LatLng(41.9 + i * 0.001, 12.5)];
    expect(await service.drive(stops), hasLength(3));
    expect(asked.single.path, contains('routed-car'));
    expect(asked.single.path, endsWith('12.5000,41.9000;12.5000,41.9010;12.5000,41.9020'));
    expect(await service.drive([stops.first]), isEmpty);
    expect(await service.drive([for (var i = 0; i <= StreetRouteService.maxStops; i++) stops.first]), isEmpty);
    expect(asked, hasLength(1));
  });

  test('no way is an answer; no answer is an error, so that it is not kept as "no way"', () async {
    const a = LatLng(41.9, 12.5);
    const b = LatLng(41.8, 12.4);
    final none = StreetRouteService(
      MockClient((_) async => http.Response('{"code":"NoRoute","routes":[]}', 200)),
      Duration.zero,
    );
    expect(await none.route(a, b), isEmpty);
    final garbage = StreetRouteService(MockClient((_) async => http.Response('<html>', 200)), Duration.zero);
    expect(await garbage.route(a, b), isEmpty);

    final busy = StreetRouteService(MockClient((_) async => http.Response('', 429)), Duration.zero);
    await expectLater(busy.route(a, b), throwsA(isA<ServerFailure>()));
    final down = StreetRouteService(MockClient((_) async => http.Response('', 503)), Duration.zero);
    await expectLater(down.drive([a, b]), throwsA(isA<ServerFailure>()));
    final offline = StreetRouteService(MockClient((_) async => throw http.ClientException('offline')), Duration.zero);
    await expectLater(offline.route(a, b), throwsA(isA<NetworkFailure>()));
  });

  test('requests go one at a time, a pause apart', () async {
    final starts = <DateTime>[];
    final service = StreetRouteService(
      MockClient((request) async {
        starts.add(DateTime.now());
        return http.Response.bytes(utf8.encode(jsonEncode(_answer)), 200);
      }),
      const Duration(milliseconds: 120),
    );
    const a = LatLng(41.9, 12.5);
    const b = LatLng(41.8, 12.4);
    await Future.wait([service.route(a, b), service.route(b, a), service.route(a, b)]);
    expect(starts, hasLength(3));
    expect(starts[1].difference(starts[0]).inMilliseconds, greaterThanOrEqualTo(100));
    expect(starts[2].difference(starts[1]).inMilliseconds, greaterThanOrEqualTo(100));
  });

  testWidgets('a path that got no answer is asked again, not kept as "no way"', (tester) async {
    var calls = 0;
    final service = StreetRouteService(
      MockClient((_) async {
        calls++;
        return calls == 1 ? http.Response('', 503) : http.Response.bytes(utf8.encode(jsonEncode(_answer)), 200);
      }),
      Duration.zero,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [streetRouteServiceProvider.overrideWithValue(service)],
        child: Consumer(
          builder: (context, ref, _) {
            final route = ref.watch(walkRouteProvider(const LatLng(41.9, 12.5), const LatLng(41.8, 12.4)));
            return Text(route.hasValue ? 'points ${route.value!.length}' : 'waiting', textDirection: TextDirection.ltr);
          },
        ),
      ),
    );
    await tester.pump();
    expect(find.text('waiting'), findsOneWidget); // the first request failed: no straight line kept as the answer
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('points 3'), findsOneWidget);
    expect(calls, 2);
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
