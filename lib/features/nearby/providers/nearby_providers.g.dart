// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nearby_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Device position, null when the permission is denied (the app stays usable: RF-02).

@ProviderFor(position)
final positionProvider = PositionProvider._();

/// Device position, null when the permission is denied (the app stays usable: RF-02).

final class PositionProvider extends $FunctionalProvider<AsyncValue<LatLng?>, LatLng?, FutureOr<LatLng?>>
    with $FutureModifier<LatLng?>, $FutureProvider<LatLng?> {
  /// Device position, null when the permission is denied (the app stays usable: RF-02).
  PositionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'positionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$positionHash();

  @$internal
  @override
  $FutureProviderElement<LatLng?> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<LatLng?> create(Ref ref) {
    return position(ref);
  }
}

String _$positionHash() => r'bc08fbc10f56f2554678ed6d61697c87b233aa01';

@ProviderFor(nearbyStops)
final nearbyStopsProvider = NearbyStopsProvider._();

final class NearbyStopsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<({double meters, Stop stop})>>,
          List<({double meters, Stop stop})>,
          FutureOr<List<({double meters, Stop stop})>>
        >
    with $FutureModifier<List<({double meters, Stop stop})>>, $FutureProvider<List<({double meters, Stop stop})>> {
  NearbyStopsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nearbyStopsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nearbyStopsHash();

  @$internal
  @override
  $FutureProviderElement<List<({double meters, Stop stop})>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<({double meters, Stop stop})>> create(Ref ref) {
    return nearbyStops(ref);
  }
}

String _$nearbyStopsHash() => r'397bb25d7600f54cbbdda2b2e6bef8cb8b753b5d';

/// One call for the arrivals of the ten nearest stops (RF-03), refreshed while the list is open.

@ProviderFor(nearbyArrivals)
final nearbyArrivalsProvider = NearbyArrivalsProvider._();

/// One call for the arrivals of the ten nearest stops (RF-03), refreshed while the list is open.

final class NearbyArrivalsProvider extends $FunctionalProvider<AsyncValue<Arrivals?>, Arrivals?, FutureOr<Arrivals?>>
    with $FutureModifier<Arrivals?>, $FutureProvider<Arrivals?> {
  /// One call for the arrivals of the ten nearest stops (RF-03), refreshed while the list is open.
  NearbyArrivalsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nearbyArrivalsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nearbyArrivalsHash();

  @$internal
  @override
  $FutureProviderElement<Arrivals?> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<Arrivals?> create(Ref ref) {
    return nearbyArrivals(ref);
  }
}

String _$nearbyArrivalsHash() => r'45d69f6b4be98ab32e9f84e72d04acf85cc79dff';

/// Map or list, remembered between launches (RF-01).

@ProviderFor(NearbyMapView)
final nearbyMapViewProvider = NearbyMapViewProvider._();

/// Map or list, remembered between launches (RF-01).
final class NearbyMapViewProvider extends $NotifierProvider<NearbyMapView, bool> {
  /// Map or list, remembered between launches (RF-01).
  NearbyMapViewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nearbyMapViewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nearbyMapViewHash();

  @$internal
  @override
  NearbyMapView create() => NearbyMapView();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<bool>(value));
  }
}

String _$nearbyMapViewHash() => r'cebdb7fb7ceaaeb8d481b342c2bdb5959251628b';

/// Map or list, remembered between launches (RF-01).

abstract class _$NearbyMapView extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<bool, bool>, bool, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
