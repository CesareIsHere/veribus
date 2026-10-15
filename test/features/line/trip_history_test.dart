import 'package:flutter_test/flutter_test.dart';
import 'package:veribus/features/line/components/trip_history_card.dart';
import 'package:veribus/l10n/gen/app_localizations_it.dart';
import 'package:veribus/models/transit/live.dart';

TripDay _day(String status, [int? delay]) =>
    TripDay.fromJson({'date': '2026-10-14', 'status': status, 'delay_s': delay});

void main() {
  final l10n = AppLocalizationsIt();
  String verdict(List<TripDay> days) => tripVerdict(l10n, tripRecord(days));

  test('counts on time, late, early, not tracked and canceled; the typical delay is the median', () {
    final r = tripRecord([
      _day('ran', 60),
      _day('ran', 400),
      _day('ran', -120),
      _day('ran', 200),
      _day('not_tracked'),
      _day('canceled'),
    ]);
    expect((r.onTime, r.late, r.early, r.notTracked, r.canceled), (1, 2, 1, 1, 1));
    expect(r.typical, const Duration(seconds: 200));
  });

  test('the verdict says what to expect', () {
    expect(verdict([]), l10n.tripHistoryEmpty);
    expect(verdict([_day('ran', 60), _day('ran', -30), _day('ran', 500)]), l10n.tripUsuallyOnTime);
    expect(verdict([_day('ran', 300), _day('ran', 420), _day('ran', 60)]), l10n.tripUsuallyLate(5));
    expect(verdict([_day('ran', -180), _day('ran', -150)]), l10n.tripUsuallyEarly(3));
    // Mostly without data: the bus may pass all the same, the delays say little.
    expect(verdict([_day('ran', 600), _day('not_tracked'), _day('not_tracked')]), l10n.tripRarelyTracked);
  });
}
