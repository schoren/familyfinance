import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'expense.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Expense {
  final String id;
  final DateTime date;
  final String categoryId;
  final String accountId;
  final String? userId;
  final User? user;
  final double amount;
  final String? note;

  Expense({
    required this.id,
    required this.date,
    required this.categoryId,
    required this.accountId,
    this.userId,
    this.user,
    required this.amount,
    this.note,
  });

  factory Expense.fromJson(Map<String, dynamic> json) => _$ExpenseFromJson(json);
  Map<String, dynamic> toJson() {
    final map = _$ExpenseToJson(this);
    if (date.isUtc) {
      map['date'] = date.toIso8601String();
    } else {
      final offset = date.timeZoneOffset;
      final sign = offset.isNegative ? '-' : '+';
      final hours = offset.inHours.abs().toString().padLeft(2, '0');
      final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
      map['date'] = '${date.toIso8601String()}$sign$hours:$minutes';
    }
    return map;
  }

  Expense copyWith({
    String? id,
    DateTime? date,
    String? categoryId,
    String? accountId,
    String? userId,
    User? user,
    double? amount,
    String? note,
  }) {
    return Expense(
      id: id ?? this.id,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      userId: userId ?? this.userId,
      user: user ?? this.user,
      amount: amount ?? this.amount,
      note: note ?? this.note,
    );
  }
}
