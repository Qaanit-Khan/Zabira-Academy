import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_config.dart';
import '../models/library_category_model.dart';
import '../models/library_item_model.dart';

class LibraryApiService {
  LibraryApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'User-Agent': 'ZabiraAcademy-App/1.0',
  };

  Future<Map<String, dynamic>> _getWithFallback(String path, {Map<String, String>? queryParams}) async {
    final primaryUri = Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: queryParams);
    debugPrint('[LIBRARY API] GET $primaryUri');

    try {
      final response = await _client.get(primaryUri, headers: _headers).timeout(const Duration(seconds: 12));
      debugPrint('[LIBRARY API] HTTP ${response.statusCode} | URL: $primaryUri');

      if (response.statusCode == 200) {
        return _parseJson(response.body, primaryUri.toString());
      }

      if (response.statusCode == 404 && !path.endsWith('.php')) {
        final fallbackUri = Uri.parse('${ApiConfig.baseUrl}$path.php').replace(queryParameters: queryParams);
        debugPrint('[LIBRARY API RETRY] GET $fallbackUri');

        final fallbackResponse = await _client.get(fallbackUri, headers: _headers).timeout(const Duration(seconds: 12));
        debugPrint('[LIBRARY API] HTTP ${fallbackResponse.statusCode} | URL: $fallbackUri');

        if (fallbackResponse.statusCode == 200) {
          return _parseJson(fallbackResponse.body, fallbackUri.toString());
        }
      }

      throw Exception('Library request failed (HTTP ${response.statusCode})');
    } catch (e) {
      debugPrint('[LIBRARY API EXCEPTION] GET $primaryUri -> $e');
      rethrow;
    }
  }

  Map<String, dynamic> _parseJson(String body, String url) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw FormatException('Expected JSON object, got ${decoded.runtimeType}');
    } catch (e) {
      debugPrint('[LIBRARY API PARSE ERROR] URL: $url | Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _postWithFallback(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final headers = Map<String, String>.from(_headers);
    headers['Content-Type'] = 'application/json';
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final primaryUri = Uri.parse('${ApiConfig.baseUrl}$path');
    final encodedBody = jsonEncode(body);
    debugPrint('[LIBRARY API] POST $primaryUri | Body: $encodedBody');

    try {
      final response = await _client.post(primaryUri, headers: headers, body: encodedBody).timeout(const Duration(seconds: 15));
      debugPrint('[LIBRARY API] HTTP ${response.statusCode} | URL: $primaryUri');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return _parseJson(response.body, primaryUri.toString());
      }
      if (response.statusCode == 404 && !path.endsWith('.php')) {
        final fallbackUri = Uri.parse('${ApiConfig.baseUrl}$path.php');
        debugPrint('[LIBRARY API RETRY] POST $fallbackUri');
        final fallbackResponse = await _client.post(fallbackUri, headers: headers, body: encodedBody).timeout(const Duration(seconds: 15));
        debugPrint('[LIBRARY API] HTTP ${fallbackResponse.statusCode} | URL: $fallbackUri');
        if (fallbackResponse.statusCode == 200 || fallbackResponse.statusCode == 201) {
          return _parseJson(fallbackResponse.body, fallbackUri.toString());
        }
        debugPrint('[LIBRARY API ERROR BODY] ${fallbackResponse.body.length > 1000 ? fallbackResponse.body.substring(0, 1000) : fallbackResponse.body}');
      }
      debugPrint('[LIBRARY API ERROR BODY] ${response.body.length > 1000 ? response.body.substring(0, 1000) : response.body}');
      String backendMessage = 'Library action failed';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          backendMessage = decoded['message']?.toString() ?? decoded['error']?.toString() ?? backendMessage;
        }
      } catch (_) {}
      throw Exception('POST $path failed (HTTP ${response.statusCode}): $backendMessage | payload=$encodedBody');
    } catch (e) {
      debugPrint('[LIBRARY API EXCEPTION] POST $primaryUri -> $e');
      rethrow;
    }
  }

  /// `GET /library/public_stats`
  Future<LibraryStatsModel> getStats() async {
    try {
      final json = await _getWithFallback('/library/public_stats.php');
      final data = json['data'];
      if (data != null && data is Map<String, dynamic>) {
        return LibraryStatsModel.fromJson(data);
      }
    } catch (e) {
      debugPrint('[LIBRARY API] getStats error: $e');
    }
    return const LibraryStatsModel();
  }

  /// `GET /library/public_categories`
  Future<List<LibraryCategoryModel>> getCategories() async {
    final json = await _getWithFallback(ApiConfig.libraryCategories);
    final data = json['data'];
    if (data != null && data is Map<String, dynamic> && data['items'] is List) {
      return (data['items'] as List)
          .map((e) => LibraryCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// `GET /library/public_list`
  Future<List<LibraryItemModel>> getLibraryList({
    int page = 1,
    int limit = 20,
    int? categoryId,
    String? category,
    int? collectionId,
    String? search,
    String? featured,
    String? bestseller,
    String? isNew,
    String? sort,
    String? dir,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (categoryId != null && categoryId > 0) {
      queryParams['category_id'] = categoryId.toString();
    }
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (collectionId != null) {
      queryParams['collection_id'] = collectionId.toString();
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (featured != null) queryParams['featured'] = featured;
    if (bestseller != null) queryParams['bestseller'] = bestseller;
    if (isNew != null) queryParams['new'] = isNew;
    if (sort != null) queryParams['sort'] = sort;
    if (dir != null) queryParams['dir'] = dir;

    final json = await _getWithFallback(ApiConfig.libraryList, queryParams: queryParams);
    final data = json['data'];
    if (data != null && data is Map<String, dynamic> && data['items'] is List) {
      return (data['items'] as List)
          .map((e) => LibraryItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// `GET /library/public_details`
  Future<LibraryItemModel?> getLibraryDetails({int? id, String? slug}) async {
    final queryParams = <String, String>{};
    if (id != null && id > 0) queryParams['id'] = id.toString();
    if (slug != null && slug.isNotEmpty) queryParams['slug'] = slug;

    final json = await _getWithFallback(ApiConfig.libraryDetails, queryParams: queryParams);
    final data = json['data'];
    if (data != null && data is Map<String, dynamic>) {
      if (data['item'] != null && data['item'] is Map<String, dynamic>) {
        return LibraryItemModel.fromJson(data['item'] as Map<String, dynamic>);
      }
      return LibraryItemModel.fromJson(data);
    }
    return null;
  }

  Future<Map<String, dynamic>> purchaseLibraryItem({
    required int bookId,
    required String format,
    String? token,
  }) {
    // Per OpenAPI spec: POST /library/purchase.php
    // Documented fields: book_id (integer), format (string)
    // No other fields are defined in the spec.
    final body = <String, dynamic>{
      'book_id': bookId,
      'format': format,
    };
    debugPrint('[LIBRARY API] purchaseLibraryItem | book_id=$bookId | format=$format');
    return _postWithFallback(
      ApiConfig.libraryPurchase,
      body: body,
      token: token,
    );
  }
}
