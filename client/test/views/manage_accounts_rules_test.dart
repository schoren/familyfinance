import 'package:keda/models/finance_account.dart';
import 'package:keda/models/account_type.dart';
import 'package:keda/providers/data_providers.dart';
import 'package:keda/views/manage_accounts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../utils/test_utils.dart';

class MockAccountsNotifier extends AccountsNotifier {
  final List<FinanceAccount> data;
  MockAccountsNotifier(this.data);
  @override
  Future<List<FinanceAccount>> build() async => data;
}

void main() {
  testWidgets('ManageAccountsScreen disables edit and delete for cash accounts', (tester) async {
    final accounts = [
      FinanceAccount(id: 'a1', name: 'Cash', type: AccountType.cash, displayName: 'Efectivo'),
      FinanceAccount(id: 'a2', name: 'Visa', type: AccountType.card, displayName: 'Visa'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountsProvider.overrideWith(() => MockAccountsNotifier(accounts)),
        ],
        child: createTestApp(home: const ManageAccountsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Verify "Efectivo" row buttons are disabled
    // We can find the icon buttons by icon and then check if they are in the same row as "Efectivo"
    // Or just find all icon buttons and check which ones are disabled.
    
    final editButtons = find.widgetWithIcon(IconButton, Icons.edit);
    final deleteButtons = find.widgetWithIcon(IconButton, Icons.delete);

    expect(editButtons, findsNWidgets(2));
    expect(deleteButtons, findsNWidgets(2));

    // The first row is "Efectivo"
    final cashEditButton = tester.widget<IconButton>(editButtons.at(0));
    final cashDeleteButton = tester.widget<IconButton>(deleteButtons.at(0));
    
    expect(cashEditButton.onPressed, isNull);
    expect(cashDeleteButton.onPressed, isNull);

    // The second row is "Visa"
    final visaEditButton = tester.widget<IconButton>(editButtons.at(1));
    final visaDeleteButton = tester.widget<IconButton>(deleteButtons.at(1));
    
    expect(visaEditButton.onPressed, isNotNull);
    expect(visaDeleteButton.onPressed, isNotNull);
  });
}
