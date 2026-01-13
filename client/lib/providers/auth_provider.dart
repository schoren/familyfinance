import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/runtime_config.dart';

class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String? householdId;
  final String? token;

  AuthState({
    this.isAuthenticated = false,
    this.userId,
    this.userName,
    this.userEmail,
    this.householdId,
    this.token,
  });

  Map<String, dynamic> toJson() => {
    'isAuthenticated': isAuthenticated,
    'userId': userId,
    'userName': userName,
    'userEmail': userEmail,
    'householdId': householdId,
    'token': token,
  };

  factory AuthState.fromJson(Map<String, dynamic> json) => AuthState(
    isAuthenticated: json['isAuthenticated'] ?? false,
    userId: json['userId'],
    userName: json['userName'],
    userEmail: json['userEmail'],
    householdId: json['householdId'],
    token: json['token'],
  );
}

class AuthNotifier extends Notifier<AuthState> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: RuntimeConfig.googleClientId,
    scopes: ['email', 'profile'],
  );

  @override
  AuthState build() {
    // Try to load state from persistent storage
    _loadState();
    return AuthState();
  }

  static const _storageKey = 'auth_state';

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      try {
        final data = jsonDecode(jsonString);
        state = AuthState.fromJson(data);
      } catch (e) {
        print('Error loading auth state: $e');
      }
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.toJson()));
  }

  Future<void> _clearState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> loginWithGoogle({String? inviteCode}) async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null && accessToken == null) {
        throw Exception('Failed to get any token from Google');
      }

      // Authenticate with backend
      final response = await http.post(
        Uri.parse('${RuntimeConfig.apiUrl}/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_token': idToken,
          'access_token': accessToken,
          'invite_code': inviteCode,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'];
        
        state = AuthState(
          isAuthenticated: true,
          userId: user['id'],
          userName: user['name'],
          userEmail: user['email'],
          householdId: data['household_id'],
          token: data['token'],
        );
        await _saveState();
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Backend authentication failed: ${response.statusCode}';
        throw Exception(error);
      }
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _clearState();
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
