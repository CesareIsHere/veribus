// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_preferences_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loaded once in `main()` and injected with an override, so reads are sync.

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

/// Loaded once in `main()` and injected with an override, so reads are sync.

final class SharedPreferencesProvider
    extends $FunctionalProvider<SharedPreferencesWithCache, SharedPreferencesWithCache, SharedPreferencesWithCache>
    with $Provider<SharedPreferencesWithCache> {
  /// Loaded once in `main()` and injected with an override, so reads are sync.
  SharedPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $ProviderElement<SharedPreferencesWithCache> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  SharedPreferencesWithCache create(Ref ref) {
    return sharedPreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedPreferencesWithCache value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<SharedPreferencesWithCache>(value));
  }
}

String _$sharedPreferencesHash() => r'704b056ea14cd9fad057b2c8e8896f371233b27b';
