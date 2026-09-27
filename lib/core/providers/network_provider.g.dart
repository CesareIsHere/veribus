// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Active network version and remote config; checked at every app start. The API needs a signed-in user,
/// so it runs again when the user changes.

@ProviderFor(networkInfo)
final networkInfoProvider = NetworkInfoProvider._();

/// Active network version and remote config; checked at every app start. The API needs a signed-in user,
/// so it runs again when the user changes.

final class NetworkInfoProvider extends $FunctionalProvider<AsyncValue<NetworkInfo>, NetworkInfo, FutureOr<NetworkInfo>>
    with $FutureModifier<NetworkInfo>, $FutureProvider<NetworkInfo> {
  /// Active network version and remote config; checked at every app start. The API needs a signed-in user,
  /// so it runs again when the user changes.
  NetworkInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkInfoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkInfoHash();

  @$internal
  @override
  $FutureProviderElement<NetworkInfo> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<NetworkInfo> create(Ref ref) {
    return networkInfo(ref);
  }
}

String _$networkInfoHash() => r'e84928efc6bc6a58eff88477cb56d24e18a9985f';

/// Stops and lines, in memory for the whole session (search and nearby run on the phone: RF-11).

@ProviderFor(network)
final networkProvider = NetworkProvider._();

/// Stops and lines, in memory for the whole session (search and nearby run on the phone: RF-11).

final class NetworkProvider extends $FunctionalProvider<AsyncValue<Network>, Network, FutureOr<Network>>
    with $FutureModifier<Network>, $FutureProvider<Network> {
  /// Stops and lines, in memory for the whole session (search and nearby run on the phone: RF-11).
  NetworkProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkHash();

  @$internal
  @override
  $FutureProviderElement<Network> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<Network> create(Ref ref) {
    return network(ref);
  }
}

String _$networkHash() => r'aab50eb3b7f6a916e979f64b8267029abc8be202';
