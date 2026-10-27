import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:veribus/core/widgets/line_chip.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/journeys/providers/journeys_providers.dart';
import 'package:veribus/features/notifications/follow_page.dart'; // feature:push
import 'package:veribus/features/stop/components/arrival_tile.dart';
import 'package:veribus/l10n/gen/app_localizations.dart';
import 'package:veribus/models/journeys/journey_planner.dart';
import 'package:veribus/models/journeys/raptor.dart';
import 'package:veribus/models/journeys/timetable.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/models/transit/transit_kind.dart';
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
List<LatLng> alongShape(List<LatLng> shape, List<LatLng> stops, int board, int alight) =>
    alongShapeOrNull(shape, stops, board, alight) ?? stops.sublist(board, alight + 1);

/// [alongShape], or null where it would join the stops straight: the line has no path, or a stop is not on it.
List<LatLng>? alongShapeOrNull(List<LatLng> shape, List<LatLng> stops, int board, int alight) {
  const List<LatLng>? straight = null;
  final joined = stops.sublist(board, alight + 1);
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
  return length(piece) > 2 * length(joined) + 500 ? straight : piece;
}

/// "1 h 5 min" from 60 minutes up, "42 min" below: the big number of a journey.
String journeyDuration(AppLocalizations l10n, int seconds) {
  final minutes = journeyMinutes(seconds);
  return minutes < 60 ? l10n.minutes(minutes) : l10n.journeysDurationHm(minutes ~/ 60, minutes % 60);
}

/// The kind of vehicle of a ride: what its chip shows.
TransitKind rideKind(JourneyPlanner planner, RideLeg ride) => routeKind(planner, ride.route);

/// The kind of vehicle of a route of the timetable.
TransitKind routeKind(JourneyPlanner planner, int route) {
  final tt = planner.timetable;
  final line = tt.routeLine[route];
  return TransitKind.ofTimetable(
    name: tt.lineNames[line],
    isTram: tt.lineTypes[line] == Timetable.tram,
    isMetro: tt.lineTypes[line] == Timetable.metro,
  );
}

/// The streets of [ride] on the map: the line's path cut between its stops, or from stop to stop for the metro and
/// when the line has no path (`alongShape`). Watches the path of the line, which the first call loads.
List<LatLng> rideRoute(WidgetRef ref, JourneyPlanner planner, RideLeg ride) {
  final tt = planner.timetable;
  LatLng stop(int s) => LatLng(tt.stopLat[s] / 1e6, tt.stopLon[s] / 1e6);
  final stops = [for (var i = 0; i <= ride.alight; i++) stop(tt.routeStop(ride.route, i))];
  final joined = stops.sublist(ride.board);
  if (rideKind(planner, ride) == TransitKind.metro) return joined;
  final shape = ref.watch(lineShapeProvider(tt.lineIds[tt.routeLine[ride.route]], tt.routeDirection[ride.route]));
  final along = alongShapeOrNull(shape.value ?? const [], stops, ride.board, ride.alight);
  if (along != null || !shape.hasValue) return along ?? joined;
  // A variant of the line, which the path does not follow: the streets between its stops, by road, rather than the
  // stops joined by straight lines across the blocks.
  final road = ref.watch(roadRouteProvider(waypointsOf(joined))).value;
  return road == null || road.length < 2 ? joined : road;
}

/// The line of a ride: its chip with the color and the icon of its kind (the metro and the tram are told apart from
/// the bus by the icon, not by color alone). Muted when the line never transmits positions; not for the metro, whose
/// colors are what riders look for.
class RideChip extends StatelessWidget {
  const RideChip({required this.planner, required this.ride, required this.noRealtime, this.large = false, super.key});

  final JourneyPlanner planner;
  final RideLeg ride;
  final Set<String> noRealtime;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final tt = planner.timetable;
    final line = tt.routeLine[ride.route];
    final kind = rideKind(planner, ride);
    return Semantics(
      label: kind == TransitKind.metro ? context.l10n.journeysMetro(tt.lineNames[line]) : null,
      child: LineChip(
        tt.lineNames[line],
        kind: kind,
        muted: kind != TransitKind.metro && noRealtime.contains(tt.lineIds[line]),
        large: large,
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

/// Seconds on foot in a journey, whatever the legs.
int walkingSeconds(Journey journey) => journey.legs.whereType<WalkLeg>().fold(0, (sum, w) => sum + (w.end - w.start));

/// One journey in the list: how long it takes, with what (the legs at a glance), when, and the state of the first
/// bus (the one to catch now) with how often the first change worked.
class JourneyCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final j = journey.journey;
    final rides = journey.rides;
    final changes = rides.length - 1;
    final walk = journeyMinutes(walkingSeconds(j));
    final first = rides.firstOrNull;
    return Card.filled(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Spacing.s,
                children: [
                  Expanded(
                    child: LegsSummary(planner: planner, journey: j, noRealtime: noRealtime),
                  ),
                  Text(
                    journeyDuration(l10n, j.arrive - j.depart),
                    style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              Text(
                [
                  l10n.journeysTimes(journeyClock(planner, j.depart), journeyClock(planner, j.arrive)),
                  if (first == null) l10n.journeysWalkOnly else if (changes > 0) l10n.journeysChanges(changes),
                  if (first != null && changes == 0) l10n.journeysDirect,
                  if (walk > 0 && first != null) l10n.journeysWalkTotal(walk),
                ].join(' · '),
                style: context.textTheme.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              if (first != null) ...[
                const Divider(height: Spacing.l),
                _FirstRide(planner: planner, journey: journey, ride: first, noRealtime: noRealtime),
                if (changes > 0) _ChangeRecord(planner: planner, rides: rides, journey: j),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The first bus: when it comes, from which stop, and how sure that is.
class _FirstRide extends StatelessWidget {
  const _FirstRide({required this.planner, required this.journey, required this.ride, required this.noRealtime});

  final JourneyPlanner planner;
  final PlannedJourney journey;
  final RideLeg ride;
  final Set<String> noRealtime;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final arrival = journey.realtimeOf(ride);
    final tt = planner.timetable;
    return Row(
      spacing: Spacing.s,
      children: [
        if (arrival != null)
          ArrivalTime(arrival, large: false)
        else
          Text(journeyClock(planner, ride.start), style: context.textTheme.titleSmall),
        Expanded(
          child: Text(
            l10n.journeysFrom(tt.stopNames[ride.fromStop]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium,
          ),
        ),
        StatusTag(arrival?.status ?? ArrivalStatus.scheduled),
      ],
    );
  }
}

/// How often the first change of the journey worked in the last weeks: "17 times out of 20". Nothing without history.
class _ChangeRecord extends ConsumerWidget {
  const _ChangeRecord({required this.planner, required this.rides, required this.journey});

  final JourneyPlanner planner;
  final List<RideLeg> rides;
  final Journey journey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final legs = journey.legs;
    final next = legs.indexOf(rides[1]);
    final before = next > 0 ? legs[next - 1] : null;
    final walk = before is WalkLeg && before.from != null ? before.end - before.start : 0;
    final record = ref.watch(changeReliabilityProvider(changeSlots(planner, rides[0], rides[1], walk)));
    return switch (record) {
      AsyncValue(value: (:final made, :final days)?) when days > 0 => Row(
        spacing: Spacing.s,
        children: [
          Icon(
            made * 10 >= days * 7 ? Icons.check_circle_outline : Icons.warning_amber,
            size: Spacing.l,
            color: made * 10 >= days * 7 ? context.appColors.success : context.colors.tertiary,
          ),
          Expanded(
            child: Text(
              context.l10n.journeysChangeRecord(made, days),
              style: context.textTheme.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

/// The legs in a row: the minutes on foot and the chips of the lines, with arrows between them.
class LegsSummary extends StatelessWidget {
  const LegsSummary({required this.planner, required this.journey, required this.noRealtime, super.key});

  final JourneyPlanner planner;
  final Journey journey;
  final Set<String> noRealtime;

  @override
  Widget build(BuildContext context) {
    // Two walks in a row (to a stop, then along a link to the next) are one walk for the traveller.
    final parts = <Widget>[];
    var walked = 0;
    void flushWalk() {
      // The number alone reads as minutes on foot next to its icon; screen readers get it in words.
      if (walked >= 60) parts.add(WalkChip(minutes: journeyMinutes(walked)));
      walked = 0;
    }

    for (final leg in journey.legs) {
      switch (leg) {
        case RideLeg():
          flushWalk();
          parts.add(RideChip(planner: planner, ride: leg, noRealtime: noRealtime));
        case WalkLeg():
          walked += leg.end - leg.start;
      }
    }
    flushWalk();
    return Wrap(
      spacing: Spacing.xs,
      runSpacing: Spacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (i, part) in parts.indexed) ...[
          if (i > 0) Icon(Icons.chevron_right, size: Spacing.l, color: context.colors.outline),
          part,
        ],
      ],
    );
  }
}

/// Minutes on foot: the walking icon and the number.
class WalkChip extends StatelessWidget {
  const WalkChip({required this.minutes, super.key});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.onSurfaceVariant;
    return Semantics(
      label: context.l10n.journeysWalkTotal(minutes),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_walk, size: Spacing.l + Spacing.xs, color: color),
          Text(
            '$minutes',
            style: context.textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
