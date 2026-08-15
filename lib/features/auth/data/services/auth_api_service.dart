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

/// Official Zabira Academy Auth API Network Service.
///
/// Implements OpenAPI endpoints:
/// `POST /auth/login`
/// `POST /auth/register`
/// `POST /auth/forgot_password`
/// `POST /auth/validate_reset_token`
/// `POST /auth/reset_password`
/// `GET  /auth/profile`
/// `POST /auth/refresh`
/// `POST /student/profile`
/// `GET  /student/dashboard`
class AuthApiService {
  AuthApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'ZabiraAcademy-App/1.0',
  };

  /// Helper for POST with automatic .php fallback if 404
  Future<Map<String, dynamic>> _postWithFallback(
    String path, {
    required Map<String, dynamic> body,
    String? token,
    int timeoutSeconds = 12,
  }) async {
    final headers = Map<String, String>.from(_headers);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final jsonBody = jsonEncode(body);
    final primaryUri = Uri.parse('${ApiConfig.baseUrl}$path');
    _logRequest('POST', primaryUri, jsonBody);

    try {
      final response = await _client
          .post(primaryUri, headers: headers, body: jsonBody)
          .timeout(Duration(seconds: timeoutSeconds));

      _logResponse(primaryUri, response.statusCode, response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _parseSuccess(response.body);
      }

      if (response.statusCode == 404 && !path.endsWith('.php')) {
        final fallbackUri = Uri.parse('${ApiConfig.baseUrl}$path.php');
        _logRequest('POST (RETRY FALLBACK)', fallbackUri, jsonBody);

        final fallbackResp = await _client
            .post(fallbackUri, headers: headers, body: jsonBody)
            .timeout(Duration(seconds: timeoutSeconds));

        _logResponse(fallbackUri, fallbackResp.statusCode, fallbackResp.body);

        if (fallbackResp.statusCode == 200 || fallbackResp.statusCode == 201) {
          return _parseSuccess(fallbackResp.body);
        }

        throw _mapErrorResponse(fallbackResp.statusCode, fallbackResp.body);
      }

      throw _mapErrorResponse(response.statusCode, response.body);
    } on TimeoutException {
      throw const AuthApiException(
        message: 'Connection timed out. Please check your internet connection and try again.',
        statusCode: 408,
      );
    } on SocketException {
      throw const AuthApiException(
        message: 'Unable to connect to Zabira Academy server. Please verify your network.',
      );
    } on http.ClientException catch (e) {
      if (e.message.contains('XMLHttpRequest')) {
        throw const AuthApiException(
          message: 'Backend CORS Restriction: api.zabiraacademy.com did not include Access-Control-Allow-Origin header for browser requests.',
        );
      }
      throw AuthApiException(message: 'Network error: ${e.message}');
    } catch (e) {
      if (e is AuthApiException) rethrow;
      throw AuthApiException(message: 'Authentication request failed: $e');
    }
  }

  /// Helper for GET with automatic .php fallback if 404
  Future<Map<String, dynamic>> _getWithFallback(
    String path, {
    Map<String, String>? queryParams,
    String? token,
    int timeoutSeconds = 12,
  }) async {
    final headers = Map<String, String>.from(_headers);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final primaryUri = Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: queryParams);
    _logRequest('GET', primaryUri, null);

    try {
      final response = await _client
          .get(primaryUri, headers: headers)
          .timeout(Duration(seconds: timeoutSeconds));

      _logResponse(primaryUri, response.statusCode, response.body);

      if (response.statusCode == 200) {
        return _parseSuccess(response.body);
      }

      if (response.statusCode == 404 && !path.endsWith('.php')) {
        final fallbackUri = Uri.parse('${ApiConfig.baseUrl}$path.php').replace(queryParameters: queryParams);
        _logRequest('GET (RETRY FALLBACK)', fallbackUri, null);

        final fallbackResp = await _client
            .get(fallbackUri, headers: headers)
            .timeout(Duration(seconds: timeoutSeconds));

        _logResponse(fallbackUri, fallbackResp.statusCode, fallbackResp.body);

        if (fallbackResp.statusCode == 200) {
          return _parseSuccess(fallbackResp.body);
        }

        throw _mapErrorResponse(fallbackResp.statusCode, fallbackResp.body);
      }

      throw _mapErrorResponse(response.statusCode, response.body);
    } on TimeoutException {
      throw const AuthApiException(
        message: 'Connection timed out. Please check your internet connection and try again.',
        statusCode: 408,
      );
    } on SocketException {
      throw const AuthApiException(
        message: 'Unable to connect to Zabira Academy server. Please verify your network.',
      );
    } on http.ClientException catch (e) {
      if (e.message.contains('XMLHttpRequest')) {
        throw const AuthApiException(
          message: 'Backend CORS Restriction: api.zabiraacademy.com did not include Access-Control-Allow-Origin header for browser requests.',
        );
      }
      throw AuthApiException(message: 'Network error: ${e.message}');
    } catch (e) {
      if (e is AuthApiException) rethrow;
      throw AuthApiException(message: 'Request failed: $e');
    }
  }

  /// `POST /auth/login`
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String portal = 'student',
  }) async {
    return _postWithFallback(
      ApiConfig.authLogin,
      body: {
        'email': email.trim(),
        'password': password,
        'portal': portal.trim(),
      },
    );
  }

  /// `POST /auth/register`
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
    final body = <String, dynamic>{
      'full_name': fullName.trim(),
      'fullName': fullName.trim(),
      'email': email.trim(),
      'password': password,
      'confirm_password': confirmPassword,
      'confirmPassword': confirmPassword,
      'accept_terms': acceptTerms ? '1' : '0',
      'acceptTerms': acceptTerms ? '1' : '0',
    };
    if (mobile != null && mobile.trim().isNotEmpty) {
      body['mobile'] = mobile.trim();
      body['phone'] = mobile.trim();
    }
    if (gender != null && gender.trim().isNotEmpty) {
      body['gender'] = gender.trim();
    }
    if (dateOfBirth != null && dateOfBirth.trim().isNotEmpty) {
      body['date_of_birth'] = dateOfBirth.trim();
      body['dateOfBirth'] = dateOfBirth.trim();
    }
    if (country != null && country.trim().isNotEmpty) {
      body['country'] = country.trim();
    }
    if (state != null && state.trim().isNotEmpty) {
      body['state'] = state.trim();
    }
    if (city != null && city.trim().isNotEmpty) {
      body['city'] = city.trim();
    }

    return _postWithFallback(ApiConfig.authRegister, body: body);
  }

  /// `POST /auth/forgot_password`
  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    return _postWithFallback(
      ApiConfig.authForgotPassword,
      body: {'email': email.trim()},
    );
  }

  /// `POST /auth/validate_reset_token`
  Future<Map<String, dynamic>> validateResetToken({required String token}) async {
    return _postWithFallback(
      ApiConfig.authValidateResetToken,
      body: {'token': token.trim()},
    );
  }

  /// `POST /auth/reset_password`
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    return _postWithFallback(
      ApiConfig.authResetPassword,
      body: {
        'token': token.trim(),
        'password': password,
        'confirm_password': confirmPassword,
      },
    );
  }

  /// `GET /auth/profile`
  Future<Map<String, dynamic>> getProfile({required String token}) async {
    return _getWithFallback(ApiConfig.authProfile, token: token);
  }

  /// `POST /auth/refresh`
  Future<Map<String, dynamic>> refreshToken({required String token}) async {
    return _postWithFallback(ApiConfig.authRefresh, body: {}, token: token);
  }

  /// `POST /student/profile`
  Future<Map<String, dynamic>> updateStudentProfile({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    return _postWithFallback(ApiConfig.studentProfile, body: data, token: token);
  }

  /// `GET /student/dashboard`
  Future<Map<String, dynamic>> getStudentDashboard({required String token}) async {
    return _getWithFallback(ApiConfig.studentDashboard, token: token);
  }

  /// `POST /auth/google_auth`
  Future<Map<String, dynamic>> googleAuth({
    required String idToken,
    String portal = 'student',
  }) async {
    return _postWithFallback(
      ApiConfig.authGoogleAuth,
      body: {
        'id_token': idToken,
        'credential': idToken,
        'portal': portal.trim(),
      },
    );
  }

  Map<String, dynamic> _parseSuccess(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {'success': true, 'data': data};
    } catch (e) {
      debugPrint('[AUTH PARSE ERROR] Error parsing success JSON: $e');
      throw const AuthApiException(message: 'Unexpected server response format.');
    }
  }

  AuthApiException _mapErrorResponse(int statusCode, String body) {
    String? message;
    int? remainingAttempts;
    int? retryAfter;

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        message = decoded['message']?.toString() ?? decoded['error']?.toString();
        final data = decoded['data'];
        if (data is Map<String, dynamic>) {
          if (data['attempts_remaining'] != null) {
            remainingAttempts = int.tryParse(data['attempts_remaining'].toString());
          }
          if (data['retry_after'] != null) {
            retryAfter = int.tryParse(data['retry_after'].toString());
          }
        }
      }
    } catch (_) {
      // Non-JSON response body
    }

    switch (statusCode) {
      case 400:
      case 422:
        return AuthApiException(
          message: message ?? 'Please check your inputs and try again.',
          statusCode: statusCode,
        );
      case 401:
        final extra = remainingAttempts != null ? ' ($remainingAttempts attempts remaining)' : '';
        return AuthApiException(
          message: '${message ?? "Invalid credentials or session expired."}$extra',
          statusCode: statusCode,
          remainingAttempts: remainingAttempts,
        );
      case 403:
        return AuthApiException(
          message: message ?? 'Access denied for this request.',
          statusCode: statusCode,
        );
      case 404:
        return const AuthApiException(
          message: 'Requested service is currently unavailable.',
          statusCode: 404,
        );
      case 429:
        final waitMsg = retryAfter != null ? ' Please wait ${(retryAfter / 60).ceil()} minutes.' : '';
        return AuthApiException(
          message: message ?? 'Too many attempts.$waitMsg',
          statusCode: statusCode,
          retryAfterSeconds: retryAfter,
        );
      case 500:
      case 502:
      case 503:
        return AuthApiException(
          message: message ?? 'Server encountered an error. Please try again shortly.',
          statusCode: statusCode,
        );
      default:
        return AuthApiException(
          message: message ?? 'Request failed (HTTP $statusCode).',
          statusCode: statusCode,
        );
    }
  }

  void _logRequest(String method, Uri uri, String? body) {
    if (kDebugMode) {
      debugPrint('[AUTH API] $method $uri');
    }
  }

  void _logResponse(Uri uri, int statusCode, String body) {
    if (kDebugMode) {
      debugPrint('[AUTH API RESPONSE] HTTP $statusCode | URL: $uri');
    }
  }
}
