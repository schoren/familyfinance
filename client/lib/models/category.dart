import 'package:json_annotation/json_annotation.dart';

part 'category.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Category {
  final String id;
  final String name;
  final double monthlyBudget;
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    required this.monthlyBudget,
    this.isActive = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryToJson(this);

  Category copyWith({
    String? id,
    String? name,
    double? monthlyBudget,
    bool? isActive,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      isActive: isActive ?? this.isActive,
    );
  }
}
