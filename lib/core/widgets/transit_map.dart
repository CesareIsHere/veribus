import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:veribus/core/providers/network_provider.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/styles/app_theme.dart';

/// Rome's center, used when the position is not available (RF-02).
const rome = LatLng(41.8986, 12.4768);

/// Map with the tile provider from the remote config (the provider is still to be chosen: spec 11).
class TransitMap extends ConsumerWidget {
  const TransitMap({required this.children, this.center = rome, this.zoom = 16, this.controller, super.key});

  final List<Widget> children;
  final LatLng center;
  final double zoom;
  final MapController? controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tileUrl = ref.watch(networkInfoProvider).value?.tileUrl;
    // Tiles are always light: markers use the light scheme too, or in dark mode they turn into black dots.
    return Theme(
      data: AppTheme.light(),
      child: FlutterMap(
        mapController: controller,
        options: MapOptions(
          initialCenter: center,
          initialZoom: zoom,
          minZoom: 10,
          maxZoom: 19,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
        ),
        children: [
          if (tileUrl != null) TileLayer(urlTemplate: tileUrl, userAgentPackageName: 'com.emilianocesare.veribus'),
          ...children,
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
    );
  }
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

/// A vehicle on the map with its fleet number.
class VehicleMarker extends Marker {
  VehicleMarker({required super.point, required String label})
    : super(
        width: 72,
        height: 28,
        child: Builder(
          builder: (context) => Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(color: context.colors.inverseSurface, borderRadius: BorderRadius.circular(14)),
            child: Text(label, style: context.textTheme.labelMedium?.copyWith(color: context.colors.onInverseSurface)),
          ),
        ),
      );
}
