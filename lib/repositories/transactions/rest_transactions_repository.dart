import 'package:dio/dio.dart';
import 'package:emiliano_cesare_flutter_template/models/transactions/transaction_model.dart';
import 'package:emiliano_cesare_flutter_template/repositories/transactions/i_transactions_repository.dart';
import 'package:emiliano_cesare_flutter_template/services/api/endpoints.dart';

/// Contract: docs/BACKEND_API.md
class RestTransactionsRepository implements ITransactionsRepository {
  RestTransactionsRepository(this._api);

  final Dio _api;

  @override
  Future<TransactionsPage> fetchPage({String? cursor, int limit = 20, TransactionType? type}) async {
    final res = await _api.get<Map<String, dynamic>>(
      Endpoints.transactions,
      queryParameters: {'limit': limit, 'cursor': ?cursor, 'type': ?type?.name},
    );
    return (items: _list(res.data!['data']), nextCursor: res.data!['nextCursor'] as String?);
  }

  @override
  Future<List<TransactionModel>> fetchRange({required DateTime from, required DateTime to}) async {
    final res = await _api.get<Map<String, dynamic>>(
      Endpoints.transactions,
      queryParameters: {'from': from.toUtc().toIso8601String(), 'to': to.toUtc().toIso8601String(), 'limit': 1000},
    );
    return _list(res.data!['data']);
  }

  @override
  Future<TransactionModel> fetchById(String id) async {
    final res = await _api.get<Map<String, dynamic>>(Endpoints.transaction(id));
    return TransactionModel.fromJson(res.data!);
  }

  @override
  Future<TransactionModel> save(TransactionModel transaction) async {
    final body = transaction.toJson()..remove('id');
    final res = transaction.id.isEmpty
        ? await _api.post<Map<String, dynamic>>(Endpoints.transactions, data: body)
        : await _api.put<Map<String, dynamic>>(Endpoints.transaction(transaction.id), data: body);
    return TransactionModel.fromJson(res.data!);
  }

  @override
  Future<void> delete(String id) => _api.delete<void>(Endpoints.transaction(id));

  static List<TransactionModel> _list(Object? data) => [
    for (final json in data! as List<dynamic>) TransactionModel.fromJson(json as Map<String, dynamic>),
  ];
}
