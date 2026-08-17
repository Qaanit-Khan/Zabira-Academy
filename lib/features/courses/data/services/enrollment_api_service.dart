import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_config.dart';
import '../models/enrolled_course_model.dart';

/// Network service interacting with Zabira Academy Enrollment API endpoints.
///
/// Follows the official API specification:
/// `GET  /enrollment/my_courses`
/// `POST /enrollment/enroll`
class EnrollmentApiService {
  EnrollmentApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'ZabiraAcademy-App/1.0',
  };

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
    if (kDebugMode) debugPrint('[ENROLLMENT API] GET $primaryUri');

    try {
      final response = await _client.get(primaryUri, headers: headers).timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        return _parseSuccess(response.body);
      }

      if (response.statusCode == 404 && !path.endsWith('.php')) {
        final fallbackUri = Uri.parse('${ApiConfig.baseUrl}$path.php').replace(queryParameters: queryParams);
        if (kDebugMode) debugPrint('[ENROLLMENT API RETRY] GET $fallbackUri');

        final fallbackResp = await _client.get(fallbackUri, headers: headers).timeout(Duration(seconds: timeoutSeconds));
        if (fallbackResp.statusCode == 200) {
          return _parseSuccess(fallbackResp.body);
        }
      }

      throw Exception('Enrollment request failed (HTTP ${response.statusCode})');
    } on TimeoutException {
      throw Exception('Request timed out. Please check your network.');
    } on SocketException {
      throw Exception('Unable to reach Zabira Academy server.');
    } catch (e) {
      if (kDebugMode) debugPrint('[ENROLLMENT API ERROR] GET $primaryUri -> $e');
      rethrow;
    }
  }

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
    if (kDebugMode) debugPrint('[ENROLLMENT API] POST $primaryUri | Body: $jsonBody');

    try {
      final response = await _client.post(primaryUri, headers: headers, body: jsonBody).timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _parseSuccess(response.body);
      }

      if (response.statusCode == 404 && !path.endsWith('.php')) {
        final fallbackUri = Uri.parse('${ApiConfig.baseUrl}$path.php');
        if (kDebugMode) debugPrint('[ENROLLMENT API RETRY] POST $fallbackUri');

        final fallbackResp = await _client.post(fallbackUri, headers: headers, body: jsonBody).timeout(Duration(seconds: timeoutSeconds));
        if (fallbackResp.statusCode == 200 || fallbackResp.statusCode == 201) {
          return _parseSuccess(fallbackResp.body);
        }
      }

      throw Exception('Enrollment action failed (HTTP ${response.statusCode})');
    } on TimeoutException {
      throw Exception('Request timed out. Please check your network.');
    } on SocketException {
      throw Exception('Unable to reach Zabira Academy server.');
    } catch (e) {
      if (kDebugMode) debugPrint('[ENROLLMENT API ERROR] POST $primaryUri -> $e');
      rethrow;
    }
  }

  /// `GET /enrollment/my_courses`
  Future<List<EnrolledCourseModel>> getMyCourses({String? token}) async {
    final response = await _getWithFallback(ApiConfig.enrollmentMyCourses, token: token);
    
    if (kDebugMode) {
      debugPrint('[ENROLLMENT API] getMyCourses raw keys: ${response.keys.toList()}');
    }

    final dynamic data = response['data'] ?? response;
    List? rawList;

    if (data is List) {
      rawList = data;
    } else if (data is Map) {
      rawList = (data['courses'] ?? data['enrollments'] ?? data['items'] ?? data['data'] ?? data['enrolled_courses']) as List?;
    } else if (response['courses'] is List) {
      rawList = response['courses'] as List;
    } else if (response['enrollments'] is List) {
      rawList = response['enrollments'] as List;
    }

    if (rawList != null) {
      final courses = rawList
          .whereType<Map<String, dynamic>>()
          .map((e) => EnrolledCourseModel.fromJson(e))
          .where((e) => e.courseId > 0 || e.id > 0)
          .toList();
      
      if (kDebugMode) {
        debugPrint('[ENROLLMENT API] getMyCourses parsed count: ${courses.length}');
      }
      return courses;
    }

    if (kDebugMode) {
      debugPrint('[ENROLLMENT API] getMyCourses returned empty or unknown structure');
    }
    return [];
  }

  /// `POST /enrollment/enroll`
  ///
  /// Per OpenAPI spec: course_id (required integer), payment_plan (optional string),
  /// plan_type (optional string), email (optional string).
  Future<Map<String, dynamic>> enrollInCourse({
    required int courseId,
    String? paymentPlan,
    String? planType,
    String? email,
    String? token,
  }) async {
    final body = <String, dynamic>{
      'course_id': courseId,
    };
    if (paymentPlan != null) body['payment_plan'] = paymentPlan;
    if (planType != null) body['plan_type'] = planType;
    if (email != null) body['email'] = email;

    if (kDebugMode) {
      debugPrint('[ENROLLMENT API] enrollInCourse | course_id=$courseId | payment_plan=$paymentPlan | plan_type=$planType');
    }

    final result = await _postWithFallback(ApiConfig.enrollmentEnroll, body: body, token: token);

    if (kDebugMode) {
      final data = result['data'] is Map<String, dynamic> ? result['data'] as Map<String, dynamic> : result;
      final orderId = data['order_id'] ?? data['id'];
      final status = data['status'] ?? result['message'];
      debugPrint('[ENROLLMENT API] enrollInCourse response | order_id=$orderId | status=$status | success=${result['success']}');
    }

    return result;
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
