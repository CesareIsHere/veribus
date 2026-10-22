// The providers are overridden at the root of each test: nothing scoped to declare.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:veribus/core/providers/locale_notifier.dart';
import 'package:veribus/core/providers/network_provider.dart';
import 'package:veribus/core/providers/position_provider.dart';
import 'package:veribus/core/providers/shared_preferences_provider.dart';
import 'package:veribus/features/journeys/components/journey_widgets.dart';
import 'package:veribus/features/journeys/journey_page.dart';
import 'package:veribus/features/journeys/journeys_page.dart';
import 'package:veribus/features/journeys/place_search_page.dart';
import 'package:veribus/features/journeys/providers/journeys_providers.dart';
import 'package:veribus/features/journeys/save_place_page.dart';
import 'package:veribus/features/nearby/providers/nearby_providers.dart';
import 'package:veribus/l10n/gen/app_localizations.dart';
import 'package:veribus/models/journeys/place.dart';
import 'package:veribus/repositories/journeys/journeys_repository_provider.dart';
import 'package:veribus/repositories/journeys/mock_journeys_repository.dart';
import 'package:veribus/repositories/transit/mock_transit_repository.dart';
import 'package:veribus/repositories/transit/transit_repository_provider.dart';
import 'package:veribus/services/map_tile_service.dart';
import 'package:veribus/services/place_search_service.dart';

const _termini = LatLng(41.9010, 12.5003);
const _venezia = LatLng(41.8963, 12.4825);

/// Photon, answering every search with Piazza Venezia.
class _Search extends PlaceSearchService {
  final asked = <String>[];

  @override
  Future<List<Place>> search(String query) async {
    asked.add(query);
    return [const Place(name: 'Piazza Venezia', detail: 'Trevi', point: _venezia)];
  }
}

/// The preferences in memory: only what the recent places use.
class _Prefs extends Fake implements SharedPreferencesWithCache {
  final values = <String, String>{};

  @override
  String? getString(String key) => values[key];

  @override
  Future<void> setString(String key, String value) async => values[key] = value;
}

Future<void> _open(
  WidgetTester tester, {
  required LatLng? home,
  LatLng from = _termini,
  String? location,
  _Search? search,
}) async {
  tester.view
    ..physicalSize = const Size(800, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final transit = MockTransitRepository();
  final router = GoRouter(
    initialLocation: location ?? JourneysPage.route,
    routes: [
      GoRoute(
        path: JourneysPage.route,
        builder: (_, state) => JourneysPage(args: state.extra is JourneysArgs ? state.extra! as JourneysArgs : null),
      ),
      GoRoute(
        path: PlaceSearchPage.route,
        builder: (_, state) => PlaceSearchPage(
          args: state.extra is PlaceSearchArgs ? state.extra! as PlaceSearchArgs : const PlaceSearchArgs(),
        ),
      ),
      GoRoute(
        path: SavePlacePage.route,
        builder: (_, state) => SavePlacePage(
          args: state.extra is SavePlaceArgs
              ? state.extra! as SavePlaceArgs
              : const SavePlaceArgs(type: PlaceType.home),
        ),
      ),
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
        placeSearchServiceProvider.overrideWithValue(search ?? _Search()),
        sharedPreferencesProvider.overrideWithValue(_Prefs()),
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
  testWidgets('without a home or a destination: asks where to', (tester) async {
    await _open(tester, home: null);
    expect(find.text('Where to?'), findsWidgets);
    expect(find.widgetWithText(FilledButton, 'Search for an address'), findsOneWidget);
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
    expect(find.text('Your location'), findsOneWidget);
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
    expect(find.text('Start'), findsOneWidget);
    expect(find.textContaining('get off'), findsWidgets);
    await _close(tester);
  });

  testWidgets('any destination: searched by address, then its journeys', (tester) async {
    final search = _Search();
    await _open(tester, home: null, search: search);
    await tester.tap(find.widgetWithText(FilledButton, 'Search for an address'));
    await tester.pumpAndSettle();
    expect(find.text('Set home'), findsOneWidget); // saved places come first, to set when missing

    await tester.enterText(find.byType(TextField).last, 'pia');
    await tester.enterText(find.byType(TextField).last, 'piazza ven');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(search.asked, ['piazza ven']); // once, after the typing stopped
    await tester.tap(find.text('Piazza Venezia').first);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.text('Piazza Venezia'), findsOneWidget); // the destination, on top of its journeys
    expect(find.byType(JourneyCard), findsWidgets);

    await tester.tap(find.byType(JourneyCard).first);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.text('Start'), findsOneWidget);
    expect(find.textContaining('Piazza Venezia'), findsWidgets);
    await _close(tester);
  });

  testWidgets('the options leave the metro out and say so on the chip', (tester) async {
    await _open(tester, home: _venezia);
    await tester.tap(find.widgetWithText(ActionChip, 'Options'));
    await tester.pumpAndSettle();
    expect(find.text('When and how'), findsOneWidget);
    await tester.tap(find.text('Use the metro'));
    await tester.pump();
    await tester.tap(find.text('Show journeys'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.byType(JourneyCard), findsWidgets);
    expect(find.byType(Badge), findsWidgets);
    await _close(tester);
  });

  testWidgets('at the chosen destination: nothing to plan', (tester) async {
    await _open(tester, home: null, from: _venezia);
    await tester.tap(find.widgetWithText(FilledButton, 'Search for an address'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'venezia');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.tap(find.text('Piazza Venezia').first);
    await tester.pumpAndSettle();
    expect(find.text('You are already there'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('home by address: the map goes there, the user saves', (tester) async {
    await _open(tester, home: null, location: SavePlacePage.route);
    await tester.tap(find.text('Search for an address'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'piazza venezia');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.tap(find.text('Piazza Venezia').first);
    await tester.pumpAndSettle();
    expect(find.text('Piazza Venezia'), findsOneWidget); // the address under the pin
    await tester.tap(find.widgetWithText(FilledButton, 'Save home'));
    await tester.pump();
    final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    final home = container.read(homePlaceProvider)!;
    expect(const Distance()(home, _venezia), lessThan(1));
    await _close(tester);
  });

  testWidgets('a journey page opened without its journey says to go back', (tester) async {
    await _open(tester, home: _venezia, location: JourneyPage.route);
    expect(find.textContaining('no longer available'), findsOneWidget);
    await _close(tester);
  });
}
