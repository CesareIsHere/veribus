import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:veribus/core/widgets/vehicles_layer.dart';

const _a = LatLng(41.9000, 12.5000);
const _b = LatLng(41.9010, 12.5010);
const _far = LatLng(42.2000, 12.5000);

MapVehicle _bus(LatLng at, {String id = '8001'}) => (id: id, label: id, position: at, kind: null);

Widget _map(ValueNotifier<List<MapVehicle>> vehicles, ValueNotifier<int> rebuilds) => MaterialApp(
  home: ValueListenableBuilder<int>(
    valueListenable: rebuilds,
    builder: (context, _, _) => ValueListenableBuilder<List<MapVehicle>>(
      valueListenable: vehicles,
      builder: (context, list, _) => FlutterMap(
        options: const MapOptions(initialCenter: _a, initialZoom: 15),
        children: [VehiclesLayer(list)],
      ),
    ),
  ),
);

LatLng _drawn(WidgetTester tester) => tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.single.point;

const _glide = Duration(seconds: 14);

void main() {
  late ValueNotifier<List<MapVehicle>> vehicles;
  late ValueNotifier<int> rebuilds;

  setUp(() {
    vehicles = ValueNotifier([_bus(_a)]);
    rebuilds = ValueNotifier(0);
  });

  testWidgets('draws the vehicle where the data puts it', (tester) async {
    await tester.pumpWidget(_map(vehicles, rebuilds));
    expect(_drawn(tester), _a);
  });

  testWidgets('new data: the vehicle glides to the new position instead of jumping', (tester) async {
    await tester.pumpWidget(_map(vehicles, rebuilds));
    vehicles.value = [_bus(_b)];
    await tester.pump();
    expect(_drawn(tester), _a);

    await tester.pump(_glide * 0.5);
    final half = _drawn(tester);
    expect(half.latitude, closeTo((_a.latitude + _b.latitude) / 2, 1e-6));
    expect(half.longitude, closeTo((_a.longitude + _b.longitude) / 2, 1e-6));

    await tester.pump(_glide * 0.5);
    expect(_drawn(tester), _b);
  });

  testWidgets('a rebuild with the same data does not restart the glide', (tester) async {
    await tester.pumpWidget(_map(vehicles, rebuilds));
    vehicles.value = [_bus(_b)];
    await tester.pump();
    await tester.pump(_glide * 0.5);

    // The page rebuilds (a GPS fix, say) with the same vehicles: the glide keeps its pace.
    vehicles.value = [_bus(_b)];
    rebuilds.value++;
    await tester.pump();
    await tester.pump(_glide * 0.5);
    expect(_drawn(tester), _b);
  });

  testWidgets('a jump of kilometers is a different trip or bad data: no glide across the city', (tester) async {
    await tester.pumpWidget(_map(vehicles, rebuilds));
    vehicles.value = [_bus(_far)];
    await tester.pump();
    expect(_drawn(tester), _far);
  });

  testWidgets('new data while gliding starts from where the vehicle is drawn, not from the old target', (tester) async {
    await tester.pumpWidget(_map(vehicles, rebuilds));
    vehicles.value = [_bus(_b)];
    await tester.pump();
    await tester.pump(_glide * 0.5);
    final shown = _drawn(tester);

    vehicles.value = [_bus(_a)];
    await tester.pump();
    expect(_drawn(tester).latitude, closeTo(shown.latitude, 1e-9));
    await tester.pump(_glide);
    expect(_drawn(tester), _a);
  });

  testWidgets('a vehicle that shows up for the first time appears in place', (tester) async {
    await tester.pumpWidget(_map(vehicles, rebuilds));
    vehicles.value = [_bus(_a), _bus(_b, id: '8002')];
    await tester.pump();
    final points = tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.map((m) => m.point).toList();
    expect(points, [_a, _b]);
  });
}
