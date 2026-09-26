// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payments_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Customer info (null when payments aren't available), kept in sync with the
/// signed-in user. Watched by `App` so it lives as long as the app.

@ProviderFor(PaymentsNotifier)
final paymentsProvider = PaymentsNotifierProvider._();

/// Customer info (null when payments aren't available), kept in sync with the
/// signed-in user. Watched by `App` so it lives as long as the app.
final class PaymentsNotifierProvider extends $StreamNotifierProvider<PaymentsNotifier, CustomerInfo?> {
  /// Customer info (null when payments aren't available), kept in sync with the
  /// signed-in user. Watched by `App` so it lives as long as the app.
  PaymentsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paymentsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paymentsNotifierHash();

  @$internal
  @override
  PaymentsNotifier create() => PaymentsNotifier();
}

String _$paymentsNotifierHash() => r'c0fa0ef6373cc57ad62984348a65bb062fc700b3';

/// Customer info (null when payments aren't available), kept in sync with the
/// signed-in user. Watched by `App` so it lives as long as the app.

abstract class _$PaymentsNotifier extends $StreamNotifier<CustomerInfo?> {
  Stream<CustomerInfo?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CustomerInfo?>, CustomerInfo?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CustomerInfo?>, CustomerInfo?>,
              AsyncValue<CustomerInfo?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(paymentsAvailable)
final paymentsAvailableProvider = PaymentsAvailableProvider._();

final class PaymentsAvailableProvider extends $FunctionalProvider<bool, bool, bool> with $Provider<bool> {
  PaymentsAvailableProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paymentsAvailableProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paymentsAvailableHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return paymentsAvailable(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<bool>(value));
  }
}

String _$paymentsAvailableHash() => r'b8c5333e506933a1c612609d32f84d5300fe90b8';

@ProviderFor(isPremium)
final isPremiumProvider = IsPremiumProvider._();

final class IsPremiumProvider extends $FunctionalProvider<bool, bool, bool> with $Provider<bool> {
  IsPremiumProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isPremiumProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isPremiumHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isPremium(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<bool>(value));
  }
}

String _$isPremiumHash() => r'1d68642a22afa6a5f96ca7d6df89c20b18188d8e';

@ProviderFor(currentOffering)
final currentOfferingProvider = CurrentOfferingProvider._();

final class CurrentOfferingProvider extends $FunctionalProvider<AsyncValue<Offering?>, Offering?, FutureOr<Offering?>>
    with $FutureModifier<Offering?>, $FutureProvider<Offering?> {
  CurrentOfferingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentOfferingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentOfferingHash();

  @$internal
  @override
  $FutureProviderElement<Offering?> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<Offering?> create(Ref ref) {
    return currentOffering(ref);
  }
}

String _$currentOfferingHash() => r'a0a73c90120393e47c350adf94aa7f35b18c6f79';
