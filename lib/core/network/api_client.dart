import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_config.dart';

/// Standard Zabira Academy API Exception
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  final String message;
  final int? statusCode;
  final dynamic errors;

  @override
  String toString() => message;
}

/// Shared API Client for Zabira Academy Mobile App
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const int defaultTimeoutSeconds = 15;

  Map<String, String> _buildHeaders({String? token, Map<String, String>? extraHeaders}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'ZabiraAcademy-App/1.0',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  /// Perform a GET request against the Zabira Academy API
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    String? token,
    int timeoutSeconds = defaultTimeoutSeconds,
  }) async {
    final path = ApiConfig.normalizePath(endpoint);
    final cleanParams = <String, String>{};
    if (queryParameters != null) {
      queryParameters.forEach((key, value) {
        if (value != null) cleanParams[key] = value.toString();
      });
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: cleanParams.isEmpty ? null : cleanParams,
    );

    if (kDebugMode) debugPrint('[API GET] $uri');

    try {
      final response = await _client
          .get(uri, headers: _buildHeaders(token: token))
          .timeout(Duration(seconds: timeoutSeconds));

      return _handleResponse(response, uri);
    } on SocketException {
      throw const ApiException(message: 'Unable to reach server. Please check your internet connection.');
    } on TimeoutException {
      throw const ApiException(message: 'Request timed out. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  /// Perform a POST request against the Zabira Academy API
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
    int timeoutSeconds = defaultTimeoutSeconds,
  }) async {
    final path = ApiConfig.normalizePath(endpoint);
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final jsonBody = body != null ? jsonEncode(body) : '{}';

    if (kDebugMode) debugPrint('[API POST] $uri | Body: $jsonBody');

    try {
      final response = await _client
          .post(uri, headers: _buildHeaders(token: token), body: jsonBody)
          .timeout(Duration(seconds: timeoutSeconds));

      return _handleResponse(response, uri);
    } on SocketException {
      throw const ApiException(message: 'Unable to reach server. Please check your internet connection.');
    } on TimeoutException {
      throw const ApiException(message: 'Request timed out. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  /// Perform a PUT / PATCH request against the Zabira Academy API
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
    int timeoutSeconds = defaultTimeoutSeconds,
  }) async {
    final path = ApiConfig.normalizePath(endpoint);
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final jsonBody = body != null ? jsonEncode(body) : '{}';

    if (kDebugMode) debugPrint('[API PUT] $uri | Body: $jsonBody');

    try {
      final response = await _client
          .put(uri, headers: _buildHeaders(token: token), body: jsonBody)
          .timeout(Duration(seconds: timeoutSeconds));

      return _handleResponse(response, uri);
    } on SocketException {
      throw const ApiException(message: 'Unable to reach server. Please check your internet connection.');
    } on TimeoutException {
      throw const ApiException(message: 'Request timed out. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  /// Perform a DELETE request against the Zabira Academy API
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    String? token,
    int timeoutSeconds = defaultTimeoutSeconds,
  }) async {
    final path = ApiConfig.normalizePath(endpoint);
    final cleanParams = <String, String>{};
    if (queryParameters != null) {
      queryParameters.forEach((key, value) {
        if (value != null) cleanParams[key] = value.toString();
      });
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: cleanParams.isEmpty ? null : cleanParams,
    );

    if (kDebugMode) debugPrint('[API DELETE] $uri');

    try {
      final response = await _client
          .delete(uri, headers: _buildHeaders(token: token))
          .timeout(Duration(seconds: timeoutSeconds));

      return _handleResponse(response, uri);
    } on SocketException {
      throw const ApiException(message: 'Unable to reach server. Please check your internet connection.');
    } on TimeoutException {
      throw const ApiException(message: 'Request timed out. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response, Uri uri) {
    if (kDebugMode) {
      debugPrint('[API RESPONSE] HTTP ${response.statusCode} | URL: $uri');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': 'Success'};
      }
      throw ApiException(
        message: 'Server error (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (decoded is Map<String, dynamic>) return decoded;
      return {'success': true, 'data': decoded};
    }

    if (response.statusCode == 401) {
      final msg = decoded is Map ? (decoded['message'] ?? 'Session expired or unauthorized. Please sign in again.') : 'Unauthorized';
      throw ApiException(message: msg.toString(), statusCode: 401);
    }

    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'] ?? decoded['error'] ?? 'Request failed (${response.statusCode})';
      throw ApiException(
        message: message.toString(),
        statusCode: response.statusCode,
        errors: decoded['errors'],
      );
    }

    throw ApiException(
      message: 'Request failed (${response.statusCode})',
      statusCode: response.statusCode,
    );
  }
}
