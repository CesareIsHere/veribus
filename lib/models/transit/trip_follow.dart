import 'package:flutter/foundation.dart';
import 'package:veribus/models/transit/live.dart';

/// A trip the user follows: the same trip every day on the chosen weekdays, identified by what survives a GTFS
/// reimport (stop, line, direction, scheduled time at the stop), not by `trip_id`. The server notifies a few minutes
/// before the bus passes (`leadMinutes`, up to [maxLeads]) and when something happens to it.
@immutable
class TripFollow {
  const TripFollow({
    required this.stopId,
    required this.lineId,
    required this.directionId,
    required this.departureSeconds,
    required this.days,
    required this.leadMinutes,
    this.id,
    this.enabled = true,
    this.today,
  });

  factory TripFollow.fromJson(Map<String, dynamic> json) => TripFollow(
    id: json['id'] as String,
    stopId: json['stop_id'] as String,
    lineId: json['route_id'] as String,
    directionId: json['direction_id'] as int,
    departureSeconds: json['departure_s'] as int,
    days: {for (final d in json['days'] as List) d as int},
    leadMinutes: sortedLeads([for (final m in json['lead_min'] as List) m as int]),
    enabled: json['enabled'] as bool,
    today: json['today'] == null ? null : FollowToday.fromJson(json['today'] as Map<String, dynamic>),
  );

  static const maxLeads = 3;
  static const maxFollows = 30;

  /// Minutes the user can ask to be notified before the bus passes.
  static const leadOptions = [2, 3, 5, 10, 15, 20, 30];

  /// Longest first: 15, 10, 5.
  static List<int> sortedLeads(Iterable<int> minutes) => [...minutes]..sort((a, b) => b.compareTo(a));

  /// Null until saved.
  final String? id;
  final String stopId;
  final String lineId;
  final int directionId;

  /// Scheduled time at the stop, in seconds from the service day's midnight (past 24 h: after midnight).
  final int departureSeconds;

  /// ISO weekdays (1 Monday .. 7 Sunday) of the service day.
  final Set<int> days;

  /// Longest first: 15, 10, 5.
  final List<int> leadMinutes;
  final bool enabled;

  /// How today's trip is doing; only when it is about to run (or has just run).
  final FollowToday? today;

  /// What makes a follow the same follow, saved or not.
  String get key => keyOf(stopId, lineId, directionId, departureSeconds);

  static String keyOf(String stopId, String lineId, int directionId, int departureSeconds) =>
      '$stopId/$lineId/$directionId/$departureSeconds';

  /// The row as the table stores it (`user_id` comes from the session on the server).
  Map<String, dynamic> toRow() => {
    'stop_id': stopId,
    'route_id': lineId,
    'direction_id': directionId,
    'departure_s': departureSeconds,
    'days': (days.toList()..sort()),
    'lead_min': leadMinutes,
    'enabled': enabled,
  };

  TripFollow copyWith({String? id, Set<int>? days, List<int>? leadMinutes, bool? enabled, FollowToday? today}) =>
      TripFollow(
        id: id ?? this.id,
        stopId: stopId,
        lineId: lineId,
        directionId: directionId,
        departureSeconds: departureSeconds,
        days: days ?? this.days,
        leadMinutes: leadMinutes ?? this.leadMinutes,
        enabled: enabled ?? this.enabled,
        today: today ?? this.today,
      );
}

/// Today's trip of a follow: the same words as an arrival (status, time, minutes only from realtime).
@immutable
class FollowToday {
  const FollowToday({required this.status, required this.time, this.minutes, this.signal});

  factory FollowToday.fromJson(Map<String, dynamic> json) => FollowToday(
    status: ArrivalStatus.values.byName(json['status'] as String),
    time: DateTime.parse(json['time'] as String),
    minutes: json['minutes'] as int?,
    signal: json['signal'] == null ? null : Signal.fromJson(json['signal'] as Map<String, dynamic>),
  );

  final ArrivalStatus status;

  /// Predicted time with realtime, the scheduled one otherwise.
  final DateTime time;
  final int? minutes;
  final Signal? signal;
}

/// "17:10" from seconds past the service day's midnight (past 24 h it is the night after).
String clockOf(int seconds) {
  final h = (seconds ~/ 3600) % 24;
  final m = seconds % 3600 ~/ 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}
