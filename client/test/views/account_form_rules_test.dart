import 'package:keda/models/finance_account.dart';
import 'package:keda/models/account_type.dart';
import 'package:keda/providers/data_providers.dart';
import 'package:keda/views/account_form_screen.dart';
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
  testWidgets('AccountFormScreen hides Efectivo type if one already exists', (tester) async {
    final accounts = [
      FinanceAccount(id: 'a1', name: 'Cash', type: AccountType.cash, displayName: 'Efectivo'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountsProvider.overrideWith(() => MockAccountsNotifier(accounts)),
        ],
        child: createTestApp(home: const AccountFormScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Open dropdown
    final dropdown = find.byType(DropdownButtonFormField<AccountType>);
    expect(dropdown, findsOneWidget);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();

    // "Efectivo" should NOT be present in the dropdown items
    expect(find.text('Efectivo'), findsNothing);
    expect(find.text('Tarjeta'), findsAtLeastNWidgets(1));
    expect(find.text('Cuenta Bancaria'), findsAtLeastNWidgets(1));
  });

  testWidgets('AccountFormScreen shows Efectivo type if NONE exists', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountsProvider.overrideWith(() => MockAccountsNotifier([])),
        ],
        child: createTestApp(home: const AccountFormScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Open dropdown
    final dropdown = find.byType(DropdownButtonFormField<AccountType>);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();

    // "Efectivo" SHOULD be present
    expect(find.text('Efectivo'), findsOneWidget);
  });
}
