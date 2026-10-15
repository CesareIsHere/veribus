import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:veribus/core/providers/network_provider.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/line/providers/line_providers.dart';
import 'package:veribus/l10n/gen/app_localizations.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/models/transit/trip_follow.dart';
import 'package:veribus/styles/app_spacing.dart';

/// Beyond these a passage counts as late or early.
const _lateAfter = Duration(minutes: 3);
const _earlyBefore = Duration(minutes: -1);

/// The record of a slot: how many days it was on time, late, early, not tracked, canceled, and its median delay.
typedef TripRecord = ({int onTime, int late, int early, int notTracked, int canceled, Duration? typical});

TripRecord tripRecord(List<TripDay> days) {
  final delays = [for (final d in days) ?d.delay]..sort();
  return (
    onTime: delays.where((d) => d <= _lateAfter && d >= _earlyBefore).length,
    late: delays.where((d) => d > _lateAfter).length,
    early: delays.where((d) => d < _earlyBefore).length,
    notTracked: days.where((d) => d.status == TripDayStatus.notTracked).length,
    canceled: days.where((d) => d.status == TripDayStatus.canceled).length,
    typical: delays.isEmpty ? null : delays[delays.length ~/ 2],
  );
}

/// What to expect, in one line: usually on time, late, early, or rarely tracked.
String tripVerdict(AppLocalizations l10n, TripRecord r) {
  final ran = r.onTime + r.late + r.early;
  return switch (r.typical) {
    _ when ran == 0 && r.notTracked + r.canceled == 0 => l10n.tripHistoryEmpty,
    _ when ran < r.notTracked => l10n.tripRarelyTracked,
    final t? when t > _lateAfter => l10n.tripUsuallyLate((t.inSeconds / 60).round()),
    final t? when t < _earlyBefore => l10n.tripUsuallyEarly((-t.inSeconds / 60).round()),
    _ => l10n.tripUsuallyOnTime,
  };
}

/// "+3 min", "-1 min", "0 min".
String _delayText(AppLocalizations l10n, Duration d) {
  final m = (d.inSeconds / 60).round();
  return '${m > 0 ? '+' : ''}${l10n.minutes(m)}';
}

/// The history of one trip at one stop on past weekdays or weekends: a verdict, the counts, and day by day.
class TripHistoryCard extends ConsumerWidget {
  const TripHistoryCard({
    required this.stopId,
    required this.lineId,
    required this.directionId,
    required this.departureSeconds,
    required this.weekend,
    this.action,
    this.margin = const EdgeInsets.symmetric(horizontal: Spacing.l, vertical: Spacing.s),
    this.showTrip = true,
    super.key,
  });

  /// Off where the page already says which trip it is.
  final bool showTrip;

  final EdgeInsetsGeometry margin;

  final String stopId;
  final String lineId;
  final int directionId;
  final int departureSeconds;
  final bool weekend;

  /// A button under the history (e.g. show the bus on the map).
  final Widget? action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final stop = ref.watch(networkProvider).value?.stopById[stopId]?.name ?? stopId;
    final days = ref.watch(tripHistoryProvider(stopId, lineId, directionId, departureSeconds, weekend: weekend));
    return Card.outlined(
      margin: margin,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Spacing.s,
          children: [
            if (showTrip) Text(l10n.tripAt(clockOf(departureSeconds), stop), style: context.textTheme.titleSmall),
            Text(
              weekend ? l10n.tripHistoryWeekend : l10n.tripHistoryWeekdays,
              style: context.textTheme.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
            ),
            switch (days) {
              AsyncValue(:final value?) => _History(value),
              // The history is a bonus: an error is not worth a retry button here.
              AsyncValue(hasError: true) => Text(l10n.tripHistoryEmpty, style: context.textTheme.bodyMedium),
              _ => const LinearProgressIndicator(),
            },
            ?action,
          ],
        ),
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History(this.days);

  final List<TripDay> days;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = tripRecord(days);
    final counts = [
      if (r.onTime > 0) l10n.tripOnTimeCount(r.onTime),
      if (r.late > 0) l10n.tripLateCount(r.late),
      if (r.early > 0) l10n.tripEarlyCount(r.early),
      if (r.notTracked > 0) l10n.tripNotTrackedCount(r.notTracked),
      if (r.canceled > 0) l10n.tripCanceledCount(r.canceled),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spacing.s,
      children: [
        Text(tripVerdict(l10n, r), style: context.textTheme.titleMedium),
        if (counts.isNotEmpty) Text(counts.join(' · '), style: context.textTheme.bodySmall),
        if (days.isNotEmpty)
          Wrap(
            spacing: Spacing.xs,
            runSpacing: Spacing.xs,
            // Oldest first, like a calendar read left to right.
            children: [for (final d in days.reversed) _Day(d)],
          ),
      ],
    );
  }
}

/// One day: weekday and date, then the delay or what happened. Never told by color alone (RNF-07).
class _Day extends StatelessWidget {
  const _Day(this.day);

  final TripDay day;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final (text, bg, fg) = switch (day) {
      TripDay(status: TripDayStatus.canceled) => (l10n.tripDayCanceled, c.errorContainer, c.onErrorContainer),
      TripDay(status: TripDayStatus.notTracked) => (l10n.tripDayNotTracked, c.surfaceContainerHighest, c.outline),
      TripDay(:final delay?) when delay > _lateAfter => (
        _delayText(l10n, delay),
        c.tertiaryContainer,
        c.onTertiaryContainer,
      ),
      TripDay(:final delay) => (_delayText(l10n, delay ?? Duration.zero), c.secondaryContainer, c.onSecondaryContainer),
    };
    final style = context.textTheme.labelSmall?.copyWith(color: fg);
    return Container(
      constraints: const BoxConstraints(minWidth: Spacing.xxxl + Spacing.s),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xs, vertical: Spacing.xs),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(Spacing.s)),
      child: Column(
        children: [
          Text(DateFormat.MEd().format(day.date), style: style),
          Text(text, style: style?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
