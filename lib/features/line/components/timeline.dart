import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:veribus/core/widgets/transit_map.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/stop/components/arrival_tile.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/models/transit/network.dart';
import 'package:veribus/styles/app_spacing.dart';

/// Height of the first line of a row: the rail's node is centered on it.
const double _lineHeight = Spacing.xxxl;
const double _nodeBox = Spacing.xl + Spacing.xs;

/// One row of the route: a node on the vertical rail (the line's path), content on the right. The rail runs through
/// every row, so stops and vehicles read as one path with the vehicles sitting between the stops they are heading to.
class TimelineRow extends StatelessWidget {
  const TimelineRow({required this.node, required this.child, this.first = false, this.last = false, super.key});

  final Widget node;
  final Widget child;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final rail = SizedBox(
      width: Spacing.xxxl,
      child: Stack(
        children: [
          if (!(first && last))
            Positioned(
              left: Spacing.xxxl / 2 - 1,
              width: 2,
              top: first ? _lineHeight / 2 : 0,
              bottom: last ? null : 0,
              height: last ? _lineHeight / 2 : null,
              child: ColoredBox(color: context.colors.outlineVariant),
            ),
          Positioned(
            top: (_lineHeight - _nodeBox) / 2,
            left: (Spacing.xxxl - _nodeBox) / 2,
            width: _nodeBox,
            height: _nodeBox,
            child: Center(child: node),
          ),
        ],
      ),
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(width: Spacing.xs),
          rail,
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// A stop of the route. The terminals are filled and bolder: where the trip starts and ends.
class TimelineStop extends StatelessWidget {
  const TimelineStop({required this.name, required this.terminus, required this.onTap, super.key});

  final String name;
  final bool terminus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: _lineHeight),
        padding: const EdgeInsets.only(right: Spacing.l),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Expanded(child: Text(name, style: terminus ? context.textTheme.titleSmall : context.textTheme.bodyLarge)),
            if (terminus)
              Text(
                context.l10n.terminus,
                style: context.textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }

  /// The node on the rail for a stop.
  static Widget node(BuildContext context, {required bool terminus}) {
    final colors = context.colors;
    final size = terminus ? Spacing.l : Spacing.m;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: terminus ? colors.primary : colors.surface,
        border: Border.all(color: colors.primary, width: 2),
      ),
    );
  }
}

/// A vehicle between two stops: what it is, where it is heading, and anything wrong with its signal. Tapping it
/// shows it on the map.
class TimelineVehicle extends StatelessWidget {
  const TimelineVehicle({required this.vehicle, required this.nextStop, this.onTap, super.key});

  final VehicleInfo vehicle;
  final String? nextStop;
  final VoidCallback? onTap;

  /// The node on the rail for a vehicle: the accent color, so it stands out from the stops.
  static Widget node(BuildContext context, LineKind? kind) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(shape: BoxShape.circle, color: colors.primary),
      child: SizedBox.square(
        dimension: _nodeBox,
        child: Icon(vehicleIcon(kind), size: Spacing.l + Spacing.xs, color: colors.onPrimary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final old = DateTime.now().difference(vehicle.gpsAt) > const Duration(minutes: 2);
    final secondary = context.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, Spacing.xs, Spacing.l, Spacing.xs),
      child: Card.filled(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.m),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: Spacing.xs,
                    children: [
                      Text(l10n.vehicleNumber(vehicle.label ?? vehicle.id), style: context.textTheme.titleSmall),
                      if (nextStop != null) Text(l10n.nextStopName(nextStop!), style: secondary),
                      if (old)
                        Text(l10n.lastPositionAt(DateFormat.Hm().format(vehicle.gpsAt.toLocal())), style: secondary),
                      if (vehicle.signal case final s?)
                        Row(
                          spacing: Spacing.xs,
                          children: [
                            Icon(Icons.info_outline, size: Spacing.l, color: colors.onSurfaceVariant),
                            Expanded(child: Text(ArrivalText.signal(l10n, s), style: secondary)),
                          ],
                        ),
                    ],
                  ),
                ),
                if (onTap != null) Icon(Icons.map_outlined, color: colors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
