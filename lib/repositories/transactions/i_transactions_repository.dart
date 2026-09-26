import 'package:emiliano_cesare_flutter_template/models/transactions/transaction_model.dart';

/// Transactions of the signed-in user. Same backend switch as auth:
/// copy this folder as the starting point for your own entities.
abstract interface class ITransactionsRepository {
  /// Newest first. Pass the previous page's `nextCursor`, null for the first page.
  Future<TransactionsPage> fetchPage({String? cursor, int limit = 20, TransactionType? type});

  /// All transactions with `from <= date < to` (for summaries).
  Future<List<TransactionModel>> fetchRange({required DateTime from, required DateTime to});

  Future<TransactionModel> fetchById(String id);

  /// Creates it when `id` is empty, updates it otherwise. Returns the saved copy.
  Future<TransactionModel> save(TransactionModel transaction);

  Future<void> delete(String id);
}
