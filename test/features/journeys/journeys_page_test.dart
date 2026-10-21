// The providers are overridden at the root of each test: nothing scoped to declare.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:veribus/core/providers/locale_notifier.dart';
import 'package:veribus/core/providers/network_provider.dart';
import 'package:veribus/core/providers/position_provider.dart';
import 'package:veribus/features/journeys/components/journey_widgets.dart';
import 'package:veribus/features/journeys/journey_page.dart';
import 'package:veribus/features/journeys/journeys_page.dart';
import 'package:veribus/features/journeys/providers/journeys_providers.dart';
import 'package:veribus/features/nearby/providers/nearby_providers.dart';
import 'package:veribus/l10n/gen/app_localizations.dart';
import 'package:veribus/repositories/journeys/journeys_repository_provider.dart';
import 'package:veribus/repositories/journeys/mock_journeys_repository.dart';
import 'package:veribus/repositories/transit/mock_transit_repository.dart';
import 'package:veribus/repositories/transit/transit_repository_provider.dart';
import 'package:veribus/services/map_tile_service.dart';

const _termini = LatLng(41.9010, 12.5003);
const _venezia = LatLng(41.8963, 12.4825);

Future<void> _open(WidgetTester tester, {required LatLng? home, LatLng from = _termini, String? location}) async {
  tester.view
    ..physicalSize = const Size(800, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final transit = MockTransitRepository();
  final router = GoRouter(
    initialLocation: location ?? JourneysPage.route,
    routes: [
      GoRoute(path: JourneysPage.route, builder: (_, _) => const JourneysPage()),
      GoRoute(
        path: JourneyPage.route,
        builder: (_, state) => JourneyPage(args: state.extra is JourneyArgs ? state.extra! as JourneyArgs : null),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        transitRepositoryProvider.overrideWithValue(transit),
        journeysRepositoryProvider.overrideWithValue(MockJourneysRepository()),
        networkInfoProvider.overrideWith((ref) => transit.networkInfo()),
        homePlaceProvider.overrideWithBuild((ref, notifier) => home),
        nearbyOriginProvider.overrideWith((ref) => Stream.value(from)),
        localeProvider.overrideWithBuild((ref, notifier) => null),
        // No tiles in tests: the maps are just the camera, the lines and the markers.
        mapTilesProvider.overrideWith((ref) => Completer<TileProviders>().future),
        positionProvider.overrideWith((ref) => Stream.value(from)),
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  // The planner asks the mock arrivals (300 ms each round of realtime).
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

/// Unmounts the page, so that its one-minute refresh timer is canceled.
Future<void> _close(WidgetTester tester) => tester.pumpWidget(const SizedBox());

void main() {
  testWidgets('without a home: set it first', (tester) async {
    await _open(tester, home: null);
    expect(find.text('You have not set your home yet'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Set home'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('already home: nothing to plan', (tester) async {
    await _open(tester, home: _termini);
    expect(find.text('You are already home'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('from Termini to Venezia: journeys with the state of their first bus, then the detail', (tester) async {
    await _open(tester, home: _venezia);
    expect(find.byType(JourneyCard), findsWidgets);
    expect(find.textContaining('Direct'), findsWidgets);
    expect(find.text('Open in Google Maps'), findsOneWidget);
    // The demo 40 from Termini is canceled and the 170 suppressed: never proposed from there.
    for (final card in tester.widgetList<JourneyCard>(find.byType(JourneyCard))) {
      final first = card.journey.rides.first;
      final tt = card.planner.timetable;
      final line = tt.lineNames[tt.routeLine[first.route]];
      final status = card.journey.realtimeOf(first)?.status.name;
      expect(status, isNot(anyOf('canceled', 'suppressed')), reason: '$line from ${tt.stopNames[first.fromStop]}');
    }

    await tester.tap(find.byType(JourneyCard).first);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.text('Journey'), findsOneWidget);
    expect(find.textContaining('Get on at'), findsWidgets);
    expect(find.textContaining('Home around'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('a journey page opened without its journey says to go back', (tester) async {
    await _open(tester, home: _venezia, location: JourneyPage.route);
    expect(find.textContaining('no longer available'), findsOneWidget);
    await _close(tester);
  });
}
