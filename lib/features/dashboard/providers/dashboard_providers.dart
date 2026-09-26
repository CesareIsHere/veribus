import 'package:emiliano_cesare_flutter_template/models/transactions/month_summary.dart';
import 'package:emiliano_cesare_flutter_template/repositories/transactions/transactions_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_providers.g.dart';

/// First day of the month shown by the dashboard.
@riverpod
class SelectedMonth extends _$SelectedMonth {
  @override
  DateTime build() => _thisMonth();

  static DateTime _thisMonth() => DateTime(DateTime.now().year, DateTime.now().month);

  /// The future isn't browsable.
  bool get canGoNext => state.isBefore(_thisMonth());

  void previous() => state = DateTime(state.year, state.month - 1);

  void next() {
    if (canGoNext) state = DateTime(state.year, state.month + 1);
  }
}

@riverpod
Future<MonthSummary> monthSummary(Ref ref, DateTime month) async {
  final end = DateTime(month.year, month.month + 1);
  final transactions = await ref.watch(transactionsRepositoryProvider).fetchRange(from: month, to: end);
  final now = DateTime.now();
  final days = now.isBefore(end) ? now.day : end.subtract(const Duration(days: 1)).day;
  return MonthSummary.from(transactions, days: days);
}
