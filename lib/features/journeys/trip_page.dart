import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:veribus/core/providers/network_provider.dart';
import 'package:veribus/core/providers/position_provider.dart';
import 'package:veribus/core/widgets/line_chip.dart';
import 'package:veribus/core/widgets/states/message_view.dart';
import 'package:veribus/core/widgets/transit_map.dart';
import 'package:veribus/core/widgets/vehicle_route.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/journeys/components/journey_widgets.dart';
import 'package:veribus/features/journeys/journey_page.dart';
import 'package:veribus/features/journeys/providers/journeys_providers.dart';
import 'package:veribus/features/line/components/timeline.dart';
import 'package:veribus/features/nearby/nearby_page.dart';
import 'package:veribus/features/stop/components/arrival_tile.dart';
import 'package:veribus/l10n/gen/app_localizations.dart';
import 'package:veribus/models/journeys/raptor.dart';
import 'package:veribus/models/journeys/trip_progress.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/services/location_tracker.dart';
import 'package:veribus/services/push_notifications_service.dart'; // feature:push
import 'package:veribus/styles/app_spacing.dart';
import 'package:veribus/styles/app_theme.dart';

/// A journey followed step by step: one instruction at a time, as big as it can be read walking (walk to this stop,
/// get on this bus, get off in 3 stops), with the state of the bus from the realtime. The position says where the
/// traveller is (`followTrip`); a stop before the one to get off the phone vibrates and, when the notices are on, shows
/// one. Works with the screen on: the app asks the position only while it is in front.
class TripPage extends ConsumerStatefulWidget {
  const TripPage({required this.args, super.key});

  static const route = '/journeys/trip';

  /// Null when the page is opened without its journey (restored after the app was killed): back to the list.
  final JourneyArgs? args;

  @override
  ConsumerState<TripPage> createState() => _TripPageState();
}

class _TripPageState extends ConsumerState<TripPage> {
  static const _noticeId = 7001; // feature:push

  var _state = const TripState();
  late TripView _view;
  final _alerted = <int>{};

  /// The tracker that holds the foreground service while the journey goes on (kept to release it in [dispose]).
  late final LocationTracker _tracker = ref.read(locationTrackerProvider);

  /// What the notification says changes with this: a new text means listening again.
  (TripPhase, int, int?)? _noticeKey;
  var _started = false;

  List<RideLeg> get _rides => widget.args!.journey.rides;

  @override
  void initState() {
    super.initState();
    if (widget.args != null) _advance(ref.read(positionProvider).value);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.args == null || _started) return;
    _started = true;
    _syncNotification();
    // feature:push:start
    unawaited(_askNotifications());
    // feature:push:end
  }

  @override
  void dispose() {
    if (widget.args != null) unawaited(_tracker.follow(null));
    super.dispose();
  }

  // feature:push:start
  /// The notification of the journey needs the permission of the notices (Android 13+): asked once, when it starts.
  Future<void> _askNotifications() async {
    try {
      await ref.read(pushServiceProvider).requestNotifications();
    } on Object {
      // This build has no notices (no Firebase configuration): the journey goes on without the permission.
    }
  }
  // feature:push:end

  void _advance(LatLng? position) {
    final args = widget.args!;
    final view = followTrip(
      timetable: args.planner.timetable,
      rides: _rides,
      destination: args.to.point,
      state: _state,
      position: position,
    );
    // One stop before the one to get off at: the phone vibrates, and a notice is shown when they are allowed.
    if (view.phase == TripPhase.onBoard && view.stopsLeft == 1 && _alerted.add(view.state.ride)) {
      unawaited(HapticFeedback.heavyImpact());
      // feature:push:start
      unawaited(
        ref
            .read(pushServiceProvider)
            .showNow(
              id: _noticeId,
              title: context.l10n.tripAlertTitle,
              body: args.planner.timetable.stopNames[view.ride!.toStop],
            ),
      );
      // feature:push:end
    }
    _state = view.state;
    _view = view;
    if (_started) _syncNotification();
  }

  /// The ongoing notification says the next step, and the foreground service behind it keeps the position coming with
  /// the screen off. When the step changes the tracker starts the service again with the new text; when the journey ends
  /// it lets it go.
  void _syncNotification() {
    final view = _view;
    final key = (view.phase, view.state.ride, view.stopsLeft);
    if (key == _noticeKey) return;
    _noticeKey = key;
    if (view.phase == TripPhase.arrived) {
      unawaited(_tracker.follow(null));
      return;
    }
    final l10n = context.l10n;
    final notice = tripNotice(l10n, widget.args!, view);
    unawaited(_tracker.follow((title: notice.title, text: notice.text, channelName: l10n.tripChannelName)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final args = widget.args;
    if (args == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.journeysDetails)),
        body: MessageView(icon: Icons.route, title: l10n.journeysGone),
      );
    }
    // Every new fix moves the journey on, from the foreground service or from the live position of the map.
    ref.listen(positionProvider, (_, next) => setState(() => _advance(next.value)));
    final position = ref.watch(positionProvider).value;
    final view = _view;
    final noRealtime = ref.watch(networkInfoProvider).value?.noRealtime ?? const {};
    return Scaffold(
      body: switch (view.phase) {
        TripPhase.onBoard => _OnBoard(args: args, view: view, noRealtime: noRealtime),
        TripPhase.arrived => _Arrived(args: args),
        _ => _OnFoot(args: args, view: view, position: position, noRealtime: noRealtime),
      },
    );
  }
}

/// What the ongoing notification says for [view]: the step and its stable details (the clock times, not the metres,
/// which would be wrong a moment later: the text only changes with the step).
({String title, String text}) tripNotice(AppLocalizations l10n, JourneyArgs args, TripView view) {
  final planner = args.planner;
  final tt = planner.timetable;
  final ride = view.ride;
  final arrive = journeyClock(planner, args.journey.journey.arrive);
  final end = args.to.isHome ? l10n.journeysArriveHome(arrive) : l10n.journeysArriveDestination(arrive);
  if (ride == null) {
    return view.phase == TripPhase.arrived
        ? (title: l10n.tripArrived, text: args.to.name)
        : (title: l10n.tripWalkTo(args.to.name), text: end);
  }
  final line = tt.lineNames[tt.routeLine[ride.route]];
  return switch (view.phase) {
    TripPhase.atStop => (title: l10n.tripBoard(line), text: l10n.tripWaitHere(tt.routeHeadsign[ride.route])),
    TripPhase.onBoard => (
      title: (view.stopsLeft ?? 2) <= 1 ? l10n.tripGetOffNext : l10n.tripGetOffIn(view.stopsLeft!),
      text: l10n.tripGetOffAt(tt.stopNames[ride.toStop], journeyClock(planner, ride.end)),
    ),
    _ => (
      title: l10n.tripWalkTo(tt.stopNames[ride.fromStop]),
      text: l10n.tripYourLine(line, l10n.tripAtTime(journeyClock(planner, ride.start))),
    ),
  };
}

/// The instruction in a big card: what to do now, and the details under it.
class _InstructionCard extends StatelessWidget {
  const _InstructionCard({required this.icon, required this.title, this.subtitle, this.footer});

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Material(
      color: scheme.primary,
      borderRadius: BorderRadius.circular(AppTheme.sheetRadius),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl - Spacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Spacing.m,
          children: [
            Row(
              spacing: Spacing.l,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(Spacing.l + Spacing.xs),
                  ),
                  child: SizedBox.square(
                    dimension: Spacing.xxxl + Spacing.s,
                    child: Icon(icon, size: Spacing.xxl, color: scheme.onPrimaryContainer),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.textTheme.headlineSmall?.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle != null)
                        Text(subtitle!, style: context.textTheme.bodyLarge?.copyWith(color: scheme.onPrimary)),
                    ],
                  ),
                ),
              ],
            ),
            if (footer != null) ...[Divider(height: 1, color: scheme.onPrimary.withValues(alpha: 0.25)), footer!],
          ],
        ),
      ),
    );
  }
}

/// "5 min" on foot for [meters], at the planner's pace, at least one.
int _walkMinutes(double meters) => math.max(1, (meters / (1.2 * 60)).ceil());

/// Metres to the nearest ten: a GPS does not know the units.
int _round(double meters) => (meters / 10).round() * 10;

/// The state of the ride at its boarding stop, for the card: "Your H comes in 7 min", with the tag.
class _BusStatus extends StatelessWidget {
  const _BusStatus({required this.args, required this.ride, required this.noRealtime});

  final JourneyArgs args;
  final RideLeg ride;
  final Set<String> noRealtime;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final planner = args.planner;
    final tt = planner.timetable;
    final arrival = args.journey.realtimeOf(ride);
    final scheme = context.colors;
    final line = tt.lineNames[tt.routeLine[ride.route]];
    final when = arrival?.minutes != null
        ? l10n.journeysInMinutes(arrival!.minutes!)
        : l10n.tripAtTime(journeyClock(planner, ride.start));
    return Row(
      spacing: Spacing.s,
      children: [
        if (arrival?.status == ArrivalStatus.confirmed)
          Icon(Icons.rss_feed, size: Spacing.l, color: scheme.inversePrimary),
        Expanded(
          child: Text(
            l10n.tripYourLine(line, when),
            style: context.textTheme.titleSmall?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w700),
          ),
        ),
        StatusTag(arrival?.status ?? ArrivalStatus.scheduled),
      ],
    );
  }
}

/// Walking to a stop (or home) and waiting at the stop: the map, the instruction on top and the journey in short at the
/// bottom. The way is drawn along the streets, from where the walk began, and asked again if the traveller leaves it.
class _OnFoot extends ConsumerStatefulWidget {
  const _OnFoot({required this.args, required this.view, required this.position, required this.noRealtime});

  final JourneyArgs args;
  final TripView view;
  final LatLng? position;
  final Set<String> noRealtime;

  @override
  ConsumerState<_OnFoot> createState() => _OnFootState();
}

class _OnFootState extends ConsumerState<_OnFoot> {
  /// Farther than this from the way drawn, the traveller took another street: a new way is asked from where they are.
  static const _lostMeters = 80.0;

  /// Where the way on the map starts: the position when the walk began, or where the traveller left the way.
  LatLng? _from;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final args = widget.args;
    final view = widget.view;
    final position = widget.position;
    final planner = args.planner;
    final tt = planner.timetable;
    final scheme = context.colors;
    final ride = view.ride;
    final atStop = view.phase == TripPhase.atStop;
    final toDestination = view.phase == TripPhase.toDestination;
    final target = toDestination || ride == null
        ? args.to.point
        : LatLng(tt.stopLat[ride.fromStop] / 1e6, tt.stopLon[ride.fromStop] / 1e6);
    final targetName = toDestination || ride == null ? args.to.name : tt.stopNames[ride.fromStop];
    final line = ride == null ? null : tt.lineNames[tt.routeLine[ride.route]];
    final meters = view.meters;
    final rideLine = ride == null ? const <LatLng>[] : rideRoute(ref, planner, ride);

    if (position != null) _from ??= position;
    final route = _from == null ? null : ref.watch(walkRouteProvider(_from!, target)).value;
    var walkAhead = <LatLng>[?position, target];
    if (position != null && route != null && route.length > 1) {
      final (:behind, :ahead) = splitRoute(route, position);
      if (const Distance()(position, behind.last) > _lostMeters) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _from = position);
        });
      } else {
        walkAhead = [position, ...ahead, target];
      }
    }
    return Stack(
      children: [
        Positioned.fill(
          child: TransitMap(
            fit: [?position, target],
            fitPadding: const EdgeInsets.fromLTRB(Spacing.xxxl, Spacing.xxxl * 4, Spacing.xxxl, Spacing.xxxl * 4),
            locateButton: false,
            children: [
              PolylineLayer(
                polylines: [
                  if (position != null)
                    Polyline(
                      points: walkAhead,
                      strokeWidth: 4,
                      color: scheme.primary,
                      pattern: const StrokePattern.dotted(),
                    ),
                  if (rideLine.length > 1 && !toDestination && ride != null)
                    Polyline(
                      points: rideLine,
                      strokeWidth: 6,
                      color: LineChip.colorOf(context, rideKind(planner, ride), line ?? ''),
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: target,
                    width: Spacing.xxxl,
                    height: Spacing.xxxl,
                    child: Icon(
                      toDestination ? Icons.location_on : Icons.directions_bus,
                      size: Spacing.xxl,
                      color: toDestination ? scheme.error : scheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.all(context.pageMargin - Spacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: Spacing.s,
              children: [
                _InstructionCard(
                  icon: atStop ? Icons.directions_bus : Icons.directions_walk,
                  title: atStop && line != null ? l10n.tripBoard(line) : l10n.tripWalkTo(targetName),
                  subtitle: atStop && ride != null
                      ? l10n.tripWaitHere(tt.routeHeadsign[ride.route])
                      : meters == null
                      ? null
                      : l10n.tripDistance(_round(meters), _walkMinutes(meters)),
                  footer: ride == null || toDestination
                      ? null
                      : _BusStatus(args: args, ride: ride, noRealtime: widget.noRealtime),
                ),
                if (position == null)
                  Card(
                    margin: EdgeInsets.zero,
                    color: scheme.errorContainer,
                    child: ListTile(
                      leading: Icon(Icons.location_disabled, color: scheme.onErrorContainer),
                      title: Text(l10n.tripNeedPosition, style: TextStyle(color: scheme.onErrorContainer)),
                      trailing: TextButton(
                        onPressed: () => ref.read(locationTrackerProvider).enable(),
                        child: Text(l10n.enableLocation),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: _Summary(args: args),
        ),
      ],
    );
  }
}

/// The journey in short under the instruction: how far along it is, when it ends, and the way out.
class _Summary extends StatelessWidget {
  const _Summary({required this.args});

  final JourneyArgs args;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colors;
    final planner = args.planner;
    final journey = args.journey.journey;
    final elapsed = DateTime.now().difference(planner.timeOf(journey.depart)).inSeconds;
    final progress = (elapsed / math.max(1, journey.arrive - journey.depart)).clamp(0.0, 1.0);
    final arrive = journeyClock(planner, journey.arrive);
    return Material(
      color: scheme.surface,
      elevation: 3,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.xl, Spacing.xl, Spacing.xl, Spacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Spacing.m,
            children: [
              LinearProgressIndicator(
                value: progress,
                minHeight: Spacing.s,
                borderRadius: BorderRadius.circular(Spacing.xs),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      args.to.isHome ? l10n.journeysArriveHome(arrive) : l10n.journeysArriveDestination(arrive),
                      style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    journeyDuration(l10n, journey.arrive - journey.depart),
                    style: context.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              Row(
                spacing: Spacing.s,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
                      onPressed: () => context.go(NearbyPage.route),
                      child: Text(l10n.tripEnd),
                    ),
                  ),
                  Expanded(
                    child: FilledButton.tonal(onPressed: () => context.pop(), child: Text(l10n.tripAllSteps)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// On a vehicle: how many stops are left, the stops ahead with the one to get off at, and what comes next.
class _OnBoard extends ConsumerWidget {
  const _OnBoard({required this.args, required this.view, required this.noRealtime});

  final JourneyArgs args;
  final TripView view;
  final Set<String> noRealtime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colors;
    final planner = args.planner;
    final tt = planner.timetable;
    final ride = view.ride!;
    final left = view.stopsLeft ?? ride.alight - ride.board;
    final index = view.state.stopIndex ?? ride.board;
    final line = tt.lineNames[tt.routeLine[ride.route]];
    final color = LineChip.colorOf(context, rideKind(planner, ride), line);
    final rides = args.journey.rides;
    final position = rides.indexOf(ride);
    final next = position + 1 < rides.length ? rides[position + 1] : null;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(context.pageMargin - Spacing.xs),
            child: Column(
              spacing: Spacing.s,
              children: [
                _InstructionCard(
                  icon: Icons.directions_bus,
                  title: left <= 1 ? l10n.tripGetOffNext : l10n.tripGetOffIn(left),
                  subtitle: l10n.tripGetOffAt(tt.stopNames[ride.toStop], journeyClock(planner, ride.end)),
                  footer: Row(
                    spacing: Spacing.s,
                    children: [
                      RideChip(planner: planner, ride: ride, noRealtime: noRealtime),
                      Expanded(
                        child: Text(
                          '→ ${tt.routeHeadsign[ride.route]}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyLarge?.copyWith(color: scheme.onPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(Spacing.l + Spacing.xs),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.l, vertical: Spacing.m),
                    child: Row(
                      spacing: Spacing.m,
                      children: [
                        Icon(Icons.vibration, color: scheme.onTertiaryContainer),
                        Expanded(
                          child: Text(
                            l10n.tripAlertHint,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: scheme.onTertiaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(context.pageMargin, Spacing.s, context.pageMargin, Spacing.l),
              children: [
                for (var i = ride.board; i <= ride.alight; i++)
                  TimelineRow(
                    first: i == ride.board,
                    last: i == ride.alight,
                    railColor: color,
                    node: i == index
                        ? TimelineVehicle.node(context, null, color: color)
                        : TimelineStop.node(context, terminus: i == ride.alight, color: color),
                    child: Opacity(
                      opacity: i < index ? 0.45 : 1,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: Spacing.xxxl),
                        padding: const EdgeInsets.only(right: Spacing.s),
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                tt.stopNames[tt.routeStop(ride.route, i)] +
                                    (i == ride.alight ? ' · ${l10n.journeysGetOff}' : ''),
                                style: i == ride.alight || i == index
                                    ? context.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: i == ride.alight ? color : null,
                                      )
                                    : context.textTheme.bodyLarge,
                              ),
                            ),
                            Text(
                              journeyClock(planner, tt.time(ride.trip, i) + ride.delay),
                              style: context.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Material(
            color: scheme.surfaceContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.xl, Spacing.l, Spacing.xl, Spacing.l),
              child: Row(
                spacing: Spacing.m,
                children: [
                  if (next != null) ...[
                    RideChip(planner: planner, ride: next, noRealtime: noRealtime),
                    Expanded(
                      child: Text(
                        l10n.tripThenNoWalk(tt.lineNames[tt.routeLine[next.route]], journeyClock(planner, next.start)),
                        style: context.textTheme.bodyMedium,
                      ),
                    ),
                  ] else
                    Expanded(
                      child: Text(
                        args.to.isHome
                            ? l10n.journeysArriveHome(journeyClock(planner, args.journey.journey.arrive))
                            : l10n.journeysArriveDestination(journeyClock(planner, args.journey.journey.arrive)),
                        style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  TextButton(onPressed: () => context.pop(), child: Text(l10n.tripAllSteps)),
                  TextButton(
                    onPressed: () => context.go(NearbyPage.route),
                    style: TextButton.styleFrom(foregroundColor: scheme.error),
                    child: Text(l10n.tripEnd),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Got there.
class _Arrived extends StatelessWidget {
  const _Arrived({required this.args});

  final JourneyArgs args;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MessageView(
      icon: args.to.isHome ? Icons.home : Icons.where_to_vote_outlined,
      title: l10n.tripArrived,
      description: args.to.name,
      action: FilledButton(onPressed: () => context.go(NearbyPage.route), child: Text(l10n.tripEnd)),
    );
  }
}
