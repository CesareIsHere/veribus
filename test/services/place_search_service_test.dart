import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:veribus/core/utils/app_failure.dart';
import 'package:veribus/services/place_search_service.dart';

/// Photon's answer to "colosseo" and to an address, cut to the fields the app reads.
final Map<String, dynamic> _photon = {
  'type': 'FeatureCollection',
  'features': [
    _feature(12.4924, 41.8902, {
      'name': 'Colosseo',
      'street': 'Piazza del Colosseo',
      'locality': 'Celio',
      'city': 'Roma',
    }),
    // The same place again (the monument on the square): shown once.
    _feature(12.4923, 41.8901, {
      'name': 'Colosseo',
      'street': 'Piazza del Colosseo',
      'locality': 'Celio',
      'city': 'Roma',
    }),
    _feature(12.5214, 41.8796, {
      'street': 'Via Tuscolana',
      'housenumber': '200',
      'district': 'Tuscolano',
      'city': 'Roma',
    }),
    _feature(12.6, 41.95, {'name': 'Via Roma', 'city': 'Guidonia Montecelio'}),
    // Same name, another place.
    _feature(12.45, 41.85, {'name': 'Via Roma', 'district': 'Magliana', 'city': 'Roma'}),
    // Nothing to call it by: left out.
    _feature(12.5, 41.9, {'city': 'Roma'}),
  ],
};

Map<String, dynamic> _feature(double lon, double lat, Map<String, String> properties) => {
  'type': 'Feature',
  'properties': properties,
  'geometry': {
    'type': 'Point',
    'coordinates': [lon, lat],
  },
};

void main() {
  test('names, details and points from Photon, each place once', () {
    final places = parsePhoton(_photon);
    expect([for (final p in places) p.name], ['Colosseo', 'Via Tuscolana 200', 'Via Roma', 'Via Roma']);
    expect(
      [for (final p in places) p.detail],
      ['Piazza del Colosseo, Celio', 'Tuscolano', 'Guidonia Montecelio', 'Magliana'],
    );
    expect(places[1].point.latitude, 41.8796);
    expect(places[1].point.longitude, 12.5214);
  });

  test('sends only the text, leaning towards Rome', () async {
    late Uri asked;
    final service = PlaceSearchService(
      MockClient((request) async {
        asked = request.url;
        return http.Response.bytes(utf8.encode(jsonEncode(_photon)), 200);
      }),
    );
    final places = await service.search('via tuscolana 200');
    expect(places, hasLength(4));
    expect(asked.host, 'photon.komoot.io');
    expect(asked.queryParameters['q'], 'via tuscolana 200');
    expect(asked.queryParameters['bbox'], isNotNull);
    // The centre of Rome, never the user.
    expect(asked.queryParameters['lat'], '41.8933');
  });

  test('a failed search is a network or server failure', () async {
    final offline = PlaceSearchService(MockClient((_) async => throw http.ClientException('offline')));
    await expectLater(offline.search('colosseo'), throwsA(isA<NetworkFailure>()));
    final down = PlaceSearchService(MockClient((_) async => http.Response('', 503)));
    await expectLater(
      down.search('colosseo'),
      throwsA(isA<ServerFailure>().having((f) => f.statusCode, 'status', 503)),
    );
  });
}
