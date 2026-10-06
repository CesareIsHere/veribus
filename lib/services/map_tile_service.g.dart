// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_tile_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mapTileService)
final mapTileServiceProvider = MapTileServiceProvider._();

final class MapTileServiceProvider extends $FunctionalProvider<MapTileService, MapTileService, MapTileService>
    with $Provider<MapTileService> {
  MapTileServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapTileServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapTileServiceHash();

  @$internal
  @override
  $ProviderElement<MapTileService> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  MapTileService create(Ref ref) {
    return mapTileService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MapTileService value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<MapTileService>(value));
  }
}

String _$mapTileServiceHash() => r'579d05dc380c65ee87cad298fd0be9b0f27c43a8';

/// The tile sources of the map. Without network the first time there is no map yet: look again until there is.

@ProviderFor(mapTiles)
final mapTilesProvider = MapTilesProvider._();

/// The tile sources of the map. Without network the first time there is no map yet: look again until there is.

final class MapTilesProvider
    extends $FunctionalProvider<AsyncValue<TileProviders>, TileProviders, FutureOr<TileProviders>>
    with $FutureModifier<TileProviders>, $FutureProvider<TileProviders> {
  /// The tile sources of the map. Without network the first time there is no map yet: look again until there is.
  MapTilesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapTilesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapTilesHash();

  @$internal
  @override
  $FutureProviderElement<TileProviders> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<TileProviders> create(Ref ref) {
    return mapTiles(ref);
  }
}

String _$mapTilesHash() => r'edbd6da24f8d5d56721ee42c70b8e8b427f025d9';
