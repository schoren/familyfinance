import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:keda/main.dart' as app;
import 'package:keda/core/runtime_config.dart';
import 'package:keda/models/account_type.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keda/providers/settings_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;

  void logScreenText() {
    final textWidgets = find.byType(Text).evaluate().map((e) => (e.widget as Text).data ?? (e.widget as Text).textSpan?.toPlainText() ?? '').toList();
    print('DEBUG: VISIBLE TEXT: $textWidgets');
  }

  group('E2E Account Management', () {
    testWidgets('Verify cash account rules and create/delete custom account', (tester) async {
      await app.main();
      await tester.pumpAndSettle();
      
      // Force English locale for the test
      final element = tester.element(find.byType(app.MyApp));
      final container = ProviderScope.containerOf(element);
      await container.read(settingsProvider.notifier).setLanguage('en');
      await tester.pumpAndSettle();

      print('DEBUG: Test Mode is: ${RuntimeConfig.testMode}');
      print('DEBUG: Waiting for initial load...');
      
      bool homeScreenFound = false;
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        // Check for Home tab text or Home screen specific text
        if (find.text('Home').evaluate().isNotEmpty ||
            find.textContaining('REMAINING').evaluate().isNotEmpty) {
          homeScreenFound = true;
          break;
        }
        
        // Diagnostic: what do we see?
        if (i % 5 == 0) {
          logScreenText();
          if (find.text('Sign in with Google').evaluate().isNotEmpty) {
            print('DEBUG: APP IS ON LOGIN SCREEN');
          }
        }
      }
      
      logScreenText();
      expect(homeScreenFound, isTrue, reason: 'Home screen (Dashboard icon) was not found after initial load');

      // 2. Navigate to Accounts tab
      Finder accountsTab = find.text('Accounts');
      
      print('DEBUG: Tapping Accounts tab');
      await tester.tap(accountsTab);
      await tester.pumpAndSettle();
      logScreenText();
      
      // Verify we are on Accounts screen
      expect(find.text('Accounts'), findsWidgets); // One in nav bar, maybe one in title

      // 3. Verify cash account rules (cannot delete/edit)
      // The cash account should be seeded by the backend in TEST_MODE
      // Wait for at least one account to load
      bool accountsLoaded = false;
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (find.text('Cash').evaluate().isNotEmpty) {
          accountsLoaded = true;
          break;
        }
      }
      expect(accountsLoaded, isTrue, reason: 'Accounts list (specifically Cash account) did not load in time');

      final cashListTile = find.ancestor(
        of: find.text('Cash'),
        matching: find.byType(ListTile),
      ).first;
      expect(cashListTile, findsOneWidget);

      // Find edit and delete icons within the cash tile
      final editButton = find.descendant(
        of: cashListTile,
        matching: find.byIcon(Icons.edit),
      );
      final deleteButton = find.descendant(
        of: cashListTile,
        matching: find.byIcon(Icons.delete),
      );

      // Verify they are present but their onPressed is null
      final IconButton editIconButton = tester.widget(find.ancestor(of: editButton, matching: find.byType(IconButton)));
      final IconButton deleteIconButton = tester.widget(find.ancestor(of: deleteButton, matching: find.byType(IconButton)));
      
      expect(editIconButton.onPressed, isNull);
      expect(deleteIconButton.onPressed, isNull);

      // 4. Create a custom account
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // We should be on the New Account screen
      expect(find.byType(Form), findsOneWidget);

      // Fill name for Bank account (default is card, let's switch to Bank)
      // Open type dropdown
      // Select "Bank Account"
      print('DEBUG: Selecting Bank Account from dropdown');
      await tester.tap(find.byType(DropdownButtonFormField<AccountType>));
      await tester.pumpAndSettle();
      logScreenText();
      await tester.tap(find.text('Bank Account').last);
      await tester.pumpAndSettle();

      final nameField = find.byType(TextFormField); // On Bank type, there's only one TextFormField for name
      await tester.enterText(nameField, 'E2E Bank');
      await tester.pumpAndSettle();

      // Tap SAVE (ElevatedButton)
      print('DEBUG: Tapping SAVE');
      logScreenText();
      await tester.tap(find.text('SAVE'));
      await tester.pumpAndSettle();

      // 5. Verify it appears in the list
      expect(find.text('E2E Bank'), findsOneWidget);

      // 6. Delete it
      final bankListTile = find.ancestor(
        of: find.text('E2E Bank'),
        matching: find.byType(ListTile),
      );
      
      final bankDeleteButton = find.descendant(
        of: bankListTile,
        matching: find.byIcon(Icons.delete),
      );
      
      await tester.tap(bankDeleteButton);
      await tester.pumpAndSettle();

      // 7. Confirm deletion
      Finder deleteConfirmButton = find.widgetWithText(TextButton, 'Delete');
      
      await tester.tap(deleteConfirmButton.last);
      await tester.pumpAndSettle();

      // 8. Verify it's gone
      expect(find.text('E2E Bank'), findsNothing);
    });
  });
}
