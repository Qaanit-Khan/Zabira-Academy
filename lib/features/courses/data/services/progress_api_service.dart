import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_config.dart';

/// Network service interacting with Zabira Academy Progress API endpoints.
///
/// Follows the official API specification:
/// `GET  /progress/course`
/// `POST /progress/update`
class ProgressApiService {
  ProgressApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'ZabiraAcademy-App/1.0',
  };

  /// `GET /progress/course`
  Future<Map<String, dynamic>> getCourseProgress({
    required int courseId,
    String? token,
  }) async {
    final headers = Map<String, String>.from(_headers);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final queryParams = {'course_id': courseId.toString()};
    final primaryUri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.progressCourse}').replace(queryParameters: queryParams);
    if (kDebugMode) debugPrint('[PROGRESS API] GET $primaryUri');

    try {
      final response = await _client.get(primaryUri, headers: headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        return {'success': true, 'data': decoded};
      }

      if (response.statusCode == 404) {
        final fallbackUri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.progressCourse}.php').replace(queryParameters: queryParams);
        final fallbackResp = await _client.get(fallbackUri, headers: headers).timeout(const Duration(seconds: 10));
        if (fallbackResp.statusCode == 200) {
          final decoded = jsonDecode(fallbackResp.body);
          if (decoded is Map<String, dynamic>) return decoded;
          return {'success': true, 'data': decoded};
        }
      }

      return {'success': false};
    } catch (e) {
      if (kDebugMode) debugPrint('[PROGRESS API ERROR] GET $primaryUri -> $e');
      return {'success': false};
    }
  }

  /// `POST /progress/update`
  Future<bool> updateProgress({
    required int courseId,
    required int lessonId,
    String? status,
    double? progressPercent,
    double? watchPercent,
    int? lastPositionSeconds,
    int? timeSpentSeconds,
    String? token,
  }) async {
    final headers = Map<String, String>.from(_headers);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final body = <String, dynamic>{
      'course_id': courseId,
      'lesson_id': lessonId,
    };
    if (status != null) body['status'] = status;
    if (progressPercent != null) body['progress_percent'] = progressPercent.toStringAsFixed(1);
    if (watchPercent != null) body['watch_percent'] = watchPercent.toStringAsFixed(1);
    if (lastPositionSeconds != null) body['last_position_seconds'] = lastPositionSeconds.toString();
    if (timeSpentSeconds != null) body['time_spent_seconds'] = timeSpentSeconds.toString();

    final jsonBody = jsonEncode(body);
    final primaryUri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.progressUpdate}');
    if (kDebugMode) debugPrint('[PROGRESS API] POST $primaryUri | Body: $jsonBody');

    try {
      final response = await _client.post(primaryUri, headers: headers, body: jsonBody).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      if (response.statusCode == 404) {
        final fallbackUri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.progressUpdate}.php');
        final fallbackResp = await _client.post(fallbackUri, headers: headers, body: jsonBody).timeout(const Duration(seconds: 10));
        return fallbackResp.statusCode == 200 || fallbackResp.statusCode == 201;
      }

      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('[PROGRESS API ERROR] POST $primaryUri -> $e');
      return false;
    }
  }
}
