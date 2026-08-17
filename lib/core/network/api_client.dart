import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_config.dart';
import 'debug_logger.dart';

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

  static const int defaultTimeoutSeconds = 20;

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

    final headers = _buildHeaders(token: token);
    DebugLogger.logRequest(method: 'GET', uri: uri, headers: headers);

    final stopwatch = Stopwatch()..start();
    try {
      final response = await _client
          .get(uri, headers: headers)
          .timeout(Duration(seconds: timeoutSeconds));
      stopwatch.stop();

      DebugLogger.logResponse(
        method: 'GET',
        uri: uri,
        statusCode: response.statusCode,
        body: response.body,
        duration: stopwatch.elapsed,
      );

      return _handleResponse(response, uri);
    } on SocketException catch (e) {
      DebugLogger.logError(context: 'GET $uri SocketException', error: e);
      throw const ApiException(message: 'Unable to reach server. Please check your internet connection.');
    } on TimeoutException catch (e) {
      DebugLogger.logError(context: 'GET $uri TimeoutException', error: e);
      throw const ApiException(message: 'Request timed out. Please try again.');
    } catch (e) {
      DebugLogger.logError(context: 'GET $uri Exception', error: e);
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

    final headers = _buildHeaders(token: token);
    DebugLogger.logRequest(method: 'POST', uri: uri, headers: headers, body: body);

    final stopwatch = Stopwatch()..start();
    try {
      final response = await _client
          .post(uri, headers: headers, body: jsonBody)
          .timeout(Duration(seconds: timeoutSeconds));
      stopwatch.stop();

      DebugLogger.logResponse(
        method: 'POST',
        uri: uri,
        statusCode: response.statusCode,
        body: response.body,
        duration: stopwatch.elapsed,
      );

      return _handleResponse(response, uri);
    } on SocketException catch (e) {
      DebugLogger.logError(context: 'POST $uri SocketException', error: e);
      throw const ApiException(message: 'Unable to reach server. Please check your internet connection.');
    } on TimeoutException catch (e) {
      DebugLogger.logError(context: 'POST $uri TimeoutException', error: e);
      throw const ApiException(message: 'Request timed out. Please try again.');
    } catch (e) {
      DebugLogger.logError(context: 'POST $uri Exception', error: e);
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

    final headers = _buildHeaders(token: token);
    DebugLogger.logRequest(method: 'PUT', uri: uri, headers: headers, body: body);

    final stopwatch = Stopwatch()..start();
    try {
      final response = await _client
          .put(uri, headers: headers, body: jsonBody)
          .timeout(Duration(seconds: timeoutSeconds));
      stopwatch.stop();

      DebugLogger.logResponse(
        method: 'PUT',
        uri: uri,
        statusCode: response.statusCode,
        body: response.body,
        duration: stopwatch.elapsed,
      );

      return _handleResponse(response, uri);
    } on SocketException catch (e) {
      DebugLogger.logError(context: 'PUT $uri SocketException', error: e);
      throw const ApiException(message: 'Unable to reach server. Please check your internet connection.');
    } on TimeoutException catch (e) {
      DebugLogger.logError(context: 'PUT $uri TimeoutException', error: e);
      throw const ApiException(message: 'Request timed out. Please try again.');
    } catch (e) {
      DebugLogger.logError(context: 'PUT $uri Exception', error: e);
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

    final headers = _buildHeaders(token: token);
    DebugLogger.logRequest(method: 'DELETE', uri: uri, headers: headers);

    final stopwatch = Stopwatch()..start();
    try {
      final response = await _client
          .delete(uri, headers: headers)
          .timeout(Duration(seconds: timeoutSeconds));
      stopwatch.stop();

      DebugLogger.logResponse(
        method: 'DELETE',
        uri: uri,
        statusCode: response.statusCode,
        body: response.body,
        duration: stopwatch.elapsed,
      );

      return _handleResponse(response, uri);
    } on SocketException catch (e) {
      DebugLogger.logError(context: 'DELETE $uri SocketException', error: e);
      throw const ApiException(message: 'Unable to reach server. Please check your internet connection.');
    } on TimeoutException catch (e) {
      DebugLogger.logError(context: 'DELETE $uri TimeoutException', error: e);
      throw const ApiException(message: 'Request timed out. Please try again.');
    } catch (e) {
      DebugLogger.logError(context: 'DELETE $uri Exception', error: e);
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
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
