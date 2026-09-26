// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TransactionModel _$TransactionModelFromJson(Map<String, dynamic> json) => _TransactionModel(
  id: json['id'] as String,
  title: json['title'] as String,
  amount: (json['amount'] as num).toInt(),
  category: $enumDecode(_$TransactionCategoryEnumMap, json['category']),
  date: DateTime.parse(json['date'] as String),
  note: json['note'] as String?,
);

Map<String, dynamic> _$TransactionModelToJson(_TransactionModel instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'amount': instance.amount,
  'category': _$TransactionCategoryEnumMap[instance.category]!,
  'date': instance.date.toIso8601String(),
  'note': instance.note,
};

const _$TransactionCategoryEnumMap = {
  TransactionCategory.salary: 'salary',
  TransactionCategory.freelance: 'freelance',
  TransactionCategory.gift: 'gift',
  TransactionCategory.otherIncome: 'otherIncome',
  TransactionCategory.groceries: 'groceries',
  TransactionCategory.restaurants: 'restaurants',
  TransactionCategory.transport: 'transport',
  TransactionCategory.home: 'home',
  TransactionCategory.bills: 'bills',
  TransactionCategory.health: 'health',
  TransactionCategory.entertainment: 'entertainment',
  TransactionCategory.shopping: 'shopping',
  TransactionCategory.travel: 'travel',
  TransactionCategory.otherExpense: 'otherExpense',
};
