import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_config.dart';
import '../models/cart_item_model.dart';

/// Network service interacting with Zabira Academy Cart API endpoints.
///
/// Follows the official API specification:
/// `GET  /cart/list`
/// `GET  /cart/count`
/// `POST /cart/add`
/// `GET  /cart/remove`
/// `POST /cart/clear`
class CartApiService {
  CartApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'ZabiraAcademy-App/1.0',
  };

  Exception _httpError({
    required String method,
    required Uri uri,
    required int statusCode,
    required String body,
    Map<String, dynamic>? payload,
  }) {
    String message = 'HTTP $statusCode';
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final backendMessage = decoded['message']?.toString() ?? decoded['error']?.toString();
        if (backendMessage != null && backendMessage.isNotEmpty) {
          message = backendMessage;
        }
      }
    } catch (_) {}

    final payloadText = payload == null ? '' : ' | payload=${jsonEncode(payload)}';
    return Exception('$method $uri failed (HTTP $statusCode): $message$payloadText');
  }

  /// Helper for GET requests with automatic .php fallback
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
    if (kDebugMode) debugPrint('[CART API] GET $primaryUri');

    try {
      final response = await _client.get(primaryUri, headers: headers).timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        return _parseSuccess(response.body);
      }

      if (response.statusCode == 404 && !path.endsWith('.php')) {
        final fallbackUri = Uri.parse('${ApiConfig.baseUrl}$path.php').replace(queryParameters: queryParams);
        if (kDebugMode) debugPrint('[CART API RETRY] GET $fallbackUri');

        final fallbackResp = await _client.get(fallbackUri, headers: headers).timeout(Duration(seconds: timeoutSeconds));
        if (fallbackResp.statusCode == 200) {
          return _parseSuccess(fallbackResp.body);
        }
      }

      throw _httpError(
        method: 'GET',
        uri: primaryUri,
        statusCode: response.statusCode,
        body: response.body,
      );
    } on TimeoutException {
      throw Exception('Cart request timed out. Please check your internet connection.');
    } on SocketException {
      throw Exception('Unable to reach Zabira Academy server.');
    } catch (e) {
      if (kDebugMode) debugPrint('[CART API ERROR] GET $primaryUri -> $e');
      rethrow;
    }
  }

  /// Helper for POST requests with automatic .php fallback
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
    if (kDebugMode) debugPrint('[CART API] POST $primaryUri | Body: $jsonBody');

    try {
      final response = await _client.post(primaryUri, headers: headers, body: jsonBody).timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _parseSuccess(response.body);
      }

      if (response.statusCode == 404 && !path.endsWith('.php')) {
        final fallbackUri = Uri.parse('${ApiConfig.baseUrl}$path.php');
        if (kDebugMode) debugPrint('[CART API RETRY] POST $fallbackUri');

        final fallbackResp = await _client.post(fallbackUri, headers: headers, body: jsonBody).timeout(Duration(seconds: timeoutSeconds));
        if (fallbackResp.statusCode == 200 || fallbackResp.statusCode == 201) {
          return _parseSuccess(fallbackResp.body);
        }
      }

      if (kDebugMode) {
        debugPrint('[CART API ERROR BODY] ${response.body.length > 1000 ? response.body.substring(0, 1000) : response.body}');
      }
      throw _httpError(
        method: 'POST',
        uri: primaryUri,
        statusCode: response.statusCode,
        body: response.body,
        payload: body,
      );
    } on TimeoutException {
      throw Exception('Cart request timed out. Please check your internet connection.');
    } on SocketException {
      throw Exception('Unable to reach Zabira Academy server.');
    } catch (e) {
      if (kDebugMode) debugPrint('[CART API ERROR] POST $primaryUri -> $e');
      rethrow;
    }
  }

  /// Helper for DELETE requests with automatic .php fallback
  Future<Map<String, dynamic>> _deleteWithFallback(
    String path, {
    Map<String, String>? queryParams,
    Map<String, dynamic>? body,
    String? token,
    int timeoutSeconds = 12,
  }) async {
    final headers = Map<String, String>.from(_headers);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final jsonBody = body != null ? jsonEncode(body) : null;
    final primaryUri = Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: queryParams);
    if (kDebugMode) debugPrint('[CART API] DELETE $primaryUri');

    try {
      final response = await _client.delete(
        primaryUri,
        headers: headers,
        body: jsonBody,
      ).timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return _parseSuccess(response.body);
      }

      if (response.statusCode == 404 && !path.endsWith('.php')) {
        final fallbackUri = Uri.parse('${ApiConfig.baseUrl}$path.php').replace(queryParameters: queryParams);
        if (kDebugMode) debugPrint('[CART API RETRY] DELETE $fallbackUri');

        final fallbackResp = await _client.delete(
          fallbackUri,
          headers: headers,
          body: jsonBody,
        ).timeout(Duration(seconds: timeoutSeconds));
        if (fallbackResp.statusCode == 200 || fallbackResp.statusCode == 204) {
          return _parseSuccess(fallbackResp.body);
        }
      }

      if (kDebugMode) {
        debugPrint('[CART API DELETE ERROR BODY] ${response.body}');
      }
      throw _httpError(
        method: 'DELETE',
        uri: primaryUri,
        statusCode: response.statusCode,
        body: response.body,
      );
    } on TimeoutException {
      throw Exception('Cart request timed out. Please check your internet connection.');
    } on SocketException {
      throw Exception('Unable to reach Zabira Academy server.');
    } catch (e) {
      if (kDebugMode) debugPrint('[CART API ERROR] DELETE $primaryUri -> $e');
      rethrow;
    }
  }

  /// `GET /cart/list`
  Future<CartSummaryModel> getCartList({String? token}) async {
    final response = await _getWithFallback(ApiConfig.cartList, token: token);
    return CartSummaryModel.fromJson(response);
  }

  /// `GET /cart/count`
  Future<int> getCartCount({String? token}) async {
    try {
      final response = await _getWithFallback(ApiConfig.cartCount, token: token);
      final rawCount = response['count'] ?? response['data']?['count'] ?? response['items_count'];
      return int.tryParse(rawCount?.toString() ?? '0') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// `POST /cart/add`
  Future<Map<String, dynamic>> addToCart({
    required Map<String, dynamic> itemData,
    String? token,
  }) async {
    return _postWithFallback(ApiConfig.cartAdd, body: itemData, token: token);
  }

  /// `DELETE /cart/remove`
  Future<Map<String, dynamic>> removeFromCart({
    int? cartId,
    int? bookId,
    String? format,
    int? courseId,
    String? token,
  }) async {
    final queryParams = <String, String>{};
    if (cartId != null && cartId > 0) queryParams['cart_id'] = cartId.toString();
    if (bookId != null && bookId > 0) queryParams['book_id'] = bookId.toString();
    if (format != null && format.isNotEmpty) queryParams['format'] = format;
    if (courseId != null && courseId > 0) queryParams['course_id'] = courseId.toString();

    final bodyPayload = <String, dynamic>{
      if (cartId != null && cartId > 0) 'cart_id': cartId,
      if (bookId != null && bookId > 0) 'book_id': bookId,
      if (format != null && format.isNotEmpty) 'format': format,
      if (courseId != null && courseId > 0) 'course_id': courseId,
    };

    return _deleteWithFallback(
      ApiConfig.cartRemove,
      queryParams: queryParams.isEmpty ? null : queryParams,
      body: bodyPayload.isEmpty ? null : bodyPayload,
      token: token,
    );
  }

  /// `DELETE /cart/clear`
  Future<Map<String, dynamic>> clearCart({String? token}) async {
    return _deleteWithFallback(ApiConfig.cartClear, body: {}, token: token);
  }

  /// `POST /cart/checkout`
  Future<Map<String, dynamic>> checkout({
    String? token,
    Map<String, dynamic>? body,
  }) async {
    return _postWithFallback(
      ApiConfig.cartCheckout,
      body: body ?? {},
      token: token,
    );
  }

  Map<String, dynamic> _parseSuccess(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) return data;
      return {'success': true, 'data': data};
    } catch (_) {
      return {'success': true};
    }
  }
}
