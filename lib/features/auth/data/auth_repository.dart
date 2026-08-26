import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import 'services/auth_api_service.dart';
import 'services/google_oauth_service.dart';

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

    final effectiveToken = token ?? 'session_active';

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
    _cachedToken = effectiveToken;
    _cachedUser = user;

    // Persist session securely
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, effectiveToken);
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

  /// Official REST API Google Sign-In (web-based OAuth, no SHA-1 needed)
  ///
  /// [googleClientId] — a Web-type OAuth 2.0 client ID from Google Cloud Console.
  /// Register your redirect URI: zabiraauth://callback
  Future<UserModel> signInWithGoogle({
    String portal = 'student',
    String googleClientId = _googleWebClientId,
  }) async {
    final oauthService = GoogleOAuthService();

    final GoogleOAuthResult result;
    try {
      result = await oauthService.signIn(clientId: googleClientId);
    } on GoogleOAuthException catch (e) {
      throw AuthApiException(message: e.message);
    } catch (e) {
      throw AuthApiException(message: 'Google sign-in failed: $e');
    }

    final credential = result.credential;
    if (credential == null || credential.isEmpty) {
      throw const AuthApiException(
        message: 'Google did not return a usable sign-in token.',
      );
    }

    debugPrint('[GOOGLE AUTH] Sending token to Zabira backend...');
    final response = await _apiService.googleAuth(
      idToken: credential,
      portal: portal,
      email: result.email,
      name: result.name,
      googleId: result.googleId,
      avatar: result.photoUrl,
    );

    final token = _extractAuthToken(response);
    if (token == null || token.isEmpty) {
      debugPrint('[GOOGLE AUTH API] No backend token in response: $response');
      throw const AuthApiException(
        message: 'Google Sign-In could not create a Zabira session.',
      );
    }

    _cachedToken = token;

    final userData = _extractUserMap(response);
    final user = UserModel(
      uid: userData?['id']?.toString() ??
          userData?['uid']?.toString() ??
          result.googleId ??
          '',
      email: (userData?['email']?.toString().isNotEmpty == true)
          ? userData!['email'].toString()
          : (result.email ?? ''),
      displayName: userData?['name']?.toString() ??
          userData?['display_name']?.toString() ??
          result.name ??
          result.email?.split('@').first ??
          'Student',
      photoUrl: userData?['photo_url']?.toString() ??
          userData?['avatar']?.toString() ??
          result.photoUrl,
      role: UserRole.fromString(userData?['role']?.toString() ?? portal),
      createdAt: DateTime.now(),
    );

    _cachedUser = user;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
    } catch (_) {}

    return user;
  }

  // ── Google Web Client ID ───────────────────────────────────────────────────
  // Replace this with your real Web-type OAuth 2.0 Client ID from:
  //   https://console.cloud.google.com/apis/credentials
  //   → Create → OAuth client ID → Application type: Web application
  //   → Authorized redirect URIs: zabiraauth://callback
  // The client type must be "Web application", NOT Android or iOS.
  static const String _googleWebClientId =
      'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';

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
