import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:veribus/core/config.dart'; // feature:push
import 'package:veribus/core/providers/network_provider.dart';
import 'package:veribus/core/widgets/states/message_view.dart';
import 'package:veribus/core/widgets/transit_map.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/journeys/components/journey_widgets.dart';
import 'package:veribus/features/journeys/providers/journeys_providers.dart';
import 'package:veribus/features/stop/stop_page.dart';
import 'package:veribus/models/journeys/journey_planner.dart';
import 'package:veribus/models/journeys/place.dart';
import 'package:veribus/models/journeys/raptor.dart';
import 'package:veribus/models/journeys/timetable.dart';
import 'package:veribus/styles/app_spacing.dart';

/// What the detail page shows: a journey of a plan, with its planner, where the user was and where they go.
class JourneyArgs {
  const JourneyArgs({required this.planner, required this.journey, required this.from, required this.to});

  final JourneyPlanner planner;
  final PlannedJourney journey;
  final LatLng from;
  final Place to;
}

/// One journey leg by leg: where to walk, which bus to take and its state, where to get off, how a change went in the
/// last weeks and what comes next if it is missed. The map shows the rides (solid) and the walks (dotted).
class JourneyPage extends ConsumerWidget {
  const JourneyPage({required this.args, super.key});

  static const route = '/journeys/detail';

  /// Null when the page is opened without its journey (restored after the app was killed): back to the list.
  final JourneyArgs? args;

  /// A wait longer than this at a change is said aloud: at night it means standing at a stop for a while.
  static const int _longWait = 20 * 60;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final args = this.args;
    if (args == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.journeysDetails)),
        body: MessageView(icon: Icons.route, title: l10n.journeysGone),
      );
    }
    final planner = args.planner;
    final tt = planner.timetable;
    final journey = args.journey.journey;
    final noRealtime = ref.watch(networkInfoProvider).value?.noRealtime ?? const {};
    final legs = journey.legs;
    final muted = context.textTheme.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant);

    LatLng stop(int s) => LatLng(tt.stopLat[s] / 1e6, tt.stopLon[s] / 1e6);
    LatLng endOf(int? s, LatLng place) => s == null ? place : stop(s);
    bool metro(RideLeg r) => tt.lineTypes[tt.routeLine[r.route]] == Timetable.metro;
    // The stop page knows the bus and tram stops only: the metro is in the planner's timetable alone.
    VoidCallback? openStop(int s, RideLeg r) => metro(r) ? null : () => context.push(StopPage.route(tt.stopIds[s]));
    final rides = [
      for (final r in legs.whereType<RideLeg>())
        [for (var i = r.board; i <= r.alight; i++) stop(tt.routeStop(r.route, i))],
    ];
    final walks = [
      for (final w in legs.whereType<WalkLeg>())
        if (w.end > w.start) [endOf(w.from, args.from), endOf(w.to, args.to.point)],
    ];

    final steps = <Widget>[];
    RideLeg? previous;
    for (final (i, leg) in legs.indexed) {
      switch (leg) {
        case WalkLeg(:final from, :final to) when leg.end > leg.start:
          final minutes = journeyMinutes(leg.end - leg.start);
          steps.add(
            _Step(
              icon: Icons.directions_walk,
              title: to == null
                  ? (args.to.isHome ? l10n.journeysWalkHome(minutes) : l10n.journeysWalkToDestination(minutes))
                  : from == null
                  ? l10n.journeysWalkToStop(minutes, tt.stopNames[to])
                  : l10n.journeysWalkBetween(minutes, tt.stopNames[to]),
              subtitle: Text(journeyClock(planner, leg.start), style: muted),
            ),
          );
        case WalkLeg():
          break;
        case RideLeg():
          final before = i > 0 ? legs[i - 1] : null;
          final walk = before is WalkLeg && before.from != null ? before.end - before.start : 0;
          if (previous != null) {
            final wait = leg.start - previous.end - walk;
            steps.add(
              _ChangeInfo(slots: changeSlots(planner, previous, leg, walk), wait: wait, longWait: wait > _longWait),
            );
          }
          final next = previous == null ? null : planner.nextDeparture(leg);
          final line = tt.lineNames[tt.routeLine[leg.route]];
          steps.add(
            _Step(
              leading: RideBadge(planner: planner, ride: leg, noRealtime: noRealtime),
              title: '→ ${tt.routeHeadsign[leg.route]}',
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Spacing.xs,
                children: [
                  InkWell(
                    onTap: openStop(leg.fromStop, leg),
                    child: Text(l10n.journeysBoard(tt.stopNames[leg.fromStop], journeyClock(planner, leg.start))),
                  ),
                  RideStatus(planner: planner, journey: args.journey, ride: leg, noRealtime: noRealtime),
                  Text(
                    l10n.journeysAlight(
                      tt.stopNames[leg.toStop],
                      journeyClock(planner, leg.end),
                      l10n.journeysStops(leg.alight - leg.board),
                    ),
                  ),
                  // feature:push:start
                  if (Features.push)
                    if (followRouteOf(planner, leg) case final route?)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => context.push(route),
                          icon: const Icon(Icons.notifications_outlined),
                          label: Text(l10n.followTrip),
                        ),
                      ),
                  // feature:push:end
                  // Missing a change is what goes wrong: what to take then.
                  if (previous != null)
                    Text(
                      next == null
                          ? l10n.journeysIfMissedNone(line)
                          : l10n.journeysIfMissed(line, journeyClock(planner, next)),
                      style: muted,
                    ),
                ],
              ),
            ),
          );
          previous = leg;
      }
    }
    final arrive = journeyClock(planner, journey.arrive);
    steps.add(
      args.to.isHome
          ? _Step(icon: Icons.home_outlined, title: l10n.journeysArriveHome(arrive))
          : _Step(
              icon: Icons.place_outlined,
              title: l10n.journeysArriveDestination(arrive),
              subtitle: Text(args.to.name),
            ),
    );

    final changes = journey.rides - 1;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.journeysDetails)),
      body: ListView(
        padding: context.pagePadding(),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Spacing.m),
            child: SizedBox(
              height: 220,
              child: TransitMap(
                fit: [args.from, args.to.point, for (final r in rides) ...r],
                children: [
                  PolylineLayer(
                    polylines: [
                      for (final w in walks)
                        Polyline(
                          points: w,
                          strokeWidth: 3,
                          color: context.colors.outline,
                          pattern: const StrokePattern.dotted(),
                        ),
                      for (final r in rides) Polyline(points: r, strokeWidth: 5, color: context.colors.primary),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      for (final r in legs.whereType<RideLeg>()) ...[
                        for (final s in [r.fromStop, r.toStop])
                          StopMarker(point: stop(s), label: tt.stopNames[s], onTap: openStop(s, r) ?? () {}),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spacing.l),
          Text(
            l10n.journeysTimes(journeyClock(planner, journey.depart), journeyClock(planner, journey.arrive)),
            style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            [
              l10n.minutes(journeyMinutes(journey.arrive - journey.depart)),
              if (journey.rides == 0)
                l10n.journeysWalkOnly
              else if (changes == 0)
                l10n.journeysDirect
              else
                l10n.journeysChanges(changes),
            ].join(' · '),
            style: muted,
          ),
          const SizedBox(height: Spacing.l),
          ...steps,
          const SizedBox(height: Spacing.xl),
          Text(l10n.journeysNote, style: context.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// One step of the journey: an icon or a badge, what to do, and its details.
class _Step extends StatelessWidget {
  const _Step({required this.title, this.icon, this.leading, this.subtitle});

  final IconData? icon;
  final Widget? leading;
  final String title;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Spacing.l,
        children: [
          SizedBox(
            width: Spacing.xxxl + Spacing.xl,
            child: Align(
              alignment: Alignment.topLeft,
              child: leading ?? Icon(icon, color: context.colors.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Spacing.xs,
              children: [
                Text(title, style: context.textTheme.titleSmall),
                ?subtitle,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A change: the wait, and how often it worked in the history of both trips.
class _ChangeInfo extends ConsumerWidget {
  const _ChangeInfo({required this.slots, required this.wait, required this.longWait});

  final ChangeSlots slots;
  final int wait;
  final bool longWait;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final record = ref.watch(changeReliabilityProvider(slots));
    final style = context.textTheme.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant);
    return _Step(
      icon: Icons.sync_alt,
      title: [l10n.journeysWait(journeyMinutes(wait)), if (longWait) l10n.journeysLongWait].join(' · '),
      subtitle: switch (record) {
        AsyncValue(value: (:final made, :final days)?) when days > 0 => Text(
          l10n.journeysChangeRecord(made, days),
          style: style,
        ),
        // The history is a bonus: an error or no data says the same.
        AsyncValue(hasValue: true) || AsyncValue(hasError: true) => Text(l10n.journeysChangeNoRecord, style: style),
        _ => const LinearProgressIndicator(),
      },
    );
  }
}
