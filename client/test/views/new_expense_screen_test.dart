import 'package:family_finance/models/category.dart';
import 'package:family_finance/models/finance_account.dart';
import 'package:family_finance/models/account_type.dart';
import 'package:family_finance/providers/auth_provider.dart';
import 'package:family_finance/providers/data_providers.dart';
import 'package:family_finance/views/new_expense_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../providers_test.mocks.dart';

void main() {
  late MockApiClient mockApiClient;
  const categoryId = 'cat1';

  setUp(() {
    mockApiClient = MockApiClient();
    when(mockApiClient.householdId).thenReturn('hh1');
  });

  testWidgets('NewExpenseScreen shows autocomplete suggestions and selects one', (tester) async {
    final suggestions = ['Milk', 'Bread', 'Eggs'];
    final categories = [Category(id: categoryId, name: 'Food', monthlyBudget: 100)];
    final accounts = [FinanceAccount(id: 'acc1', name: 'Cash', type: AccountType.cash, displayName: 'Cash')];

    when(mockApiClient.getCategories()).thenAnswer((_) async => categories);
    when(mockApiClient.getAccounts()).thenAnswer((_) async => accounts);
    when(mockApiClient.getSuggestedNotes(categoryId)).thenAnswer((_) async => suggestions);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
          authProvider.overrideWith(() => MockAuthNotifier()),
        ],
        child: const MaterialApp(
          home: NewExpenseScreen(categoryId: categoryId),
        ),
      ),
    );

    // Initial load
    await tester.pumpAndSettle();

    // Find the note field by label
    final noteField = find.widgetWithText(TextFormField, 'Nota (opcional)');
    expect(noteField, findsOneWidget);

    // Enter some text to trigger autocomplete
    await tester.enterText(noteField, 'M');
    await tester.pumpAndSettle();

    // Verify suggestions appear
    expect(find.text('Milk'), findsOneWidget);
    
    // Select a suggestion
    await tester.tap(find.text('Milk'));
    await tester.pumpAndSettle();

    // Verify field is updated
    expect(find.text('Milk'), findsOneWidget);
    
    // Ensure manual entry still works
    await tester.enterText(noteField, 'Custom Note');
    await tester.pumpAndSettle();
    expect(find.text('Custom Note'), findsOneWidget);
  });
}

class MockAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    return AuthState(
      isAuthenticated: true,
      userId: 'user1',
      userName: 'Test User',
      userEmail: 'test@example.com',
      householdId: 'hh1',
    );
  }
}
