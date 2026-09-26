// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transactions_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Cursor-paginated list, one instance per filter (null = all).
/// Pattern to copy for any infinite list.

@ProviderFor(TransactionsNotifier)
final transactionsProvider = TransactionsNotifierFamily._();

/// Cursor-paginated list, one instance per filter (null = all).
/// Pattern to copy for any infinite list.
final class TransactionsNotifierProvider extends $AsyncNotifierProvider<TransactionsNotifier, TransactionsState> {
  /// Cursor-paginated list, one instance per filter (null = all).
  /// Pattern to copy for any infinite list.
  TransactionsNotifierProvider._({
    required TransactionsNotifierFamily super.from,
    required TransactionType? super.argument,
  }) : super(
         retry: null,
         name: r'transactionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$transactionsNotifierHash();

  @override
  String toString() {
    return r'transactionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TransactionsNotifier create() => TransactionsNotifier();

  @override
  bool operator ==(Object other) {
    return other is TransactionsNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$transactionsNotifierHash() => r'8c1519137ceff4723c0658b245d418dd579b1163';

/// Cursor-paginated list, one instance per filter (null = all).
/// Pattern to copy for any infinite list.

final class TransactionsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          TransactionsNotifier,
          AsyncValue<TransactionsState>,
          TransactionsState,
          FutureOr<TransactionsState>,
          TransactionType?
        > {
  TransactionsNotifierFamily._()
    : super(
        retry: null,
        name: r'transactionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Cursor-paginated list, one instance per filter (null = all).
  /// Pattern to copy for any infinite list.

  TransactionsNotifierProvider call(TransactionType? type) =>
      TransactionsNotifierProvider._(argument: type, from: this);

  @override
  String toString() => r'transactionsProvider';
}

/// Cursor-paginated list, one instance per filter (null = all).
/// Pattern to copy for any infinite list.

abstract class _$TransactionsNotifier extends $AsyncNotifier<TransactionsState> {
  late final _$args = ref.$arg as TransactionType?;
  TransactionType? get type => _$args;

  FutureOr<TransactionsState> build(TransactionType? type);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<TransactionsState>, TransactionsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TransactionsState>, TransactionsState>,
              AsyncValue<TransactionsState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(transaction)
final transactionProvider = TransactionFamily._();

final class TransactionProvider
    extends $FunctionalProvider<AsyncValue<TransactionModel>, TransactionModel, FutureOr<TransactionModel>>
    with $FutureModifier<TransactionModel>, $FutureProvider<TransactionModel> {
  TransactionProvider._({required TransactionFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'transactionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionHash();

  @override
  String toString() {
    return r'transactionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TransactionModel> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<TransactionModel> create(Ref ref) {
    final argument = this.argument as String;
    return transaction(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TransactionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$transactionHash() => r'61e3258ee8629f6bed75e88db76368316ae12335';

final class TransactionFamily extends $Family with $FunctionalFamilyOverride<FutureOr<TransactionModel>, String> {
  TransactionFamily._()
    : super(
        retry: null,
        name: r'transactionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TransactionProvider call(String id) => TransactionProvider._(argument: id, from: this);

  @override
  String toString() => r'transactionProvider';
}

/// All writes go through here, so every screen showing transactions is
/// refreshed in one place. Kept alive: callers only `read` it, and an
/// auto-disposed controller would be gone after the first `await`.

@ProviderFor(TransactionsController)
final transactionsControllerProvider = TransactionsControllerProvider._();

/// All writes go through here, so every screen showing transactions is
/// refreshed in one place. Kept alive: callers only `read` it, and an
/// auto-disposed controller would be gone after the first `await`.
final class TransactionsControllerProvider extends $NotifierProvider<TransactionsController, void> {
  /// All writes go through here, so every screen showing transactions is
  /// refreshed in one place. Kept alive: callers only `read` it, and an
  /// auto-disposed controller would be gone after the first `await`.
  TransactionsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionsControllerHash();

  @$internal
  @override
  TransactionsController create() => TransactionsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<void>(value));
  }
}

String _$transactionsControllerHash() => r'198cd3bb1cfdf7b202cbc03eeeb3c0da4b74c7ef';

/// All writes go through here, so every screen showing transactions is
/// refreshed in one place. Kept alive: callers only `read` it, and an
/// auto-disposed controller would be gone after the first `await`.

abstract class _$TransactionsController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<void, void>, void, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
