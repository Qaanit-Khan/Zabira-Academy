import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_config.dart';
import '../models/user_model.dart';
import 'services/auth_api_service.dart';

/// Zabira Academy — Auth Repository
///
/// Handles official API authentication, session state, and secure token persistence.
class AuthRepository {
  AuthRepository({AuthApiService? apiService})
    : _apiService = apiService ?? AuthApiService();

  final AuthApiService _apiService;

  static const String _tokenKey = 'zabira_auth_token';
  static const String _userKey = 'zabira_auth_user';

  String? _cachedToken;
  UserModel? _cachedUser;

  String? get currentToken => _cachedToken;
  UserModel? get currentUser => _cachedUser;
  bool get isSignedIn => _cachedToken != null && _cachedToken!.isNotEmpty;

  /// Initialize and restore stored session from local storage.
  Future<UserModel?> initSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final userJson = prefs.getString(_userKey);

      if (token != null &&
          token.isNotEmpty &&
          userJson != null &&
          userJson.isNotEmpty) {
        final data = jsonDecode(userJson) as Map<String, dynamic>;
        final user = UserModel.fromJson(data);
        _cachedToken = token;
        _cachedUser = user;

        // Verify token in background — if invalid/expired (401), invalidate session
        _validateSessionSilently(token);

        return _cachedUser;
      }
    } catch (_) {
      // Clear corrupted session storage
      await signOut();
    }
    return null;
  }

  Future<void> _validateSessionSilently(String token) async {
    try {
      final response = await _apiService.getProfile(token: token);
      final data = response['data'] ?? response['user'] ?? response;
      if (data is Map<String, dynamic>) {
        final updatedUser = UserModel.fromJson(data);
        _cachedUser = updatedUser;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(updatedUser.toJson()));
      }
    } on AuthApiException catch (e) {
      if (e.statusCode == 401) {
        // Token is no longer valid on backend — clear session
        await signOut();
      }
    } catch (_) {
      // Network failure on background check: keep local session
    }
  }

  /// Official REST API sign in
  Future<UserModel> signInWithApi({
    required String email,
    required String password,
    String portal = 'student',
  }) async {
    final response = await _apiService.login(
      email: email,
      password: password,
      portal: portal,
    );

    if (response['success'] == false) {
      final msg =
          response['message']?.toString() ?? 'Invalid email or password.';
      throw AuthApiException(message: msg, statusCode: 401);
    }

    // Extract token from various standard response keys
    String? token;
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      token =
          data['token']?.toString() ??
          data['access_token']?.toString() ??
          data['jwt']?.toString();
    } else if (response['token'] != null) {
      token = response['token']?.toString();
    }

    if (token == null || token.isEmpty) {
      throw const AuthApiException(
        message: 'Login succeeded but the Zabira session token was missing.',
      );
    }

    // Construct User Model from API data
    Map<String, dynamic> userMap = {};
    if (data is Map<String, dynamic>) {
      if (data['user'] is Map<String, dynamic>) {
        userMap = data['user'] as Map<String, dynamic>;
      } else {
        userMap = data;
      }
    } else if (response['user'] is Map<String, dynamic>) {
      userMap = response['user'] as Map<String, dynamic>;
    }

    if (!userMap.containsKey('email')) userMap['email'] = email.trim();
    if (!userMap.containsKey('role')) userMap['role'] = portal.trim();

    final user = UserModel.fromJson(userMap);

    // Commit only after successful parsing
    _cachedToken = token;
    _cachedUser = user;

    // Persist session securely
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
    } catch (_) {}

    return user;
  }

  /// Official REST API Register
  Future<Map<String, dynamic>> registerWithApi({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    String? mobile,
    String? gender,
    String? dateOfBirth,
    String? country,
    String? state,
    String? city,
    bool acceptTerms = true,
  }) async {
    final response = await _apiService.register(
      fullName: fullName,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      mobile: mobile,
      gender: gender,
      dateOfBirth: dateOfBirth,
      country: country,
      state: state,
      city: city,
      acceptTerms: acceptTerms,
    );

    // Check if registration returned an active token/session directly
    String? token;
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      token = data['token']?.toString() ?? data['access_token']?.toString();
      if (token != null && token.isNotEmpty) {
        _cachedToken = token;
        final userMap = data['user'] is Map<String, dynamic>
            ? data['user'] as Map<String, dynamic>
            : data;
        if (!userMap.containsKey('email')) userMap['email'] = email;
        final user = UserModel.fromJson(userMap);
        _cachedUser = user;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        await prefs.setString(_userKey, jsonEncode(user.toJson()));
      }
    }

    return response;
  }

  /// Official REST API Password Reset Request
  Future<void> sendPasswordResetEmail(String email) async {
    await _apiService.forgotPassword(email: email);
  }

  /// Official REST API Validate Reset Token
  Future<bool> validateResetToken(String token) async {
    final res = await _apiService.validateResetToken(token: token);
    return res['success'] == true || res['status'] == 'success';
  }

  /// Official REST API Reset Password
  Future<void> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    await _apiService.resetPassword(
      token: token,
      password: password,
      confirmPassword: confirmPassword,
    );
  }

  /// Update cached user profile locally and persist to storage
  Future<void> updateCachedUser(UserModel updatedUser) async {
    _cachedUser = updatedUser;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(updatedUser.toJson()));
    } catch (_) {}
  }

  /// Fetch latest user profile from API
  Future<UserModel> refreshProfile() async {
    if (_cachedToken == null || _cachedToken!.isEmpty) {
      throw const AuthApiException(message: 'No active session token found.');
    }

    final response = await _apiService.getProfile(token: _cachedToken!);
    final data = response['data'] ?? response['user'] ?? response;
    if (data is Map<String, dynamic>) {
      final user = UserModel.fromJson(data);
      _cachedUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      return user;
    }
    throw const AuthApiException(
      message: 'Invalid profile response from server.',
    );
  }

  /// Native On-Device Google Sign-In
  ///
  /// Uses official GoogleSignIn with serverClientId (Web Client ID)
  /// so Google Play Services / iOS can issue an OpenID Connect ID Token (JWT).
  /// Sends the token to backend POST /auth/google_auth.php for signature verification
  /// and canonical user resolution.
  Future<UserModel> signInWithGoogle({String portal = 'student'}) async {
    String? idToken;

    debugPrint(
      '[GOOGLE AUTH DIAGNOSTIC] 1. Initializing GoogleSignIn with serverClientId: ${ApiConfig.googleServerClientId.isNotEmpty ? "(configured)" : "(none)"}',
    );
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: ApiConfig.googleServerClientId.isNotEmpty
            ? ApiConfig.googleServerClientId
            : null,
        clientId: ApiConfig.googleIosClientId,
        scopes: const ['email', 'profile', 'openid'],
      );

      // Sign out from any local Google session to always allow account selection
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      debugPrint(
        '[GOOGLE AUTH DIAGNOSTIC] 2. Launching native Google Account Picker...',
      );
      final account = await googleSignIn.signIn();
      if (account == null) {
        debugPrint(
          '[GOOGLE AUTH DIAGNOSTIC] 3. User closed account picker without selecting an account.',
        );
        throw const GoogleSignInCancelledException();
      }

      debugPrint(
        '[GOOGLE AUTH DIAGNOSTIC] 3. Account selected successfully. Fetching authentication tokens...',
      );
      final auth = await account.authentication;
      idToken = auth.idToken;
      debugPrint(
        '[GOOGLE AUTH DIAGNOSTIC] 4. ID token status: ${idToken != null && idToken.isNotEmpty ? "Available (len=${idToken.length})" : "NOT available"}',
      );
    } on AuthApiException {
      rethrow;
    } catch (e) {
      debugPrint('[GOOGLE AUTH DIAGNOSTIC ERROR] Native sign-in error: $e');
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('cancel') ||
          errStr.contains('canceled') ||
          errStr.contains('dismiss') ||
          errStr.contains('interrupted')) {
        throw const GoogleSignInCancelledException();
      }
      if (errStr.contains('network') || errStr.contains('socket')) {
        throw const AuthApiException(
          message:
              'Unable to connect to Google. Please check your internet connection.',
        );
      }
      if (errStr.contains('10:') || errStr.contains('apiexception: 10')) {
        throw const AuthApiException(
          message:
              'Google Sign-In configuration error (Developer Error 10). The Android OAuth client must match com.example.zabira_academy and this APK signing SHA-1.',
        );
      }
      if (errStr.contains('12500:') || errStr.contains('apiexception: 12500')) {
        throw const AuthApiException(
          message:
              'Google Sign-In failed (Error 12500). Please check your Google Play Services.',
        );
      }
      throw AuthApiException(message: 'Google sign-in failed: $e');
    }

    if (idToken == null || idToken.isEmpty) {
      throw const AuthApiException(
        message: 'Google did not return a valid authentication token.',
      );
    }

    debugPrint(
      '[GOOGLE AUTH DIAGNOSTIC] 5. Sending verified ID token to Zabira backend POST /auth/google_auth.php...',
    );
    final response = await _apiService.googleAuth(idToken: idToken);
    debugPrint(
      '[GOOGLE AUTH DIAGNOSTIC] 6. Zabira backend response: success=${response['success']}',
    );

    if (response['success'] == false) {
      final msg =
          response['message']?.toString() ??
          'Google authentication failed on server.';
      throw AuthApiException(message: msg, statusCode: 401);
    }

    final token = _extractAuthToken(response);
    if (token == null || token.isEmpty) {
      throw const AuthApiException(
        message:
            'Google authentication succeeded but the Zabira session token was missing.',
      );
    }

    // Construct User Model from API data identically to email/password login
    final userMap = _extractUserMap(response);
    if (userMap == null ||
        userMap.isEmpty ||
        (userMap['id'] == null &&
            userMap['user_id'] == null &&
            userMap['uid'] == null)) {
      throw const AuthApiException(
        message:
            'Google authentication succeeded but the Zabira user data was missing.',
      );
    }
    if (!userMap.containsKey('role')) userMap['role'] = portal.trim();

    final user = UserModel.fromJson(userMap);

    // Commit only after successful parsing
    _cachedToken = token;
    _cachedUser = user;

    // Persist session securely using the EXACT SAME keys as email/password login
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
    } catch (_) {}

    return user;
  }

  String? _extractAuthToken(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      final token =
          data['token'] ??
          data['access_token'] ??
          data['jwt'] ??
          data['auth_token'];
      if (token != null && token.toString().isNotEmpty) return token.toString();
      final user = data['user'];
      if (user is Map<String, dynamic>) {
        final userToken = user['token'] ?? user['access_token'] ?? user['jwt'];
        if (userToken != null && userToken.toString().isNotEmpty) {
          return userToken.toString();
        }
      }
    }
    final token =
        response['token'] ??
        response['access_token'] ??
        response['jwt'] ??
        response['auth_token'];
    return token?.toString();
  }

  Map<String, dynamic>? _extractUserMap(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      final user = data['user'];
      if (user is Map<String, dynamic>) return user;
      return data;
    }
    final user = response['user'];
    if (user is Map<String, dynamic>) return user;
    return null;
  }

  /// Clear stored credentials on Sign Out
  Future<void> signOut() async {
    _cachedToken = null;
    _cachedUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    } catch (_) {}
  }
}

/// Teacher Auth Repository
class TeacherAuthRepository extends AuthRepository {
  TeacherAuthRepository({super.apiService});

  Future<UserModel> signInAsTeacher({
    required String email,
    required String password,
  }) async {
    return signInWithApi(email: email, password: password, portal: 'teacher');
  }
}
