import 'package:veribus/models/transit/live.dart';

/// How a change between two trips went in the history (`api.trip_history`, last 30 days of the same kind): on how
/// many of the days both trips were seen the first one arrived in time for the second.
typedef ChangeRecord = ({int made, int days});

/// [arriving]: the history of the first trip at the stop where it is left, scheduled there at [arriveSlot] (seconds
/// from its service day's midnight). [leaving]: the history of the second trip at the stop where it is taken,
/// scheduled at [leaveSlot]. [walk]: seconds between the two stops on foot.
///
/// A day counts when the first trip ran and the second ran or was canceled (a canceled connection is a missed
/// one); days when either was not tracked say nothing and are left out.
ChangeRecord changeRecord({
  required List<TripDay> arriving,
  required List<TripDay> leaving,
  required int arriveSlot,
  required int leaveSlot,
  int walk = 0,
}) {
  DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
  final second = {for (final d in leaving) day(d.date): d};
  var made = 0;
  var days = 0;
  for (final first in arriving) {
    final other = second[day(first.date)];
    if (first.status != TripDayStatus.ran || first.delay == null || other == null) continue;
    switch (other) {
      case TripDay(status: TripDayStatus.canceled):
        days++;
      case TripDay(status: TripDayStatus.ran, :final delay?):
        days++;
        if (arriveSlot + first.delay!.inSeconds + walk <= leaveSlot + delay.inSeconds) made++;
      default:
    }
  }
  return (made: made, days: days);
}
