import 'package:emiliano_cesare_flutter_template/features/dashboard/providers/dashboard_providers.dart';
import 'package:emiliano_cesare_flutter_template/features/transactions/providers/transactions_providers.dart';
import 'package:emiliano_cesare_flutter_template/features/transactions/transaction_form_page.dart';
import 'package:emiliano_cesare_flutter_template/l10n/gen/app_localizations.dart';
import 'package:emiliano_cesare_flutter_template/models/transactions/month_summary.dart';
import 'package:emiliano_cesare_flutter_template/models/transactions/transaction_model.dart';
import 'package:emiliano_cesare_flutter_template/repositories/transactions/mock_transactions_repository.dart';
import 'package:emiliano_cesare_flutter_template/repositories/transactions/transactions_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionModel _t(String id, int euros, TransactionCategory category, DateTime date) =>
    TransactionModel(id: id, title: 'T$id', amount: euros * 100, category: category, date: date);

void main() {
  group('MonthSummary', () {
    test('totals, category ranking, recent first, rates', () {
      final summary = MonthSummary.from([
        _t('1', 2000, TransactionCategory.salary, DateTime(2026, 9, 27)),
        _t('2', 700, TransactionCategory.home, DateTime(2026, 9)),
        _t('3', 100, TransactionCategory.groceries, DateTime(2026, 9, 5)),
        _t('4', 200, TransactionCategory.groceries, DateTime(2026, 9, 12)),
      ], days: 30);

      expect(summary.income, 200000);
      expect(summary.expenses, 100000);
      expect(summary.balance, 100000);
      expect(summary.savingsRate, 0.5);
      expect(summary.averageDailyExpense, 100000 ~/ 30);
      expect(summary.expensesByCategory.map((e) => e.category), [
        TransactionCategory.home,
        TransactionCategory.groceries,
      ]);
      expect(summary.expensesByCategory.last.amount, 30000);
      expect(summary.recent.first.id, '1');
    });

    test('no income means no savings rate', () {
      final summary = MonthSummary.from([_t('1', 10, TransactionCategory.bills, DateTime(2026))], days: 1);
      expect(summary.savingsRate, isNull);
      expect(MonthSummary.empty.isEmpty, isTrue);
    });
  });

  group('providers', () {
    late ProviderContainer container;
    final now = DateTime(2026, 9, 20);

    setUp(() {
      final repo = MockTransactionsRepository(
        latency: Duration.zero,
        seed: [
          for (var i = 0; i < 25; i++)
            _t(
              '$i',
              10 + i,
              i.isEven ? TransactionCategory.groceries : TransactionCategory.salary,
              now.subtract(Duration(days: i)),
            ),
        ],
      );
      container = ProviderContainer(overrides: [transactionsRepositoryProvider.overrideWithValue(repo)]);
      addTearDown(container.dispose);
    });

    test('pages by cursor and filters by type', () async {
      container.listen(transactionsProvider(null), (_, _) {});
      final first = await container.read(transactionsProvider(null).future);
      expect(first.items, hasLength(20));

      await container.read(transactionsProvider(null).notifier).loadMore();
      expect(container.read(transactionsProvider(null)).requireValue.items, hasLength(25));
      expect(container.read(transactionsProvider(null)).requireValue.canLoadMore, isFalse);

      final incomes = await container.read(transactionsProvider(TransactionType.income).future);
      expect(incomes.items.every((t) => t.type == TransactionType.income), isTrue);
    });

    test('controller saves, deletes and refreshes lists and summary', () async {
      final month = DateTime(now.year, now.month);
      container
        ..listen(transactionsProvider(null), (_, _) {})
        ..listen(monthSummaryProvider(month), (_, _) {});
      final before = await container.read(monthSummaryProvider(month).future);

      final controller = container.read(transactionsControllerProvider.notifier);
      final saved = await controller.save(_t('', 50, TransactionCategory.shopping, now).copyWith(id: ''));
      expect(saved.id, isNotEmpty);
      final after = await container.read(monthSummaryProvider(month).future);
      expect(after.expenses, before.expenses + 5000);

      await controller.delete(saved);
      final list = await container.read(transactionsProvider(null).future);
      expect(list.items.any((t) => t.id == saved.id), isFalse);
    });

    test('removeLocally drops the row immediately', () async {
      container.listen(transactionsProvider(null), (_, _) {});
      final first = await container.read(transactionsProvider(null).future);
      container.read(transactionsProvider(null).notifier).removeLocally(first.items.first.id);
      expect(container.read(transactionsProvider(null)).requireValue.items, hasLength(19));
    });
  });

  testWidgets('form rejects a missing amount and description', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TransactionFormPage(),
        ),
      ),
    );
    final l10n = AppLocalizations.of(tester.element(find.byType(TransactionFormPage)));

    await tester.tap(find.text(l10n.save));
    await tester.pump();

    expect(find.text(l10n.validationAmount), findsOneWidget);
    expect(find.text(l10n.validationRequired), findsOneWidget);
  });
}
