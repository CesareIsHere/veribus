import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/l10n/gen/app_localizations.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/styles/app_spacing.dart';

/// How an arrival is said: the only place that turns status, signal and time into words and style (wireframe
/// "Stati"). The status is never told by color alone (RNF-07): there is always a label.
abstract final class ArrivalText {
  /// "4 min", "verso le 21:15", "a 3 fermate", or the clock time for scheduled/canceled/suppressed trips.
  static String time(AppLocalizations l10n, Arrival a) {
    final clock = a.time == null ? '' : DateFormat.Hm().format(a.time!.toLocal());
    if (a.status case ArrivalStatus.scheduled || ArrivalStatus.canceled || ArrivalStatus.suppressed) return clock;
    if (a.overdue && a.vehicle == null) return clock; // its time has passed: "0 min" would promise too much
    if (a.time == null) return a.stopsAway == null ? l10n.arriving : l10n.stopsAway(a.stopsAway!); // RF-26
    if (a.approximate) return l10n.around(clock); // RF-29b
    return inMinutes(l10n, a.minutes!);
  }

  /// "4 min", or "arriving" at zero.
  static String inMinutes(AppLocalizations l10n, int minutes) => minutes == 0 ? l10n.arriving : l10n.minutes(minutes);

  /// The one-line reason under the time (RF-22).
  static String reason(AppLocalizations l10n, Arrival a, {required bool lineWithoutRealtime}) => switch (a.status) {
    // Past its time with no bus seen passing: buses without data often pass anyway (`missed_grace_min`).
    _ when a.overdue && a.vehicle == null && a.time != null => l10n.overdue(DateFormat.Hm().format(a.time!.toLocal())),
    ArrivalStatus.scheduled => noRealtime(l10n, lineWithoutRealtime: lineWithoutRealtime),
    ArrivalStatus.confirmed when a.approximate => l10n.approximateTime(a.minutes!),
    ArrivalStatus.confirmed => [
      if (a.vehicle?.label case final label?) l10n.vehicle(label),
      if (a.stopsAway case final n? when a.time != null) l10n.stopsAway(n),
    ].join(' · '),
    _ => a.signal == null ? '' : signal(l10n, a.signal!, stopsAway: a.stopsAway),
  };

  /// Why a trip shows its scheduled time: its line never transmits, or there are no realtime data for it (yet: the
  /// journeys of the planner beyond the next hour).
  static String noRealtime(AppLocalizations l10n, {required bool lineWithoutRealtime}) =>
      lineWithoutRealtime ? l10n.lineWithoutRealtime : l10n.noRealtimeData;

  static String signal(AppLocalizations l10n, Signal s, {int? stopsAway}) => switch (s.code) {
    'S1' => l10n.signalCanceled,
    'S2' when s.minutes != null => l10n.signalNotTransmitting(s.minutes!),
    'S2' => l10n.signalNoVehicle,
    'S3' when stopsAway != null => '${l10n.signalStill(s.minutes ?? 0)} · ${l10n.stopsAway(stopsAway)}',
    'S3' => l10n.signalStill(s.minutes ?? 0),
    'S4' => l10n.signalOldGps(s.minutes ?? 0),
    'S5' when s.departure != null => l10n.signalAtTerminus(DateFormat.Hm().format(s.departure!.toLocal())),
    'S5' => l10n.signalAtTerminusNoTime,
    'S6' => l10n.signalLateData,
    _ => '',
  };

  static String status(AppLocalizations l10n, ArrivalStatus s) => switch (s) {
    ArrivalStatus.confirmed => l10n.statusConfirmed,
    ArrivalStatus.uncertain => l10n.statusUncertain,
    ArrivalStatus.scheduled => l10n.statusScheduled,
    ArrivalStatus.canceled => l10n.statusCanceled,
    ArrivalStatus.suppressed => l10n.statusSuppressed,
  };
}

/// First arrival of each line and direction; canceled trips skipped, suppressed ones kept (RF-29).
List<Arrival> firstPerLine(List<Arrival> arrivals) {
  final seen = <String>{};
  return [
    for (final a in arrivals)
      if (a.status != ArrivalStatus.canceled && seen.add('${a.lineId}/${a.directionId}')) a,
  ];
}

/// Line number in a rounded box; muted when the line never transmits positions (RF-35).
class LineBadge extends StatelessWidget {
  const LineBadge(this.name, {this.withoutRealtime = false, this.muted = false, super.key});

  final String name;
  final bool withoutRealtime;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = muted || withoutRealtime ? context.colors.onSurfaceVariant : context.colors.onSurface;
    return Container(
      constraints: const BoxConstraints(minWidth: Spacing.xxxl + Spacing.s, minHeight: Spacing.xxl),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s),
      decoration: BoxDecoration(
        border: Border.all(color: withoutRealtime ? context.colors.outlineVariant : color, width: 1.5),
        borderRadius: BorderRadius.circular(Spacing.s),
      ),
      // widthFactor 1: as wide as the name (at least the min width), not the whole row.
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Text(
          name,
          style: context.textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class StatusTag extends StatelessWidget {
  const StatusTag(this.status, {super.key});

  final ArrivalStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = switch (status) {
      ArrivalStatus.confirmed => (c.primary, c.onPrimary),
      ArrivalStatus.uncertain => (c.tertiaryContainer, c.onTertiaryContainer),
      ArrivalStatus.scheduled => (c.surfaceContainerHighest, c.onSurfaceVariant),
      ArrivalStatus.canceled || ArrivalStatus.suppressed => (c.errorContainer, c.onErrorContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(Spacing.m)),
      child: Text(ArrivalText.status(context.l10n, status), style: context.textTheme.labelSmall?.copyWith(color: fg)),
    );
  }
}

/// Time text styled by status: bold minutes when confirmed, dotted when uncertain, struck through when gone.
class ArrivalTime extends StatelessWidget {
  const ArrivalTime(this.arrival, {this.large = true, super.key});

  final Arrival arrival;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Minutes are the headline; clock times and "N stops away" are one step smaller (wireframe "Fermata").
    final minutes = arrival.minutes != null && !arrival.approximate;
    final base = !large
        ? context.textTheme.titleSmall
        : minutes
        ? context.textTheme.titleLarge
        : context.textTheme.titleMedium;
    final style = switch (arrival.status) {
      ArrivalStatus.confirmed => base?.copyWith(fontWeight: FontWeight.w700),
      ArrivalStatus.uncertain => base?.copyWith(
        color: c.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        decoration: TextDecoration.underline,
        decorationStyle: TextDecorationStyle.dotted,
      ),
      ArrivalStatus.scheduled => base?.copyWith(color: c.onSurfaceVariant),
      ArrivalStatus.canceled ||
      ArrivalStatus.suppressed => base?.copyWith(color: c.outline, decoration: TextDecoration.lineThrough),
    };
    return Text(ArrivalText.time(context.l10n, arrival), style: style);
  }
}

/// One arrival in the stop panel (RF-21, RF-22).
class ArrivalTile extends StatelessWidget {
  const ArrivalTile({
    required this.arrival,
    required this.lineName,
    required this.lineWithoutRealtime,
    this.onTap,
    super.key,
  });

  final Arrival arrival;
  final String lineName;
  final bool lineWithoutRealtime;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final gone = arrival.status == ArrivalStatus.canceled || arrival.status == ArrivalStatus.suppressed;
    final reason = ArrivalText.reason(context.l10n, arrival, lineWithoutRealtime: lineWithoutRealtime);
    final headsign = context.textTheme.bodyLarge?.copyWith(
      color: gone ? context.colors.outline : null,
      decoration: gone ? TextDecoration.lineThrough : null,
    );
    // Wireframe "Fermata": destination and time on the first row, status and reason below at full width,
    // so long destinations are not squeezed by the time.
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.l, vertical: Spacing.m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Spacing.l,
          children: [
            LineBadge(lineName, withoutRealtime: lineWithoutRealtime, muted: gone),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Spacing.xs,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    spacing: Spacing.s,
                    children: [
                      Expanded(child: Text('→ ${arrival.headsign}', maxLines: 2, style: headsign)),
                      ArrivalTime(arrival),
                    ],
                  ),
                  Wrap(
                    spacing: Spacing.s,
                    runSpacing: Spacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      StatusTag(arrival.status),
                      if (reason.isNotEmpty)
                        Text(
                          reason,
                          style: context.textTheme.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
