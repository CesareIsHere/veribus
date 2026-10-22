import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:veribus/core/providers/map_theme_provider.dart';
import 'package:veribus/core/providers/position_provider.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/models/transit/network.dart';
import 'package:veribus/services/map_tile_service.dart';
import 'package:veribus/styles/app_spacing.dart';
import 'package:veribus/styles/app_theme.dart';
import 'package:veribus/styles/minimal_map_style.dart';

/// Rome's center, used when the position is not available (RF-02).
const rome = LatLng(41.8986, 12.4768);

/// The app's map: a minimal base (roads, water, green, street names: `styles/minimal_map_style.dart`) drawn from
/// OpenFreeMap vector tiles, in the light or dark variant of the app theme. Every map shows the device position as a
/// blue dot above everything else, with a button to come back to it.
class TransitMap extends ConsumerStatefulWidget {
  const TransitMap({
    required this.children,
    this.center = rome,
    this.zoom = 16,
    this.controller,
    this.fit,
    this.fitPadding = const EdgeInsets.all(Spacing.xxxl + Spacing.s),
    this.onMoved,
    this.locateButton = true,
    super.key,
  });

  final List<Widget> children;
  final LatLng center;
  final double zoom;
  final MapController? controller;

  /// Points that must all be in view (a bus, a stop and the user, say): the camera frames them when the map opens,
  /// and again if one leaves the view, so the zoom adapts to the distance. [center] and [zoom] are then ignored.
  /// Once the user moves the map by hand it is left alone.
  final List<LatLng>? fit;

  /// The margin around the [fit] points: a sheet over the map takes its share of the bottom.
  final EdgeInsets fitPadding;

  /// Called after every camera move, by the user or by code.
  final void Function(MapCamera camera, {required bool byUser})? onMoved;

  /// The button that brings the camera back to the user; off when something of the page covers its corner.
  final bool locateButton;

  @override
  ConsumerState<TransitMap> createState() => _TransitMapState();
}

class _TransitMapState extends ConsumerState<TransitMap> {
  MapController? _own;
  var _ready = false;

  /// The user moved the map by hand (or came back to their position): the camera is theirs now.
  var _moved = false;

  MapController get _controller => widget.controller ?? (_own ??= MapController());

  CameraFit? get _cameraFit {
    final points = widget.fit;
    if (points == null || points.length < 2) return null;
    return CameraFit.coordinates(coordinates: points, padding: widget.fitPadding, maxZoom: 17);
  }

  @override
  void didUpdateWidget(TransitMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final fit = _cameraFit;
    if (fit == null || !_ready || _moved) return;
    // A point left the view (the bus drove away, the user's position just arrived): frame them all again. Not on
    // every update, or the map would keep shifting under the eyes.
    final bounds = _controller.camera.visibleBounds;
    if (widget.fit!.any((p) => !bounds.contains(p))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_moved) _controller.fitCamera(fit);
      });
    }
  }

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final tiles = ref.watch(mapTilesProvider).value;
    final position = ref.watch(positionProvider).value;
    // The markers use the scheme of the map's own brightness, like the tiles.
    return Theme(
      data: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: widget.center,
              initialZoom: widget.zoom,
              initialCameraFit: _cameraFit,
              onMapReady: () => _ready = true,
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture) _moved = true;
                widget.onMoved?.call(camera, byUser: hasGesture);
              },
              minZoom: 10,
              maxZoom: 19,
              backgroundColor: minimalMapLand(brightness),
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
            ),
            children: [
              if (tiles != null) VectorTileLayer(theme: ref.watch(mapThemeProvider(brightness)), tileProviders: tiles),
              ...widget.children,
              if (position != null) MarkerLayer(markers: [UserMarker(point: position)]),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenFreeMap', onTap: () => launchUrl(Uri.parse('https://openfreemap.org'))),
                  TextSourceAttribution(
                    '© OpenMapTiles',
                    onTap: () => launchUrl(Uri.parse('https://openmaptiles.org')),
                  ),
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
                  ),
                ],
              ),
            ],
          ),
          if (position != null && widget.locateButton)
            Positioned(
              right: Spacing.l,
              bottom: Spacing.xxxl + Spacing.l, // above the map attribution button
              child: Builder(
                builder: (context) => FloatingActionButton.small(
                  tooltip: context.l10n.backToMyPosition,
                  onPressed: () {
                    _moved = true;
                    _controller.move(position, math.max(_controller.camera.zoom, 16));
                  },
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
                      border: Border.all(color: context.appColors.onLocation, width: 3),
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

/// A vehicle on the map: bus or tram icon and the line's code. Tappable (44 dp) when `onTap` is given.
class VehicleMarker extends Marker {
  VehicleMarker({
    required super.point,
    required String label,
    LineKind? kind,
    bool selected = false,
    VoidCallback? onTap,
  }) : super(
         width: 84,
         height: 44,
         child: Builder(
           builder: (context) {
             final colors = context.colors;
             // The selected one is the accent color, not just bigger: it is told apart in a crowd of dark pills.
             final background = selected ? colors.primary : colors.inverseSurface;
             final foreground = selected ? colors.onPrimary : colors.onInverseSurface;
             return Semantics(
               button: onTap != null,
               label: label,
               child: GestureDetector(
                 behavior: HitTestBehavior.opaque,
                 onTap: onTap,
                 child: Center(
                   child: Container(
                     height: 28,
                     constraints: const BoxConstraints(minWidth: 56),
                     padding: const EdgeInsets.symmetric(horizontal: Spacing.s),
                     alignment: Alignment.center,
                     decoration: BoxDecoration(
                       color: background,
                       borderRadius: BorderRadius.circular(14),
                       border: selected ? Border.all(color: colors.surface, width: 2) : null,
                       boxShadow: [BoxShadow(color: colors.shadow.withValues(alpha: 0.3), blurRadius: 3)],
                     ),
                     child: Row(
                       mainAxisSize: MainAxisSize.min,
                       spacing: Spacing.xs,
                       children: [
                         Icon(vehicleIcon(kind), size: 16, color: foreground),
                         Flexible(
                           child: Text(
                             label,
                             maxLines: 1,
                             overflow: TextOverflow.ellipsis,
                             style: context.textTheme.labelMedium?.copyWith(color: foreground),
                           ),
                         ),
                       ],
                     ),
                   ),
                 ),
               ),
             );
           },
         ),
       );
}
