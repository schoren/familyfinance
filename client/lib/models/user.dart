import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class User {
  final String id;
  final String name;
  final String email;
  final String? pictureUrl;
  final String? color;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.pictureUrl,
    this.color,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
