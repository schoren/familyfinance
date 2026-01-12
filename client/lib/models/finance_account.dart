import 'package:json_annotation/json_annotation.dart';
import 'account_type.dart';

part 'finance_account.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class FinanceAccount {
  final String id;
  final AccountType type;
  final String name;
  final String? brand;
  final String? bank;
  final String displayName;

  FinanceAccount({
    required this.id,
    required this.type,
    required this.name,
    this.brand,
    this.bank,
    required this.displayName,
  });

  factory FinanceAccount.fromJson(Map<String, dynamic> json) => _$FinanceAccountFromJson(json);
  Map<String, dynamic> toJson() => _$FinanceAccountToJson(this);
}
