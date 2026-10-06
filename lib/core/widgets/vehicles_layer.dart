import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:veribus/core/widgets/transit_map.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/models/transit/network.dart';

/// A vehicle as the map draws it: the pill shows the `label` (the line's code), the fleet number is for the details.
typedef MapVehicle = ({
  String id,
  String label,
  String? fleet,
  String lineId,
  int directionId,
  LatLng position,
  LineKind? kind,
});

extension MapVehicleMoved on MapVehicle {
  MapVehicle movedTo(LatLng to) =>
      (id: id, label: label, fleet: fleet, lineId: lineId, directionId: directionId, position: to, kind: kind);
}

MapVehicle mapVehicle(VehicleInfo v, {required String lineId, required int directionId, required Network? network}) => (
  id: v.id,
  label: network?.lines[lineId]?.name ?? lineId,
  fleet: v.label,
  lineId: lineId,
  directionId: directionId,
  position: v.position,
  kind: network?.lines[lineId]?.kind,
);

/// The vehicles of a map, where the last data puts them (it arrives every ~15 s). They jump there: a straight glide
/// would cut across blocks, and the app has no way to follow the real street between two fixes.
class VehiclesLayer extends StatelessWidget {
  const VehiclesLayer(this.vehicles, {this.selectedId, this.onTap, super.key});

  final List<MapVehicle> vehicles;

  /// The vehicle whose route is shown, drawn emphasized.
  final String? selectedId;
  final ValueChanged<MapVehicle>? onTap;

  @override
  Widget build(BuildContext context) => MarkerLayer(
    markers: [
      for (final v in vehicles)
        VehicleMarker(
          point: v.position,
          label: v.label,
          kind: v.kind,
          selected: v.id == selectedId,
          onTap: onTap == null ? null : () => onTap!(v),
        ),
    ],
  );
}

/// The distinct vehicles behind a set of arrivals (a vehicle serves several stops), for the map.
List<MapVehicle> vehiclesOfArrivals(Iterable<Arrival> arrivals, Network? network) => [
  for (final a in {
    for (final a in arrivals)
      if (a.vehicle != null) a.vehicle!.id: a,
  }.values)
    mapVehicle(a.vehicle!, lineId: a.lineId, directionId: a.directionId, network: network),
];
