import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:veribus/core/config.dart';
import 'package:veribus/core/providers/network_provider.dart';
import 'package:veribus/core/widgets/section_header.dart';
import 'package:veribus/core/widgets/states/message_view.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/notifications/components/follow_time_chip.dart'; // feature:push
import 'package:veribus/features/stop/providers/stop_providers.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/styles/app_spacing.dart';

/// Scheduled times of a line at a stop, for one day, grouped by hour, first and last trip highlighted (RF-28).
class TimetablePage extends ConsumerStatefulWidget {
  const TimetablePage({required this.stopId, required this.lineId, super.key});

  static String route(String stopId, String lineId) => '/stop/$stopId/timetable?line=${Uri.encodeComponent(lineId)}';

  final String stopId;
  final String lineId;

  @override
  ConsumerState<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends ConsumerState<TimetablePage> {
  late String _line = widget.lineId;
  DateTime _day = DateUtils.dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final network = ref.watch(networkProvider).value;
    final stop = network?.stopById[widget.stopId];
    final timetable = ref.watch(timetableProvider(widget.stopId, _line, _day));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.timetable)),
      body: ListView(
        padding: context.pagePadding(),
        children: [
          Text(stop?.name ?? '', style: context.textTheme.titleMedium),
          const SizedBox(height: Spacing.l),
          Row(
            spacing: Spacing.s,
            children: [
              DropdownMenu<String>(
                label: Text(l10n.line),
                initialSelection: _line,
                onSelected: (id) => setState(() => _line = id ?? _line),
                dropdownMenuEntries: [
                  for (final id in stop?.lineIds ?? [widget.lineId])
                    DropdownMenuEntry(value: id, label: network?.lines[id]?.name ?? id),
                ],
              ),
              const Spacer(),
              IconButton(
                tooltip: l10n.previousDay,
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => _day = _day.subtract(const Duration(days: 1))),
              ),
              Text(DateFormat.MMMEd().format(_day)),
              IconButton(
                tooltip: l10n.nextDay,
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() => _day = _day.add(const Duration(days: 1))),
              ),
            ],
          ),
          const SizedBox(height: Spacing.s),
          Text(l10n.scheduledTimesNote, style: context.textTheme.bodySmall),
          if (Features.push) Text(l10n.followTripHint, style: context.textTheme.bodySmall), // feature:push
          ...switch (timetable) {
            AsyncValue(:final value?) when value.isEmpty => [
              MessageView(icon: Icons.event_busy_outlined, title: l10n.noServiceThisDay),
            ],
            AsyncValue(:final value?) => [for (final d in value) ..._direction(context, d)],
            AsyncValue(:final error?) => [
              MessageView.error(context, error, onRetry: () => ref.invalidate(timetableProvider)),
            ],
            _ => [
              const Padding(
                padding: EdgeInsets.all(Spacing.xxl),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          },
        ],
      ),
    );
  }

  List<Widget> _direction(BuildContext context, TimetableDirection d) {
    final byHour = <int, List<int>>{};
    for (final s in d.departures) {
      byHour.putIfAbsent(s ~/ 3600, () => []).add(s);
    }
    String minute(int s) => (s % 3600 ~/ 60).toString().padLeft(2, '0');
    // Times past 24:00 belong to this service day but happen after midnight.
    String hour(int h) => (h % 24).toString().padLeft(2, '0');
    final bold = context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700);
    return [
      SectionHeader('→ ${d.headsign}'),
      for (final MapEntry(key: h, value: times) in byHour.entries)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: Spacing.xxxl,
                child: Text(hour(h), style: bold),
              ),
              Expanded(
                child: Wrap(
                  spacing: Spacing.m,
                  runSpacing: Spacing.xs,
                  children: [for (final s in times) _time(context, d, s, minute, bold)],
                ),
              ),
            ],
          ),
        ),
    ];
  }

  /// One time of the timetable; with followed trips it is a chip to tap.
  Widget _time(BuildContext context, TimetableDirection d, int s, String Function(int) minute, TextStyle? bold) {
    final emphasized = s == d.departures.first || s == d.departures.last;
    // feature:push:start
    if (Features.push) {
      return FollowTimeChip(
        stopId: widget.stopId,
        lineId: _line,
        directionId: d.directionId,
        seconds: s,
        weekday: _day.weekday,
        label: _label(context, d, s, minute),
        emphasized: emphasized,
      );
    }
    // feature:push:end
    return Text(_label(context, d, s, minute), style: emphasized ? bold : null);
  }

  String _label(BuildContext context, TimetableDirection d, int s, String Function(int) minute) =>
      s == d.departures.first
      ? '${minute(s)} (${context.l10n.firstTrip})'
      : s == d.departures.last
      ? '${minute(s)} (${context.l10n.lastTrip})'
      : minute(s);
}
