import 'package:keda/models/category.dart';
import 'package:keda/models/finance_account.dart';
import 'package:keda/models/account_type.dart';
import 'package:keda/models/expense.dart';
import 'package:keda/providers/data_providers.dart';
import 'package:keda/repositories/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'providers_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ApiClient>()])
void main() {
  group('Data Providers', () {
    late MockApiClient mockApiClient;
    late ProviderContainer container;

    setUp(() {
      mockApiClient = MockApiClient();
      container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
        ],
      );
      // Mock basic auth/householdId access if needed by provider implementation
      when(mockApiClient.householdId).thenReturn('hh1');
    });

    // ========================================================================
    // Categories
    // ========================================================================
    test('CategoriesNotifier fetches from server', () async {
      final cats = [Category(id: '1', name: 'Food', monthlyBudget: 100.0)];
      when(mockApiClient.getCategories()).thenAnswer((_) async => cats);

      final result = await container.read(categoriesProvider.future);
      expect(result, cats);
      verify(mockApiClient.getCategories()).called(1);
    });

    test('CategoriesNotifier returns empty when householdId is null', () async {
      reset(mockApiClient);
      when(mockApiClient.householdId).thenReturn(null);
      container.invalidate(categoriesProvider);
      final result = await container.read(categoriesProvider.future);
      expect(result, isEmpty);
      when(mockApiClient.householdId).thenReturn('hh1');
    });

    test('CategoriesNotifier creates category', () async {
      final newCat = Category(id: '', name: 'Test', monthlyBudget: 10.0);
      final createdCat = Category(id: '2', name: 'Test', monthlyBudget: 10.0);
      
      when(mockApiClient.getCategories()).thenAnswer((_) async => []);
      when(mockApiClient.createCategory(newCat)).thenAnswer((_) async => createdCat);

      await container.read(categoriesProvider.future);
      await container.read(categoriesProvider.notifier).createCategory(newCat);
      
      final state = await container.read(categoriesProvider.future);
      expect(state, contains(createdCat));
    });

    test('CategoriesNotifier creates category throws on error', () async {
       final newCat = Category(id: '', name: 'Test', monthlyBudget: 10.0);
       when(mockApiClient.createCategory(newCat)).thenAnswer((_) async => throw Exception('Create error'));
       expect(container.read(categoriesProvider.notifier).createCategory(newCat), throwsException);
    });

    test('CategoriesNotifier updates category', () async {
      final initialCat = Category(id: '1', name: 'Old', monthlyBudget: 10.0);
      final updatedCat = Category(id: '1', name: 'New', monthlyBudget: 20.0);
      
      when(mockApiClient.getCategories()).thenAnswer((_) async => [initialCat]);
      when(mockApiClient.updateCategory('1', updatedCat)).thenAnswer((_) async => updatedCat);

      await container.read(categoriesProvider.future);
      await container.read(categoriesProvider.notifier).updateCategory(updatedCat);

      final state = await container.read(categoriesProvider.future);
      expect(state.first.name, 'New');
    });
    
    test('CategoriesNotifier updates category throws on error', () async {
       final cat = Category(id: '1', name: 'Test', monthlyBudget: 10.0);
       when(mockApiClient.updateCategory('1', cat)).thenAnswer((_) async => throw Exception('Update error'));
       expect(container.read(categoriesProvider.notifier).updateCategory(cat), throwsException);
    });

    test('CategoriesNotifier deletes category', () async {
      final cat = Category(id: '1', name: 'Del', monthlyBudget: 10.0);
      when(mockApiClient.getCategories()).thenAnswer((_) async => [cat]);
      when(mockApiClient.deleteCategory('1')).thenAnswer((_) async {});

      await container.read(categoriesProvider.future);
      await container.read(categoriesProvider.notifier).deleteCategory('1');

      final state = await container.read(categoriesProvider.future);
      expect(state, isEmpty);
    });

    test('CategoriesNotifier deletes category throws on error', () async {
       when(mockApiClient.deleteCategory('1')).thenAnswer((_) async => throw Exception('Delete error'));
       expect(container.read(categoriesProvider.notifier).deleteCategory('1'), throwsException);
    });

    // ========================================================================
    // Accounts
    // ========================================================================
    test('AccountsNotifier fetches from server', () async {
      final accounts = [FinanceAccount(id: 'a1', name: 'Bank', type: AccountType.bank, displayName: 'Bank Account')];
      when(mockApiClient.getAccounts()).thenAnswer((_) async => accounts);

      final result = await container.read(accountsProvider.future);
      expect(result, accounts);
    });
    
    test('AccountsNotifier returns empty when householdId is null', () async {
      reset(mockApiClient);
      when(mockApiClient.householdId).thenReturn(null);
      container.invalidate(accountsProvider);
      final result = await container.read(accountsProvider.future);
      expect(result, isEmpty);
      when(mockApiClient.householdId).thenReturn('hh1');
    });

    // ========================================================================
    // Expenses
    // ========================================================================
    test('ExpensesNotifier fetches from server', () async {
      final expenses = [Expense(id: 'e1', amount: 10.0, date: DateTime.now(), categoryId: 'c1', accountId: 'a1')];
      when(mockApiClient.getTransactions(month: anyNamed('month'))).thenAnswer((_) async => expenses);

      final result = await container.read(expensesProvider.future);
      expect(result, expenses);
    });

    test('ExpensesNotifier returns empty when householdId is null', () async {
      reset(mockApiClient);
      when(mockApiClient.householdId).thenReturn(null);
      container.invalidate(expensesProvider);
      final result = await container.read(expensesProvider.future);
      expect(result, isEmpty);
      when(mockApiClient.householdId).thenReturn('hh1');
    });
  });
}
