// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Account _$AccountFromJson(Map<String, dynamic> json) => _Account(
  id: json['id'] as String,
  type: $enumDecode(_$AccountTypeEnumMap, json['type']),
  name: json['name'] as String,
  brand: json['brand'] as String?,
  bank: json['bank'] as String?,
  displayName: json['displayName'] as String,
);

Map<String, dynamic> _$AccountToJson(_Account instance) => <String, dynamic>{
  'id': instance.id,
  'type': _$AccountTypeEnumMap[instance.type]!,
  'name': instance.name,
  'brand': instance.brand,
  'bank': instance.bank,
  'displayName': instance.displayName,
};

const _$AccountTypeEnumMap = {
  AccountType.cash: 'cash',
  AccountType.card: 'card',
  AccountType.bank: 'bank',
};
