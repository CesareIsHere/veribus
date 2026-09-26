// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transactions_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(transactionsRepository)
final transactionsRepositoryProvider = TransactionsRepositoryProvider._();

final class TransactionsRepositoryProvider
    extends $FunctionalProvider<ITransactionsRepository, ITransactionsRepository, ITransactionsRepository>
    with $Provider<ITransactionsRepository> {
  TransactionsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ITransactionsRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ITransactionsRepository create(Ref ref) {
    return transactionsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ITransactionsRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ITransactionsRepository>(value));
  }
}

String _$transactionsRepositoryHash() => r'bb06c30cfe3ca2871f7330bc76a64393b3ca305e';
