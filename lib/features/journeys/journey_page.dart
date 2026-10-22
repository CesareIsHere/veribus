import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:veribus/core/providers/network_provider.dart';
import 'package:veribus/core/widgets/line_chip.dart';
import 'package:veribus/core/widgets/states/message_view.dart';
import 'package:veribus/core/widgets/transit_map.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/journeys/components/journey_timeline.dart';
import 'package:veribus/features/journeys/components/journey_widgets.dart';
import 'package:veribus/features/journeys/providers/journeys_providers.dart';
import 'package:veribus/features/journeys/trip_page.dart';
import 'package:veribus/models/journeys/journey_planner.dart';
import 'package:veribus/models/journeys/place.dart';
import 'package:veribus/models/journeys/raptor.dart';
import 'package:veribus/styles/app_spacing.dart';
import 'package:veribus/styles/app_theme.dart';

/// What the detail page shows: a journey of a plan, with its planner, where the user was and where they go.
class JourneyArgs {
  const JourneyArgs({required this.planner, required this.journey, required this.from, required this.to});

  final JourneyPlanner planner;
  final PlannedJourney journey;
  final Place from;
  final Place to;
}

/// One journey on the map and, in a sheet that rises over it, leg by leg: where to walk, which bus to take and its
/// state, where to get off, how a change went in the last weeks and what comes next if it is missed. The map shows the
/// rides in the color of their line and the walks dotted. "Start" follows the journey step by step.
class JourneyPage extends ConsumerWidget {
  const JourneyPage({required this.args, super.key});

  static const route = '/journeys/detail';

  /// Null when the page is opened without its journey (restored after the app was killed): back to the list.
  final JourneyArgs? args;

  /// The sheet starts at this fraction of the screen, high enough for the times and the first legs.
  static const _sheetStart = 0.5;

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
    final height = MediaQuery.sizeOf(context).height;

    LatLng stop(int s) => LatLng(tt.stopLat[s] / 1e6, tt.stopLon[s] / 1e6);
    LatLng endOf(int? s, LatLng place) => s == null ? place : stop(s);
    final rides = [
      for (final r in legs.whereType<RideLeg>()) (line: rideRoute(ref, planner, r), color: _color(context, planner, r)),
    ];
    // On foot along the streets as soon as the routing service answers; the straight line until then.
    final walks = [
      for (final w in legs.whereType<WalkLeg>())
        if (w.end > w.start)
          walkLine(
            endOf(w.from, args.from.point),
            endOf(w.to, args.to.point),
            ref.watch(walkRouteProvider(endOf(w.from, args.from.point), endOf(w.to, args.to.point))).value,
          ),
    ];
    final changes = journey.rides - 1;
    final scheme = context.colors;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: TransitMap(
              fit: [args.from.point, args.to.point, for (final r in rides) ...r.line],
              fitPadding: EdgeInsets.fromLTRB(
                Spacing.xxxl,
                Spacing.xxxl * 2,
                Spacing.xxxl,
                height * _sheetStart + Spacing.l,
              ),
              locateButton: false,
              children: [
                PolylineLayer(
                  polylines: [
                    for (final w in walks)
                      Polyline(points: w, strokeWidth: 3, color: scheme.outline, pattern: const StrokePattern.dotted()),
                    for (final r in rides) Polyline(points: r.line, strokeWidth: 6, color: r.color),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    for (final r in legs.whereType<RideLeg>())
                      for (final s in [r.fromStop, r.toStop])
                        StopMarker(point: stop(s), label: tt.stopNames[s], onTap: () {}),
                    Marker(
                      point: args.to.point,
                      width: Spacing.xxxl,
                      height: Spacing.xxxl,
                      child: Icon(Icons.location_on, size: Spacing.xxxl, color: scheme.error),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(context.pageMargin),
              child: IconButton.filledTonal(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.canPop() ? context.pop() : context.go('/'),
              ),
            ),
          ),
          DraggableScrollableSheet(
            minChildSize: 0.28,
            maxChildSize: 0.94,
            snap: true,
            snapSizes: const [0.28, _sheetStart, 0.94],
            builder: (context, controller) => Material(
              color: scheme.surface,
              elevation: 3,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
              clipBehavior: Clip.antiAlias,
              child: ListView(
                controller: controller,
                padding: EdgeInsets.fromLTRB(context.pageMargin, 0, context.pageMargin, Spacing.xxxl * 2 + Spacing.xl),
                children: [
                  Center(
                    child: Container(
                      width: Spacing.xxl,
                      height: Spacing.xs,
                      margin: const EdgeInsets.symmetric(vertical: Spacing.m),
                      decoration: BoxDecoration(color: scheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Text(
                    l10n.journeysTimes(journeyClock(planner, journey.depart), journeyClock(planner, journey.arrive)),
                    style: context.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    [
                      journeyDuration(l10n, journey.arrive - journey.depart),
                      if (journey.rides == 0)
                        l10n.journeysWalkOnly
                      else if (changes == 0)
                        l10n.journeysDirect
                      else
                        l10n.journeysChanges(changes),
                      if (journeyMinutes(walkingSeconds(journey)) > 0 && journey.rides > 0)
                        l10n.journeysWalkTotal(journeyMinutes(walkingSeconds(journey))),
                    ].join(' · '),
                    style: context.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: Spacing.l),
                  JourneyTimeline(
                    planner: planner,
                    journey: args.journey,
                    from: args.from,
                    to: args.to,
                    noRealtime: noRealtime,
                  ),
                  const SizedBox(height: Spacing.l),
                  Text(l10n.journeysNote, style: context.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: journey.rides == 0
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push(TripPage.route, extra: args),
              icon: const Icon(Icons.navigation),
              label: Text(l10n.journeysStart),
            ),
    );
  }

  static Color _color(BuildContext context, JourneyPlanner planner, RideLeg ride) {
    final tt = planner.timetable;
    return LineChip.colorOf(context, rideKind(planner, ride), tt.lineNames[tt.routeLine[ride.route]]);
  }
}
