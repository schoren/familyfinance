// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Category _$CategoryFromJson(Map<String, dynamic> json) => Category(
  id: json['id'] as String,
  name: json['name'] as String,
  monthlyBudget: (json['monthly_budget'] as num).toDouble(),
  isActive: json['is_active'] as bool? ?? true,
);

Map<String, dynamic> _$CategoryToJson(Category instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'monthly_budget': instance.monthlyBudget,
  'is_active': instance.isActive,
};
