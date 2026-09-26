// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Shared HTTP client for your REST API: bearer token, refresh on 401,
/// logging, Sentry breadcrumbs.

@ProviderFor(apiClient)
final apiClientProvider = ApiClientProvider._();

/// Shared HTTP client for your REST API: bearer token, refresh on 401,
/// logging, Sentry breadcrumbs.

final class ApiClientProvider extends $FunctionalProvider<Dio, Dio, Dio> with $Provider<Dio> {
  /// Shared HTTP client for your REST API: bearer token, refresh on 401,
  /// logging, Sentry breadcrumbs.
  ApiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiClientHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return apiClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<Dio>(value));
  }
}

String _$apiClientHash() => r'174af124891d12097e42e81ff539335253bcfb92';
