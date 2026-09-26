import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_model.freezed.dart';
part 'transaction_model.g.dart';

enum TransactionType { income, expense }

/// The category decides the type, so a transaction can't be inconsistent.
enum TransactionCategory {
  salary(TransactionType.income),
  freelance(TransactionType.income),
  gift(TransactionType.income),
  otherIncome(TransactionType.income),
  groceries(TransactionType.expense),
  restaurants(TransactionType.expense),
  transport(TransactionType.expense),
  home(TransactionType.expense),
  bills(TransactionType.expense),
  health(TransactionType.expense),
  entertainment(TransactionType.expense),
  shopping(TransactionType.expense),
  travel(TransactionType.expense),
  otherExpense(TransactionType.expense);

  TransactionCategory(this.type);

  final TransactionType type;

  static List<TransactionCategory> of(TransactionType type) => values.where((c) => c.type == type).toList();
}

@freezed
abstract class TransactionModel with _$TransactionModel {
  const factory TransactionModel({
    /// Empty for a transaction not saved yet.
    required String id,
    required String title,

    /// Always positive, in cents: the sign comes from [type].
    required int amount,
    required TransactionCategory category,
    required DateTime date,
    String? note,
  }) = _TransactionModel;

  const TransactionModel._();

  factory TransactionModel.fromJson(Map<String, dynamic> json) => _$TransactionModelFromJson(json);

  TransactionType get type => category.type;

  /// Positive for income, negative for expenses.
  int get signedAmount => type == TransactionType.income ? amount : -amount;
}

/// One page of a cursor-paginated list.
typedef TransactionsPage = ({List<TransactionModel> items, String? nextCursor});
