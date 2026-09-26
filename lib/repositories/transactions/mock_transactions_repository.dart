import 'dart:math';

import 'package:emiliano_cesare_flutter_template/core/utils/app_failure.dart';
import 'package:emiliano_cesare_flutter_template/models/transactions/transaction_model.dart';
import 'package:emiliano_cesare_flutter_template/repositories/transactions/i_transactions_repository.dart';

/// In-memory transactions, seeded with a few realistic months of data.
class MockTransactionsRepository implements ITransactionsRepository {
  MockTransactionsRepository({
    this.latency = const Duration(milliseconds: 400),
    List<TransactionModel>? seed,
    DateTime? now,
  }) : _items = seed ?? _seed(now ?? DateTime.now()) {
    _nextId = _items.length;
    _sort();
  }

  final Duration latency;
  final List<TransactionModel> _items;
  late int _nextId;

  void _sort() => _items.sort((a, b) => b.date.compareTo(a.date));

  @override
  Future<TransactionsPage> fetchPage({String? cursor, int limit = 20, TransactionType? type}) async {
    await Future<void>.delayed(latency);
    final all = type == null ? _items : _items.where((t) => t.type == type).toList();
    final start = int.tryParse(cursor ?? '') ?? 0;
    final end = min(start + limit, all.length);
    return (items: all.sublist(min(start, end), end), nextCursor: end < all.length ? '$end' : null);
  }

  @override
  Future<List<TransactionModel>> fetchRange({required DateTime from, required DateTime to}) async {
    await Future<void>.delayed(latency);
    return _items.where((t) => !t.date.isBefore(from) && t.date.isBefore(to)).toList();
  }

  @override
  Future<TransactionModel> fetchById(String id) async {
    await Future<void>.delayed(latency);
    return _items.firstWhere((t) => t.id == id, orElse: () => throw const ServerFailure(statusCode: 404));
  }

  @override
  Future<TransactionModel> save(TransactionModel transaction) async {
    await Future<void>.delayed(latency);
    final saved = transaction.id.isEmpty ? transaction.copyWith(id: '${_nextId++}') : transaction;
    _items
      ..removeWhere((t) => t.id == saved.id)
      ..add(saved);
    _sort();
    return saved;
  }

  @override
  Future<void> delete(String id) async {
    await Future<void>.delayed(latency);
    _items.removeWhere((t) => t.id == id);
  }

  /// ~4 months of plausible data, deterministic so screenshots and tests are stable.
  static List<TransactionModel> _seed(DateTime now) {
    final random = Random(42);
    final items = <TransactionModel>[];
    void add(String title, TransactionCategory category, int euros, DateTime date, [String? note]) {
      if (date.isAfter(now)) return;
      items.add(
        TransactionModel(
          id: '${items.length}',
          title: title,
          amount: euros * 100 + random.nextInt(100),
          category: category,
          date: date,
          note: note,
        ),
      );
    }

    for (var m = 3; m >= 0; m--) {
      final month = DateTime(now.year, now.month - m);
      DateTime day(int d) => DateTime(month.year, month.month, d, 9 + random.nextInt(11), random.nextInt(60));
      add('Stipendio', TransactionCategory.salary, 2350, day(1));
      add('Affitto', TransactionCategory.home, 750, day(1));
      add('Bolletta luce e gas', TransactionCategory.bills, 70 + random.nextInt(60), day(10));
      add('Internet e telefono', TransactionCategory.bills, 35, day(15));
      add('Abbonamento palestra', TransactionCategory.health, 45, day(5));
      if (m.isOdd) add('Progetto freelance', TransactionCategory.freelance, 400 + random.nextInt(500), day(18));
      for (var w = 0; w < 4; w++) {
        add('Spesa al supermercato', TransactionCategory.groceries, 45 + random.nextInt(50), day(3 + w * 7));
        add(
          ['Pizzeria', 'Sushi', 'Aperitivo', 'Bar'][random.nextInt(4)],
          TransactionCategory.restaurants,
          12 + random.nextInt(40),
          day(5 + w * 7),
        );
        add(
          ['Carburante', 'Treno', 'Metro'][random.nextInt(3)],
          TransactionCategory.transport,
          10 + random.nextInt(50),
          day(2 + w * 7),
        );
      }
      add(
        ['Cinema', 'Concerto', 'Streaming'][random.nextInt(3)],
        TransactionCategory.entertainment,
        10 + random.nextInt(50),
        day(20),
      );
      add(
        ['Scarpe', 'Libri', 'Elettronica'][random.nextInt(3)],
        TransactionCategory.shopping,
        25 + random.nextInt(120),
        day(12),
      );
      if (m == 2) add('Weekend al mare', TransactionCategory.travel, 320, day(22), 'Hotel + treno');
    }
    return items;
  }
}
