// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monthly_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategorySummary _$CategorySummaryFromJson(Map<String, dynamic> json) =>
    CategorySummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      budget: (json['budget'] as num?)?.toDouble() ?? 0.0,
      spent: (json['spent'] as num?)?.toDouble() ?? 0.0,
      remaining: (json['remaining'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$CategorySummaryToJson(CategorySummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'budget': instance.budget,
      'spent': instance.spent,
      'remaining': instance.remaining,
    };

MonthlySummary _$MonthlySummaryFromJson(Map<String, dynamic> json) =>
    MonthlySummary(
      month: json['month'] as String? ?? '',
      totalBudget: (json['total_budget'] as num?)?.toDouble() ?? 0.0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => CategorySummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$MonthlySummaryToJson(MonthlySummary instance) =>
    <String, dynamic>{
      'month': instance.month,
      'total_budget': instance.totalBudget,
      'total_spent': instance.totalSpent,
      'categories': instance.categories,
    };
