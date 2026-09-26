// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payments_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(paymentsRepository)
final paymentsRepositoryProvider = PaymentsRepositoryProvider._();

final class PaymentsRepositoryProvider
    extends $FunctionalProvider<PaymentsRepository, PaymentsRepository, PaymentsRepository>
    with $Provider<PaymentsRepository> {
  PaymentsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paymentsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paymentsRepositoryHash();

  @$internal
  @override
  $ProviderElement<PaymentsRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  PaymentsRepository create(Ref ref) {
    return paymentsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PaymentsRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<PaymentsRepository>(value));
  }
}

String _$paymentsRepositoryHash() => r'd28c4b601600809523e17dd0e1038084582c526c';
