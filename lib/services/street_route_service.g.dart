// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'street_route_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(streetRouteService)
final streetRouteServiceProvider = StreetRouteServiceProvider._();

final class StreetRouteServiceProvider
    extends $FunctionalProvider<StreetRouteService, StreetRouteService, StreetRouteService>
    with $Provider<StreetRouteService> {
  StreetRouteServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'streetRouteServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$streetRouteServiceHash();

  @$internal
  @override
  $ProviderElement<StreetRouteService> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  StreetRouteService create(Ref ref) {
    return streetRouteService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StreetRouteService value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<StreetRouteService>(value));
  }
}

String _$streetRouteServiceHash() => r'db9256b5233b2eebb6e847cd488121a3006d8edb';
