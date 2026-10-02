import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:veribus/core/providers/favorites_notifier.dart';
import 'package:veribus/core/providers/network_provider.dart';
import 'package:veribus/features/stop/components/arrival_tile.dart';
import 'package:veribus/features/stop/stop_page.dart';
import 'package:veribus/l10n/gen/app_localizations.dart';
import 'package:veribus/l10n/gen/app_localizations_it.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/repositories/transit/mock_transit_repository.dart';
import 'package:veribus/repositories/transit/transit_repository_provider.dart';

void main() {
  final l10n = AppLocalizationsIt();
  final at = DateTime.now().add(const Duration(minutes: 14));
  final clock = DateFormat.Hm().format(at);

  Arrival arrival(String status, {int? minutes, bool approximate = false, bool withTime = true, int? stopsAway}) =>
      Arrival.fromJson({
        'trip_id': 't',
        'route_id': '64',
        'direction_id': 0,
        'headsign': 'TERMINI',
        'status': status,
        'time': withTime ? at.toUtc().toIso8601String() : null,
        'minutes': minutes,
        'approximate': approximate,
        'stops_away': stopsAway,
      });

  group('ArrivalText', () {
    test('a scheduled time is never shown as minutes (RNF-03)', () {
      expect(ArrivalText.time(l10n, arrival('scheduled', minutes: 14)), clock);
      expect(ArrivalText.time(l10n, arrival('suppressed', minutes: 14)), clock);
    });

    test('realtime: minutes, approximate beyond the threshold (RF-29b), stops away without a time (RF-26)', () {
      expect(ArrivalText.time(l10n, arrival('confirmed', minutes: 4)), '4 min');
      expect(ArrivalText.time(l10n, arrival('confirmed', minutes: 14, approximate: true)), 'verso le $clock');
      expect(ArrivalText.time(l10n, arrival('confirmed', withTime: false, stopsAway: 3)), 'a 3 fermate');
      expect(ArrivalText.time(l10n, arrival('uncertain', minutes: 0)), 'in arrivo');
    });

    test('reasons', () {
      expect(ArrivalText.reason(l10n, arrival('scheduled'), lineWithoutRealtime: true), l10n.lineWithoutRealtime);
      expect(
        ArrivalText.signal(l10n, Signal.fromJson({'code': 'S3', 'min': 8}), stopsAway: 3),
        'Mezzo fermo da 8 min · a 3 fermate',
      );
      expect(ArrivalText.signal(l10n, Signal.fromJson({'code': 'S2'})), 'Nessun mezzo localizzato');
    });
  });

  testWidgets('stop panel lists every status with its label (RNF-07)', (tester) async {
    final repo = MockTransitRepository();
    tester.view
      ..physicalSize =
          const Size(1080, 4000) // the whole list fits: ListView builds only what is visible
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transitRepositoryProvider.overrideWithValue(repo),
          networkInfoProvider.overrideWith((ref) => repo.networkInfo()),
          favoritesProvider.overrideWithBuild((ref, notifier) => (stops: <String>[], lines: <String>[])),
        ],
        child: const MaterialApp(
          locale: Locale('it'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StopPage(stopId: '70001'),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('VENEZIA'), findsOneWidget);
    for (final label in ['Confermato', 'Da verificare', 'Programmato', 'Soppressa', 'Cancellata']) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    // Alerts fold into one row; the full text opens on demand.
    expect(find.text('1 avviso'), findsOneWidget);
    expect(find.text('Linea 40 deviata'), findsOneWidget);
    await tester.tap(find.text('1 avviso'));
    await tester.pumpAndSettle();
    expect(find.text('Linea 40 deviata'), findsNWidgets(2)); // tile subtitle + card in the sheet
    expect(find.textContaining('Per lavori in via Nazionale'), findsOneWidget);
    Navigator.of(tester.element(find.text('Avvisi'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('8BUS').first); // filter on one line (RF-27)
    await tester.pump();
    expect(find.text('Confermato'), findsNothing);
    expect(find.text(l10n.lineWithoutRealtime), findsWidgets);
  });
}
