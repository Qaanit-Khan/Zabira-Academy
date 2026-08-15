import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_config.dart';
import '../models/event_item_model.dart';

class EventsApiService {
  EventsApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'User-Agent': 'ZabiraAcademy-App/1.0',
  };

  Future<Map<String, dynamic>> _getWithFallback(String path, {Map<String, String>? queryParams}) async {
    final primaryUri = Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: queryParams);
    debugPrint('[EVENTS API] GET $primaryUri');

    try {
      final response = await _client.get(primaryUri, headers: _headers).timeout(const Duration(seconds: 12));
      debugPrint('[EVENTS API] HTTP ${response.statusCode} | URL: $primaryUri');

      if (response.statusCode == 200) {
        return _parseJson(response.body, primaryUri.toString());
      }

      if (response.statusCode == 404 && !path.endsWith('.php')) {
        final fallbackUri = Uri.parse('${ApiConfig.baseUrl}$path.php').replace(queryParameters: queryParams);
        debugPrint('[EVENTS API RETRY] GET $fallbackUri');

        final fallbackResponse = await _client.get(fallbackUri, headers: _headers).timeout(const Duration(seconds: 12));
        debugPrint('[EVENTS API] HTTP ${fallbackResponse.statusCode} | URL: $fallbackUri');

        if (fallbackResponse.statusCode == 200) {
          return _parseJson(fallbackResponse.body, fallbackUri.toString());
        }
      }

      throw Exception('Events request failed (HTTP ${response.statusCode})');
    } catch (e) {
      debugPrint('[EVENTS API EXCEPTION] GET $primaryUri -> $e');
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
      debugPrint('[EVENTS API PARSE ERROR] URL: $url | Error: $e');
      rethrow;
    }
  }

  /// `GET /events/featured`
  Future<EventItemModel?> getFeaturedEvent() async {
    try {
      final json = await _getWithFallback(ApiConfig.eventsFeatured);
      final data = json['data'];
      if (data != null && data is Map<String, dynamic> && data['event'] != null) {
        return EventItemModel.fromJson(data['event'] as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[EVENTS API] Featured event error: $e');
    }
    return null;
  }

  /// `GET /events/public_list`
  Future<List<EventItemModel>> getEventsList({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
    String? type,
    String? upcoming,
    String? past,
    String? featured,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (type != null) queryParams['type'] = type;
    if (upcoming != null) queryParams['upcoming'] = upcoming;
    if (past != null) queryParams['past'] = past;
    if (featured != null) queryParams['featured'] = featured;
    if (status != null) queryParams['status'] = status;

    final json = await _getWithFallback(ApiConfig.eventsList, queryParams: queryParams);
    final data = json['data'];
    if (data != null && data is Map<String, dynamic>) {
      final events = data['events'] ?? data['items'];
      if (events is List) {
        return events
            .map((e) => EventItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }

  /// `GET /events/public_details`
  Future<EventItemModel?> getEventDetails({int? id, String? slug}) async {
    final queryParams = <String, String>{};
    if (id != null && id > 0) queryParams['id'] = id.toString();
    if (slug != null && slug.isNotEmpty) queryParams['slug'] = slug;

    final json = await _getWithFallback(ApiConfig.eventsDetails, queryParams: queryParams);
    final data = json['data'];
    if (data != null && data is Map<String, dynamic>) {
      if (data['event'] != null && data['event'] is Map<String, dynamic>) {
        return EventItemModel.fromJson(data['event'] as Map<String, dynamic>);
      }
      return EventItemModel.fromJson(data);
    }
    return null;
  }

  /// `POST /events/register`
  Future<Map<String, dynamic>> registerForEvent({
    required int eventId,
    required String name,
    required String email,
    required String phone,
    String? grade,
    String? notes,
    String? token,
  }) async {
    final primaryUri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.eventsRegister}');
    final headers = Map<String, String>.from(_headers);
    headers['Content-Type'] = 'application/json';
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final bodyMap = <String, dynamic>{
      'event_id': eventId,
      'name': name,
      'email': email,
      'phone': phone,
    };
    if (grade != null) bodyMap['grade'] = grade;
    if (notes != null) bodyMap['notes'] = notes;
    final body = jsonEncode(bodyMap);

    final response = await _client.post(primaryUri, headers: headers, body: body).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _parseJson(response.body, primaryUri.toString());
    }

    if (response.statusCode == 404) {
      final fallbackUri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.eventsRegister}.php');
      final fallbackResp = await _client.post(fallbackUri, headers: headers, body: body).timeout(const Duration(seconds: 15));
      if (fallbackResp.statusCode == 200 || fallbackResp.statusCode == 201) {
        return _parseJson(fallbackResp.body, fallbackUri.toString());
      }
    }

    throw Exception('Registration failed (HTTP ${response.statusCode})');
  }
}
