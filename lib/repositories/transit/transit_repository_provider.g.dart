// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transit_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The only place that knows which backend is active.

@ProviderFor(transitRepository)
final transitRepositoryProvider = TransitRepositoryProvider._();

/// The only place that knows which backend is active.

final class TransitRepositoryProvider
    extends $FunctionalProvider<ITransitRepository, ITransitRepository, ITransitRepository>
    with $Provider<ITransitRepository> {
  /// The only place that knows which backend is active.
  TransitRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transitRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transitRepositoryHash();

  @$internal
  @override
  $ProviderElement<ITransitRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ITransitRepository create(Ref ref) {
    return transitRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ITransitRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ITransitRepository>(value));
  }
}

String _$transitRepositoryHash() => r'478455a66e14aec92afd3d200514fe09d4aec088';
