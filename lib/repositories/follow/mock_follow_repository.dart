import 'package:veribus/core/utils/app_failure.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/models/transit/trip_follow.dart';
import 'package:veribus/repositories/follow/i_follow_repository.dart';

/// In memory. By default it starts with two follows (the mock timetable has a trip every 15 minutes); `seed` starts it
/// with others, or with none.
class MockFollowRepository implements IFollowRepository {
  MockFollowRepository({List<TripFollow>? seed}) : _follows = [...seed ?? _demo()];

  static List<TripFollow> _demo() {
    final now = DateTime.now();
    final seconds = now.hour * 3600 + now.minute * 60;
    final next = (seconds ~/ 900 + 1) * 900; // the next quarter of an hour
    return [
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

  final List<TripFollow> _follows;
  var _ids = 2;

  /// What is stored, without today's state.
  List<TripFollow> get follows => List.unmodifiable(_follows);

  @override
  Future<List<TripFollow>> list() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    return [
      for (final f in _follows)
        // Within two hours of its time the trip is "today's": confirmed, a few minutes late.
        if (midnight.add(Duration(seconds: f.departureSeconds, minutes: 2)) case final t
            when f.enabled && f.days.contains(now.weekday) && t.difference(now).inMinutes < 120)
          f.copyWith(
            today: FollowToday(
              status: ArrivalStatus.confirmed,
              time: t,
              minutes: t.difference(now).inMinutes.clamp(0, 999),
            ),
          )
        else
          f,
    ];
  }

  @override
  Future<void> save(TripFollow follow) async {
    final i = _follows.indexWhere((f) => f.key == follow.key);
    if (i >= 0) {
      _follows[i] = follow.copyWith(id: _follows[i].id);
    } else if (_follows.length >= TripFollow.maxFollows) {
      throw const LimitFailure();
    } else {
      _follows.add(follow.copyWith(id: 'f${++_ids}'));
    }
  }

  @override
  Future<void> setEnabled(String id, {required bool enabled}) async {
    final i = _follows.indexWhere((f) => f.id == id);
    if (i >= 0) _follows[i] = _follows[i].copyWith(enabled: enabled);
  }

  @override
  Future<void> remove(String id) async => _follows.removeWhere((f) => f.id == id);
}
