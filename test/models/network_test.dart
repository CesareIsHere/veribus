import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:veribus/core/widgets/update_required_page.dart';
import 'package:veribus/models/transit/network.dart';

void main() {
  final network = Network.fromJson({
    'version': 'v',
    'stops': [
      [
        '70001',
        'VENEZIA',
        41.8963,
        12.4825,
        ['64'],
      ],
      [
        '05000',
        'TERMINI (MA-MB-FS)',
        41.9013,
        12.5004,
        ['64', '640'],
      ],
      [
        '71000',
        'CITTÀ UNIVERSITARIA',
        41.9030,
        12.5140,
        ['310'],
      ],
    ],
    'routes': [
      ['640', '640', 'bus', false, <List<Object>>[]],
      ['64', '64', 'bus', false, <List<Object>>[]],
      ['310', '310', 'tram', false, <List<Object>>[]],
    ],
  });

  test('search: "64" puts line 64 first, codes match exactly, names ignore case and accents (RF-10)', () {
    expect(network.search('64').lines.map((l) => l.id), ['64', '640']);
    expect(network.search('70001').stops.single.name, 'VENEZIA');
    expect(network.search('termini').stops.single.id, '05000');
    expect(network.search('citta').stops.single.id, '71000');
    expect(network.search('  ').stops, isEmpty);
  });

  test('nearby: within 500 m, widened to 1 km when empty (RF-03)', () {
    expect(network.nearby(const LatLng(41.8965, 12.4826)).map((s) => s.stop.id), ['70001']);
    // ~800 m from Termini, nothing within 500 m.
    expect(network.nearby(const LatLng(41.9013, 12.4910)).map((s) => s.stop.id), ['05000', '70001']);
    expect(network.nearby(const LatLng(41.80, 12.30)), isEmpty);
  });

  test('min app version (RNF-08)', () {
    expect(isOlderVersion('1.0.0', '1.0.1'), isTrue);
    expect(isOlderVersion('1.10.0', '1.9.0'), isFalse);
    expect(isOlderVersion('1.0.0+7', '1.0'), isFalse);
  });
}
