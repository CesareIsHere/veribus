import 'package:flutter/material.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/models/transit/transit_kind.dart';
import 'package:veribus/styles/app_spacing.dart';

/// The line of a bus, tram, metro or night bus as everyone reads it: its name in a chip with the color of the kind of
/// vehicle and its icon (the kind is never told by color alone). Muted when the line never transmits positions or its
/// trip is gone.
class LineChip extends StatelessWidget {
  const LineChip(this.name, {this.kind = TransitKind.bus, this.muted = false, this.large = false, super.key});

  final String name;
  final TransitKind kind;
  final bool muted;

  /// The title of a line page, not a row of a list.
  final bool large;

  static IconData iconOf(TransitKind kind) => switch (kind) {
    TransitKind.bus => Icons.directions_bus,
    TransitKind.tram => Icons.tram,
    TransitKind.metro => Icons.subway,
    TransitKind.night => Icons.nightlight,
  };

  /// The chip color of a line: the metro lines by their letter, the bus the brand color.
  static Color colorOf(BuildContext context, TransitKind kind, String name) {
    final colors = context.appColors;
    return switch (kind) {
      TransitKind.bus => colors.bus,
      TransitKind.tram => colors.tram,
      TransitKind.night => colors.night,
      TransitKind.metro => switch (name.toUpperCase()) {
        final n when n.startsWith('A') => colors.metroA,
        final n when n.startsWith('B') => colors.metroB,
        final n when n.startsWith('C') => colors.metroC,
        _ => colors.bus,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final background = muted ? scheme.surfaceContainerHighest : colorOf(context, kind, name);
    final foreground = muted ? scheme.onSurfaceVariant : context.appColors.onTransit;
    final style = (large ? context.textTheme.headlineSmall : context.textTheme.titleSmall)?.copyWith(
      color: foreground,
      fontWeight: FontWeight.w800,
    );
    final height = large ? Spacing.xxxl - Spacing.xs : Spacing.xxl - Spacing.xs - Spacing.xs;
    return Container(
      constraints: BoxConstraints(minWidth: height + Spacing.s, minHeight: height),
      padding: const EdgeInsets.only(left: Spacing.s, right: Spacing.m),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(large ? Spacing.m : Spacing.s)),
      // widthFactor 1: as wide as the name, not the whole row.
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: Spacing.xs,
          children: [
            Icon(iconOf(kind), size: large ? Spacing.xl : Spacing.l, color: foreground),
            Text(name, style: style),
          ],
        ),
      ),
    );
  }
}
