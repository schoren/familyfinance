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
       print('Initializing Google Sign In');
       
       // Initialize GoogleSignIn
       // We use dynamic dispatch to avoid compilation issues if the analyzer is outdated,
       // but strictly speaking, in v7 we must initialize.
       await (GoogleSignIn.instance as dynamic).initialize(
        clientId: RuntimeConfig.googleClientId,
        scopes: ['email', 'profile'],
       );
       
       final googleUser = await GoogleSignIn.instance.authenticate();
       if (googleUser == null) return;

       final googleAuth = await googleUser.authentication;
       final idToken = googleAuth.idToken;
       // Note: In GoogleSignIn v7, accessToken is not directly available on authentication object.
       // We rely on idToken for authentication. If accessToken is needed (e.g. for Google API calls),
       // it requires a separate authorization flow.
       final String? accessToken = null;

       if (idToken == null) {
         throw Exception('Failed to get idToken from Google');
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
    await GoogleSignIn.instance.signOut();
    await _clearState();
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
