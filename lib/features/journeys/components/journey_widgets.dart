import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/notifications/follow_page.dart'; // feature:push
import 'package:veribus/features/stop/components/arrival_tile.dart';
import 'package:veribus/models/journeys/journey_planner.dart';
import 'package:veribus/models/journeys/raptor.dart';
import 'package:veribus/models/journeys/timetable.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/styles/app_spacing.dart';

/// "21:47" for seconds from the planner's midnight.
String journeyClock(JourneyPlanner planner, int seconds) => DateFormat.Hm().format(planner.timeOf(seconds));

/// Whole minutes, at least one: a 40-second walk is "1 min", never "0 min".
int journeyMinutes(int seconds) => seconds <= 0 ? 0 : (seconds + 59) ~/ 60;

/// A stop further than this from the line's path is not on it: that trip takes a variant, or the path is wrong.
const _offPathMeters = 100.0;

/// The streets of a ride from its [board]-th to its [alight]-th stop: [shape] (the line's main path) cut there. [stops]
/// are all the stops of the trip from its first, matched in order along the path, so a loop line that passes twice
/// on the same street is cut on the right pass. The stops joined straight when the line has no path or a stop is
/// not on it (a variant), so the map never draws a street the bus does not take.
List<LatLng> alongShape(List<LatLng> shape, List<LatLng> stops, int board, int alight) {
  final straight = stops.sublist(board, alight + 1);
  if (shape.length < 2) return straight;
  final scale = math.cos(stops.first.latitudeInRad);
  // Where a stop falls on segment [i] of the path, not before the fraction [after]: the fraction along it and the
  // distance in metres.
  ({double t, double metres}) onSegment(LatLng p, int i, [double after = 0]) {
    final a = shape[i];
    final dx = (shape[i + 1].longitude - a.longitude) * scale;
    final dy = shape[i + 1].latitude - a.latitude;
    final px = (p.longitude - a.longitude) * scale;
    final py = p.latitude - a.latitude;
    final length2 = dx * dx + dy * dy;
    final t = length2 == 0 ? after : ((px * dx + py * dy) / length2).clamp(after, 1.0);
    return (t: t, metres: math.sqrt(math.pow(px - t * dx, 2) + math.pow(py - t * dy, 2)) * 111195);
  }

  // Each stop on the first stretch of path near it after the previous stop, at the closest point of that stretch.
  final at = <({int segment, double t})>[];
  var segment = 0;
  var t = 0.0;
  for (var s = 0; s <= alight; s++) {
    // Never behind the previous stop: on its segment, only the part after it counts.
    ({double t, double metres}) near(int i) => onSegment(stops[s], i, i == segment ? t : 0);
    var i = segment;
    while (i < shape.length - 1 && near(i).metres > _offPathMeters) {
      i++;
    }
    if (i == shape.length - 1) return straight;
    var best = near(i);
    while (i + 1 < shape.length - 1 && onSegment(stops[s], i + 1).metres < best.metres) {
      i++;
      best = onSegment(stops[s], i);
    }
    (segment, t) = (i, best.t);
    at.add((segment: i, t: best.t));
  }

  LatLng point(({int segment, double t}) p) {
    final a = shape[p.segment];
    final b = shape[p.segment + 1];
    return LatLng(a.latitude + (b.latitude - a.latitude) * p.t, a.longitude + (b.longitude - a.longitude) * p.t);
  }

  final (from, to) = (at[board], at[alight]);
  final piece = [point(from), ...shape.sublist(from.segment + 1, to.segment + 1), point(to)];
  // Matched on the wrong pass of a loop (a trip starting halfway, after midnight): far longer than the stops.
  double length(List<LatLng> line) =>
      [for (var i = 1; i < line.length; i++) const Distance()(line[i - 1], line[i])].fold(0, (a, b) => a + b);
  return length(piece) > 2 * length(straight) + 500 ? straight : piece;
}

/// The line of a ride: its badge, after a metro or tram icon (the badge alone would read as a bus).
class RideBadge extends StatelessWidget {
  const RideBadge({required this.planner, required this.ride, required this.noRealtime, super.key});

  final JourneyPlanner planner;
  final RideLeg ride;
  final Set<String> noRealtime;

  @override
  Widget build(BuildContext context) {
    final tt = planner.timetable;
    final line = tt.routeLine[ride.route];
    final name = tt.lineNames[line];
    final icon = switch (tt.lineTypes[line]) {
      Timetable.metro => Icons.subway_outlined,
      Timetable.tram => Icons.tram,
      _ => null,
    };
    return Semantics(
      label: tt.lineTypes[line] == Timetable.metro ? context.l10n.journeysMetro(name) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: Spacing.xs,
        children: [
          if (icon != null) Icon(icon, size: Spacing.l + Spacing.xs, color: context.colors.onSurfaceVariant),
          LineBadge(name, withoutRealtime: rideWithoutRealtime(planner, ride, noRealtime)),
        ],
      ),
    );
  }
}

// feature:push:start
/// The followed-trip page for [ride] (lib/features/notifications): notified before its bus passes, on the weekday of
/// its service day. Null for the metro, which is not in the network the follows use.
String? followRouteOf(JourneyPlanner planner, RideLeg ride) {
  final tt = planner.timetable;
  if (tt.lineTypes[tt.routeLine[ride.route]] == Timetable.metro) return null;
  return FollowPage.routeFor(
    stopId: tt.stopIds[ride.fromStop],
    lineId: tt.lineIds[tt.routeLine[ride.route]],
    directionId: tt.routeDirection[ride.route],
    departureSeconds: tt.serviceSeconds(ride.trip, ride.board),
    weekday: tt.midnight.subtract(Duration(days: tt.tripPreviousDay[ride.trip])).weekday,
  );
}
// feature:push:end

/// The metro publishes no realtime; nor do the lines the API lists as never transmitting.
bool rideWithoutRealtime(JourneyPlanner planner, RideLeg ride, Set<String> noRealtime) {
  final tt = planner.timetable;
  final line = tt.routeLine[ride.route];
  return tt.lineTypes[line] == Timetable.metro || noRealtime.contains(tt.lineIds[line]);
}

/// What is known of a ride at its boarding stop: the realtime arrival (time, status and reason, in the words of the
/// stop page) or its scheduled time and why there is nothing better.
class RideStatus extends StatelessWidget {
  const RideStatus({
    required this.planner,
    required this.journey,
    required this.ride,
    required this.noRealtime,
    super.key,
  });

  final JourneyPlanner planner;
  final PlannedJourney journey;
  final RideLeg ride;
  final Set<String> noRealtime;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final arrival = journey.realtimeOf(ride);
    final withoutRealtime = rideWithoutRealtime(planner, ride, noRealtime);
    final reason = arrival == null
        ? ArrivalText.noRealtime(l10n, lineWithoutRealtime: withoutRealtime)
        : ArrivalText.reason(l10n, arrival, lineWithoutRealtime: withoutRealtime);
    final muted = context.textTheme.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant);
    return Wrap(
      spacing: Spacing.s,
      runSpacing: Spacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (arrival != null)
          ArrivalTime(arrival, large: false)
        else
          Text(journeyClock(planner, ride.start), style: context.textTheme.titleSmall?.copyWith(color: muted?.color)),
        StatusTag(arrival?.status ?? ArrivalStatus.scheduled),
        if (reason.isNotEmpty) Text(reason, style: muted),
      ],
    );
  }
}

/// One journey in the list: leave → arrive, how long, the legs at a glance, and the state of the first bus (the one
/// to catch now).
class JourneyCard extends StatelessWidget {
  const JourneyCard({
    required this.planner,
    required this.journey,
    required this.noRealtime,
    required this.onTap,
    super.key,
  });

  final JourneyPlanner planner;
  final PlannedJourney journey;
  final Set<String> noRealtime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final j = journey.journey;
    final rides = journey.rides;
    final tt = planner.timetable;
    final changes = rides.length - 1;
    return Card.outlined(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Spacing.s,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      l10n.journeysTimes(journeyClock(planner, j.depart), journeyClock(planner, j.arrive)),
                      style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(l10n.minutes(journeyMinutes(j.arrive - j.depart)), style: context.textTheme.titleMedium),
                ],
              ),
              LegsSummary(planner: planner, journey: j, noRealtime: noRealtime),
              if (rides.isEmpty)
                Text(l10n.journeysWalkOnly, style: context.textTheme.bodyMedium)
              else ...[
                Text(
                  '${changes == 0 ? l10n.journeysDirect : l10n.journeysChanges(changes)} · '
                  '${l10n.journeysFrom(tt.stopNames[rides.first.fromStop])}',
                  style: context.textTheme.bodyMedium,
                ),
                RideStatus(planner: planner, journey: journey, ride: rides.first, noRealtime: noRealtime),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The legs in a row: walking minutes and line badges, with arrows between them.
class LegsSummary extends StatelessWidget {
  const LegsSummary({required this.planner, required this.journey, required this.noRealtime, super.key});

  final JourneyPlanner planner;
  final Journey journey;
  final Set<String> noRealtime;

  @override
  Widget build(BuildContext context) {
    final muted = context.colors.onSurfaceVariant;
    final parts = <Widget?>[
      for (final leg in journey.legs)
        switch (leg) {
          RideLeg() => RideBadge(planner: planner, ride: leg, noRealtime: noRealtime),
          // The number alone reads as minutes on foot next to its icon; screen readers get it in words.
          WalkLeg() when leg.end - leg.start >= 60 => Semantics(
            label: '${context.l10n.journeysWalkOnly} ${context.l10n.minutes(journeyMinutes(leg.end - leg.start))}',
            excludeSemantics: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions_walk, size: Spacing.l + Spacing.xs, color: muted),
                Text(
                  '${journeyMinutes(leg.end - leg.start)}',
                  style: context.textTheme.labelLarge?.copyWith(color: muted),
                ),
              ],
            ),
          ),
          WalkLeg() => null,
        },
    ].nonNulls.toList();
    return Wrap(
      spacing: Spacing.xs,
      runSpacing: Spacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (i, part) in parts.indexed) ...[
          if (i > 0) Icon(Icons.chevron_right, size: Spacing.l, color: muted),
          part,
        ],
      ],
    );
  }
}
