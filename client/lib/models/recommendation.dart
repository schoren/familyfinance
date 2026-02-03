class Recommendation {
  final String categoryId;
  final String categoryName;
  final String action;
  final double amount;
  bool isSelected;

  Recommendation({
    required this.categoryId,
    required this.categoryName,
    required this.action,
    required this.amount,
    this.isSelected = true,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      categoryId: json['category_id'] as String,
      categoryName: json['category'] as String,
      action: json['action'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }
}
