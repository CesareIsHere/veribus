// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journeys_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The only place that knows which backend is active.

@ProviderFor(journeysRepository)
final journeysRepositoryProvider = JourneysRepositoryProvider._();

/// The only place that knows which backend is active.

final class JourneysRepositoryProvider
    extends $FunctionalProvider<IJourneysRepository, IJourneysRepository, IJourneysRepository>
    with $Provider<IJourneysRepository> {
  /// The only place that knows which backend is active.
  JourneysRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journeysRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journeysRepositoryHash();

  @$internal
  @override
  $ProviderElement<IJourneysRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  IJourneysRepository create(Ref ref) {
    return journeysRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IJourneysRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<IJourneysRepository>(value));
  }
}

String _$journeysRepositoryHash() => r'8e1db4baff7fc7c7c416c79a73cb344251384f50';
