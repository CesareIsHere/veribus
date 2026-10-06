// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Tracks the device position while someone watches it, and not in the background (it stops the GPS then).

@ProviderFor(locationTracker)
final locationTrackerProvider = LocationTrackerProvider._();

/// Tracks the device position while someone watches it, and not in the background (it stops the GPS then).

final class LocationTrackerProvider extends $FunctionalProvider<LocationTracker, LocationTracker, LocationTracker>
    with $Provider<LocationTracker> {
  /// Tracks the device position while someone watches it, and not in the background (it stops the GPS then).
  LocationTrackerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationTrackerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationTrackerHash();

  @$internal
  @override
  $ProviderElement<LocationTracker> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  LocationTracker create(Ref ref) {
    return locationTracker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocationTracker value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<LocationTracker>(value));
  }
}

String _$locationTrackerHash() => r'246c3edc92f3c7f7614609ffeac38cacd085fd37';

/// Live device position, null while it is not available (the app stays usable: RF-02). It comes back by itself when
/// the user turns the GPS on or grants the permission.

@ProviderFor(position)
final positionProvider = PositionProvider._();

/// Live device position, null while it is not available (the app stays usable: RF-02). It comes back by itself when
/// the user turns the GPS on or grants the permission.

final class PositionProvider extends $FunctionalProvider<AsyncValue<LatLng?>, LatLng?, Stream<LatLng?>>
    with $FutureModifier<LatLng?>, $StreamProvider<LatLng?> {
  /// Live device position, null while it is not available (the app stays usable: RF-02). It comes back by itself when
  /// the user turns the GPS on or grants the permission.
  PositionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'positionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$positionHash();

  @$internal
  @override
  $StreamProviderElement<LatLng?> $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<LatLng?> create(Ref ref) {
    return position(ref);
  }
}

String _$positionHash() => r'50fa38356a44ab510b8d1a987061301f27bc93cf';
