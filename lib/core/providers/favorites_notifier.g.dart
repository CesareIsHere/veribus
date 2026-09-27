// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorites_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Favorite stops and lines, saved only on the phone (RF-40).

@ProviderFor(FavoritesNotifier)
final favoritesProvider = FavoritesNotifierProvider._();

/// Favorite stops and lines, saved only on the phone (RF-40).
final class FavoritesNotifierProvider extends $NotifierProvider<FavoritesNotifier, Favorites> {
  /// Favorite stops and lines, saved only on the phone (RF-40).
  FavoritesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoritesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoritesNotifierHash();

  @$internal
  @override
  FavoritesNotifier create() => FavoritesNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Favorites value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<Favorites>(value));
  }
}

String _$favoritesNotifierHash() => r'0ab2ca414fc8488a9de6cbde25ad913a986b5859';

/// Favorite stops and lines, saved only on the phone (RF-40).

abstract class _$FavoritesNotifier extends $Notifier<Favorites> {
  Favorites build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Favorites, Favorites>;
    final element =
        ref.element as $ClassProviderElement<AnyNotifier<Favorites, Favorites>, Favorites, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
