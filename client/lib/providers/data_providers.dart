import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../models/finance_account.dart';
import '../models/expense.dart';
import '../models/monthly_summary.dart';
import '../repositories/api_client.dart';
import '../providers/auth_provider.dart';

// ============================================================================
// API CLIENT
// ============================================================================

final apiClientProvider = Provider((ref) {
  final authState = ref.watch(authProvider);
  return ApiClient(
    baseUrl: 'http://localhost:8090',
    householdId: authState.householdId,
    authToken: authState.token,
  );
});

// ============================================================================
// CATEGORIES
// ============================================================================

class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    return _fetchFromServer();
  }

  Future<List<Category>> _fetchFromServer() async {
    final apiClient = ref.watch(apiClientProvider);
    try {
      if (apiClient.householdId == null) return [];
      return await apiClient.getCategories();
    } catch (e) {
      if (kDebugMode) print('Failed to fetch categories from server: $e');
      rethrow;
    }
  }

  Future<void> createCategory(Category category) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      final created = await apiClient.createCategory(category);
      final current = await future;
      state = AsyncData([...current, created]);
      ref.invalidate(currentMonthSummaryProvider);
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    ref.invalidate(monthlySummaryProvider(month));
    } catch (e) {
      if (kDebugMode) print('Failed to create category: $e');
      rethrow;
    }
  }

  Future<void> updateCategory(Category category) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      final updated = await apiClient.updateCategory(category.id, category);
      final current = await future;
      state = AsyncData(
        current.map((c) => c.id == updated.id ? updated : c).toList(),
      );
      ref.invalidate(currentMonthSummaryProvider);
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    ref.invalidate(monthlySummaryProvider(month));
    } catch (e) {
      if (kDebugMode) print('Failed to update category: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      await apiClient.deleteCategory(id);
      final current = await future;
      state = AsyncData(current.where((c) => c.id != id).toList());
      ref.invalidate(currentMonthSummaryProvider);
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    ref.invalidate(monthlySummaryProvider(month));
    } catch (e) {
      if (kDebugMode) print('Failed to delete category: $e');
      rethrow;
    }
  }
}

final categoriesProvider = AsyncNotifierProvider<CategoriesNotifier, List<Category>>(() {
  return CategoriesNotifier();
});

// ============================================================================
// ACCOUNTS
// ============================================================================

class AccountsNotifier extends AsyncNotifier<List<FinanceAccount>> {
  @override
  Future<List<FinanceAccount>> build() async {
    return _fetchFromServer();
  }

  Future<List<FinanceAccount>> _fetchFromServer() async {
    final apiClient = ref.watch(apiClientProvider);
    try {
      if (apiClient.householdId == null) return [];
      return await apiClient.getAccounts();
    } catch (e) {
      if (kDebugMode) print('Failed to fetch accounts from server: $e');
      rethrow;
    }
  }

  Future<void> createAccount(FinanceAccount account) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      final created = await apiClient.createAccount(account);
      final current = await future;
      state = AsyncData([...current, created]);
    } catch (e) {
      if (kDebugMode) print('Failed to create account: $e');
      rethrow;
    }
  }

  Future<void> updateAccount(FinanceAccount account) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      final updated = await apiClient.updateAccount(account.id, account);
      final current = await future;
      state = AsyncData(
        current.map((a) => a.id == updated.id ? updated : a).toList(),
      );
    } catch (e) {
      if (kDebugMode) print('Failed to update account: $e');
      rethrow;
    }
  }

  Future<void> deleteAccount(String id) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      await apiClient.deleteAccount(id);
      final current = await future;
      state = AsyncData(current.where((a) => a.id != id).toList());
      // Re-invalidate summary because account balance might affect it (though currently summary is by category)
      ref.invalidate(currentMonthSummaryProvider);
    } catch (e) {
      if (kDebugMode) print('Failed to delete account: $e');
      rethrow;
    }
  }
}

final accountsProvider = AsyncNotifierProvider<AccountsNotifier, List<FinanceAccount>>(() {
  return AccountsNotifier();
});

// ============================================================================
// EXPENSES (TRANSACTIONS)
// ============================================================================

class ExpensesNotifier extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() async {
    return _fetchFromServer();
  }

  Future<List<Expense>> _fetchFromServer() async {
    final apiClient = ref.watch(apiClientProvider);
    try {
      if (apiClient.householdId == null) return [];
      final now = DateTime.now();
      final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      return await apiClient.getTransactions(month: month);
    } catch (e) {
      if (kDebugMode) print('Failed to fetch expenses from server: $e');
      rethrow;
    }
  }

  Future<void> addExpense(Expense expense) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      final created = await apiClient.createTransaction(expense);
      final current = await future;
      state = AsyncData([...current, created]);
      final now = DateTime.now();
      final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      ref.invalidate(monthlySummaryProvider(month));
      ref.invalidate(currentMonthSummaryProvider);
    } catch (e) {
      if (kDebugMode) print('Failed to add expense: $e');
      rethrow;
    }
  }

  Future<void> updateExpense(Expense expense) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      final updated = await apiClient.updateTransaction(expense.id, expense);
      final current = await future;
      state = AsyncData(
        current.map((e) => e.id == updated.id ? updated : e).toList(),
      );
      final now = DateTime.now();
      final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      ref.invalidate(monthlySummaryProvider(month));
      ref.invalidate(currentMonthSummaryProvider);
    } catch (e) {
      if (kDebugMode) print('Failed to update expense: $e');
      rethrow;
    }
  }

  Future<void> deleteExpense(String id) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      await apiClient.deleteTransaction(id);
      final current = await future;
      state = AsyncData(current.where((e) => e.id != id).toList());
      final now = DateTime.now();
      final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      ref.invalidate(monthlySummaryProvider(month));
      ref.invalidate(currentMonthSummaryProvider);
    } catch (e) {
      if (kDebugMode) print('Failed to delete expense: $e');
      rethrow;
    }
  }
}

final expensesProvider = AsyncNotifierProvider<ExpensesNotifier, List<Expense>>(() {
  return ExpensesNotifier();
});

// ============================================================================
// MONTHLY SUMMARY
// ============================================================================

final monthlySummaryProvider = FutureProvider.family<MonthlySummary, String>((ref, month) async {
  final apiClient = ref.watch(apiClientProvider);
  if (apiClient.householdId == null) throw Exception('No household selected');
  return await apiClient.getMonthlySummary(month);
});

final currentMonthSummaryProvider = FutureProvider<MonthlySummary>((ref) async {
  final now = DateTime.now();
  final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  return ref.watch(monthlySummaryProvider(month).future);
});

// ============================================================================
// CONVENIENCE PROVIDERS
// ============================================================================

final categoryRemainingProvider = Provider.family<double, String>((ref, categoryId) {
  final summaryAsync = ref.watch(currentMonthSummaryProvider);
  return summaryAsync.maybeWhen(
    data: (summary) {
      final categorySummary = summary.categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => CategorySummary(id: '', name: '', budget: 0, spent: 0, remaining: 0),
      );
      return categorySummary.remaining;
    },
    orElse: () => 0.0,
  );
});

final monthlyTotalsProvider = Provider.autoDispose<(double budget, double spent)>((ref) {
  final summaryAsync = ref.watch(currentMonthSummaryProvider);
  return summaryAsync.maybeWhen(
    data: (summary) => (summary.totalBudget, summary.totalSpent),
    orElse: () => (0.0, 0.0),
  );
});

final serverVersionProvider = FutureProvider<String>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return await apiClient.getServerVersion();
});
