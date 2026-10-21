import 'package:flutter_test/flutter_test.dart';
import 'package:veribus/models/journeys/change_reliability.dart';
import 'package:veribus/models/transit/live.dart';

TripDay _day(int day, String status, [int? delay]) =>
    TripDay.fromJson({'date': '2026-10-${day.toString().padLeft(2, '0')}', 'status': status, 'delay_s': delay});

void main() {
  test('a change made when the first bus arrives before the second leaves, walk included', () {
    final record = changeRecord(
      // Scheduled: arrive at 22:00, leave at 22:05 from a stop 2 minutes away on foot.
      arriveSlot: 22 * 3600,
      leaveSlot: 22 * 3600 + 300,
      walk: 120,
      arriving: [
        _day(1, 'ran', 60), // 22:01 + 2 → 22:03, the second leaves 22:05: made
        _day(2, 'ran', 240), // 22:04 + 2 → 22:06, the second leaves 22:05: missed
        _day(3, 'ran', 240), // 22:06 on foot, the second is 3 minutes late (22:08): made
        _day(4, 'ran', 0), // the second was canceled: missed
        _day(5, 'not_tracked'), // nothing known
        _day(6, 'ran', 0), // the second not tracked: nothing known
        _day(7, 'canceled'), // the first was canceled: not a change that day
      ],
      leaving: [
        _day(1, 'ran', 0),
        _day(2, 'ran', 0),
        _day(3, 'ran', 180),
        _day(4, 'canceled'),
        _day(5, 'ran', 0),
        _day(6, 'not_tracked'),
        _day(7, 'ran', 0),
      ],
    );
    expect(record, (made: 2, days: 4));
  });

  test('no common days: nothing to say', () {
    expect(changeRecord(arriving: [_day(1, 'ran', 0)], leaving: [_day(2, 'ran', 0)], arriveSlot: 0, leaveSlot: 600), (
      made: 0,
      days: 0,
    ));
  });
}
