// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finance_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FinanceAccount _$FinanceAccountFromJson(Map<String, dynamic> json) =>
    FinanceAccount(
      id: json['id'] as String? ?? '',
      type: $enumDecodeNullable(_$AccountTypeEnumMap, json['type']) ?? AccountType.cash,
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String?,
      bank: json['bank'] as String?,
      displayName: json['display_name'] as String? ?? json['name'] as String? ?? 'Cuenta sin nombre',
    );

Map<String, dynamic> _$FinanceAccountToJson(FinanceAccount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$AccountTypeEnumMap[instance.type]!,
      'name': instance.name,
      'brand': instance.brand,
      'bank': instance.bank,
      'display_name': instance.displayName,
    };

const _$AccountTypeEnumMap = {
  AccountType.cash: 'cash',
  AccountType.card: 'card',
  AccountType.bank: 'bank',
};
