import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:veribus/core/widgets/transit_map.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/models/transit/network.dart';

/// A vehicle as the map draws it.
typedef MapVehicle = ({String id, String label, LatLng position, LineKind? kind});

MapVehicle mapVehicle(VehicleInfo v, LineKind? kind) =>
    (id: v.id, label: v.label ?? v.id, position: v.position, kind: kind);

/// The vehicles of a map, in motion. Data arrives every ~15 s: instead of jumping, each vehicle glides from where it is
/// drawn to where the new data puts it, over about the time until the next update, so buses are seen moving.
class VehiclesLayer extends StatefulWidget {
  const VehiclesLayer(this.vehicles, {super.key});

  final List<MapVehicle> vehicles;

  @override
  State<VehiclesLayer> createState() => _VehiclesLayerState();
}

class _VehiclesLayerState extends State<VehiclesLayer> with SingleTickerProviderStateMixin {
  /// A bit less than the refresh period (`AutoRefresh`): the glide ends as the next data arrives.
  static const glide = Duration(seconds: 14);

  /// Farther than this between two updates is not a bus driving: a new trip or a data jump, so no glide.
  static const _snapMeters = 1500.0;

  late final _controller = AnimationController(vsync: this, duration: glide);
  late Map<String, LatLng> _from = _targets(widget.vehicles);
  late Map<String, LatLng> _to = _from;

  static Map<String, LatLng> _targets(List<MapVehicle> vehicles) => {for (final v in vehicles) v.id: v.position};

  @override
  void didUpdateWidget(VehiclesLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targets = _targets(widget.vehicles);
    // The parent rebuilds for many reasons (the GPS fix, a rebuilt page): only new data restarts the glide, or the
    // vehicles would slow down at every rebuild.
    if (_sameTargets(targets, _to)) return;
    final shown = _shown();
    _from = {
      for (final e in targets.entries)
        e.key: switch (shown[e.key]) {
          final s? when const Distance()(s, e.value) < _snapMeters => s,
          _ => e.value,
        },
    };
    _to = targets;
    _controller.forward(from: 0);
  }

  static bool _sameTargets(Map<String, LatLng> a, Map<String, LatLng> b) =>
      a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

  /// Where each vehicle is drawn right now.
  Map<String, LatLng> _shown() {
    final t = _controller.value;
    return {
      for (final e in _to.entries)
        e.key: switch (_from[e.key]) {
          final from? => LatLng(
            from.latitude + (e.value.latitude - from.latitude) * t,
            from.longitude + (e.value.longitude - from.longitude) * t,
          ),
          _ => e.value,
        },
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final shown = _shown();
      return MarkerLayer(
        markers: [
          for (final v in widget.vehicles)
            VehicleMarker(point: shown[v.id] ?? v.position, label: v.label, kind: v.kind),
        ],
      );
    },
  );
}

/// The distinct vehicles behind a set of arrivals (a vehicle serves several stops), for the map.
List<MapVehicle> vehiclesOfArrivals(Iterable<Arrival> arrivals, Network? network) => [
  for (final a in {
    for (final a in arrivals)
      if (a.vehicle != null) a.vehicle!.id: a,
  }.values)
    mapVehicle(a.vehicle!, network?.lines[a.lineId]?.kind),
];
