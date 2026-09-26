import 'dart:convert';

import 'package:emiliano_cesare_flutter_template/core/utils/app_failure.dart';
import 'package:emiliano_cesare_flutter_template/models/transactions/transaction_model.dart';
import 'package:emiliano_cesare_flutter_template/repositories/transactions/supabase_transactions_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late List<http.Request> requests;
  late List<Map<String, dynamic>> rows;
  late SupabaseClient client;
  late SupabaseTransactionsRepository repo;

  Map<String, dynamic> row(String id, DateTime date) => {
    'id': id,
    'title': 'T$id',
    'amount': 1250,
    'category': 'groceries',
    'type': 'expense',
    'date': date.toUtc().toIso8601String(),
    'note': null,
  };

  setUp(() {
    requests = [];
    rows = [];
    client = SupabaseClient(
      'https://test.supabase.co',
      'sb_publishable_test',
      httpClient: MockClient((request) async {
        requests.add(request);
        // `.single()` asks PostgREST for one object instead of a list.
        final single = request.headers['Accept']?.contains('vnd.pgrst.object') ?? false;
        return http.Response(
          jsonEncode(single ? rows.single : rows),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    repo = SupabaseTransactionsRepository(client: client);
  });
  tearDown(() => client.dispose());

  test('pages newest first with a (date, id) cursor', () async {
    final a = DateTime.utc(2026, 9, 20);
    final b = DateTime.utc(2026, 9, 18, 10, 30);
    rows = [row('a', a), row('b', b)];

    final first = await repo.fetchPage(limit: 2, type: TransactionType.expense);
    final params = requests.single.url.queryParameters;
    expect(params['order'], 'date.desc.nullslast,id.desc.nullslast');
    expect(params['limit'], '2');
    expect(params['type'], 'eq.expense');
    expect(first.items.map((t) => t.id), ['a', 'b']);
    expect(first.nextCursor, '${b.toIso8601String()}|b');

    rows = [row('c', DateTime.utc(2026, 9))];
    final second = await repo.fetchPage(cursor: first.nextCursor, limit: 2);
    final date = b.toIso8601String();
    expect(requests.last.url.queryParameters['or'], '(date.lt."$date",and(date.eq."$date",id.lt.b))');
    expect(second.nextCursor, isNull);
  });

  test('fetchById maps a missing row to a 404', () {
    expect(repo.fetchById('missing'), throwsA(isA<ServerFailure>().having((f) => f.statusCode, 'statusCode', 404)));
  });

  test('save inserts without an id and returns the stored row', () async {
    final date = DateTime.utc(2026, 9, 26);
    rows = [row('new-id', date)];
    final saved = await repo.save(
      TransactionModel(id: '', title: 'Tnew-id', amount: 1250, category: TransactionCategory.groceries, date: date),
    );

    final request = requests.single;
    expect(request.method, 'POST');
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    expect(body.containsKey('id'), isFalse);
    expect(body['type'], 'expense');
    expect(saved.id, 'new-id');
  });
}
