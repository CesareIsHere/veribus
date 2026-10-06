import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/styles/app_spacing.dart';

/// [shape] cut where a vehicle is: what it has travelled and what it still has to go. The cut is at the point of the
/// route nearest to [at], so a GPS fix a few meters off the line still splits it cleanly.
// ponytail: nearest point, wrong on loop lines where the vehicle is near both passes; per-trip shapes if it matters.
({List<LatLng> behind, List<LatLng> ahead}) splitRoute(List<LatLng> shape, LatLng at) {
  if (shape.length < 2) return (behind: const [], ahead: shape);
  // A flat plane, longitude scaled by latitude: precise enough at the scale of a city.
  final scale = math.cos(at.latitudeInRad);
  var segment = 0;
  var along = 0.0;
  var best = double.infinity;
  for (var i = 0; i < shape.length - 1; i++) {
    final a = shape[i];
    final dx = (shape[i + 1].longitude - a.longitude) * scale;
    final dy = shape[i + 1].latitude - a.latitude;
    final length2 = dx * dx + dy * dy;
    final px = (at.longitude - a.longitude) * scale;
    final py = at.latitude - a.latitude;
    final t = length2 == 0 ? 0.0 : ((px * dx + py * dy) / length2).clamp(0.0, 1.0);
    final distance2 = math.pow(px - t * dx, 2) + math.pow(py - t * dy, 2);
    if (distance2 < best) {
      best = distance2.toDouble();
      segment = i;
      along = t;
    }
  }
  final a = shape[segment];
  final b = shape[segment + 1];
  final cut = LatLng(a.latitude + (b.latitude - a.latitude) * along, a.longitude + (b.longitude - a.longitude) * along);
  return (behind: [...shape.sublist(0, segment + 1), cut], ahead: [cut, ...shape.sublist(segment + 1)]);
}

/// The whole route of a vehicle: dashed and muted where it has been, solid and in the accent color where it goes.
/// The two are told apart by the line style too, not only by color.
class VehicleRouteLayer extends StatelessWidget {
  const VehicleRouteLayer({required this.shape, required this.at, super.key});

  final List<LatLng> shape;
  final LatLng at;

  @override
  Widget build(BuildContext context) {
    final (:behind, :ahead) = splitRoute(shape, at);
    return PolylineLayer(
      polylines: [
        if (behind.length > 1)
          Polyline(
            points: behind,
            strokeWidth: 4,
            color: context.colors.outline,
            pattern: StrokePattern.dashed(segments: const [8, 8]),
          ),
        if (ahead.length > 1) Polyline(points: ahead, strokeWidth: 5, color: context.colors.primary),
      ],
    );
  }
}

/// Key to [VehicleRouteLayer]: which stroke is the road already travelled and which the road still to go.
class RouteLegend extends StatelessWidget {
  const RouteLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = context.textTheme.labelMedium?.copyWith(color: context.colors.onSurfaceVariant);
    Widget key(Widget stroke, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      spacing: Spacing.s,
      children: [
        stroke,
        Text(text, style: style),
      ],
    );
    return Wrap(
      spacing: Spacing.l,
      runSpacing: Spacing.xs,
      children: [
        key(
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: Spacing.xs,
            children: [
              for (var i = 0; i < 3; i++) Container(width: Spacing.s, height: 4, color: context.colors.outline),
            ],
          ),
          l10n.routeTravelled,
        ),
        key(Container(width: Spacing.xl, height: 5, color: context.colors.primary), l10n.routeAhead),
      ],
    );
  }
}
