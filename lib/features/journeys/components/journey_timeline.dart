import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veribus/core/config.dart'; // feature:push
import 'package:veribus/core/widgets/line_chip.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/journeys/components/journey_widgets.dart';
import 'package:veribus/features/journeys/providers/journeys_providers.dart';
import 'package:veribus/features/stop/stop_page.dart';
import 'package:veribus/models/journeys/journey_planner.dart';
import 'package:veribus/models/journeys/place.dart';
import 'package:veribus/models/journeys/raptor.dart';
import 'package:veribus/models/transit/transit_kind.dart';
import 'package:veribus/styles/app_spacing.dart';

/// A journey leg by leg on a vertical rail, as every transit app tells it: the time on the left, the rail in the color
/// of the line (dotted on foot) in the middle, what to do on the right. At a change, a card says how long the wait is,
/// how often the change worked in the last weeks and what to take if it is missed.
class JourneyTimeline extends StatelessWidget {
  const JourneyTimeline({
    required this.planner,
    required this.journey,
    required this.from,
    required this.to,
    required this.noRealtime,
    super.key,
  });

  final JourneyPlanner planner;
  final PlannedJourney journey;
  final Place from;
  final Place to;
  final Set<String> noRealtime;

  /// A wait longer than this at a change is said aloud: at night it means standing at a stop for a while.
  static const int longWait = 20 * 60;

  @override
  Widget build(BuildContext context) {
    final tt = planner.timetable;
    final scheme = context.colors;
    final walkSeg = _Seg(scheme.outline, solid: false);
    final legs = [
      for (final l in journey.journey.legs)
        if (!(l is WalkLeg && l.end <= l.start)) l,
    ];
    _Seg rideSeg(RideLeg r) =>
        _Seg(LineChip.colorOf(context, rideKind(planner, r), tt.lineNames[tt.routeLine[r.route]]));
    VoidCallback? openStop(int s, RideLeg r) =>
        rideKind(planner, r) == TransitKind.metro ? null : () => context.push(StopPage.route(tt.stopIds[s]));

    final nodes = <_Node>[];
    RideLeg? previous;
    for (final (i, leg) in legs.indexed) {
      switch (leg) {
        case WalkLeg(from: null, to: null):
          nodes
            ..add(_Boundary(time: journeyClock(planner, leg.start), title: from.name, kind: _BoundaryKind.origin))
            ..add(_Body(walkSeg, _WalkBody(minutes: journeyMinutes(leg.end - leg.start))))
            ..add(_Boundary(time: journeyClock(planner, leg.end), title: to.name, kind: _BoundaryKind.destination));
        case WalkLeg(from: null):
          nodes
            ..add(_Boundary(time: journeyClock(planner, leg.start), title: from.name, kind: _BoundaryKind.origin))
            ..add(_Body(walkSeg, _WalkBody(minutes: journeyMinutes(leg.end - leg.start))));
        case WalkLeg(to: null):
          nodes
            ..add(_Body(walkSeg, _WalkBody(minutes: journeyMinutes(leg.end - leg.start))))
            ..add(_Boundary(time: journeyClock(planner, leg.end), title: to.name, kind: _BoundaryKind.destination));
        case WalkLeg():
          break; // between two rides: told by the change card
        case RideLeg():
          if (previous != null) {
            final before = i > 0 ? legs[i - 1] : null;
            final walk = before is WalkLeg && before.from != null ? before.end - before.start : 0;
            nodes.add(
              _Body(
                walkSeg,
                _ChangeCard(
                  planner: planner,
                  previous: previous,
                  next: leg,
                  walk: walk,
                  stop: tt.stopNames[leg.fromStop],
                ),
              ),
            );
          }
          nodes
            ..add(
              _Boundary(
                time: journeyClock(planner, leg.start),
                title: tt.stopNames[leg.fromStop],
                onTap: openStop(leg.fromStop, leg),
              ),
            )
            ..add(_Body(rideSeg(leg), _RideBody(planner: planner, journey: journey, ride: leg, noRealtime: noRealtime)))
            ..add(
              _Boundary(
                time: journeyClock(planner, leg.end),
                title: tt.stopNames[leg.toStop],
                note: context.l10n.journeysGetOff,
                onTap: openStop(leg.toStop, leg),
              ),
            );
          previous = leg;
      }
    }

    // The journey ends at the destination even when the last stop is right there: no walk, no gap on the rail.
    if (nodes.isNotEmpty && !(nodes.last is _Boundary && (nodes.last as _Boundary).kind == _BoundaryKind.destination)) {
      nodes
        ..add(_Body(walkSeg, const SizedBox(height: Spacing.m)))
        ..add(
          _Boundary(
            time: journeyClock(planner, journey.journey.arrive),
            title: to.name,
            kind: _BoundaryKind.destination,
          ),
        );
    }

    return Column(
      children: [
        for (final (k, node) in nodes.indexed)
          switch (node) {
            _Boundary() => _TimelineRow(
              time: node.time,
              above: k > 0 && nodes[k - 1] is _Body ? (nodes[k - 1] as _Body).seg : null,
              below: k + 1 < nodes.length && nodes[k + 1] is _Body ? (nodes[k + 1] as _Body).seg : null,
              kind: node.kind,
              onTap: node.onTap,
              minHeight: Spacing.xxxl - Spacing.s,
              child: Padding(
                padding: const EdgeInsets.only(top: Spacing.xs),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: node.title,
                        style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (node.note != null)
                        TextSpan(
                          text: ' · ${node.note}',
                          style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            _Body() => _TimelineRow(through: node.seg, child: node.child),
          },
      ],
    );
  }
}

// The timeline is made of boundaries (a stop, the start, the end) and bodies (what happens between two of them).
sealed class _Node {
  const _Node();
}

enum _BoundaryKind { stop, origin, destination }

class _Boundary extends _Node {
  const _Boundary({required this.time, required this.title, this.kind = _BoundaryKind.stop, this.note, this.onTap});

  final String time;
  final String title;
  final _BoundaryKind kind;
  final String? note;
  final VoidCallback? onTap;
}

class _Body extends _Node {
  const _Body(this.seg, this.child);

  final _Seg seg;
  final Widget child;
}

/// A piece of the rail: solid and thick in the color of the line, dotted on foot.
class _Seg {
  const _Seg(this.color, {this.solid = true});

  final Color color;
  final bool solid;
}

const double _timeWidth = Spacing.xxxl + Spacing.xs;
const double _railWidth = Spacing.xxl;

/// The dot sits on the first line of its row.
const double _dotY = Spacing.l + Spacing.xs;

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.child,
    this.time,
    this.above,
    this.below,
    this.through,
    this.kind = _BoundaryKind.stop,
    this.onTap,
    this.minHeight = 0,
  });

  final Widget child;
  final String? time;
  final _Seg? above;
  final _Seg? below;
  final _Seg? through;
  final _BoundaryKind kind;
  final VoidCallback? onTap;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final accent = switch (kind) {
      _BoundaryKind.origin => scheme.primary,
      _BoundaryKind.destination => scheme.error,
      _BoundaryKind.stop => (below ?? above)?.color ?? scheme.primary,
    };
    final row = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: _timeWidth,
              child: time == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(top: Spacing.xs + Spacing.xs, right: Spacing.s),
                      child: Text(
                        time!,
                        textAlign: TextAlign.right,
                        style: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
            ),
            SizedBox(
              width: _railWidth,
              child: CustomPaint(
                painter: _RailPainter(
                  above: above,
                  below: below,
                  through: through,
                  dotColor: time == null ? null : accent,
                  hollow: kind == _BoundaryKind.stop || kind == _BoundaryKind.origin,
                  background: scheme.surface,
                  big: kind == _BoundaryKind.destination,
                ),
                child: kind == _BoundaryKind.destination
                    ? Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: _dotY - Spacing.m),
                          child: Icon(Icons.flag, size: Spacing.l, color: scheme.onError),
                        ),
                      )
                    : null,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: Spacing.s),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}

class _RailPainter extends CustomPainter {
  const _RailPainter({
    required this.dotColor,
    required this.hollow,
    required this.background,
    required this.big,
    this.above,
    this.below,
    this.through,
  });

  final _Seg? above;
  final _Seg? below;
  final _Seg? through;
  final Color? dotColor;
  final bool hollow;
  final Color background;
  final bool big;

  static const _thick = 6.0;
  static const _dot = 2.5;

  void _line(Canvas canvas, _Seg seg, double x, double from, double to) {
    if (seg.solid) {
      canvas.drawLine(
        Offset(x, from),
        Offset(x, to),
        Paint()
          ..color = seg.color
          ..strokeWidth = _thick,
      );
      return;
    }
    final paint = Paint()..color = seg.color;
    for (var y = from + _dot; y < to; y += _dot * 3) {
      canvas.drawCircle(Offset(x, y), _dot / 1.5, paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    if (through != null) _line(canvas, through!, x, 0, size.height);
    if (above != null) _line(canvas, above!, x, 0, _dotY);
    if (below != null) _line(canvas, below!, x, _dotY, size.height);
    final color = dotColor;
    if (color == null) return;
    final radius = big ? Spacing.m + Spacing.xs / 2 : Spacing.s;
    canvas.drawCircle(Offset(x, _dotY), radius, Paint()..color = hollow ? color : color);
    if (hollow) canvas.drawCircle(Offset(x, _dotY), radius - 4, Paint()..color = background);
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.above?.color != above?.color ||
      old.below?.color != below?.color ||
      old.through?.color != through?.color ||
      old.dotColor != dotColor ||
      old.background != background;
}

class _WalkBody extends StatelessWidget {
  const _WalkBody({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.s),
      child: Row(
        spacing: Spacing.s,
        children: [
          Icon(Icons.directions_walk, size: Spacing.xl - Spacing.xs, color: context.colors.onSurfaceVariant),
          Text(
            context.l10n.journeysWalkMinutes(minutes),
            style: context.textTheme.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// A ride: its chip and destination, what the realtime says about it, and the stops it passes (folded).
class _RideBody extends StatefulWidget {
  const _RideBody({required this.planner, required this.journey, required this.ride, required this.noRealtime});

  final JourneyPlanner planner;
  final PlannedJourney journey;
  final RideLeg ride;
  final Set<String> noRealtime;

  @override
  State<_RideBody> createState() => _RideBodyState();
}

class _RideBodyState extends State<_RideBody> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colors;
    final planner = widget.planner;
    final ride = widget.ride;
    final tt = planner.timetable;
    final stops = ride.alight - ride.board;
    final push = _followButton(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Spacing.s,
        children: [
          Row(
            spacing: Spacing.s,
            children: [
              RideChip(planner: planner, ride: ride, noRealtime: widget.noRealtime),
              Expanded(
                child: Text(
                  '→ ${tt.routeHeadsign[ride.route]}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyLarge,
                ),
              ),
            ],
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(Spacing.l),
            ),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.m),
              child: RideStatus(planner: planner, journey: widget.journey, ride: ride, noRealtime: widget.noRealtime),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(Spacing.s),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: Spacing.xs,
                children: [
                  Text(
                    l10n.journeysIntermediate(l10n.journeysStops(stops), journeyMinutes(ride.end - ride.start)),
                    style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    size: Spacing.xl - Spacing.xs,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            for (var i = ride.board + 1; i < ride.alight; i++)
              Padding(
                padding: const EdgeInsets.only(left: Spacing.s, bottom: Spacing.xs),
                child: Text(
                  '${journeyClock(planner, tt.time(ride.trip, i) + ride.delay)}  ${tt.stopNames[tt.routeStop(ride.route, i)]}',
                  style: context.textTheme.bodyMedium,
                ),
              ),
          ?push,
        ],
      ),
    );
  }

  // feature:push:start
  /// Notified before this bus passes, through the followed trips.
  Widget? _followButton(BuildContext context) {
    if (!Features.push) return null;
    final route = followRouteOf(widget.planner, widget.ride);
    if (route == null) return null;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => context.push(route),
        icon: const Icon(Icons.notifications_outlined),
        label: Text(context.l10n.followTrip),
      ),
    );
  }
  // feature:push:end
}

/// A change: how long to walk and wait, how often it worked in the history of both trips, what to take if it is missed.
class _ChangeCard extends ConsumerWidget {
  const _ChangeCard({
    required this.planner,
    required this.previous,
    required this.next,
    required this.walk,
    required this.stop,
  });

  final JourneyPlanner planner;
  final RideLeg previous;
  final RideLeg next;
  final int walk;
  final String stop;

  /// Squares in the strip of the history: one per day, at most.
  static const _cells = 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colors;
    final wait = next.start - previous.end - walk;
    final record = ref.watch(changeReliabilityProvider(changeSlots(planner, previous, next, walk)));
    final line = planner.timetable.lineNames[planner.timetable.routeLine[next.route]];
    final nextTime = planner.nextDeparture(next);
    final muted = context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.s),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(Spacing.l + Spacing.xs),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.m + Spacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Spacing.s,
            children: [
              Row(
                spacing: Spacing.s,
                children: [
                  const Icon(Icons.sync_alt),
                  Expanded(
                    child: Text(
                      l10n.journeysChangeAt(stop),
                      style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              Text(
                [
                  l10n.journeysChangeTimes(journeyMinutes(walk), journeyMinutes(wait)),
                  if (wait > JourneyTimeline.longWait) l10n.journeysLongWait,
                ].join(' · '),
                style: muted,
              ),
              switch (record) {
                AsyncValue(value: (:final made, :final days)?) when days > 0 => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Spacing.xs,
                  children: [
                    _HistoryStrip(made: made, days: days, cells: _cells),
                    Text(
                      l10n.journeysChangeRecord(made, days),
                      style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                // The history is a bonus: an error or no data says the same.
                AsyncValue(hasValue: true) ||
                AsyncValue(hasError: true) => Text(l10n.journeysChangeNoRecord, style: muted),
                _ => const LinearProgressIndicator(),
              },
              // Missing a change is what goes wrong: what to take then.
              Text(
                nextTime == null
                    ? l10n.journeysIfMissedNone(line)
                    : l10n.journeysIfMissed(line, journeyClock(planner, nextTime)),
                style: muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One square per day of the history: green when the change worked, red when it did not.
class _HistoryStrip extends StatelessWidget {
  const _HistoryStrip({required this.made, required this.days, required this.cells});

  final int made;
  final int days;
  final int cells;

  @override
  Widget build(BuildContext context) {
    final count = math.min(days, cells);
    final good = (made * count / days).round();
    return ExcludeSemantics(
      child: Row(
        spacing: Spacing.xs / 2,
        children: [
          for (var i = 0; i < count; i++)
            Expanded(
              child: Container(
                height: Spacing.s,
                decoration: BoxDecoration(
                  color: i < good ? context.appColors.success : context.colors.error,
                  borderRadius: BorderRadius.circular(Spacing.xs / 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
