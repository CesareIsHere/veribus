import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veribus/core/providers/auto_refresh.dart';
import 'package:veribus/core/providers/network_provider.dart';
import 'package:veribus/core/providers/shared_preferences_provider.dart';
import 'package:veribus/models/transit/live.dart';
import 'package:veribus/models/transit/network.dart';
import 'package:veribus/repositories/transit/transit_repository_provider.dart';
import 'package:veribus/services/location_service.dart';

part 'nearby_providers.g.dart';

/// Device position, null when the permission is denied (the app stays usable: RF-02).
@Riverpod(keepAlive: true)
Future<LatLng?> position(Ref ref) => ref.watch(locationServiceProvider).current();

@riverpod
Future<List<({Stop stop, double meters})>> nearbyStops(Ref ref) async {
  final at = await ref.watch(positionProvider.future);
  if (at == null) return const [];
  return (await ref.watch(networkProvider.future)).nearby(at);
}

/// One call for the arrivals of the ten nearest stops (RF-03), refreshed while the list is open.
@riverpod
Future<Arrivals?> nearbyArrivals(Ref ref) async {
  final stops = await ref.watch(nearbyStopsProvider.future);
  if (stops.isEmpty) return null;
  ref.refreshEvery();
  return await ref.watch(transitRepositoryProvider).arrivals([for (final s in stops) s.stop.id]);
}

/// Map or list, remembered between launches (RF-01).
@riverpod
class NearbyMapView extends _$NearbyMapView {
  static const _key = 'nearby_map_view';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? true;

  Future<void> set({required bool map}) async {
    state = map;
    await ref.read(sharedPreferencesProvider).setBool(_key, map);
  }
}
