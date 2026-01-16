import 'package:keda/models/category.dart';
import 'package:keda/models/finance_account.dart';
import 'package:keda/models/monthly_summary.dart';
import 'package:keda/providers/auth_provider.dart';
import 'package:keda/providers/data_providers.dart';
import 'package:keda/views/new_expense_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import '../utils/test_utils.dart';

import '../providers_test.mocks.dart';

void main() {
  late MockApiClient mockApiClient;
  const categoryId = 'cat1';

  setUp(() {
    mockApiClient = MockApiClient();
    when(mockApiClient.householdId).thenReturn('hh1');
    when(mockApiClient.getMonthlySummary(any)).thenAnswer((_) async => MonthlySummary(
      month: '2026-01',
      totalBudget: 1000,
      totalSpent: 0,
      categories: [],
    ));
  });

  testWidgets('NewExpenseScreen shows "Crear mi primera cuenta" when no accounts exist', (tester) async {
    final categories = [Category(id: categoryId, name: 'Food', monthlyBudget: 100)];

    when(mockApiClient.getCategories()).thenAnswer((_) async => categories);
    when(mockApiClient.getAccounts()).thenAnswer((_) async => []);
    when(mockApiClient.getSuggestedNotes(categoryId)).thenAnswer((_) async => []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
          authProvider.overrideWith(() => MockAuthNotifier()),
        ],
        child: createTestApp(
          home: const NewExpenseScreen(categoryId: categoryId),
        ),
      ),
    );

    await tester.pumpAndSettle();
    
    // Wait for focus delay timer
    await tester.pump(const Duration(milliseconds: 250));

    // Verify button exists
    expect(find.text('Crear mi primera cuenta'), findsOneWidget);
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
