import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../models/finance_account.dart';
import '../models/expense.dart';
import '../models/monthly_summary.dart';
import '../repositories/api_client.dart';
import '../providers/auth_provider.dart';
import '../core/runtime_config.dart';
import '../core/update_logic.dart';

// ============================================================================
// API CLIENT
// ============================================================================

final apiClientProvider = Provider((ref) {
  final authState = ref.watch(authProvider);
  return ApiClient(
    baseUrl: RuntimeConfig.apiUrl,
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

  Future<Category> createCategory(Category category) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      final created = await apiClient.createCategory(category);
      final current = await future;
      state = AsyncData([...current, created]);
      ref.invalidate(currentMonthSummaryProvider);
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    ref.invalidate(monthlySummaryProvider(month));
    return created;
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

  Future<FinanceAccount> createAccount(FinanceAccount account) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      final created = await apiClient.createAccount(account);
      final current = await future;
      state = AsyncData([...current, created]);
      return created;
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
    await apiClient.createTransaction(expense);
    _refreshAll(expense.categoryId);
  }

  Future<void> updateExpense(Expense expense) async {
    final apiClient = ref.read(apiClientProvider);
    await apiClient.updateTransaction(expense.id, expense);
    _refreshAll(expense.categoryId);
  }

  Future<void> deleteExpense(String id) async {
    final apiClient = ref.read(apiClientProvider);
    await apiClient.deleteTransaction(id);
    _refreshAll();
  }

  void _refreshAll([String? categoryId]) {
    ref.invalidateSelf();
    ref.invalidate(currentMonthSummaryProvider);
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    ref.invalidate(monthlySummaryProvider(month));
    if (categoryId != null) {
      ref.invalidate(suggestedNotesProvider(categoryId));
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

final suggestedNotesProvider = FutureProvider.family<List<String>, String>((ref, categoryId) async {
  final apiClient = ref.watch(apiClientProvider);
  if (apiClient.householdId == null) return [];
  return await apiClient.getSuggestedNotes(categoryId);
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

// ============================================================================
// VERSION CHECK
// ============================================================================

enum UpdateState { upToDate, updateAvailable }

class VersionCheckNotifier extends AsyncNotifier<UpdateState> with WidgetsBindingObserver {
  @override
  Future<UpdateState> build() async {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));

    // Check once at startup
    return await _checkWebVersion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkWebVersion();
    }
  }

  Future<UpdateState> _checkWebVersion() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final serverVersion = await apiClient.getServerVersion();
      final currentVersion = RuntimeConfig.appVersion;

      if (kDebugMode) {
        print('Version check: current=$currentVersion, server=$serverVersion');
      }

      if (serverVersion != currentVersion && currentVersion != 'local-dev') {
        if (kDebugMode) print('Update detected! Forcing auto-reload...');
        forceAppUpdate();
        state = const AsyncData(UpdateState.updateAvailable);
        return UpdateState.updateAvailable;
      }
    } catch (e) {
      if (kDebugMode) print('Failed to check version: $e');
    }
    
    // We don't want to overwrite updateAvailable if a check fails later
    if (state.value == UpdateState.updateAvailable) {
      return UpdateState.updateAvailable;
    }

    state = const AsyncData(UpdateState.upToDate);
    return UpdateState.upToDate;
  }
}

final versionCheckProvider = AsyncNotifierProvider<VersionCheckNotifier, UpdateState>(() {
  return VersionCheckNotifier();
});
