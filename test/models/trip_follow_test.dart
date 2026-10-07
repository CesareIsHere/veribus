import 'package:flutter_test/flutter_test.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/models/transit/trip_follow.dart';

void main() {
  test('a follow as the server sends it: longest notice first, today only when the trip is about to run', () {
    final f = TripFollow.fromJson(const {
      'id': 'f1',
      'stop_id': '70001',
      'route_id': '64',
      'direction_id': 1,
      'departure_s': 62100,
      'days': [1, 2, 3, 4, 5],
      'lead_min': [5, 15, 10],
      'enabled': true,
      'today': {'status': 'confirmed', 'time': '2026-10-07T15:12:00Z', 'minutes': 9, 'signal': null},
    });
    expect(f.leadMinutes, [15, 10, 5]);
    expect(f.days, {1, 2, 3, 4, 5});
    expect(f.today?.status, ArrivalStatus.confirmed);
    expect(f.today?.minutes, 9);
    expect(f.key, '70001/64/1/62100');

    final idle = TripFollow.fromJson(const {
      'id': 'f2',
      'stop_id': '70001',
      'route_id': '64',
      'direction_id': 1,
      'departure_s': 3600,
      'days': [6, 7],
      'lead_min': [10],
      'enabled': false,
      'today': null,
    });
    expect(idle.today, isNull);
    expect(idle.enabled, isFalse);
  });

  test('the row to save names the trip by stop, line, direction and time at the stop', () {
    const f = TripFollow(
      stopId: '70001',
      lineId: '64',
      directionId: 0,
      departureSeconds: 62100,
      days: {5, 1, 3},
      leadMinutes: [15, 5],
    );
    expect(f.toRow(), {
      'stop_id': '70001',
      'route_id': '64',
      'direction_id': 0,
      'departure_s': 62100,
      'days': [1, 3, 5],
      'lead_min': [15, 5],
      'enabled': true,
    });
  });

  test('clockOf: seconds past the service day midnight, wrapping past 24 h', () {
    expect(clockOf(62100), '17:15');
    expect(clockOf(5 * 3600 + 30 * 60), '05:30');
    expect(clockOf(24 * 3600 + 10 * 60), '00:10');
  });
}
