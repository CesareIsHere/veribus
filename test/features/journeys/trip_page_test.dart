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
import 'package:veribus/core/widgets/transit_map.dart';
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
import 'package:veribus/services/location_tracker.dart';
import 'package:veribus/services/map_tile_service.dart';
import 'package:veribus/services/push_notifications_service.dart';

/// The foreground service of the journey: what the tracker was asked to show, each time (null: let it go).
class _Tracker extends Fake implements LocationTracker {
  final notices = <FollowNotice?>[];

  @override
  Future<void> follow(FollowNotice? notice) async => notices.add(notice);
}

/// The ongoing notification of the journey: every version of it, and whether it was taken away.
class _Push extends MockPushService {
  final List<TripNotification> shown = <TripNotification>[];
  int cancelled = 0;

  @override
  Future<bool> showTrip(TripNotification notification) async {
    shown.add(notification);
    return true;
  }

  @override
  Future<void> cancelTrip() async => cancelled++;
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

class _Rig {
  _Rig({
    required this.planner,
    required this.journey,
    required this.position,
    required this.tracker,
    required this.push,
  });

  final JourneyPlanner planner;
  final PlannedJourney journey;
  final StreamController<LatLng?> position;
  final _Tracker tracker;
  final _Push push;
}

/// A journey from [from] to [to] on the X line, whose trips leave stop A at [times], opened on the trip page.
Future<_Rig> _open(
  WidgetTester tester, {
  required List<String> times,
  required DateTime now,
  required DateTime Function() clock,
  required LatLng from,
  required LatLng to,
  Duration replanEvery = const Duration(seconds: 30),
}) async {
  tester.view
    ..physicalSize = const Size(800, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final tt = buildTimetable(
    date: 20261020,
    stops: _stops,
    trips: [
      for (final t in times)
        (
          line: 'X',
          direction: 0,
          headsign: 'To D',
          stops: ['A', 'B', 'C', 'D'],
          times: [for (var i = 0; i < 4; i++) _hm(t) + i * 600],
          previousDay: false,
        ),
    ],
  );
  Future<Arrivals> none(List<String> stops, List<String> lines) async => Arrivals.fromJson({
    'computed_at': now.toUtc().toIso8601String(),
    'feed': {'status': 'ok'},
    'stops': <Map<String, dynamic>>[],
    'alerts': <Map<String, dynamic>>[],
    'routes': <Map<String, dynamic>>[],
  });
  final planner = JourneyPlanner(tt, none);
  final journey = (await planner.plan(from: from, to: to, at: now, options: 1)).first;
  expect(journey.rides, hasLength(1));

  final position = StreamController<LatLng?>();
  addTearDown(position.close);
  final transit = MockTransitRepository();
  final tracker = _Tracker();
  final push = _Push();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        transitRepositoryProvider.overrideWithValue(transit),
        networkInfoProvider.overrideWith((ref) => transit.networkInfo()),
        localeProvider.overrideWithBuild((ref, notifier) => null),
        mapTilesProvider.overrideWith((ref) => Completer<TileProviders>().future),
        positionProvider.overrideWith((ref) => position.stream),
        locationTrackerProvider.overrideWithValue(tracker),
        pushServiceProvider.overrideWithValue(push),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TripPage(
          clock: clock,
          replanEvery: replanEvery,
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
  return _Rig(planner: planner, journey: journey, position: position, tracker: tracker, push: push);
}

void main() {
  testWidgets('walk to the stop, wait, ride and get off: one instruction at a time', (tester) async {
    final now = DateTime(2026, 10, 20, 9, 50);
    final from = _at('A', metres: -300);
    final to = _at('D', metres: 300);
    final rig = await _open(tester, times: ['10:00'], now: now, clock: () => now, from: from, to: to);
    final (:tracker, :push, :position) = (tracker: rig.tracker, push: rig.push, position: rig.position);
    Future<void> move(LatLng p) async {
      position.add(p);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    }

    await move(from);
    // The location service runs as a plain "following you", once; the steps are in the ongoing notification.
    expect(tracker.notices.single?.title, 'Veribus · on your way');
    expect(tracker.notices.single?.text, 'Following you to Home');
    expect(push.shown.last.title, 'Walk to STOP A');
    // The bus and its state, with the words of the stop page, and the way left.
    expect(push.shown.last.text, 'Your X comes at 10:00 · Scheduled');
    expect(push.shown.last.details, contains('<b>Scheduled</b> · no realtime data'));
    expect(push.shown.last.details.any((d) => d.contains('m · ') && d.contains('min')), isTrue);
    // The clock in the header counts down to the bus.
    expect(push.shown.last.countdownTo, DateTime(2026, 10, 20, 10));
    expect(find.text('Walk to STOP A'), findsOneWidget);
    expect(find.textContaining('min'), findsWidgets);
    expect(find.text('Your X comes at 10:00'), findsOneWidget);
    // The same words on the screen: the status and what it means.
    expect(find.text('no realtime data'), findsOneWidget);

    // Walking updates the notification: the distance changes, the service is not started again.
    final before = push.shown.length;
    await move(_at('A', metres: -150));
    expect(push.shown.length, greaterThan(before));
    expect(tracker.notices, hasLength(1));

    await move(_at('A', metres: 20));
    expect(find.text('Get on the X'), findsOneWidget);
    expect(push.shown.last.title, 'Get on the X');

    await move(_at('B', metres: 10));
    expect(find.text('Get off in 2 stops'), findsOneWidget);
    expect(push.shown.last.title, 'Get off in 2 stops');
    expect(push.shown.last.text, 'at STOP D · 10:30');
    expect(push.shown.last.countdownTo, DateTime(2026, 10, 20, 10, 30));
    expect(find.text('STOP D · get off'), findsOneWidget);

    // On a vehicle the stops are a list; the map is one tap away, and back.
    expect(find.byType(TransitMap), findsNothing);
    await tester.tap(find.byTooltip('Show the map'));
    await tester.pump();
    expect(find.byType(TransitMap), findsOneWidget);
    expect(find.text('STOP D · get off'), findsNothing);
    await tester.tap(find.byTooltip('Show the stops'));
    await tester.pump();
    expect(find.byType(TransitMap), findsNothing);
    expect(find.text('STOP D · get off'), findsOneWidget);

    await move(_at('C', metres: 10));
    expect(find.text('Get off at the next stop'), findsOneWidget);

    await move(_at('D', metres: 20));
    expect(find.text('Walk to Home'), findsOneWidget);

    await move(to);
    expect(find.text('You have arrived'), findsOneWidget);
    // Arrived: the tracker is told to let the service go and the notification is taken away.
    expect(tracker.notices.last, isNull);
    expect(push.cancelled, greaterThan(0));
  });

  testWidgets('a bus that was missed: the journey is planned again, with the next bus and the new arrival', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 20, 9, 50);
    final from = _at('A', metres: -300);
    final to = _at('D', metres: 300);
    final rig = await _open(
      tester,
      times: ['10:00', '10:20'],
      now: now,
      clock: () => now,
      from: from,
      to: to,
      replanEvery: const Duration(seconds: 1),
    );
    expect(rig.journey.rides.single.start, _hm('10:00'));
    expect(find.text('Home around 10:35'), findsOneWidget);

    // The traveller is still far from the stop when the bus leaves.
    rig.position.add(from);
    await tester.pump(const Duration(milliseconds: 100));
    now = DateTime(2026, 10, 20, 10, 5);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('The X has gone: your next is the X at 10:20'), findsOneWidget);
    expect(find.text('Your X comes at 10:20'), findsOneWidget);
    expect(find.text('Home around 10:55'), findsOneWidget);
    expect(rig.push.shown.last.text, startsWith('Your X comes at 10:20'));
    expect(rig.push.shown.last.subText, 'Home around 10:55');
    // The traveller goes on from the first step of the new journey.
    expect(find.text('Walk to STOP A'), findsOneWidget);
  });

  testWidgets('started on a bus: the journey goes on with that bus instead of waiting for the next one', (
    tester,
  ) async {
    // Planned at 9:50 to take the 10:00 from A. The traveller starts the navigation at 10:05, already on that bus,
    // halfway between A and B, driving north.
    var now = DateTime(2026, 10, 20, 10, 5);
    final from = _at('A', metres: -300);
    final to = _at('D', metres: 300);
    final rig = await _open(
      tester,
      times: ['10:00', '10:20'],
      now: DateTime(2026, 10, 20, 9, 50),
      clock: () => now,
      from: from,
      to: to,
    );
    final start = LatLng(_at('A').latitude + 0.0045, 12.5);
    for (var k = 0; k <= 12; k++) {
      now = DateTime(2026, 10, 20, 10, 5).add(Duration(seconds: 4 * k));
      rig.position.add(LatLng(start.latitude + k * 32 / 110540, 12.5));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('You are on the X: following it from here'), findsOneWidget);
    // On board, with the 10:00 trip: no more waiting for the 10:20.
    expect(find.textContaining('Get off in'), findsWidgets);
    expect(find.textContaining('Walk to STOP A'), findsNothing);
    expect(rig.push.shown.last.title, startsWith('Get off'));
    expect(rig.push.shown.last.countdownTo, DateTime(2026, 10, 20, 10, 30));
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
