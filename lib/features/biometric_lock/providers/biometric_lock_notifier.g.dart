// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'biometric_lock_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(biometricSupported)
final biometricSupportedProvider = BiometricSupportedProvider._();

final class BiometricSupportedProvider extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  BiometricSupportedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'biometricSupportedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$biometricSupportedHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return biometricSupported(ref);
  }
}

String _$biometricSupportedHash() => r'b53cd05377bae18ad2a1bebee911c10cc287e3af';

/// Whether the app asks for biometrics/device PIN when reopened. Persisted.

@ProviderFor(BiometricLockNotifier)
final biometricLockProvider = BiometricLockNotifierProvider._();

/// Whether the app asks for biometrics/device PIN when reopened. Persisted.
final class BiometricLockNotifierProvider extends $NotifierProvider<BiometricLockNotifier, bool> {
  /// Whether the app asks for biometrics/device PIN when reopened. Persisted.
  BiometricLockNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'biometricLockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$biometricLockNotifierHash();

  @$internal
  @override
  BiometricLockNotifier create() => BiometricLockNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<bool>(value));
  }
}

String _$biometricLockNotifierHash() => r'5a63884afdc14b803c350fe76dcdb030ba059e67';

/// Whether the app asks for biometrics/device PIN when reopened. Persisted.

abstract class _$BiometricLockNotifier extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<bool, bool>, bool, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
