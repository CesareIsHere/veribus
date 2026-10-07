// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The only place that knows which backend holds the followed trips.

@ProviderFor(followRepository)
final followRepositoryProvider = FollowRepositoryProvider._();

/// The only place that knows which backend holds the followed trips.

final class FollowRepositoryProvider
    extends $FunctionalProvider<IFollowRepository, IFollowRepository, IFollowRepository>
    with $Provider<IFollowRepository> {
  /// The only place that knows which backend holds the followed trips.
  FollowRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'followRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$followRepositoryHash();

  @$internal
  @override
  $ProviderElement<IFollowRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  IFollowRepository create(Ref ref) {
    return followRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IFollowRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<IFollowRepository>(value));
  }
}

String _$followRepositoryHash() => r'55d45a8424706a5dfd0afd6f279b2ba568b0eb13';
