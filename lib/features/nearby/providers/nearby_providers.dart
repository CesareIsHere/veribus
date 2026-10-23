import 'dart:async';

import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veribus/core/providers/auto_refresh.dart';
import 'package:veribus/core/providers/favorites_notifier.dart';
import 'package:veribus/core/providers/network_provider.dart';
import 'package:veribus/core/providers/position_provider.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/models/transit/network.dart';
import 'package:veribus/repositories/transit/transit_repository_provider.dart';

part 'nearby_providers.g.dart';

/// Riding a bus moves the position every few seconds, and the list and its arrivals must not reload each time.
const _refetchMeters = 100.0;

/// Where "nearby" is measured from: the live position, but a new value only after it moved [_refetchMeters] (or
/// appeared / disappeared, so the page shows the right state at once).
@riverpod
Stream<LatLng?> nearbyOrigin(Ref ref) {
  final origin = StreamController<LatLng?>();
  ref.onDispose(origin.close);
  var first = true;
  LatLng? last;
  // listen, not watch: this provider filters the fixes, it must not be rebuilt by each one.
  ref.listen(positionProvider, (_, next) {
    if (next is! AsyncData<LatLng?>) return;
    final at = next.value;
    final far = first || at == null || last == null || const Distance()(last!, at) > _refetchMeters;
    if (far && (first || at != last)) {
      first = false;
      last = at;
      origin.add(at);
    }
  }, fireImmediately: true);
  return origin.stream;
}

@riverpod
Future<List<({Stop stop, double meters})>> nearbyStops(Ref ref) async {
  final at = await ref.watch(nearbyOriginProvider.future);
  if (at == null) return const [];
  final favorites = ref.watch(favoritesProvider).stops.toSet();
  return (await ref.watch(networkProvider.future)).nearby(at, favorites: favorites);
}

/// One call for the arrivals of the ten nearest stops (RF-03), refreshed while the list is open.
@riverpod
Future<Arrivals?> nearbyArrivals(Ref ref) async {
  final stops = await ref.watch(nearbyStopsProvider.future);
  if (stops.isEmpty) return null;
  ref.refreshEvery();
  return await ref.watch(transitRepositoryProvider).arrivals([for (final s in stops) s.stop.id]);
}
