import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_config.dart';

/// Exception thrown when authentication fails.
class AuthApiException implements Exception {
  const AuthApiException({
    required this.message,
    this.statusCode,
    this.remainingAttempts,
    this.retryAfterSeconds,
  });

  final String message;
  final int? statusCode;
  final int? remainingAttempts;
  final int? retryAfterSeconds;

  @override
  String toString() => message;
}

/// Normal account-picker dismissal. This is deliberately distinct from a
/// failed sign-in so the UI can return to the login form without an error.
class GoogleSignInCancelledException extends AuthApiException {
  const GoogleSignInCancelledException()
    : super(message: 'Google sign-in was cancelled.');
}

/// Official Zabira Academy Auth API Network Service.
class AuthApiService {
  AuthApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'ZabiraAcademy-App/1.0',
  };

  /// POST request helper with clean error decoding
  Future<Map<String, dynamic>> _post(
    String endpoint, {
    required Map<String, dynamic> body,
    String? token,
    int timeoutSeconds = 15,
  }) async {
    final headers = Map<String, String>.from(_headers);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final path = ApiConfig.normalizePath(endpoint);
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final jsonBody = jsonEncode(body);

    if (kDebugMode) debugPrint('[AUTH API POST] $uri | Body: $jsonBody');

    try {
      final response = await _client
          .post(uri, headers: headers, body: jsonBody)
          .timeout(Duration(seconds: timeoutSeconds));

      if (kDebugMode)
        debugPrint(
          '[AUTH API RESPONSE] HTTP ${response.statusCode} | URL: $uri',
        );

      return _handleResponse(response, uri);
    } on SocketException {
      throw const AuthApiException(
        message:
            'Unable to reach server. Please check your internet connection.',
      );
    } on TimeoutException {
      throw const AuthApiException(
        message: 'Request timed out. Please try again.',
        statusCode: 408,
      );
    } catch (e) {
      if (e is AuthApiException) rethrow;
      throw AuthApiException(message: e.toString());
    }
  }

  /// GET request helper with clean error decoding
  Future<Map<String, dynamic>> _get(
    String endpoint, {
    Map<String, String>? queryParams,
    String? token,
    int timeoutSeconds = 15,
  }) async {
    final headers = Map<String, String>.from(_headers);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final path = ApiConfig.normalizePath(endpoint);
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}$path',
    ).replace(queryParameters: queryParams);

    if (kDebugMode) debugPrint('[AUTH API GET] $uri');

    try {
      final response = await _client
          .get(uri, headers: headers)
          .timeout(Duration(seconds: timeoutSeconds));

      if (kDebugMode)
        debugPrint(
          '[AUTH API RESPONSE] HTTP ${response.statusCode} | URL: $uri',
        );

      return _handleResponse(response, uri);
    } on SocketException {
      throw const AuthApiException(
        message:
            'Unable to reach server. Please check your internet connection.',
      );
    } on TimeoutException {
      throw const AuthApiException(
        message: 'Request timed out. Please try again.',
        statusCode: 408,
      );
    } catch (e) {
      if (e is AuthApiException) rethrow;
      throw AuthApiException(message: e.toString());
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response, Uri uri) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': 'Success'};
      }
      throw AuthApiException(
        message: 'Server error (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (decoded is Map<String, dynamic>) {
        if (decoded['success'] == false) {
          throw AuthApiException(
            message: decoded['message']?.toString() ?? 'Operation failed.',
            statusCode: response.statusCode,
          );
        }
        return decoded;
      }
      return {'success': true, 'data': decoded};
    }

    if (response.statusCode == 401) {
      final msg = decoded is Map
          ? (decoded['message'] ?? 'Invalid credentials or session expired.')
          : 'Unauthorized';
      throw AuthApiException(message: msg.toString(), statusCode: 401);
    }

    if (decoded is Map<String, dynamic>) {
      final msg =
          decoded['message'] ??
          decoded['error'] ??
          'Request failed (${response.statusCode})';
      throw AuthApiException(
        message: msg.toString(),
        statusCode: response.statusCode,
      );
    }

    throw AuthApiException(
      message: 'Request failed (${response.statusCode})',
      statusCode: response.statusCode,
    );
  }

  /// `POST /auth/login.php`
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String portal = 'student',
  }) async {
    return _post(
      ApiConfig.authLogin,
      body: {'email': email.trim(), 'password': password, 'portal': portal},
    );
  }

  /// `POST /auth/register.php`
  Future<Map<String, dynamic>> register({
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
    final nameParts = fullName.trim().split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : fullName.trim();
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final body = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName.trim(),
      'fullName': fullName.trim(),
      'name': fullName.trim(),
      'email': email.trim(),
      'password': password,
      'confirm_password': confirmPassword,
      'confirmPassword': confirmPassword,
      'password_confirmation': confirmPassword,
      'country': (country != null && country.isNotEmpty) ? country : 'India',
      'state': (state != null && state.isNotEmpty) ? state : '',
      'city': (city != null && city.isNotEmpty) ? city : '',
      'accept_terms': acceptTerms ? '1' : '0',
      'acceptTerms': acceptTerms ? 1 : 0,
      'portal': 'student',
    };

    if (mobile != null && mobile.isNotEmpty) {
      body['mobile'] = mobile.trim();
      body['phone'] = mobile.trim();
      body['contact_number'] = mobile.trim();
    }
    if (gender != null && gender.isNotEmpty) {
      body['gender'] = gender;
    }
    if (dateOfBirth != null && dateOfBirth.isNotEmpty) {
      body['date_of_birth'] = dateOfBirth;
      body['dateOfBirth'] = dateOfBirth;
      body['dob'] = dateOfBirth;
    }

    return _post(ApiConfig.authRegister, body: body);
  }

  /// `POST /auth/forgot_password.php`
  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    return _post(ApiConfig.authForgotPassword, body: {'email': email.trim()});
  }

  /// `POST /auth/validate_reset_token.php`
  Future<Map<String, dynamic>> validateResetToken({
    required String token,
  }) async {
    return _post(
      ApiConfig.authValidateResetToken,
      body: {'token': token.trim()},
    );
  }

  /// `POST /auth/reset_password.php`
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    return _post(
      ApiConfig.authResetPassword,
      body: {
        'token': token.trim(),
        'password': password,
        'confirm_password': confirmPassword,
      },
    );
  }

  /// `GET /auth/profile.php`
  Future<Map<String, dynamic>> getProfile({required String token}) async {
    return _get(ApiConfig.authProfile, token: token);
  }

  /// `POST /auth/refresh.php`
  Future<Map<String, dynamic>> refresh({required String token}) async {
    return _post(ApiConfig.authRefresh, body: {}, token: token);
  }

  /// `POST /auth/google_auth.php`
  ///
  /// Sends the Google ID Token (JWT) directly to the backend for server-side
  /// verification against Google's public keys. The backend verifies audience,
  /// issuer, expiry, and signature, and extracts verified claims (sub, email, name, avatar).
  Future<Map<String, dynamic>> googleAuth({required String idToken}) async {
    // This public endpoint accepts Google's OIDC ID token, not an existing
    // Zabira session and not a Google access token. Keep the body precisely
    // aligned with the documented contract.
    return _post(ApiConfig.authGoogleAuth, body: {'id_token': idToken.trim()});
  }

  /// `GET /student/dashboard.php`
  Future<Map<String, dynamic>> getStudentDashboard({
    required String token,
  }) async {
    return _get(ApiConfig.studentDashboard, token: token);
  }
}
