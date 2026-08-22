import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_config.dart';

/// Network service interacting with Zabira Academy Courses API endpoints.
///
/// Follows the official API specification:
/// `GET /categories/list`
/// `GET /courses/public_list`
/// `GET /courses/public_details`
/// `GET /courses/preview_media`
class CourseService {
  CourseService({http.Client? client}) : _client = client ?? http.Client();

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
      throw Exception('Course request failed (HTTP ${response.statusCode})');
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

  /// `GET /categories/list`
  Future<Map<String, dynamic>> getCategories() async {
    return _getWithFallback(ApiConfig.courseCategories);
  }

  /// `GET /courses/public_list`
  Future<Map<String, dynamic>> getCourses({
    int page = 1,
    int limit = 100,
    String? search,
    int? categoryId,
    String? level,
    String? language,
    double? price,
    String? sort,
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
    if (level != null && level.isNotEmpty) queryParams['level'] = level;
    if (language != null && language.isNotEmpty) queryParams['language'] = language;
    if (price != null && price > 0) queryParams['price'] = price.toString();
    // Note: 'featured' sort is handled client-side so backend returns ALL courses (including new ones added by admin) instead of filtering to only 4 featured courses.
    if (sort != null && sort.isNotEmpty && sort != 'featured') {
      queryParams['sort'] = sort;
    }

    return _getWithFallback(ApiConfig.courseList, queryParams: queryParams);
  }

  /// `GET /courses/public_details`
  Future<Map<String, dynamic>> getCourseDetails({int? id, String? slug}) async {
    final queryParams = <String, String>{};
    if (id != null && id > 0) queryParams['id'] = id.toString();
    if (slug != null && slug.isNotEmpty) queryParams['slug'] = slug;

    return _getWithFallback(ApiConfig.courseDetails, queryParams: queryParams);
  }

  /// `GET /courses/preview_media`
  Future<Map<String, dynamic>> getPreviewMedia({required int lessonId}) async {
    final queryParams = <String, String>{'lesson_id': lessonId.toString()};
    return _getWithFallback(ApiConfig.coursePreviewMedia, queryParams: queryParams);
  }
}
