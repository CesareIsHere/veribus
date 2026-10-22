// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'walking_route_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(walkingRouteService)
final walkingRouteServiceProvider = WalkingRouteServiceProvider._();

final class WalkingRouteServiceProvider
    extends $FunctionalProvider<WalkingRouteService, WalkingRouteService, WalkingRouteService>
    with $Provider<WalkingRouteService> {
  WalkingRouteServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walkingRouteServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walkingRouteServiceHash();

  @$internal
  @override
  $ProviderElement<WalkingRouteService> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  WalkingRouteService create(Ref ref) {
    return walkingRouteService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WalkingRouteService value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<WalkingRouteService>(value));
  }
}

String _$walkingRouteServiceHash() => r'd3bb7a2ac35c77a2d29ff1426492eff8b2677ad7';
