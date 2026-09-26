import 'package:emiliano_cesare_flutter_template/core/utils/app_failure.dart';
import 'package:emiliano_cesare_flutter_template/models/transactions/transaction_model.dart';
import 'package:emiliano_cesare_flutter_template/repositories/transactions/i_transactions_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// `public.transactions`, one row per transaction. Row Level Security limits
/// every query to the signed-in user's rows (supabase/migrations).
class SupabaseTransactionsRepository implements ITransactionsRepository {
  SupabaseTransactionsRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  SupabaseQueryBuilder get _table => _client.from('transactions');

  /// Keyset pagination on (date, id): stable while rows are added or removed,
  /// unlike offsets. The cursor is the last row's `date|id`.
  @override
  Future<TransactionsPage> fetchPage({String? cursor, int limit = 20, TransactionType? type}) async {
    var query = _table.select();
    if (type != null) query = query.eq('type', type.name);
    if (cursor != null) {
      final [date, id] = cursor.split('|');
      query = query.or('date.lt."$date",and(date.eq."$date",id.lt.$id)');
    }
    final rows = await query.order('date', ascending: false).order('id', ascending: false).limit(limit);
    final items = rows.map(_fromRow).toList();
    final last = items.lastOrNull;
    return (items: items, nextCursor: items.length == limit && last != null ? '${_utc(last.date)}|${last.id}' : null);
  }

  @override
  Future<List<TransactionModel>> fetchRange({required DateTime from, required DateTime to}) async {
    final rows = await _table.select().gte('date', _utc(from)).lt('date', _utc(to));
    return rows.map(_fromRow).toList();
  }

  @override
  Future<TransactionModel> fetchById(String id) async {
    final row = await _table.select().eq('id', id).maybeSingle();
    if (row == null) throw const ServerFailure(statusCode: 404);
    return _fromRow(row);
  }

  /// `user_id` defaults to `auth.uid()` in the table definition.
  @override
  Future<TransactionModel> save(TransactionModel transaction) async {
    final row = {
      'title': transaction.title,
      'amount': transaction.amount,
      'category': transaction.category.name,
      'type': transaction.type.name,
      'date': _utc(transaction.date),
      'note': transaction.note,
    };
    final saved = transaction.id.isEmpty
        ? await _table.insert(row).select().single()
        : await _table.update(row).eq('id', transaction.id).select().single();
    return _fromRow(saved);
  }

  @override
  Future<void> delete(String id) => _table.delete().eq('id', id);

  static String _utc(DateTime date) => date.toUtc().toIso8601String();

  static TransactionModel _fromRow(Map<String, dynamic> row) => TransactionModel(
    id: row['id'] as String,
    title: row['title'] as String,
    amount: (row['amount'] as num).toInt(),
    category: TransactionCategory.values.byName(row['category'] as String),
    date: DateTime.parse(row['date'] as String).toLocal(),
    note: row['note'] as String?,
  );
}
