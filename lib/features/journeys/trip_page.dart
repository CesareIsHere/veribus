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
import 'package:veribus/models/journeys/ride_detector.dart';
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
  const TripPage({
    required this.args,
    this.clock = DateTime.now,
    this.replanEvery = const Duration(seconds: 30),
    super.key,
  });

  static const route = '/journeys/trip';

  /// Null when the page is opened without its journey (restored after the app was killed): back to the list.
  final JourneyArgs? args;

  /// The time now: a test sets its own.
  final DateTime Function() clock;

  /// How often the journey is planned again from where the traveller is, to follow the buses that come and go.
  final Duration replanEvery;

  @override
  ConsumerState<TripPage> createState() => _TripPageState();
}

class _TripPageState extends ConsumerState<TripPage> {
  static const _noticeId = 7001; // feature:push

  /// The ongoing notification is shown again at least this often: the location service may put its own back.
  static const _noticeRefresh = Duration(seconds: 20);

  var _state = const TripState();
  late TripView _view;
  final _alerted = <int>{};

  /// The journey being followed: the one chosen, until the bus it was for is gone or the traveller cannot make it.
  JourneyArgs? _args;

  /// The tracker that holds the foreground service while the journey goes on (kept to release it in [dispose]).
  late final LocationTracker _tracker = ref.read(locationTrackerProvider);
  late final IPushService _push = ref.read(pushServiceProvider); // feature:push
  StreamSubscription<void>? _ended; // feature:push
  Timer? _replanTimer;
  Timer? _noticeTimer;
  var _planning = false;

  /// Where the phone has been in the last minutes: it tells a traveller on a bus from one walking to its stop.
  final _fixes = <Fix>[];
  var _checkedAt = DateTime(0);

  /// Trips the traveller was thought to be on, and planning from them found nothing: not tried again.
  final _skipped = <int>{};
  var _started = false;
  var _following = false;

  /// What the ongoing notification showed last, and when.
  String? _shownKey; // feature:push
  DateTime? _shownAt; // feature:push

  List<RideLeg> get _rides => _args!.journey.rides;

  @override
  void initState() {
    super.initState();
    _args = widget.args;
    if (_args != null) {
      final position = ref.read(positionProvider).value;
      _record(position);
      _advance(position);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_args == null || _started) return;
    _started = true;
    _replanTimer = Timer.periodic(widget.replanEvery, (_) => unawaited(_replan()));
    // feature:push:start
    unawaited(_askNotifications());
    _ended = _push.tripEnded.listen((_) {
      if (mounted) context.go(NearbyPage.route);
    });
    // feature:push:end
    _syncNotification();
  }

  @override
  void dispose() {
    _replanTimer?.cancel();
    _noticeTimer?.cancel();
    if (_args != null) {
      unawaited(_tracker.follow(null));
      // feature:push:start
      unawaited(_ended?.cancel());
      unawaited(_push.cancelTrip());
      // feature:push:end
    }
    super.dispose();
  }

  // feature:push:start
  /// The notification of the journey needs the permission of the notices (Android 13+): asked once, when it starts.
  Future<void> _askNotifications() async {
    try {
      await _push.requestNotifications();
    } on Object {
      // This build has no notices (no Firebase configuration): the journey goes on without the permission.
    }
  }
  // feature:push:end

  void _advance(LatLng? position) {
    final args = _args!;
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
        _push.showNow(
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

  void _record(LatLng? position) {
    if (position == null) return;
    final now = widget.clock();
    _fixes
      ..add((point: position, at: now))
      ..removeWhere((f) => now.difference(f.at) > const Duration(seconds: 90));
  }

  /// Someone who starts the navigation on a bus, or boards it where the stop was not noticed, is on a trip the plan
  /// does not know: the phone moves faster than anyone walks, along a trip that the timetable puts right there. The
  /// journey goes on with that trip from its next stop.
  void _checkBoard() {
    final now = widget.clock();
    if (_planning || !mounted || _view.phase == TripPhase.onBoard || _view.phase == TripPhase.arrived) return;
    if (now.difference(_checkedAt) < const Duration(seconds: 5)) return;
    _checkedAt = now;
    final tt = _args!.planner.timetable;
    final sure = sureTrip(tt, detectTrips(timetable: tt, fixes: _fixes, now: now));
    if (sure != null && !_skipped.contains(sure.trip)) unawaited(_boardOn(sure));
  }

  /// The buses near the traveller, for them to say which one they are on (the phone did not see them move, or the
  /// street has several lines).
  Future<void> _pickBus() async {
    final planner = _args!.planner;
    final tt = planner.timetable;
    final l10n = context.l10n;
    final trips = detectTrips(
      timetable: tt,
      fixes: _fixes,
      now: widget.clock(),
      moving: false,
      maxMeters: 300,
      limit: 5,
    );
    if (trips.isEmpty) {
      context.showSnackBar(l10n.tripNoBusNear);
      return;
    }
    final chosen = await showModalBottomSheet<BoardedTrip>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(context.pageMargin, 0, context.pageMargin, Spacing.s),
              child: Text(l10n.tripPickBus, style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            ),
            for (final t in trips)
              ListTile(
                leading: LineChip(tt.lineNames[tt.routeLine[t.route]], kind: routeKind(planner, t.route)),
                title: Text('→ ${tt.routeHeadsign[t.route]}'),
                subtitle: Text(l10n.meters(t.meters.round())),
                onTap: () => Navigator.of(context).pop(t),
              ),
          ],
        ),
      ),
    );
    if (chosen != null && mounted) {
      _skipped.remove(chosen.trip);
      await _boardOn(chosen);
    }
  }

  Future<void> _boardOn(BoardedTrip boarded) async {
    final args = _args!;
    _planning = true;
    try {
      final position = ref.read(positionProvider).value;
      final journey = await args.planner.planOnBoard(
        boarded: boarded,
        to: args.to.point,
        at: widget.clock(),
        filter: args.filter,
      );
      final ride = journey?.rides.firstOrNull;
      if (!mounted) return;
      if (journey == null || ride == null) {
        _skipped.add(boarded.trip);
        return;
      }
      final tt = args.planner.timetable;
      setState(() {
        _args = args.withJourney(journey);
        _state = TripState(nearBoard: true, boarded: true, stopIndex: ride.board - 1);
        _alerted.clear();
        _advance(position);
      });
      context.showSnackBar(context.l10n.tripOnBoardDetected(tt.lineNames[tt.routeLine[ride.route]]));
    } on Object {
      _skipped.add(boarded.trip);
    } finally {
      _planning = false;
    }
  }

  /// Plans the journey again from where the traveller is, now: the buses that were late or early, the realtime that
  /// moved. The bus waited for is kept when it can still be made, with its new time; when it cannot (it left, or the
  /// walk is too long for it) the journey becomes the best one from here and the traveller is told.
  Future<void> _replan() async {
    final args = _args!;
    final target = _view.ride;
    if (_planning || target == null || _view.phase == TripPhase.onBoard || _view.phase == TripPhase.arrived) return;
    _planning = true;
    try {
      final position = ref.read(positionProvider).value;
      final plans = await args.planner.plan(
        from: position ?? args.from.point,
        to: args.to.point,
        at: widget.clock(),
        filter: args.filter,
      );
      // The traveller may have boarded, or arrived, while the planner was asking for the realtime.
      if (!mounted || plans.isEmpty || _view.phase == TripPhase.onBoard || _view.phase == TripPhase.arrived) return;
      final same = plans.where((j) => j.rides.firstOrNull?.trip == target.trip).firstOrNull;
      final next = same ?? plans.first;
      final tt = args.planner.timetable;
      setState(() {
        _args = args.withJourney(next);
        _state = TripState(nearBoard: same != null && _state.nearBoard);
        _alerted.clear();
        _advance(position);
      });
      final ride = next.rides.firstOrNull;
      if (same == null && ride != null) {
        final l10n = context.l10n;
        context.showSnackBar(
          l10n.tripMissed(
            tt.lineNames[tt.routeLine[target.route]],
            tt.lineNames[tt.routeLine[ride.route]],
            journeyClock(args.planner, ride.start),
          ),
        );
      }
    } on Object {
      // The realtime or the planner failed for now: the journey stays as it was, and is tried again.
    } finally {
      _planning = false;
    }
  }

  /// The journey ends here: when it is walking to the destination the estimate follows the traveller, otherwise it is
  /// the one of the plan, which the planning again keeps up to date.
  int _arrive(TripView view) {
    final args = _args!;
    final meters = view.meters;
    if (view.phase == TripPhase.toDestination && meters != null) {
      return args.planner.secondsOf(widget.clock()) + (meters / _walkSpeed).ceil();
    }
    return args.journey.journey.arrive;
  }

  /// The location service runs as a plain "following you": the notification with the steps is the one below.
  void _syncNotification() {
    final view = _view;
    if (view.phase == TripPhase.arrived) {
      _following = false;
      unawaited(_tracker.follow(null));
      unawaited(_push.cancelTrip()); // feature:push
      return;
    }
    if (!_following) {
      _following = true;
      final l10n = context.l10n;
      unawaited(
        _tracker.follow((
          title: l10n.tripOngoingTitle,
          text: l10n.tripOngoingText(_args!.to.name),
          channelName: l10n.tripChannelName,
        )),
      );
      // The service puts its own notification a moment after it starts: ours goes again over it.
      _noticeTimer?.cancel();
      _noticeTimer = Timer(const Duration(seconds: 2), () => _showTrip(force: true)); // feature:push
    }
    _showTrip(); // feature:push
  }

  // feature:push:start
  /// The ongoing notification, as it is now: updated when what it says changes (the distance walked, the bus and its
  /// state, the next step), and now and then anyway.
  void _showTrip({bool force = false}) {
    if (!mounted || _view.phase == TripPhase.arrived) return;
    final view = _view;
    final args = _args!;
    final noRealtime = ref.read(networkInfoProvider).value?.noRealtime ?? const <String>{};
    final planner = args.planner;
    final ride = view.ride;
    final color = ride == null
        ? context.colors.primary
        : LineChip.colorOf(
            context,
            rideKind(planner, ride),
            planner.timetable.lineNames[planner.timetable.routeLine[ride.route]],
          );
    final now = widget.clock();
    final notification = tripNotification(
      context.l10n,
      args,
      view,
      now: now,
      arrive: _arrive(view),
      color: color,
      noRealtime: noRealtime,
    );
    final key = '${notification.title}|${notification.text}|${notification.details.join()}|${notification.progress}';
    final last = _shownAt;
    if (!force && key == _shownKey && last != null && now.difference(last) < _noticeRefresh) return;
    _shownKey = key;
    _shownAt = now;
    unawaited(_push.showTrip(notification));
  }
  // feature:push:end

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final args = _args;
    if (args == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.journeysDetails)),
        body: MessageView(icon: Icons.route, title: l10n.journeysGone),
      );
    }
    // Every new fix moves the journey on, from the foreground service or from the live position of the map.
    ref.listen(positionProvider, (_, next) {
      _record(next.value);
      setState(() => _advance(next.value));
      _checkBoard();
    });
    final position = ref.watch(positionProvider).value;
    final view = _view;
    final arrive = _arrive(view);
    final noRealtime = ref.watch(networkInfoProvider).value?.noRealtime ?? const {};
    return Scaffold(
      body: switch (view.phase) {
        TripPhase.onBoard => _OnBoard(args: args, view: view, arrive: arrive, noRealtime: noRealtime),
        TripPhase.arrived => _Arrived(args: args),
        _ => _OnFoot(
          args: args,
          view: view,
          arrive: arrive,
          position: position,
          noRealtime: noRealtime,
          onBoard: _pickBus,
        ),
      },
    );
  }
}

/// Metres a minute on foot, the pace the planner uses.
const double _walkSpeed = 1.2 * 60;

// feature:push:start
/// The ongoing notification for [view]: what to do now, the bus and how it is doing (the status and its reason, in the
/// words of the stop page), the way left, and the clock of the bus or of the stop counting down in the header. The
/// words are the app's; the layout is the push service's.
TripNotification tripNotification(
  AppLocalizations l10n,
  JourneyArgs args,
  TripView view, {
  required DateTime now,
  required int arrive,
  required Color color,
  Set<String> noRealtime = const {},
}) {
  final planner = args.planner;
  final tt = planner.timetable;
  final ride = view.ride;
  final arriveClock = journeyClock(planner, arrive);
  final end = args.to.isHome ? l10n.journeysArriveHome(arriveClock) : l10n.journeysArriveDestination(arriveClock);
  final journey = args.journey.journey;
  final elapsed = planner.secondsOf(now) - journey.depart;
  final progress = (100 * elapsed / math.max(1, arrive - journey.depart)).round().clamp(0, 100);
  final meters = view.meters;
  final distance = meters == null ? null : l10n.tripDistance(_round(meters), _walkMinutes(meters));
  String bold(String text) => '<b>${_escape(text)}</b>';

  TripNotification make(String title, String text, List<String> details, {DateTime? countdownTo}) => TripNotification(
    title: title,
    text: text,
    details: details,
    subText: end,
    channelName: l10n.tripChannelName,
    endLabel: l10n.tripEnd,
    progress: progress,
    countdownTo: countdownTo,
    color: color,
  );

  if (ride == null) {
    return make(l10n.tripWalkTo(args.to.name), distance ?? end, [
      ?distance == null ? null : _escape(distance),
      _escape(end),
    ], countdownTo: planner.timeOf(arrive));
  }
  final line = tt.lineNames[tt.routeLine[ride.route]];
  if (view.phase == TripPhase.onBoard) {
    final off = l10n.tripGetOffAt(tt.stopNames[ride.toStop], journeyClock(planner, ride.end));
    return make((view.stopsLeft ?? 2) <= 1 ? l10n.tripGetOffNext : l10n.tripGetOffIn(view.stopsLeft!), off, [
      bold(l10n.tripGetOffAt(tt.stopNames[ride.toStop], journeyClock(planner, ride.end))),
      _escape('$line → ${tt.routeHeadsign[ride.route]}'),
      _escape(end),
    ], countdownTo: planner.timeOf(ride.end));
  }
  // Waiting for the bus, or walking to its stop: its time and its state, with the reason of the state.
  final arrival = args.journey.realtimeOf(ride);
  final status = arrival?.status ?? ArrivalStatus.scheduled;
  final statusText = ArrivalText.status(l10n, status);
  final reason = arrival == null
      ? ArrivalText.noRealtime(l10n, lineWithoutRealtime: noRealtime.contains(tt.lineIds[tt.routeLine[ride.route]]))
      : ArrivalText.reason(
          l10n,
          arrival,
          lineWithoutRealtime: noRealtime.contains(tt.lineIds[tt.routeLine[ride.route]]),
        );
  final when = arrival?.minutes != null
      ? l10n.journeysInMinutes(arrival!.minutes!)
      : l10n.tripAtTime(journeyClock(planner, ride.start));
  final bus = l10n.tripYourLine(line, when);
  final atStop = view.phase == TripPhase.atStop;
  // The bus counts down to its predicted time when there is one, to its scheduled time otherwise.
  final live = arrival != null && (status == ArrivalStatus.confirmed || status == ArrivalStatus.uncertain);
  return make(atStop ? l10n.tripBoard(line) : l10n.tripWalkTo(tt.stopNames[ride.fromStop]), '$bus · $statusText', [
    _escape(bus),
    if (reason.isEmpty) bold(statusText) else '${bold(statusText)} · ${_escape(reason)}',
    if (!atStop && distance != null) _escape(distance),
    _escape(end),
  ], countdownTo: live && arrival.time != null ? arrival.time : planner.timeOf(ride.start));
}

String _escape(String text) => text.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
// feature:push:end

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
    final lineWithoutRealtime = noRealtime.contains(tt.lineIds[tt.routeLine[ride.route]]);
    final reason = arrival == null
        ? ArrivalText.noRealtime(l10n, lineWithoutRealtime: lineWithoutRealtime)
        : ArrivalText.reason(l10n, arrival, lineWithoutRealtime: lineWithoutRealtime);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spacing.xs,
      children: [
        Row(
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
        ),
        // What the state means, in the words of the stop page: the bus and how far it is, why it is doubtful.
        if (reason.isNotEmpty) Text(reason, style: context.textTheme.bodyMedium?.copyWith(color: scheme.onPrimary)),
      ],
    );
  }
}

/// Walking to a stop (or home) and waiting at the stop: the map, the instruction on top and the journey in short at the
/// bottom. The way is drawn along the streets, from where the walk began, and asked again if the traveller leaves it.
class _OnFoot extends ConsumerStatefulWidget {
  const _OnFoot({
    required this.args,
    required this.view,
    required this.arrive,
    required this.position,
    required this.noRealtime,
    required this.onBoard,
  });

  /// Opens the choice of the bus the traveller is on, when they are already on one.
  final VoidCallback onBoard;

  final JourneyArgs args;
  final TripView view;

  /// When the journey ends, in seconds from the midnight of the timetable.
  final int arrive;
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
                // For the traveller who is already on a bus, and the phone did not notice.
                if (ride != null && !toDestination)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ActionChip(
                      avatar: const Icon(Icons.directions_bus),
                      label: Text(l10n.tripAlreadyOnBoard),
                      onPressed: widget.onBoard,
                    ),
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
          child: _Summary(args: args, arrive: widget.arrive),
        ),
      ],
    );
  }
}

/// The journey in short under the instruction: how far along it is, when it ends, and the way out.
class _Summary extends StatelessWidget {
  const _Summary({required this.args, required this.arrive});

  final JourneyArgs args;
  final int arrive;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colors;
    final planner = args.planner;
    final journey = args.journey.journey;
    final elapsed = DateTime.now().difference(planner.timeOf(journey.depart)).inSeconds;
    final progress = (elapsed / math.max(1, arrive - journey.depart)).clamp(0.0, 1.0);
    final arriveClock = journeyClock(planner, arrive);
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
                      args.to.isHome
                          ? l10n.journeysArriveHome(arriveClock)
                          : l10n.journeysArriveDestination(arriveClock),
                      style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    journeyDuration(l10n, arrive - journey.depart),
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
class _OnBoard extends ConsumerStatefulWidget {
  const _OnBoard({required this.args, required this.view, required this.arrive, required this.noRealtime});

  final JourneyArgs args;
  final TripView view;
  final int arrive;
  final Set<String> noRealtime;

  @override
  ConsumerState<_OnBoard> createState() => _OnBoardState();
}

class _OnBoardState extends ConsumerState<_OnBoard> {
  /// The stops ahead on a map instead of the list, when the traveller asks for it.
  var _map = false;

  JourneyArgs get args => widget.args;
  TripView get view => widget.view;
  int get arrive => widget.arrive;
  Set<String> get noRealtime => widget.noRealtime;

  @override
  Widget build(BuildContext context) {
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
            child: _map
                ? _RideMap(args: args, ride: ride, color: color, index: index)
                : ListView(
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
                            ? l10n.journeysArriveHome(journeyClock(planner, arrive))
                            : l10n.journeysArriveDestination(journeyClock(planner, arrive)),
                        style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  IconButton.filledTonal(
                    onPressed: () => setState(() => _map = !_map),
                    tooltip: _map ? l10n.tripShowList : l10n.tripShowMap,
                    icon: Icon(_map ? Icons.format_list_bulleted : Icons.map_outlined),
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

/// The ride on a map: the way ahead along the line, the stops left and the one to get off at, with the traveller.
class _RideMap extends ConsumerWidget {
  const _RideMap({required this.args, required this.ride, required this.color, required this.index});

  final JourneyArgs args;
  final RideLeg ride;
  final Color color;

  /// The stop of the ride the vehicle is at.
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colors;
    final planner = args.planner;
    final tt = planner.timetable;
    LatLng stop(int i) {
      final s = tt.routeStop(ride.route, i);
      return LatLng(tt.stopLat[s] / 1e6, tt.stopLon[s] / 1e6);
    }

    final position = ref.watch(positionProvider).value;
    final route = rideRoute(ref, planner, ride);
    final ahead = position == null || route.length < 2 ? route : splitRoute(route, position).ahead;
    final off = stop(ride.alight);
    return TransitMap(
      fit: [?position, off],
      fitPadding: const EdgeInsets.all(Spacing.xxxl),
      locateButton: false,
      children: [
        PolylineLayer(
          polylines: [if (ahead.length > 1) Polyline(points: ahead, strokeWidth: 6, color: color)],
        ),
        MarkerLayer(
          markers: [
            for (var i = math.max(index, ride.board) + 1; i < ride.alight; i++)
              Marker(
                point: stop(i),
                width: Spacing.m,
                height: Spacing.m,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                ),
              ),
            Marker(
              point: off,
              width: Spacing.xxxl,
              height: Spacing.xxxl,
              child: Icon(Icons.location_on, size: Spacing.xxl, color: color),
            ),
          ],
        ),
      ],
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
