// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nearby_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Where "nearby" is measured from: the live position, but a new value only after it moved [_refetchMeters] (or
/// appeared / disappeared, so the page shows the right state at once).

@ProviderFor(nearbyOrigin)
final nearbyOriginProvider = NearbyOriginProvider._();

/// Where "nearby" is measured from: the live position, but a new value only after it moved [_refetchMeters] (or
/// appeared / disappeared, so the page shows the right state at once).

final class NearbyOriginProvider extends $FunctionalProvider<AsyncValue<LatLng?>, LatLng?, Stream<LatLng?>>
    with $FutureModifier<LatLng?>, $StreamProvider<LatLng?> {
  /// Where "nearby" is measured from: the live position, but a new value only after it moved [_refetchMeters] (or
  /// appeared / disappeared, so the page shows the right state at once).
  NearbyOriginProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nearbyOriginProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nearbyOriginHash();

  @$internal
  @override
  $StreamProviderElement<LatLng?> $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<LatLng?> create(Ref ref) {
    return nearbyOrigin(ref);
  }
}

String _$nearbyOriginHash() => r'cdaf2a7e3f91e1b27507fba53f271b6a78a7edf8';

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

String _$nearbyStopsHash() => r'e8c5b51307d7659b86801109804f538b381e7b4e';

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
