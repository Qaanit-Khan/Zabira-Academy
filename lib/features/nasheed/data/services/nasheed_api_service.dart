import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_config.dart';
import '../models/nasheed_category_model.dart';
import '../models/nasheed_item_model.dart';

class NasheedApiService {
  NasheedApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'User-Agent': 'ZabiraAcademy-App/1.0',
  };

  Future<Map<String, dynamic>> _getWithFallback(String path, {Map<String, String>? queryParams}) async {
    final primaryUri = Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: queryParams);
    debugPrint('[NASHEED API] GET $primaryUri');

    try {
      final response = await _client.get(primaryUri, headers: _headers).timeout(const Duration(seconds: 12));
      debugPrint('[NASHEED API] HTTP ${response.statusCode} | URL: $primaryUri');

      if (response.statusCode == 200) {
        return _parseJson(response.body, primaryUri.toString());
      }

      if (response.statusCode == 404 && !path.endsWith('.php')) {
        final fallbackUri = Uri.parse('${ApiConfig.baseUrl}$path.php').replace(queryParameters: queryParams);
        debugPrint('[NASHEED API RETRY] GET $fallbackUri');

        final fallbackResponse = await _client.get(fallbackUri, headers: _headers).timeout(const Duration(seconds: 12));
        debugPrint('[NASHEED API] HTTP ${fallbackResponse.statusCode} | URL: $fallbackUri');

        if (fallbackResponse.statusCode == 200) {
          return _parseJson(fallbackResponse.body, fallbackUri.toString());
        }
      }

      throw Exception('Nasheed request failed (HTTP ${response.statusCode})');
    } catch (e) {
      debugPrint('[NASHEED API EXCEPTION] GET $primaryUri -> $e');
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
      debugPrint('[NASHEED API PARSE ERROR] URL: $url | Error: $e');
      rethrow;
    }
  }

  /// `GET /nasheed/public_categories`
  Future<List<NasheedCategoryModel>> getCategories() async {
    final json = await _getWithFallback(ApiConfig.nasheedCategories);
    final data = json['data'];
    if (data != null && data is Map<String, dynamic> && data['items'] is List) {
      return (data['items'] as List)
          .map((e) => NasheedCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// `GET /nasheed/public_list`
  Future<List<NasheedItemModel>> getNasheedList({
    int page = 1,
    int limit = 20,
    int? categoryId,
    String? category,
    String? search,
    String? featured,
    String? type,
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
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (featured != null) queryParams['featured'] = featured;
    if (type != null) queryParams['type'] = type;
    if (sort != null) queryParams['sort'] = sort;
    if (dir != null) queryParams['dir'] = dir;

    final json = await _getWithFallback(ApiConfig.nasheedList, queryParams: queryParams);
    final data = json['data'];
    if (data != null && data is Map<String, dynamic> && data['items'] is List) {
      return (data['items'] as List)
          .map((e) => NasheedItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// `GET /nasheed/public_details`
  Future<NasheedItemModel?> getNasheedDetails({int? id, String? slug}) async {
    final queryParams = <String, String>{};
    if (id != null && id > 0) queryParams['id'] = id.toString();
    if (slug != null && slug.isNotEmpty) queryParams['slug'] = slug;

    final json = await _getWithFallback(ApiConfig.nasheedDetails, queryParams: queryParams);
    final data = json['data'];
    if (data != null && data is Map<String, dynamic>) {
      if (data['item'] != null && data['item'] is Map<String, dynamic>) {
        return NasheedItemModel.fromJson(data['item'] as Map<String, dynamic>);
      }
      return NasheedItemModel.fromJson(data);
    }
    return null;
  }
}
