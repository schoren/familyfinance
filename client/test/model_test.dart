import 'package:flutter_test/flutter_test.dart';
import 'package:keda/models/category.dart';
import 'package:keda/models/expense.dart';
import 'package:keda/models/finance_account.dart';
import 'package:keda/models/account_type.dart';

void main() {
  group('Category Model', () {
    test('should parse from JSON correctly', () {
      final json = {
        'id': '1',
        'name': 'Food',
        'monthly_budget': 500.0,
        'is_active': true,
      };
      final category = Category.fromJson(json);
      expect(category.id, '1');
      expect(category.name, 'Food');
      expect(category.monthlyBudget, 500.0);
      expect(category.isActive, true);
    });

    test('should convert to JSON correctly', () {
      final category = Category(
        id: '1',
        name: 'Food',
        monthlyBudget: 500.0,
      );
      final json = category.toJson();
      expect(json['id'], '1');
      expect(json['name'], 'Food');
      expect(json['monthly_budget'], 500.0);
    });
   group('Expense Model', () {
    test('should parse from JSON correctly', () {
      final json = {
        'id': '1',
        'date': '2024-01-01T10:00:00Z',
        'category_id': 'cat1',
        'account_id': 'acc1',
        'amount': 50.5,
        'note': 'Lunch',
      };
      final expense = Expense.fromJson(json);
      expect(expense.id, '1');
      expect(expense.amount, 50.5);
      expect(expense.note, 'Lunch');
    });

    test('should convert to JSON correctly', () {
      final date = DateTime(2024, 1, 1);
      final expense = Expense(
        id: '1',
        date: date,
        categoryId: 'cat1',
        accountId: 'acc1',
        amount: 50.5,
      );
      final json = expense.toJson();
      expect(json['id'], '1');
      expect(json['amount'], 50.5);
      expect(json['date'], isA<String>());
    });
  });

  group('FinanceAccount Model', () {
    test('should parse from JSON correctly', () {
      final json = {
        'id': '1',
        'type': 'cash',
        'name': 'Wallet',
        'display_name': 'Efectivo',
      };
      final account = FinanceAccount.fromJson(json);
      expect(account.id, '1');
      expect(account.type, AccountType.cash);
      expect(account.displayName, 'Efectivo');
    });
  });
});
}
