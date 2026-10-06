import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:veribus/core/widgets/vehicles_layer.dart';
import 'package:veribus/l10n/gen/app_localizations.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/models/transit/network.dart';

const _a = LatLng(41.9000, 12.5000);
const _b = LatLng(41.9010, 12.5010);

Widget _map(List<MapVehicle> vehicles, {ValueChanged<MapVehicle>? onTap, String? selectedId}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: FlutterMap(
    options: const MapOptions(initialCenter: _a, initialZoom: 15),
    children: [VehiclesLayer(vehicles, onTap: onTap, selectedId: selectedId)],
  ),
);

MapVehicle _bus(LatLng at, {String id = 'v1', String line = '64'}) =>
    (id: id, label: line, fleet: '3001', lineId: line, directionId: 0, position: at, kind: LineKind.bus);

void main() {
  testWidgets('the pill says the line, not the fleet number', (tester) async {
    await tester.pumpWidget(_map([_bus(_a)]));
    expect(find.text('64'), findsOneWidget);
    expect(find.text('3001'), findsNothing);
  });

  testWidgets('a vehicle is drawn where the new data puts it, without gliding there', (tester) async {
    await tester.pumpWidget(_map([_bus(_a)]));
    LatLng drawn() => tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.single.point;
    expect(drawn(), _a);

    await tester.pumpWidget(_map([_bus(_b)]));
    expect(drawn(), _b); // at once: no frame in between
  });

  testWidgets('tapping a vehicle reports it', (tester) async {
    final tapped = <String>[];
    await tester.pumpWidget(_map([_bus(_a), _bus(_b, id: 'v2', line: '170')], onTap: (v) => tapped.add(v.id)));
    await tester.tap(find.text('170'));
    expect(tapped, ['v2']);
  });

  test('mapVehicle labels the vehicle with its line and keeps the fleet number apart', () {
    final v = VehicleInfo.fromJson({
      'id': 'v1',
      'label': '3001',
      'lat': 41.9,
      'lon': 12.5,
      'gps_at': '2026-10-06T10:00:00Z',
    });
    final m = mapVehicle(v, lineId: '64', directionId: 1, network: null);
    expect((m.label, m.fleet, m.directionId), ('64', '3001', 1));
  });
}
