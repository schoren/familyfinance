import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/runtime_config.dart';

class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String? userPictureUrl;
  final String? userColor;
  final String? householdId;
  final String? token;

  AuthState({
    this.isAuthenticated = false,
    this.userId,
    this.userName,
    this.userEmail,
    this.userPictureUrl,
    this.userColor,
    this.householdId,
    this.token,
  });

  Map<String, dynamic> toJson() => {
    'isAuthenticated': isAuthenticated,
    'userId': userId,
    'userName': userName,
    'userEmail': userEmail,
    'userPictureUrl': userPictureUrl,
    'userColor': userColor,
    'householdId': householdId,
    'token': token,
  };

  factory AuthState.fromJson(Map<String, dynamic> json) => AuthState(
    isAuthenticated: json['isAuthenticated'] ?? false,
    userId: json['userId'],
    userName: json['userName'],
    userEmail: json['userEmail'],
    userPictureUrl: json['userPictureUrl'],
    userColor: json['userColor'],
    householdId: json['householdId'],
    token: json['token'],
  );
}

class AuthNotifier extends Notifier<AuthState> {
  String? _pendingInviteCode;

  void setPendingInviteCode(String? code) {
    _pendingInviteCode = code;
  }

  @override
  AuthState build() {
    _loadState();
    
    // Listen to Google Sign In events (v7)
    gsi.GoogleSignIn.instance.authenticationEvents.listen((gsi.GoogleSignInAuthenticationEvent event) {
       // Check for sign-in event
       if (event is gsi.GoogleSignInAuthenticationEventSignIn) {
         _handleSignIn(event.user);
       }
       // We can also handle signOut etc.
    });

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

  Future<void> _handleSignIn(gsi.GoogleSignInAccount googleUser) async {
       try {
         final googleAuth = await googleUser.authentication;
         final idToken = googleAuth.idToken;
         // In v7, accessToken is removed from GoogleSignInAuthentication.
         // We rely on idToken for backend verification.
         final String? accessToken = null; 

         if (idToken == null) {
           print('Failed to get idToken from Google');
           return;
         }

         // Authenticate with backend
         final response = await http.post(
           Uri.parse('${RuntimeConfig.apiUrl}/auth/google'),
           headers: {'Content-Type': 'application/json'},
           body: jsonEncode({
             'id_token': idToken,
             'access_token': accessToken,
             'invite_code': _pendingInviteCode, // Use stored code
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
             userPictureUrl: user['picture_url'],
             userColor: user['color'],
             householdId: data['household_id'],
             token: data['token'],
           );
           await _saveState();
           _pendingInviteCode = null;
         } else {
           final error = jsonDecode(response.body)['error'] ?? 'Backend authentication failed: ${response.statusCode}';
           print('Backend Logic Error: $error');
         }
       } catch (e) {
         print('Backend Auth Error: $e');
       }
  }

  Future<void>? _googleSignInInitFuture;

  Future<void> ensureGoogleSignInInitialized() {
    _googleSignInInitFuture ??= gsi.GoogleSignIn.instance.initialize(
      clientId: RuntimeConfig.googleClientId,
    );
    return _googleSignInInitFuture!;
  }

  Future<void> loginWithGoogle({String? inviteCode}) async {
    try {
       _pendingInviteCode = inviteCode;
       print('Initializing Google Sign In');
       
       final googleSignIn = gsi.GoogleSignIn.instance;
       
       // Ensure initialized
       await ensureGoogleSignInInitialized();
       
       // v7: Use authenticate() instead of signIn()
       // This is for MOBILE/DESKTOP execution or Web if supported (currently not).
       // If running on Web, this method shouldn't be called if we use the button.
       // But if called, we try.
       await googleSignIn.authenticate();
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await gsi.GoogleSignIn.instance.signOut();
    } catch (e) {
      print('Google sign out error (ignoring): $e');
    }
    await _clearState();
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
