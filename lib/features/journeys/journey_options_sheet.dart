import 'dart:async';

import 'package:flutter/material.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/models/journeys/journey_planner.dart';
import 'package:veribus/styles/app_spacing.dart';

/// What the traveller chose in the options: when to leave (now when null) and what to leave out.
typedef JourneyOptions = ({DateTime? at, JourneyFilter filter});

/// The options of a search in a bottom sheet: when to leave and whether to use the metro and the night buses.
/// Null when it is dismissed.
Future<JourneyOptions?> showJourneyOptions(
  BuildContext context, {
  required DateTime? at,
  required JourneyFilter filter,
}) {
  return showModalBottomSheet<JourneyOptions>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _JourneyOptionsSheet(at: at, filter: filter),
  );
}

class _JourneyOptionsSheet extends StatefulWidget {
  const _JourneyOptionsSheet({required this.at, required this.filter});

  final DateTime? at;
  final JourneyFilter filter;

  @override
  State<_JourneyOptionsSheet> createState() => _JourneyOptionsSheetState();
}

class _JourneyOptionsSheetState extends State<_JourneyOptionsSheet> {
  /// Days ahead the timetables cover: today and tomorrow are enough for "when do I leave".
  static const _days = 2;

  late DateTime? _at = widget.at;
  late JourneyFilter _filter = widget.filter;

  DateTime get _day => DateUtils.dateOnly(_at ?? DateTime.now());

  Future<void> _pickTime() async {
    final base = _at ?? DateTime.now();
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(base));
    if (picked != null) {
      setState(() => _at = DateTime(_day.year, _day.month, _day.day, picked.hour, picked.minute));
    }
  }

  void _setDay(int offset) {
    final base = _at ?? DateTime.now();
    final day = DateUtils.dateOnly(DateTime.now()).add(Duration(days: offset));
    setState(() => _at = DateTime(day.year, day.month, day.day, base.hour, base.minute));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final at = _at;
    final today = DateUtils.dateOnly(DateTime.now());
    final dayOffset = at == null ? 0 : DateUtils.dateOnly(at).difference(today).inDays.clamp(0, _days - 1);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.xl, 0, Spacing.xl, Spacing.xl),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Spacing.l,
          children: [
            Text(l10n.journeysOptionsTitle, style: context.textTheme.headlineSmall),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l10n.journeysNow)),
                ButtonSegment(value: true, label: Text(l10n.journeysLeaveAtLabel)),
              ],
              selected: {at != null},
              onSelectionChanged: (s) => setState(() {
                final now = DateTime.now();
                _at = s.first ? DateTime(now.year, now.month, now.day, now.hour, now.minute) : null;
              }),
            ),
            if (at != null)
              Row(
                spacing: Spacing.m,
                children: [
                  Expanded(
                    child: SegmentedButton<int>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(value: 0, label: Text(l10n.journeysToday)),
                        ButtonSegment(value: 1, label: Text(l10n.journeysTomorrow)),
                      ],
                      selected: {dayOffset},
                      onSelectionChanged: (s) => _setDay(s.first),
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () => unawaited(_pickTime()),
                    child: Text(
                      MaterialLocalizations.of(context)
                          .formatTimeOfDay(TimeOfDay.fromDateTime(at), alwaysUse24HourFormat: true),
                    ),
                  ),
                ],
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.subway_outlined),
              title: Text(l10n.journeysUseMetro),
              value: _filter.metro,
              onChanged: (v) => setState(() => _filter = (metro: v, night: _filter.night)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.nightlight_outlined),
              title: Text(l10n.journeysUseNight),
              value: _filter.night,
              onChanged: (v) => setState(() => _filter = (metro: _filter.metro, night: v)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: Spacing.s,
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    _at = null;
                    _filter = allTransport;
                  }),
                  child: Text(l10n.journeysReset),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop((at: _at, filter: _filter)),
                  child: Text(l10n.journeysShow),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
