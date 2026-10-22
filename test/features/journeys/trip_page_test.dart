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
import 'package:veribus/features/journeys/trip_page.dart';
import 'package:veribus/l10n/gen/app_localizations.dart';
import 'package:veribus/models/journeys/journey_planner.dart';
import 'package:veribus/models/journeys/place.dart';
import 'package:veribus/models/journeys/timetable_builder.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/repositories/transit/mock_transit_repository.dart';
import 'package:veribus/repositories/transit/transit_repository_provider.dart';
import 'package:veribus/services/location_service.dart';
import 'package:veribus/services/map_tile_service.dart';

/// The foreground service of the journey: what it was started with, each time.
class _Location extends LocationService {
  final started = <({String title, String text})>[];
  final cancelled = <int>[];

  @override
  Stream<LatLng> followFixes({required String title, required String text, required String channelName}) {
    started.add((title: title, text: text));
    final n = started.length;
    final controller = StreamController<LatLng>(onCancel: () => cancelled.add(n));
    return controller.stream;
  }
}

int _hm(String hhmm) => int.parse(hhmm.substring(0, 2)) * 3600 + int.parse(hhmm.substring(3)) * 60;

// Stops 1 km apart on a north-south street.
final _stops = <GtfsStop>[
  for (final (i, id) in ['A', 'B', 'C', 'D'].indexed) (id: id, name: 'STOP $id', lat: 41.9 + i * 0.009, lon: 12.5),
];
LatLng _at(String stop, {double metres = 0}) {
  final s = _stops.firstWhere((s) => s.id == stop);
  return LatLng(s.lat + metres / 110540, s.lon);
}

void main() {
  testWidgets('walk to the stop, wait, ride and get off: one instruction at a time', (tester) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final tt = buildTimetable(
      date: 20261020,
      stops: _stops,
      trips: [
        (
          line: 'X',
          direction: 0,
          headsign: 'To D',
          stops: ['A', 'B', 'C', 'D'],
          times: [
            for (final t in ['10:00', '10:10', '10:20', '10:30']) _hm(t),
          ],
          previousDay: false,
        ),
      ],
    );
    Future<Arrivals> none(List<String> stops, List<String> lines) async => Arrivals.fromJson({
      'computed_at': DateTime(2026, 10, 20, 9, 50).toUtc().toIso8601String(),
      'feed': {'status': 'ok'},
      'stops': <Map<String, dynamic>>[],
      'alerts': <Map<String, dynamic>>[],
      'routes': <Map<String, dynamic>>[],
    });
    final planner = JourneyPlanner(tt, none);
    final from = _at('A', metres: -300);
    final to = _at('D', metres: 300);
    final journey = (await planner.plan(from: from, to: to, at: DateTime(2026, 10, 20, 9, 50), options: 1)).first;
    expect(journey.rides, hasLength(1));

    final position = StreamController<LatLng?>();
    addTearDown(position.close);
    final transit = MockTransitRepository();
    final location = _Location();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transitRepositoryProvider.overrideWithValue(transit),
          networkInfoProvider.overrideWith((ref) => transit.networkInfo()),
          localeProvider.overrideWithBuild((ref, notifier) => null),
          mapTilesProvider.overrideWith((ref) => Completer<TileProviders>().future),
          positionProvider.overrideWith((ref) => position.stream),
          locationServiceProvider.overrideWithValue(location),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TripPage(
            args: JourneyArgs(
              planner: planner,
              journey: journey,
              from: Place(name: 'Your location', point: from),
              to: Place(name: 'Home', point: to, type: PlaceType.home),
            ),
          ),
        ),
      ),
    );
    Future<void> move(LatLng p) async {
      position.add(p);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    }

    await move(from);
    // The ongoing notification starts with the step: walk to the stop, which bus.
    expect(location.started.single.title, 'Walk to STOP A');
    expect(location.started.single.text, 'Your X comes at 10:00');
    expect(find.text('Walk to STOP A'), findsOneWidget);
    expect(find.textContaining('min'), findsWidgets);
    expect(find.text('Your X comes at 10:00'), findsOneWidget);

    await move(_at('A', metres: 20));
    expect(find.text('Get on the X'), findsOneWidget);
    expect(location.started.last.title, 'Get on the X');
    // Moving along the same step does not restart the service: only a new step changes the notification.
    final restarts = location.started.length;
    await move(_at('A', metres: 25));
    expect(location.started, hasLength(restarts));

    await move(_at('B', metres: 10));
    expect(find.text('Get off in 2 stops'), findsOneWidget);
    expect(location.started.last.title, 'Get off in 2 stops');
    expect(location.started.last.text, 'at STOP D · 10:30');
    expect(find.text('STOP D · get off'), findsOneWidget);

    await move(_at('C', metres: 10));
    expect(find.text('Get off at the next stop'), findsOneWidget);

    await move(_at('D', metres: 20));
    expect(find.text('Walk to Home'), findsOneWidget);

    await move(to);
    expect(find.text('You have arrived'), findsOneWidget);
    // Arrived: the last service is cancelled and no new one starts, so the notification goes away.
    expect(location.cancelled, contains(location.started.length));
  });

  testWidgets('without its journey the page says to go back', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localeProvider.overrideWithBuild((ref, notifier) => null),
          mapTilesProvider.overrideWith((ref) => Completer<TileProviders>().future),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TripPage(args: null),
        ),
      ),
    );
    expect(find.textContaining('no longer available'), findsOneWidget);
  });
}
