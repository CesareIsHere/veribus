import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:veribus/core/providers/network_provider.dart';
import 'package:veribus/core/providers/position_provider.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/models/transit/network.dart';
import 'package:veribus/styles/app_spacing.dart';
import 'package:veribus/styles/app_theme.dart';

/// Rome's center, used when the position is not available (RF-02).
const rome = LatLng(41.8986, 12.4768);

/// Map with the tile provider from the remote config (the provider is still to be chosen: spec 11). Every map shows
/// the device position as a blue dot above everything else, with a button to come back to it.
class TransitMap extends ConsumerStatefulWidget {
  const TransitMap({required this.children, this.center = rome, this.zoom = 16, this.controller, super.key});

  final List<Widget> children;
  final LatLng center;
  final double zoom;
  final MapController? controller;

  @override
  ConsumerState<TransitMap> createState() => _TransitMapState();
}

class _TransitMapState extends ConsumerState<TransitMap> {
  MapController? _own;

  MapController get _controller => widget.controller ?? (_own ??= MapController());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tileUrl = ref.watch(networkInfoProvider).value?.tileUrl;
    final position = ref.watch(positionProvider).value;
    // Tiles are always light: markers use the light scheme too, or in dark mode they turn into black dots.
    return Theme(
      data: AppTheme.light(),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: widget.center,
              initialZoom: widget.zoom,
              minZoom: 10,
              maxZoom: 19,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
            ),
            children: [
              if (tileUrl != null) TileLayer(urlTemplate: tileUrl, userAgentPackageName: 'com.emilianocesare.veribus'),
              ...widget.children,
              if (position != null) MarkerLayer(markers: [UserMarker(point: position)]),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap',
                    onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
                  ),
                ],
              ),
            ],
          ),
          if (position != null)
            Positioned(
              right: Spacing.l,
              bottom: Spacing.xxxl + Spacing.l, // above the map attribution button
              child: Builder(
                builder: (context) => FloatingActionButton.small(
                  tooltip: context.l10n.backToMyPosition,
                  onPressed: () => _controller.move(position, math.max(_controller.camera.zoom, 16)),
                  child: const Icon(Icons.my_location),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The device position: a vivid blue dot with a white ring and a soft halo, readable on any tile and clearly not a
/// stop (ring) or a vehicle (label).
class UserMarker extends Marker {
  UserMarker({required super.point})
    : super(
        width: 56,
        height: 56,
        child: Builder(
          builder: (context) {
            final blue = context.appColors.location;
            return Semantics(
              label: context.l10n.you,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(shape: BoxShape.circle, color: blue.withValues(alpha: 0.2)),
                    child: const SizedBox.square(dimension: 56),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: blue,
                      border: Border.all(color: context.colors.surface, width: 3),
                      boxShadow: [BoxShadow(color: context.colors.shadow.withValues(alpha: 0.35), blurRadius: 4)],
                    ),
                    child: const SizedBox.square(dimension: 22),
                  ),
                ],
              ),
            );
          },
        ),
      );
}

/// A stop dot on the map (tap target 44 dp).
class StopMarker extends Marker {
  StopMarker({required super.point, required VoidCallback onTap, required String label, bool selected = false})
    : super(
        width: 44,
        height: 44,
        child: Builder(
          builder: (context) => Semantics(
            button: true,
            label: label,
            child: GestureDetector(
              onTap: onTap,
              child: Center(
                child: Container(
                  width: selected ? 24 : 18,
                  height: selected ? 24 : 18,
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.colors.primary, width: selected ? 4 : 3),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

IconData vehicleIcon(LineKind? kind) => kind == LineKind.tram ? Icons.tram : Icons.directions_bus;

/// A vehicle on the map: bus or tram icon and fleet number.
class VehicleMarker extends Marker {
  VehicleMarker({required super.point, required String label, LineKind? kind})
    : super(
        width: 84,
        height: 28,
        child: Builder(
          builder: (context) => Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(color: context.colors.inverseSurface, borderRadius: BorderRadius.circular(14)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: Spacing.xs,
              children: [
                Icon(vehicleIcon(kind), size: 16, color: context.colors.onInverseSurface),
                Text(label, style: context.textTheme.labelMedium?.copyWith(color: context.colors.onInverseSurface)),
              ],
            ),
          ),
        ),
      );
}

/// The part of [shape] from the point nearest to [from] to the one nearest to [to]. The whole shape when [to] comes
/// first: the trip is a variant that leaves the main path.
// ponytail: nearest point, wrong on loop lines where the stop is near both ends; per-trip shapes if it matters.
List<LatLng> pathBetween(List<LatLng> shape, LatLng from, LatLng to) {
  if (shape.isEmpty) return const [];
  int nearest(LatLng p) {
    var best = 0;
    for (var i = 1; i < shape.length; i++) {
      if (const Distance().distance(p, shape[i]) < const Distance().distance(p, shape[best])) best = i;
    }
    return best;
  }

  final a = nearest(from);
  final b = nearest(to);
  return a <= b ? [from, ...shape.sublist(a, b + 1), to] : shape;
}
