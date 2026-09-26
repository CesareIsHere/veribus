import 'package:emiliano_cesare_flutter_template/core/utils/exception_handler.dart';
import 'package:emiliano_cesare_flutter_template/features/dashboard/providers/dashboard_providers.dart';
import 'package:emiliano_cesare_flutter_template/models/transactions/transaction_model.dart';
import 'package:emiliano_cesare_flutter_template/repositories/transactions/transactions_repository_provider.dart';
import 'package:emiliano_cesare_flutter_template/services/analytics_service.dart'; // feature:analytics
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transactions_providers.freezed.dart';
part 'transactions_providers.g.dart';

@freezed
abstract class TransactionsState with _$TransactionsState {
  const factory TransactionsState({
    required List<TransactionModel> items,
    String? nextCursor,
    @Default(false) bool loadingMore,

    /// Set when the next page failed: the list stops auto-loading until
    /// `retryLoadMore` (the first page's errors go to the AsyncValue instead).
    Object? loadMoreError,
  }) = _TransactionsState;

  const TransactionsState._();

  bool get canLoadMore => nextCursor != null && !loadingMore && loadMoreError == null;
}

/// Cursor-paginated list, one instance per filter (null = all).
/// Pattern to copy for any infinite list.
@riverpod
class TransactionsNotifier extends _$TransactionsNotifier {
  @override
  Future<TransactionsState> build(TransactionType? type) async {
    final page = await ref.watch(transactionsRepositoryProvider).fetchPage(type: type);
    return TransactionsState(items: page.items, nextCursor: page.nextCursor);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.canLoadMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final page = await ref.read(transactionsRepositoryProvider).fetchPage(cursor: current.nextCursor, type: type);
      if (!ref.mounted) return;
      state = AsyncData(current.copyWith(items: [...current.items, ...page.items], nextCursor: page.nextCursor));
    } on Object catch (e, s) {
      ExceptionHandler.report(e, s);
      if (ref.mounted) state = AsyncData(current.copyWith(loadMoreError: e));
    }
  }

  Future<void> retryLoadMore() async {
    if (state.value case final current?) {
      state = AsyncData(current.copyWith(loadMoreError: null));
      await loadMore();
    }
  }

  /// Drops the row immediately (swipe to delete); the controller deletes it for real.
  void removeLocally(String id) {
    if (state.value case final current?) {
      state = AsyncData(current.copyWith(items: current.items.where((t) => t.id != id).toList()));
    }
  }
}

@riverpod
Future<TransactionModel> transaction(Ref ref, String id) => ref.watch(transactionsRepositoryProvider).fetchById(id);

/// All writes go through here, so every screen showing transactions is
/// refreshed in one place. Kept alive: callers only `read` it, and an
/// auto-disposed controller would be gone after the first `await`.
@Riverpod(keepAlive: true)
class TransactionsController extends _$TransactionsController {
  @override
  void build() {}

  Future<TransactionModel> save(TransactionModel transaction) async {
    final saved = await ref.read(transactionsRepositoryProvider).save(transaction);
    AnalyticsService.logEvent('transaction_saved', {'type': saved.type.name}).ignore(); // feature:analytics
    _refresh();
    return saved;
  }

  Future<void> delete(TransactionModel transaction) async {
    try {
      await ref.read(transactionsRepositoryProvider).delete(transaction.id);
    } finally {
      // Also on failure: brings back a row removed optimistically.
      _refresh();
    }
  }

  void _refresh() {
    ref
      ..invalidate(transactionsProvider)
      ..invalidate(transactionProvider)
      ..invalidate(monthSummaryProvider);
  }
}
