import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:veribus/core/providers/network_provider.dart';
import 'package:veribus/core/widgets/transit_map.dart';
import 'package:veribus/core/widgets/vehicles_layer.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/line/providers/line_providers.dart';
import 'package:veribus/features/stop/components/arrival_tile.dart';
import 'package:veribus/features/stop/providers/stop_providers.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/models/transit/network.dart';
import 'package:veribus/styles/app_spacing.dart';

/// The vehicle of [arrival] on the map, with fleet number and stops left (RF-23).
Future<void> showVehicleSheet(BuildContext context, {required Stop stop, required Arrival arrival}) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => VehicleSheet(stop: stop, arrival: arrival),
    );

/// The sheet follows the vehicle live: it moves on the map and the stops left / signal update with each refresh.
class VehicleSheet extends ConsumerStatefulWidget {
  const VehicleSheet({required this.stop, required this.arrival, super.key});

  final Stop stop;
  final Arrival arrival;

  @override
  ConsumerState<VehicleSheet> createState() => _VehicleSheetState();
}

class _VehicleSheetState extends ConsumerState<VehicleSheet> {
  late Arrival _arrival = widget.arrival;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stop = widget.stop;
    // The stop page refreshes the arrivals every 15 s: follow the same trip. When it leaves the list (the bus has
    // passed) the last data stays on screen.
    ref.listen(stopArrivalsProvider(stop.id), (_, next) {
      final fresh = next.value?.byStop[stop.id]?.where((a) => a.tripId == _arrival.tripId && a.vehicle != null);
      if (fresh case Iterable(isNotEmpty: true)) setState(() => _arrival = fresh.first);
    });
    final a = _arrival;
    final v = a.vehicle!;
    final old = DateTime.now().difference(v.gpsAt) > const Duration(minutes: 2);
    final kind = ref.watch(networkProvider).value?.lines[a.lineId]?.kind;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 260,
          child: TransitMap(
            center: LatLng(
              (v.position.latitude + stop.position.latitude) / 2,
              (v.position.longitude + stop.position.longitude) / 2,
            ),
            zoom: 15,
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final shape = ref.watch(lineDetailProvider(a.lineId, a.directionId)).value?.shape ?? const [];
                  return PolylineLayer(
                    polylines: [
                      Polyline(
                        points: pathBetween(shape, v.position, stop.position),
                        strokeWidth: 4,
                        color: context.colors.primary,
                      ),
                    ],
                  );
                },
              ),
              MarkerLayer(
                markers: [StopMarker(point: stop.position, label: stop.name, selected: true, onTap: () {})],
              ),
              VehiclesLayer([mapVehicle(v, kind)]),
            ],
          ),
        ),
        ListTile(
          leading: StatusTag(a.status),
          title: Text(v.label == null ? a.headsign : l10n.vehicle(v.label!)),
          subtitle: Text(
            [
              if (a.stopsAway case final n?) l10n.stopsAway(n),
              if (old) l10n.lastPositionAt(DateFormat.Hm().format(v.gpsAt.toLocal())),
              if (a.signal case final s?) ArrivalText.signal(l10n, s, stopsAway: a.stopsAway),
            ].join(' · '),
          ),
        ),
        const SizedBox(height: Spacing.l),
      ],
    );
  }
}
