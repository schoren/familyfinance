import 'package:keda/models/expense.dart';
import 'package:keda/models/user.dart';
import 'package:keda/providers/data_providers.dart';
import 'package:keda/views/category_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keda/models/finance_account.dart';
import 'package:keda/models/category.dart';
import 'package:keda/models/account_type.dart';

class MockExpensesNotifier extends ExpensesNotifier {
  final List<Expense> data;
  MockExpensesNotifier(this.data);
  @override
  Future<List<Expense>> build() async => data;
}

class MockCategoriesNotifier extends CategoriesNotifier {
  final List<Category> data;
  MockCategoriesNotifier(this.data);
  @override
  Future<List<Category>> build() async => data;
}

class MockAccountsNotifier extends AccountsNotifier {
  final List<FinanceAccount> data;
  MockAccountsNotifier(this.data);
  @override
  Future<List<FinanceAccount>> build() async => data;
}

void main() {
  testWidgets('CategoryDetailScreen shows creator name', (tester) async {
    final now = DateTime.now();
    final categoryId = 'c1';
    final user = User(id: 'u1', name: 'Test User', email: 'test@example.com');
    final expenses = [
      Expense(
        id: 'e1',
        amount: 100.0,
        date: now,
        categoryId: categoryId,
        accountId: 'a1',
        note: 'Milk',
        user: user,
      ),
    ];
    final categories = [
      Category(id: categoryId, name: 'Food', monthlyBudget: 500),
    ];
    final accounts = [
      FinanceAccount(id: 'a1', name: 'Cash', type: AccountType.cash, displayName: 'Efectivo'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expensesProvider.overrideWith(() => MockExpensesNotifier(expenses)),
          categoriesProvider.overrideWith(() => MockCategoriesNotifier(categories)),
          accountsProvider.overrideWith(() => MockAccountsNotifier(accounts)),
        ],
        child: MaterialApp(
          home: CategoryDetailScreen(categoryId: categoryId),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);
    expect(find.textContaining('Test User'), findsOneWidget);
    expect(find.textContaining('Creado por:'), findsOneWidget);
  });

  testWidgets('CategoryDetailScreen groups expenses by day and shows time', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 14, 30); // 14:30
    final yesterday = today.subtract(const Duration(days: 1)).copyWith(hour: 10, minute: 15); // 10:15
    final categoryId = 'c1';
    
    final expenses = [
      Expense(
        id: 'e1',
        amount: 50.0,
        date: today,
        categoryId: categoryId,
        accountId: 'a1',
        note: 'Pizza',
      ),
      Expense(
        id: 'e2',
        amount: 20.0,
        date: today.add(const Duration(minutes: 30)), // 15:00
        categoryId: categoryId,
        accountId: 'a1',
        note: 'Soda',
      ),
      Expense(
        id: 'e3',
        amount: 100.0,
        date: yesterday,
        categoryId: categoryId,
        accountId: 'a1',
        note: 'Grocery',
      ),
    ];
    final categories = [
      Category(id: categoryId, name: 'Food', monthlyBudget: 500),
    ];
    final accounts = [
      FinanceAccount(id: 'a1', name: 'Cash', type: AccountType.cash, displayName: 'Efectivo'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expensesProvider.overrideWith(() => MockExpensesNotifier(expenses)),
          categoriesProvider.overrideWith(() => MockCategoriesNotifier(categories)),
          accountsProvider.overrideWith(() => MockAccountsNotifier(accounts)),
        ],
        child: MaterialApp(
          locale: const Locale('es', 'AR'),
          home: CategoryDetailScreen(categoryId: categoryId),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Check for specific notes
    expect(find.text('Pizza'), findsOneWidget);
    expect(find.text('Soda'), findsOneWidget);
    expect(find.text('Grocery'), findsOneWidget);

    // Check for times
    expect(find.textContaining('14:30'), findsOneWidget);
    expect(find.textContaining('15:00'), findsOneWidget);
    expect(find.textContaining('10:15'), findsOneWidget);

    // Verify day headers
    final headers = tester.widgetList<Text>(find.byType(Text)).where((widget) {
      return widget.style?.fontWeight == FontWeight.bold && 
             widget.style?.color != null;
    }).toList();
    // In CategoryDetailScreen, we also have the total budget amount which might match this style
    // but the headers are the ones with the primary color.
    expect(headers.length, greaterThanOrEqualTo(2));
  });
}

extension on DateTime {
  DateTime copyWith({int? hour, int? minute}) {
    return DateTime(year, month, day, hour ?? this.hour, minute ?? this.minute);
  }
}
