import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_config.dart';

/// Network service interacting with Zabira Academy Store API endpoints.
///
/// Follows the official API specification:
/// `GET  /store/public_categories`
/// `GET  /store/public_list`
/// `GET  /store/public_details`
/// `GET  /store/public_collections`
/// `POST /store/purchase`
class StoreService {
  StoreService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'User-Agent': 'ZabiraAcademy-App/1.0',
  };

  /// Helper to perform GET requests with official endpoint and automatic fallback.
  Future<Map<String, dynamic>> _getWithFallback(String path, {Map<String, String>? queryParams}) async {
    // 1. Try official endpoint without .php first
    final primaryUri = Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: queryParams);
    debugPrint('[API REQUEST] GET $primaryUri');

    try {
      final response = await _client.get(primaryUri, headers: _headers).timeout(const Duration(seconds: 12));
      debugPrint('[API RESPONSE] HTTP ${response.statusCode} | URL: $primaryUri');

      if (response.statusCode == 200) {
        return _parseJsonBody(response.body, primaryUri.toString());
      }

      // If 404, fallback to .php endpoint if server requires direct file routing
      if (response.statusCode == 404 && !path.endsWith('.php')) {
        final fallbackUri = Uri.parse('${ApiConfig.baseUrl}$path.php').replace(queryParameters: queryParams);
        debugPrint('[API RETRY FALLBACK] GET $fallbackUri');

        final fallbackResponse = await _client.get(fallbackUri, headers: _headers).timeout(const Duration(seconds: 12));
        debugPrint('[API RESPONSE] HTTP ${fallbackResponse.statusCode} | URL: $fallbackUri');

        if (fallbackResponse.statusCode == 200) {
          return _parseJsonBody(fallbackResponse.body, fallbackUri.toString());
        }
      }

      debugPrint('[API ERROR BODY] ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
      throw Exception('Store request failed (HTTP ${response.statusCode})');
    } catch (e) {
      debugPrint('[API EXCEPTION] GET $primaryUri -> $e');
      rethrow;
    }
  }

  Map<String, dynamic> _parseJsonBody(String body, String url) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw FormatException('Expected JSON object, got ${decoded.runtimeType}');
    } catch (e) {
      debugPrint('[API JSON PARSE ERROR] URL: $url | Error: $e');
      debugPrint('[API RAW BODY] ${body.length > 500 ? body.substring(0, 500) : body}');
      rethrow;
    }
  }

  /// `GET /store/public_categories`
  Future<Map<String, dynamic>> getCategories() async {
    return _getWithFallback(ApiConfig.storeCategories);
  }

  /// `GET /store/public_list`
  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 20,
    String? search,
    int? categoryId,
    String? category,
    String? featured,
    String? bestseller,
    String? isNew,
    int? collectionId,
    String? sort,
    String? dir,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (categoryId != null && categoryId > 0) {
      queryParams['category_id'] = categoryId.toString();
    }
    if (category != null && category.trim().isNotEmpty) {
      queryParams['category'] = category.trim();
    }
    if (featured != null) queryParams['featured'] = featured;
    if (bestseller != null) queryParams['bestseller'] = bestseller;
    if (isNew != null) queryParams['new'] = isNew;
    if (collectionId != null) queryParams['collection_id'] = collectionId.toString();
    if (sort != null) queryParams['sort'] = sort;
    if (dir != null) queryParams['dir'] = dir;

    return _getWithFallback(ApiConfig.storeList, queryParams: queryParams);
  }

  /// `GET /store/public_details`
  Future<Map<String, dynamic>> getProductDetails({int? id, String? slug}) async {
    final queryParams = <String, String>{};
    if (id != null && id > 0) queryParams['id'] = id.toString();
    if (slug != null && slug.isNotEmpty) queryParams['slug'] = slug;

    return _getWithFallback(ApiConfig.storeDetails, queryParams: queryParams);
  }

  /// `GET /store/public_collections`
  Future<Map<String, dynamic>> getCollections({int page = 1, int limit = 10, String? featured}) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (featured != null) queryParams['featured'] = featured;

    return _getWithFallback(ApiConfig.storeCollections, queryParams: queryParams);
  }

  /// `POST /store/purchase`
  Future<Map<String, dynamic>> purchaseProduct({
    required int storeProductId,
    int? storeVariantId,
    int quantity = 1,
    String? authToken,
  }) async {
    final path = ApiConfig.storePurchase;
    final primaryUri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = Map<String, String>.from(_headers);
    headers['Content-Type'] = 'application/json';
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    final bodyMap = <String, dynamic>{
      'store_product_id': storeProductId,
      'quantity': quantity.toString(),
    };
    if (storeVariantId != null) {
      bodyMap['store_variant_id'] = storeVariantId;
    }
    final body = jsonEncode(bodyMap);

    debugPrint('[API REQUEST] POST $primaryUri | Body: $body');

    try {
      final response = await _client.post(primaryUri, headers: headers, body: body).timeout(const Duration(seconds: 15));
      debugPrint('[API RESPONSE] HTTP ${response.statusCode} | URL: $primaryUri');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _parseJsonBody(response.body, primaryUri.toString());
      }

      if (response.statusCode == 404 && !path.endsWith('.php')) {
        final fallbackUri = Uri.parse('${ApiConfig.baseUrl}$path.php');
        debugPrint('[API RETRY FALLBACK] POST $fallbackUri');

        final fallbackResp = await _client.post(fallbackUri, headers: headers, body: body).timeout(const Duration(seconds: 15));
        if (fallbackResp.statusCode == 200 || fallbackResp.statusCode == 201) {
          return _parseJsonBody(fallbackResp.body, fallbackUri.toString());
        }
      }

      throw Exception('Purchase request failed (HTTP ${response.statusCode})');
    } catch (e) {
      debugPrint('[API EXCEPTION] POST $primaryUri -> $e');
      rethrow;
    }
  }
}
