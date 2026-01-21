import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/finance_account.dart';
import '../models/expense.dart';
import '../models/monthly_summary.dart';

class SyncResponse {
  final List<Category> categories;
  final List<FinanceAccount> accounts;
  final List<Expense> transactions;

  SyncResponse({
    required this.categories,
    required this.accounts,
    required this.transactions,
  });

  factory SyncResponse.fromJson(Map<String, dynamic> json) {
    return SyncResponse(
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => Category.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      accounts: (json['accounts'] as List<dynamic>?)
              ?.map((e) => FinanceAccount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((e) => Expense.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ApiClient {
  final String baseUrl;
  final String? householdId;
  final String? authToken;
  final http.Client _client;

  ApiClient({
    required this.baseUrl,
    this.householdId,
    this.authToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  String get _scopedUrl => '$baseUrl/households/$householdId';

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }
  void _logResponse(String method, Uri uri, int statusCode, String body) {
    print('🌐 HTTP $method: $uri');
    if (body != null) {
      print('📤 Request body: $body');
    }
    print('📥 Response [$statusCode]: $body');
  }

  // ============================================================================
  // CATEGORIES
  // ============================================================================

  Future<List<Category>> getCategories() async {
    final uri = Uri.parse('$_scopedUrl/categories');
    final response = await _client.get(uri, headers: _headers);
    _logResponse('GET', uri, response.statusCode, response.body);

    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      return json.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to fetch categories: ${response.statusCode}');
    }
  }

  Future<Category> createCategory(Category category) async {
    final uri = Uri.parse('$_scopedUrl/categories');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode(category.toJson()),
    );

    if (response.statusCode == 201) {
      return Category.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to create category: ${response.statusCode}');
    }
  }

  Future<Category> updateCategory(String id, Category category) async {
    final uri = Uri.parse('$_scopedUrl/categories/$id');
    final response = await _client.put(
      uri,
      headers: _headers,
      body: jsonEncode(category.toJson()),
    );

    if (response.statusCode == 200) {
      return Category.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to update category: ${response.statusCode}');
    }
  }

  Future<void> deleteCategory(String id) async {
    final uri = Uri.parse('$_scopedUrl/categories/$id');
    final response = await _client.delete(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete category: ${response.statusCode}');
    }
  }

  // ============================================================================
  // ACCOUNTS
  // ============================================================================

  Future<List<FinanceAccount>> getAccounts() async {
    final uri = Uri.parse('$_scopedUrl/accounts');
    final response = await _client.get(uri, headers: _headers);
    _logResponse('GET', uri, response.statusCode, response.body);

    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      return json.map((e) => FinanceAccount.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to fetch accounts: ${response.statusCode}');
    }
  }

  Future<FinanceAccount> createAccount(FinanceAccount account) async {
    final uri = Uri.parse('$_scopedUrl/accounts');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode(account.toJson()),
    );

    if (response.statusCode == 201) {
      return FinanceAccount.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to create account: ${response.statusCode}');
    }
  }

  Future<FinanceAccount> updateAccount(String id, FinanceAccount account) async {
    final uri = Uri.parse('$_scopedUrl/accounts/$id');
    final response = await _client.put(
      uri,
      headers: _headers,
      body: jsonEncode(account.toJson()),
    );

    if (response.statusCode == 200) {
      return FinanceAccount.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to update account: ${response.statusCode}');
    }
  }

  Future<void> deleteAccount(String id) async {
    final uri = Uri.parse('$_scopedUrl/accounts/$id');
    final response = await _client.delete(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete account: ${response.statusCode}');
    }
  }

  // ============================================================================
  // TRANSACTIONS (EXPENSES)
  // ============================================================================

  Future<List<Expense>> getTransactions({String? month}) async {
    final uri = Uri.parse('$_scopedUrl/transactions').replace(
      queryParameters: month != null ? {'month': month} : null,
    );
    final response = await _client.get(uri, headers: _headers);
    _logResponse('GET', uri, response.statusCode, response.body);

    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      return json.map((e) => Expense.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to fetch transactions: ${response.statusCode}');
    }
  }

  Future<Expense> createTransaction(Expense expense) async {
    final uri = Uri.parse('$_scopedUrl/transactions');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode(expense.toJson()),
    );

    if (response.statusCode == 201) {
      return Expense.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to create transaction: ${response.statusCode}');
    }
  }

  Future<Expense> updateTransaction(String id, Expense expense) async {
    final uri = Uri.parse('$_scopedUrl/transactions/$id');
    final response = await _client.put(
      uri,
      headers: _headers,
      body: jsonEncode(expense.toJson()),
    );

    if (response.statusCode == 200) {
      return Expense.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to update transaction: ${response.statusCode}');
    }
  }

  Future<void> deleteTransaction(String id) async {
    final uri = Uri.parse('$_scopedUrl/transactions/$id');
    final response = await _client.delete(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete transaction: ${response.statusCode}');
    }
  }

  Future<List<String>> getSuggestedNotes(String categoryId) async {
    final uri = Uri.parse('$_scopedUrl/categories/$categoryId/suggested-notes');
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      return json.cast<String>();
    } else {
      throw Exception('Failed to fetch suggested notes: ${response.statusCode}');
    }
  }

  // ============================================================================
  // MONTHLY SUMMARY
  // ============================================================================

  Future<MonthlySummary> getMonthlySummary(String month) async {
    final uri = Uri.parse('$_scopedUrl/summary/$month');
    final response = await _client.get(uri, headers: _headers);
    _logResponse('GET', uri, response.statusCode, response.body);

    if (response.statusCode == 200) {
      return MonthlySummary.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to fetch monthly summary: ${response.statusCode}');
    }
  }

  // ============================================================================
  // INVITATIONS
  // ============================================================================

  Future<void> createInvitation(String email) async {
    final uri = Uri.parse('$_scopedUrl/invites');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create invitation: ${response.statusCode}');
    }
  }

  // ============================================================================
  // MEMBERS
  // ============================================================================

  Future<List<Map<String, dynamic>>> getMembers() async {
    final uri = Uri.parse('$_scopedUrl/members');
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      // We don't have a Member model yet, returning raw maps for now or we can create a simple local one.
      // For simplicity in this step, let's return List<Map<String, dynamic>>
      return json.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch members: ${response.statusCode}');
    }
  }

  Future<void> removeMember(String userId) async {
    final uri = Uri.parse('$_scopedUrl/members/$userId');
    final response = await _client.delete(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to remove member: ${response.statusCode}');
    }
  }

  // ============================================================================
  // LEGACY SYNC
  // ============================================================================

  Future<SyncResponse> sync({String? month}) async {
    final uri = Uri.parse('$_scopedUrl/sync').replace(
      queryParameters: month != null ? {'month': month} : null,
    );

    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return SyncResponse.fromJson(json);
    } else {
      throw Exception('Failed to sync: ${response.statusCode} ${response.body}');
    }
  }

  // ============================================================================
  // MISC
  // ============================================================================

  Future<String> getServerVersion() async {
    final uri = Uri.parse('$baseUrl/version');
    final response = await _client.get(uri, headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['version'] as String;
    } else {
      throw Exception('Failed to fetch server version: ${response.statusCode}');
    }
  }

  void dispose() {
    _client.close();
  }
}

