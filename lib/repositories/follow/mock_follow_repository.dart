import 'package:veribus/core/utils/app_failure.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/models/transit/trip_follow.dart';
import 'package:veribus/repositories/follow/i_follow_repository.dart';

/// In memory, with two follows to start from.
class MockFollowRepository implements IFollowRepository {
  MockFollowRepository() {
    final now = DateTime.now();
    final seconds = now.hour * 3600 + now.minute * 60;
    // The next quarter of an hour, like the mock timetable (every 15 minutes).
    final next = (seconds ~/ 900 + 1) * 900;
    _follows = [
      TripFollow(
        id: 'f1',
        stopId: '70001',
        lineId: '64',
        directionId: 1,
        departureSeconds: next + 900,
        days: const {1, 2, 3, 4, 5},
        leadMinutes: const [15, 10, 5],
      ),
      TripFollow(
        id: 'f2',
        stopId: '70001',
        lineId: '170',
        directionId: 1,
        departureSeconds: next + 2700,
        days: const {1, 2, 3, 4, 5, 6, 7},
        leadMinutes: const [10],
        enabled: false,
      ),
    ];
  }

  late List<TripFollow> _follows;
  var _ids = 2;

  @override
  Future<List<TripFollow>> list() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    return [
      for (final f in _follows)
        TripFollow(
          id: f.id,
          stopId: f.stopId,
          lineId: f.lineId,
          directionId: f.directionId,
          departureSeconds: f.departureSeconds,
          days: f.days,
          leadMinutes: f.leadMinutes,
          enabled: f.enabled,
          // Within two hours of its time the trip is "today's": confirmed, a few minutes late.
          today: switch (midnight.add(Duration(seconds: f.departureSeconds)).add(const Duration(minutes: 2))) {
            final t when f.enabled && t.difference(now).inMinutes < 120 && f.days.contains(now.weekday) => FollowToday(
              status: ArrivalStatus.confirmed,
              time: t,
              minutes: t.difference(now).inMinutes.clamp(0, 999),
            ),
            _ => null,
          },
        ),
    ];
  }

  @override
  Future<void> save(TripFollow follow) async {
    final i = _follows.indexWhere((f) => f.key == follow.key);
    if (i >= 0) {
      _follows[i] = TripFollow(
        id: _follows[i].id,
        stopId: follow.stopId,
        lineId: follow.lineId,
        directionId: follow.directionId,
        departureSeconds: follow.departureSeconds,
        days: follow.days,
        leadMinutes: follow.leadMinutes,
        enabled: follow.enabled,
      );
      return;
    }
    if (_follows.length >= TripFollow.maxFollows) throw const LimitFailure();
    _follows.add(
      TripFollow(
        id: 'f${++_ids}',
        stopId: follow.stopId,
        lineId: follow.lineId,
        directionId: follow.directionId,
        departureSeconds: follow.departureSeconds,
        days: follow.days,
        leadMinutes: follow.leadMinutes,
        enabled: follow.enabled,
      ),
    );
  }

  @override
  Future<void> setEnabled(String id, {required bool enabled}) async {
    _follows = [
      for (final f in _follows)
        if (f.id == id) f.copyWith(enabled: enabled) else f,
    ];
  }

  @override
  Future<void> remove(String id) async => _follows = [
    for (final f in _follows)
      if (f.id != id) f,
  ];
}
