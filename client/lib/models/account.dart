import 'package:freezed_annotation/freezed_annotation.dart';
import 'account_type.dart';

part 'account.freezed.dart';
part 'account.g.dart';

@freezed
class Account with _$Account {
  const factory Account({
    required String id,
    required AccountType type,
    required String name,
    String? brand,
    String? bank,
    required String displayName,
  }) = _Account;

  factory Account.fromJson(Map<String, dynamic> json) => _$AccountFromJson(json);
}
