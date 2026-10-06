import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:veribus/core/providers/network_provider.dart';
import 'package:veribus/core/widgets/transit_map.dart';
import 'package:veribus/core/widgets/vehicle_route.dart';
import 'package:veribus/core/widgets/vehicles_layer.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/line/providers/line_providers.dart';
import 'package:veribus/features/stop/components/arrival_tile.dart';
import 'package:veribus/features/stop/stop_page.dart';
import 'package:veribus/styles/app_spacing.dart';

/// The whole route of a vehicle tapped on a map: where it has been and where it still goes.
Future<void> showVehicleRouteSheet(BuildContext context, {required MapVehicle vehicle}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (context) => VehicleRouteSheet(vehicle: vehicle),
);

/// Follows the vehicle live: the route is cut where it is now, and the cut moves with each refresh.
class VehicleRouteSheet extends ConsumerWidget {
  const VehicleRouteSheet({required this.vehicle, super.key});

  final MapVehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final network = ref.watch(networkProvider).value;
    final detail = ref.watch(lineDetailProvider(vehicle.lineId, vehicle.directionId)).value;
    // The route detail knows the vehicle too (and which stop it is heading to); until then the tapped data stands.
    final live = detail?.vehicles.where((v) => v.id == vehicle.id).firstOrNull;
    final position = live?.position ?? vehicle.position;
    final shape = detail?.shape ?? const <LatLng>[];
    final stops = [for (final id in detail?.stopIds ?? const <String>[]) ?network?.stopById[id]];
    final nextStop = switch (live?.index) {
      final i? when i < stops.length => stops[i],
      _ => null,
    };
    final corners = shape.length < 2 ? null : LatLngBounds.fromPoints([...shape, position]);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 320,
            child: TransitMap(
              center: position,
              zoom: 14,
              fit: corners == null ? null : [corners.southWest, corners.northEast],
              children: [
                VehicleRouteLayer(shape: shape, at: position),
                MarkerLayer(
                  markers: [
                    for (final s in stops)
                      StopMarker(
                        point: s.position,
                        label: s.name,
                        selected: s.id == nextStop?.id,
                        onTap: () {
                          Navigator.of(context).pop();
                          unawaited(context.push(StopPage.route(s.id)));
                        },
                      ),
                  ],
                ),
                VehiclesLayer([vehicle.movedTo(position)]),
              ],
            ),
          ),
          ListTile(
            leading: LineBadge(vehicle.label),
            title: Text(
              detail?.headsign == null ? l10n.vehicleNumber(vehicle.fleet ?? vehicle.id) : '→ ${detail!.headsign}',
            ),
            subtitle: Text(
              [
                if (vehicle.fleet case final f?) l10n.vehicleNumber(f),
                if (nextStop case final s?) l10n.nextStopName(s.name),
              ].join(' · '),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(context.pageMargin, 0, context.pageMargin, Spacing.l),
            child: const Align(alignment: Alignment.centerLeft, child: RouteLegend()),
          ),
        ],
      ),
    );
  }
}
