import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:veribus/core/widgets/line_chip.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/models/journeys/metro_stations.dart';
import 'package:veribus/models/transit/transit_kind.dart';
import 'package:veribus/styles/app_spacing.dart';

/// A metro station on the map: the metro icon in the color of its line. Tap for the lines and how often they pass.
class MetroMarker extends Marker {
  MetroMarker({required MetroStation station, required VoidCallback onTap})
    : super(
        point: station.point,
        width: 44,
        height: 44,
        child: Builder(
          builder: (context) => Semantics(
            button: true,
            label: station.name,
            child: GestureDetector(
              onTap: onTap,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: LineChip.colorOf(context, TransitKind.metro, station.lines.first.line),
                    shape: BoxShape.circle,
                    border: Border.all(color: context.colors.surface, width: 2),
                  ),
                  child: SizedBox.square(
                    dimension: 28,
                    child: Icon(Icons.subway, size: 16, color: context.appColors.onTransit),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

/// The lines of a station, each with how often it passes now, and a note that it is the timetable.
Future<void> showMetroSheet(BuildContext context, MetroStation station) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(context.pageMargin, 0, context.pageMargin, Spacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Spacing.m,
        children: [
          Text(station.name, style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          MetroLines(station),
          Text(context.l10n.metroScheduled, style: context.textTheme.bodySmall),
        ],
      ),
    ),
  ),
);

/// One row per line of [station]: its chip and how often it passes.
class MetroLines extends StatelessWidget {
  const MetroLines(this.station, {super.key});

  final MetroStation station;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spacing.s,
      children: [
        for (final (:line, :everyMinutes) in station.lines)
          Row(
            spacing: Spacing.m,
            children: [
              LineChip(line, kind: TransitKind.metro),
              Expanded(
                child: Text(
                  everyMinutes == null ? l10n.metroNoTrains : l10n.metroEvery(everyMinutes),
                  style: context.textTheme.bodyLarge,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
