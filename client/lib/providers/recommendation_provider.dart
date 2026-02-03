import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recommendation.dart';
import 'data_providers.dart';

class RecommendationState {
  final List<Recommendation> recommendations;
  final bool isDismissed;
  final bool isLoading;

  RecommendationState({
    required this.recommendations,
    required this.isDismissed,
    this.isLoading = false,
  });

  RecommendationState copyWith({
    List<Recommendation>? recommendations,
    bool? isDismissed,
    bool? isLoading,
  }) {
    return RecommendationState(
      recommendations: recommendations ?? this.recommendations,
      isDismissed: isDismissed ?? this.isDismissed,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class RecommendationNotifier extends Notifier<RecommendationState> {
  @override
  RecommendationState build() {
    Future.microtask(() => _init());
    return RecommendationState(recommendations: [], isDismissed: false, isLoading: true);
  }

  Future<void> _init() async {
    // Current state is already isLoading: true from build()
    
    final now = DateTime.now();
    // Only show during first 2 weeks
    if (now.day > 14) {
      state = state.copyWith(recommendations: [], isDismissed: true, isLoading: false);
      return;
    }

    final monthKey = '${now.year}-${now.month}';
    final prefs = await SharedPreferences.getInstance();
    final dismissedMonth = prefs.getString('recommendations_dismissed_month');

    if (dismissedMonth == monthKey) {
      state = state.copyWith(isDismissed: true);
    }

    await fetchRecommendations();
    state = state.copyWith(isLoading: false);
  }

  Future<void> fetchRecommendations() async {
    final apiClient = ref.read(apiClientProvider);
    if (apiClient.householdId == null) return;

    try {
      final recommendations = await apiClient.getRecommendations();
      state = state.copyWith(recommendations: recommendations);
    } catch (e) {
      // Log or handle error
    }
  }

  void dismiss() async {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month}';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('recommendations_dismissed_month', monthKey);
    state = state.copyWith(isDismissed: true);
  }

  void toggleSelection(int index) {
    final updated = List<Recommendation>.from(state.recommendations);
    final rec = updated[index];
    updated[index] = Recommendation(
      categoryId: rec.categoryId,
      categoryName: rec.categoryName,
      action: rec.action,
      amount: rec.amount,
      isSelected: !rec.isSelected,
    );
    state = state.copyWith(recommendations: updated);
  }

  Future<void> applyRecommendations() async {
    final categoriesNotifier = ref.read(categoriesProvider.notifier);
    final categories = await ref.read(categoriesProvider.future);
    
    final selected = state.recommendations.where((r) => r.isSelected).toList();
    
    for (var rec in selected) {
      final categoryIndex = categories.indexWhere((c) => c.id == rec.categoryId);
      if (categoryIndex != -1) {
        final category = categories[categoryIndex];
        final updatedCategory = category.copyWith(monthlyBudget: rec.amount);
        await categoriesNotifier.updateCategory(updatedCategory);
      }
    }
    
    dismiss();
  }
}

final recommendationProvider =
    NotifierProvider<RecommendationNotifier, RecommendationState>(() {
  return RecommendationNotifier();
});
