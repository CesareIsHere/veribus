// The providers are overridden at the root of each test: nothing scoped to declare.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:veribus/core/providers/locale_notifier.dart';
import 'package:veribus/core/providers/network_provider.dart';
import 'package:veribus/core/providers/position_provider.dart';
import 'package:veribus/features/journeys/journey_page.dart';
import 'package:veribus/l10n/gen/app_localizations.dart';
import 'package:veribus/models/journeys/journey_planner.dart';
import 'package:veribus/models/journeys/timetable_builder.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/repositories/transit/mock_transit_repository.dart';
import 'package:veribus/repositories/transit/transit_repository_provider.dart';
import 'package:veribus/services/map_tile_service.dart';

int _hm(String hhmm) => int.parse(hhmm.substring(0, 2)) * 3600 + int.parse(hhmm.substring(3)) * 60;

GtfsTrip _trip(String line, List<String> stops, List<String> times) => (
  line: line,
  direction: 0,
  headsign: 'To ${stops.last}',
  stops: stops,
  times: [for (final t in times) _hm(t)],
  previousDay: false,
);

void main() {
  testWidgets('a journey with a change: each step, how the change went, what to take if it is missed', (tester) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final stops = <GtfsStop>[
      for (final (i, id) in ['A', 'B', 'C'].indexed) (id: id, name: 'STOP $id', lat: 41.9 + i * 0.009, lon: 12.5),
    ];
    final tt = buildTimetable(
      date: 20261020,
      stops: stops,
      trips: [
        _trip('X', ['A', 'B'], ['10:00', '10:10']),
        _trip('Y', ['B', 'C'], ['10:15', '10:25']),
        _trip('Y', ['B', 'C'], ['10:30', '10:40']),
      ],
    );
    Future<Arrivals> noRealtime(List<String> stops, List<String> lines) async => Arrivals.fromJson({
      'computed_at': DateTime(2026, 10, 20, 9, 50).toUtc().toIso8601String(),
      'feed': {'status': 'ok'},
      'stops': <Map<String, dynamic>>[],
      'alerts': <Map<String, dynamic>>[],
      'routes': <Map<String, dynamic>>[],
    });
    final planner = JourneyPlanner(tt, noRealtime);
    const from = LatLng(41.9 + 50 / 110540, 12.5);
    const to = LatLng(41.918 + 50 / 110540, 12.5);
    final journey = (await planner.plan(from: from, to: to, at: DateTime(2026, 10, 20, 9, 50), options: 1)).first;
    expect(journey.rides, hasLength(2));

    final transit = MockTransitRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transitRepositoryProvider.overrideWithValue(transit),
          networkInfoProvider.overrideWith((ref) => transit.networkInfo()),
          localeProvider.overrideWithBuild((ref, notifier) => null),
          mapTilesProvider.overrideWith((ref) => Completer<TileProviders>().future),
          positionProvider.overrideWith((ref) => Stream.value(from)),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: JourneyPage(
            args: JourneyArgs(planner: planner, journey: journey, from: from, to: to),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('1 change'), findsNothing); // the header joins duration and changes
    expect(find.textContaining('1 change'), findsOneWidget);
    expect(find.text('Get on at STOP A, 10:00'), findsOneWidget);
    expect(find.text('Get off at STOP B, 10:10 · 1 stop'), findsOneWidget);
    expect(find.text('Wait 5 min'), findsOneWidget);
    // The mock history has the same delays for both trips: with five minutes to spare, every tracked day worked.
    expect(find.text('This change worked 10 times out of 10'), findsOneWidget);
    expect(find.text('If you miss it: next Y at 10:30'), findsOneWidget);
    expect(find.textContaining('Home around'), findsOneWidget);
  });
}
