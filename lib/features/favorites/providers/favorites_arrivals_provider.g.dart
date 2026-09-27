// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorites_arrivals_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Arrivals of the favorite stops and vehicles in service on the favorite lines, in one call (RF-41).

@ProviderFor(favoritesArrivals)
final favoritesArrivalsProvider = FavoritesArrivalsProvider._();

/// Arrivals of the favorite stops and vehicles in service on the favorite lines, in one call (RF-41).

final class FavoritesArrivalsProvider extends $FunctionalProvider<AsyncValue<Arrivals?>, Arrivals?, FutureOr<Arrivals?>>
    with $FutureModifier<Arrivals?>, $FutureProvider<Arrivals?> {
  /// Arrivals of the favorite stops and vehicles in service on the favorite lines, in one call (RF-41).
  FavoritesArrivalsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoritesArrivalsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoritesArrivalsHash();

  @$internal
  @override
  $FutureProviderElement<Arrivals?> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<Arrivals?> create(Ref ref) {
    return favoritesArrivals(ref);
  }
}

String _$favoritesArrivalsHash() => r'fe9296b61856f2869d7194f623a59df1c1a76f24';
