// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Expense _$ExpenseFromJson(Map<String, dynamic> json) => Expense(
  id: json['id'] as String? ?? '',
  date: json['date'] == null ? DateTime.now() : DateTime.parse(json['date'] as String),
  categoryId: json['category_id'] as String? ?? '',
  accountId: json['account_id'] as String? ?? '',
  amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
  note: json['note'] as String?,
);

Map<String, dynamic> _$ExpenseToJson(Expense instance) => <String, dynamic>{
  'id': instance.id,
  'date': instance.date.toIso8601String(),
  'category_id': instance.categoryId,
  'account_id': instance.accountId,
  'amount': instance.amount,
  'note': instance.note,
};
