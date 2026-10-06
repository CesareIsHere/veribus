import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:veribus/core/providers/position_provider.dart';
import 'package:veribus/core/widgets/transit_map.dart';
import 'package:veribus/l10n/gen/app_localizations.dart';
import 'package:veribus/services/map_tile_service.dart';

const _stop = LatLng(41.8955, 12.4823);
const _bus = LatLng(41.9300, 12.5400); // ~5 km away
const _user = LatLng(41.8800, 12.4500);

Widget _app(MapController controller, ValueNotifier<List<LatLng>> fit, {LatLng? user}) => ProviderScope(
  overrides: [
    // No tiles in tests: the map is just the camera and the markers.
    mapTilesProvider.overrideWith((ref) => Completer<TileProviders>().future),
    positionProvider.overrideWith((ref) => Stream.value(user)),
  ],
  child: MaterialApp(
    locale: const Locale('it'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: ValueListenableBuilder<List<LatLng>>(
        valueListenable: fit,
        builder: (context, points, _) => TransitMap(controller: controller, fit: points, children: const []),
      ),
    ),
  ),
);

bool _inView(MapController c, LatLng p) => c.camera.visibleBounds.contains(p);

void main() {
  late MapController controller;

  setUp(() => controller = MapController());

  testWidgets('opens with the bus, the stop and the user all in view, however far the bus is', (tester) async {
    await tester.pumpWidget(_app(controller, ValueNotifier([_bus, _stop, _user]), user: _user));
    await tester.pump();

    for (final p in [_bus, _stop, _user]) {
      expect(_inView(controller, p), isTrue, reason: '$p is out of view');
    }
    // A fixed street-level zoom (the old behavior) would have shown none of the far points.
    expect(controller.camera.zoom, lessThan(15));
  });

  testWidgets('a nearby bus is framed close, not at the far zoom', (tester) async {
    const near = LatLng(41.8960, 12.4830);
    await tester.pumpWidget(_app(controller, ValueNotifier([near, _stop])));
    await tester.pump();

    expect(_inView(controller, near), isTrue);
    expect(_inView(controller, _stop), isTrue);
    expect(controller.camera.zoom, greaterThan(15));
  });

  testWidgets('the user position arriving later is brought into view', (tester) async {
    final fit = ValueNotifier([_bus, _stop]);
    await tester.pumpWidget(_app(controller, fit, user: _user));
    await tester.pump();
    expect(_inView(controller, _user), isFalse);

    fit.value = [_bus, _stop, _user];
    await tester.pump();
    await tester.pump();
    expect(_inView(controller, _user), isTrue);
    expect(_inView(controller, _bus), isTrue);
  });

  testWidgets('a bus that drifts out of view is framed again', (tester) async {
    final fit = ValueNotifier([const LatLng(41.8960, 12.4830), _stop]);
    await tester.pumpWidget(_app(controller, fit));
    await tester.pump();

    fit.value = [_bus, _stop];
    await tester.pump();
    await tester.pump();
    expect(_inView(controller, _bus), isTrue);
    expect(_inView(controller, _stop), isTrue);
  });

  testWidgets('once the user moved the map it is left alone', (tester) async {
    final fit = ValueNotifier([const LatLng(41.8960, 12.4830), _stop]);
    await tester.pumpWidget(_app(controller, fit));
    await tester.pump();

    await tester.drag(find.byType(FlutterMap), const Offset(120, 60));
    await tester.pump();
    final before = controller.camera.center;

    fit.value = [_bus, _stop];
    await tester.pump();
    await tester.pump();
    expect(controller.camera.center, before);
    expect(_inView(controller, _bus), isFalse);
  });
}
