import 'package:emiliano_cesare_flutter_template/models/transactions/transaction_model.dart';

/// Totals of one month, computed from its transactions (amounts in cents).
class MonthSummary {
  const MonthSummary({
    required this.income,
    required this.expenses,
    required this.expensesByCategory,
    required this.recent,
    required this.days,
  });

  /// [days] is how many days of the month have passed (all of them for past months).
  factory MonthSummary.from(List<TransactionModel> transactions, {required int days, int recentCount = 5}) {
    var income = 0;
    var expenses = 0;
    final byCategory = <TransactionCategory, int>{};
    for (final t in transactions) {
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expenses += t.amount;
        byCategory.update(t.category, (v) => v + t.amount, ifAbsent: () => t.amount);
      }
    }
    final sorted = [...transactions]..sort((a, b) => b.date.compareTo(a.date));
    return MonthSummary(
      income: income,
      expenses: expenses,
      expensesByCategory: byCategory.entries.map((e) => (category: e.key, amount: e.value)).toList()
        ..sort((a, b) => b.amount.compareTo(a.amount)),
      recent: sorted.take(recentCount).toList(),
      days: days,
    );
  }

  static const empty = MonthSummary(income: 0, expenses: 0, expensesByCategory: [], recent: [], days: 1);

  final int income;
  final int expenses;

  /// Biggest spending first.
  final List<({TransactionCategory category, int amount})> expensesByCategory;
  final List<TransactionModel> recent;
  final int days;

  int get balance => income - expenses;

  bool get isEmpty => income == 0 && expenses == 0;

  /// Share of income not spent (0.25 = 25%); null without income.
  double? get savingsRate => income == 0 ? null : balance / income;

  int get averageDailyExpense => days <= 0 ? 0 : expenses ~/ days;
}
