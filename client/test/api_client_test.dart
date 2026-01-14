import 'dart:convert';
import 'package:keda/models/category.dart';
import 'package:keda/models/finance_account.dart';
import 'package:keda/models/expense.dart';
import 'package:keda/models/monthly_summary.dart';
import 'package:keda/models/account_type.dart';
import 'package:keda/repositories/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiClient', () {
    const baseUrl = 'http://test.com';
    const householdId = 'hh1';
    const token = 'token123';

    test('getCategories returns list of categories on 200', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/households/$householdId/categories') {
          return http.Response(
            jsonEncode([
              {'id': '1', 'name': 'Food', 'monthly_budget': 100.0, 'household_id': householdId}
            ]),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(
        baseUrl: baseUrl,
        householdId: householdId,
        authToken: token,
        client: client,
      );

      final categories = await apiClient.getCategories();
      expect(categories, isA<List<Category>>());
      expect(categories.length, 1);
      expect(categories.first.name, 'Food');
    });

    test('getCategories throws exception on error', () async {
      final client = MockClient((request) async => http.Response('Error', 500));
      final apiClient = ApiClient(baseUrl: baseUrl, householdId: householdId, client: client);

      expect(apiClient.getCategories(), throwsException);
    });

    test('createCategory posts data and returns category', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/households/$householdId/categories');
        expect(request.headers['Authorization'], 'Bearer $token');
        final body = jsonDecode(request.body);
        expect(body['name'], 'New Cat');

        return http.Response(
          jsonEncode({'id': '2', 'name': 'New Cat', 'monthly_budget': 50.0, 'household_id': householdId}),
          201,
        );
      });

      final apiClient = ApiClient(
        baseUrl: baseUrl,
        householdId: householdId,
        authToken: token,
        client: client,
      );

      final newCat = Category(id: '', name: 'New Cat', monthlyBudget: 50.0);
      final result = await apiClient.createCategory(newCat);
      expect(result.id, '2');
      expect(result.name, 'New Cat');
    });

    test('updateCategory puts data', () async {
      final client = MockClient((request) async {
         expect(request.method, 'PUT');
         expect(request.url.path, '/households/$householdId/categories/1');
         return http.Response(jsonEncode({'id': '1', 'name': 'Updated', 'monthly_budget': 100.0, 'household_id': householdId}), 200);
      });

      final apiClient = ApiClient(baseUrl: baseUrl, householdId: householdId, authToken: token, client: client);
      final cat = Category(id: '1', name: 'Updated', monthlyBudget: 100.0);
      final result = await apiClient.updateCategory('1', cat);
      expect(result.name, 'Updated');
    });

    test('deleteCategory sends delete request', () async {
       final client = MockClient((request) async {
         expect(request.method, 'DELETE');
         return http.Response('', 200);
       });
       final apiClient = ApiClient(baseUrl: baseUrl, householdId: householdId, client: client);
       await apiClient.deleteCategory('1');
    });

    test('getAccounts returns list', () async {
       final client = MockClient((request) async {
         return http.Response(jsonEncode([{'id': 'a1', 'name': 'Bank', 'type': 'bank', 'household_id': householdId, 'display_name': 'Bank Account'}]), 200);
       });
       final apiClient = ApiClient(baseUrl: baseUrl, householdId: householdId, client: client);
       final accounts = await apiClient.getAccounts();
       expect(accounts.length, 1);
    });

    test('createTransaction returns created expense', () async {
       final client = MockClient((request) async {
         expect(request.method, 'POST');
         return http.Response(jsonEncode({
           'id': 't1', 
           'amount': 20.0, 
           'description': 'Coffee', 
           'date': DateTime.now().toIso8601String(),
           'category_id': 'c1',
           'account_id': 'a1',
           'household_id': householdId
         }), 201);
       });
       final apiClient = ApiClient(baseUrl: baseUrl, householdId: householdId, client: client);
       final exp = Expense(id: '', amount: 20.0, note: 'Coffee', date: DateTime.now(), categoryId: 'c1', accountId: 'a1');
       final result = await apiClient.createTransaction(exp);
       expect(result.id, 't1');
    });

    test('getMonthlySummary returns summary', () async {
       final client = MockClient((request) async {
         expect(request.url.path, '/households/$householdId/summary/2024-01');
         return http.Response(jsonEncode({
             'month': '2024-01',
             'total_budget': 1000.0,
             'total_spent': 200.0,
             'categories': []
         }), 200);
       });
       
       final apiClient = ApiClient(baseUrl: baseUrl, householdId: householdId, client: client);
       final summary = await apiClient.getMonthlySummary('2024-01');
       expect(summary.totalBudget, 1000.0);
    });

    test('sync returns sync response', () async {
        final client = MockClient((request) async {
            expect(request.url.path, '/households/$householdId/sync');
            return http.Response(jsonEncode({
                'categories': [],
                'accounts': [],
                'transactions': []
            }), 200);
        });

        final apiClient = ApiClient(baseUrl: baseUrl, householdId: householdId, client: client);
        final response = await apiClient.sync();
        expect(response.categories, isEmpty);
    });

    test('getServerVersion returns version', () async {
         final client = MockClient((request) async {
             return http.Response(jsonEncode({'version': '1.0.0'}), 200);
         });
         final apiClient = ApiClient(baseUrl: baseUrl, client: client);
         final version = await apiClient.getServerVersion();
         expect(version, '1.0.0');
    });
    test('createCategory throws on error', () async {
      final client = MockClient((request) async => http.Response('Error', 500));
      final apiClient = ApiClient(baseUrl: baseUrl, householdId: householdId, client: client);
      final newCat = Category(id: '', name: 'New Cat', monthlyBudget: 50.0);
      expect(apiClient.createCategory(newCat), throwsException);
    });

    test('updateCategory throws on error', () async {
      final client = MockClient((request) async => http.Response('Error', 500));
      final apiClient = ApiClient(baseUrl: baseUrl, householdId: householdId, client: client);
      final cat = Category(id: '1', name: 'Updated', monthlyBudget: 100.0);
      expect(apiClient.updateCategory('1', cat), throwsException);
    });

    test('deleteCategory throws on error', () async {
       final client = MockClient((request) async => http.Response('Error', 500));
       final apiClient = ApiClient(baseUrl: baseUrl, householdId: householdId, client: client);
       expect(apiClient.deleteCategory('1'), throwsException);
    });

    test('getAccounts throws on error', () async {
       final client = MockClient((request) async => http.Response('Error', 500));
       final apiClient = ApiClient(baseUrl: baseUrl, householdId: householdId, client: client);
       expect(apiClient.getAccounts(), throwsException);
    });

    test('createAccount throws on error', () async {
      final client = MockClient((request) async => http.Response('Error', 500));
      final apiClient = ApiClient(baseUrl: baseUrl, householdId: householdId, client: client);
      final acc = FinanceAccount(id: '', name: 'Bank', type: AccountType.bank, displayName: 'Bank');
      expect(apiClient.createAccount(acc), throwsException);
    });

    test('updateAccount throws on error', () async {
      final client = MockClient((request) async => http.Response('Error', 500));
      final apiClient = ApiClient(baseUrl: baseUrl, householdId: householdId, client: client);
      final acc = FinanceAccount(id: 'a1', name: 'Bank', type: AccountType.bank, displayName: 'Bank');
      expect(apiClient.updateAccount('a1', acc), throwsException);
    });

    test('deleteAccount throws on error', () async {
      final client = MockClient((request) async => http.Response('Error', 500));
      final apiClient = ApiClient(baseUrl: baseUrl, householdId: householdId, client: client);
      expect(apiClient.deleteAccount('a1'), throwsException);
    });

    test('getTransactions throws on error', () async {
       final client = MockClient((request) async => http.Response('Error', 500));
       final apiClient = ApiClient(baseUrl: baseUrl, householdId: householdId, client: client);
       expect(apiClient.getTransactions(), throwsException);
    });

    test('createTransaction throws on error', () async {
       final client = MockClient((request) async => http.Response('Error', 500));
       final apiClient = ApiClient(baseUrl: baseUrl, householdId: householdId, client: client);
       final exp = Expense(id: '', amount: 20.0, note: 'Coffee', date: DateTime.now(), categoryId: 'c1', accountId: 'a1');
       expect(apiClient.createTransaction(exp), throwsException);
    });
    
    test('updateTransaction throws on error', () async {
       final client = MockClient((request) async => http.Response('Error', 500));
       final apiClient = ApiClient(baseUrl: baseUrl, householdId: householdId, client: client);
       final exp = Expense(id: 't1', amount: 20.0, note: 'Coffee', date: DateTime.now(), categoryId: 'c1', accountId: 'a1');
       expect(apiClient.updateTransaction('t1', exp), throwsException);
    });

    test('deleteTransaction throws on error', () async {
      final client = MockClient((request) async => http.Response('Error', 500));
      final apiClient = ApiClient(baseUrl: baseUrl, householdId: householdId, client: client);
      expect(apiClient.deleteTransaction('t1'), throwsException);
    });

    test('getMonthlySummary throws on error', () async {
       final client = MockClient((request) async => http.Response('Error', 500));
       final apiClient = ApiClient(baseUrl: baseUrl, householdId: householdId, client: client);
       expect(apiClient.getMonthlySummary('2024-01'), throwsException);
    });

    test('sync throws on error', () async {
        final client = MockClient((request) async => http.Response('Error', 500));
        final apiClient = ApiClient(baseUrl: baseUrl, householdId: householdId, client: client);
        expect(apiClient.sync(), throwsException);
    });

    test('getServerVersion throws on error', () async {
         final client = MockClient((request) async => http.Response('Error', 500));
         final apiClient = ApiClient(baseUrl: baseUrl, client: client);
         expect(apiClient.getServerVersion(), throwsException);
    });
  });
}
