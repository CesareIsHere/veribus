// The providers are overridden at the root of each test: nothing scoped to declare.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:veribus/core/providers/locale_notifier.dart';
import 'package:veribus/core/providers/network_provider.dart';
import 'package:veribus/features/notifications/follow_page.dart';
import 'package:veribus/features/notifications/trips_page.dart';
import 'package:veribus/l10n/gen/app_localizations.dart';
import 'package:veribus/models/transit/trip_follow.dart';
import 'package:veribus/repositories/follow/follow_repository_provider.dart';
import 'package:veribus/repositories/follow/mock_follow_repository.dart';
import 'package:veribus/repositories/transit/mock_transit_repository.dart';
import 'package:veribus/repositories/transit/transit_repository_provider.dart';
import 'package:veribus/services/push_notifications_service.dart';

/// The mock repository, remembering what was saved.
class _Follows extends MockFollowRepository {
  _Follows([List<TripFollow> seed = const []]) : super(seed: seed);

  final List<TripFollow> saved = [];

  @override
  Future<void> save(TripFollow follow) async {
    await super.save(follow);
    saved.add(follow);
  }
}

const _existing = TripFollow(
  id: 'f1',
  stopId: '70001',
  lineId: '64',
  directionId: 1,
  departureSeconds: 62100,
  days: {1, 2, 3},
  leadMinutes: [15, 10, 5],
);

Future<void> _open(WidgetTester tester, _Follows repo, {required String location}) async {
  tester.view
    ..physicalSize = const Size(800, 2000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final transit = MockTransitRepository();
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('home')),
      ),
      GoRoute(path: TripsPage.route, builder: (_, _) => const TripsPage()),
      GoRoute(
        path: FollowPage.route,
        builder: (_, state) => FollowPage(
          stopId: '70001',
          lineId: '64',
          directionId: 1,
          departureSeconds: 62100,
          weekday: int.tryParse(state.uri.queryParameters['wd'] ?? ''),
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        transitRepositoryProvider.overrideWithValue(transit),
        networkInfoProvider.overrideWith((ref) => transit.networkInfo()),
        followRepositoryProvider.overrideWithValue(repo),
        pushServiceProvider.overrideWithValue(MockPushService()),
        localeProvider.overrideWithBuild((ref, notifier) => null),
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  unawaited(router.push<void>(location));
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
}

bool _selected(WidgetTester tester, String label) =>
    tester.widget<FilterChip>(find.widgetWithText(FilterChip, label)).selected;

void main() {
  testWidgets('a new follow starts from the commute: weekdays, 10 and 5 minutes before', (tester) async {
    final repo = _Follows();
    await _open(tester, repo, location: FollowPage.route);

    expect(
      [
        for (final d in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) _selected(tester, d),
      ],
      [
        true, true, true, true, true, false, false, //
      ],
    );
    expect(_selected(tester, '10 min'), isTrue);
    expect(_selected(tester, '5 min'), isTrue);
    expect(_selected(tester, '15 min'), isFalse);
    expect(find.textContaining('17:15'), findsOneWidget);
    expect(find.text('Recent weekdays'), findsOneWidget); // what to expect from the trip
    expect(find.text('Usually on time'), findsOneWidget);
    expect(find.text('Stop following'), findsNothing); // nothing to remove yet

    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(repo.saved.single.key, '70001/64/1/62100');
    expect(repo.saved.single.days, {1, 2, 3, 4, 5});
    expect(repo.saved.single.leadMinutes, [10, 5]);
  });

  testWidgets('a time picked on a weekend timetable is followed on that day only', (tester) async {
    await _open(tester, _Follows(), location: '${FollowPage.route}?wd=6');
    expect(
      [
        for (final d in ['Mon', 'Fri', 'Sat', 'Sun']) _selected(tester, d),
      ],
      [false, false, true, false],
    );
  });

  testWidgets('at most three notices: with three chosen the others cannot be picked', (tester) async {
    await _open(tester, _Follows(), location: FollowPage.route);
    await tester.tap(find.widgetWithText(FilterChip, '15 min'));
    await tester.pump();
    expect(_selected(tester, '15 min'), isTrue);
    expect(tester.widget<FilterChip>(find.widgetWithText(FilterChip, '20 min')).onSelected, isNull);
    // One taken off frees a place.
    await tester.tap(find.widgetWithText(FilterChip, '5 min'));
    await tester.pump();
    expect(tester.widget<FilterChip>(find.widgetWithText(FilterChip, '20 min')).onSelected, isNotNull);
  });

  testWidgets('without a day or a notice there is nothing to save', (tester) async {
    await _open(tester, _Follows(), location: FollowPage.route);
    for (final d in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']) {
      await tester.tap(find.widgetWithText(FilterChip, d));
      await tester.pump();
    }
    expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Save')).onPressed, isNull);
  });

  testWidgets('a follow that exists is edited, can be turned off and removed after a confirmation', (tester) async {
    final repo = _Follows([_existing]);
    await _open(tester, repo, location: FollowPage.route);

    expect(_selected(tester, 'Mon'), isTrue);
    expect(_selected(tester, 'Thu'), isFalse);
    expect(_selected(tester, '15 min'), isTrue);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(repo.saved.single.enabled, isFalse);
  });

  testWidgets('removing asks first', (tester) async {
    final repo = _Follows([_existing]);
    await _open(tester, repo, location: FollowPage.route);
    await tester.tap(find.text('Stop following'));
    await tester.pumpAndSettle();
    expect(find.text('Stop following this trip?'), findsOneWidget);
    expect(repo.follows, hasLength(1));
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Stop following')));
    await tester.pumpAndSettle();
    expect(repo.follows, isEmpty);
  });

  testWidgets('past the limit the user is told, and nothing is lost', (tester) async {
    final repo = _Follows([
      for (var i = 0; i < TripFollow.maxFollows; i++)
        TripFollow(
          id: 'x$i',
          stopId: '70001',
          lineId: '64',
          directionId: 1,
          departureSeconds: 3600 + i * 60,
          days: const {1},
          leadMinutes: const [5],
        ),
    ]);
    await _open(tester, repo, location: FollowPage.route);
    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('You can follow at most 30 trips. Remove one first.'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget); // still on the form
  });

  testWidgets('the followed trips: what, when, on which days, how long before, and off ones muted', (tester) async {
    final repo = _Follows([
      _existing,
      const TripFollow(
        id: 'f2',
        stopId: '70001',
        lineId: '170',
        directionId: 1,
        departureSeconds: 3600 * 8,
        days: {1, 2, 3, 4, 5, 6, 7},
        leadMinutes: [5],
        enabled: false,
      ),
    ]);
    await _open(tester, repo, location: TripsPage.route);
    expect(find.text('17:15 · VENEZIA'), findsOneWidget);
    expect(find.text('Mon, Tue, Wed · 15, 10, 5 min before'), findsOneWidget);
    expect(find.text('Every day · 5 min before'), findsOneWidget);
    expect(tester.widgetList<Switch>(find.byType(Switch)).map((s) => s.value), [true, false]);

    await tester.tap(find.byType(Switch).last);
    await tester.pump(const Duration(seconds: 1));
    expect(repo.follows.last.enabled, isTrue);
  });

  testWidgets('no followed trips: says how to follow one', (tester) async {
    await _open(tester, _Follows(), location: TripsPage.route);
    expect(find.text('No followed trips'), findsOneWidget);
    expect(find.textContaining('tap the time'), findsOneWidget);
  });
}
