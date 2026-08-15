import 'package:http/http.dart' as http;
import '../../../../core/constants/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../models/student_dashboard_model.dart';

/// Student API Network Service for Student Dashboard, Profile, Notifications & Certificates
class StudentApiService {
  StudentApiService({http.Client? client, ApiClient? apiClient})
      : _client = apiClient ?? ApiClient(client: client);

  final ApiClient _client;

  /// Fetch full Student Dashboard data
  Future<StudentDashboardModel> getDashboard({
    required String token,
    String? defaultName,
    String? defaultEmail,
    String? defaultPhoto,
  }) async {
    try {
      final response = await _client.get(ApiConfig.studentDashboard, token: token);
      
      // Concurrently fetch counts for wishlist, orders, and certificates to ensure exact synchronization
      int ordersCount = 0;
      int wishlistCount = 0;
      try {
        final ordersRes = await _client.get(ApiConfig.paymentsMyOrders, queryParameters: {'limit': 1}, token: token);
        ordersCount = int.tryParse((ordersRes['pagination']?['total'] ?? (ordersRes['data'] is List ? (ordersRes['data'] as List).length : 0)).toString()) ?? 0;
      } catch (_) {}

      try {
        final wishRes = await _client.get(ApiConfig.wishlistCount, token: token);
        wishlistCount = int.tryParse((wishRes['data']?['count'] ?? wishRes['count'] ?? 0).toString()) ?? 0;
      } catch (_) {}

      return StudentDashboardModel.fromJson(
        response,
        defaultName: defaultName,
        defaultEmail: defaultEmail,
        defaultPhoto: defaultPhoto,
        fallbackOrdersCount: ordersCount,
        fallbackWishlistCount: wishlistCount,
      );
    } catch (_) {
      // Fallback with live individual counts
      int ordersCount = 0;
      int wishlistCount = 0;
      try {
        final ordersRes = await _client.get(ApiConfig.paymentsMyOrders, queryParameters: {'limit': 1}, token: token);
        ordersCount = int.tryParse((ordersRes['pagination']?['total'] ?? 0).toString()) ?? 0;
      } catch (_) {}

      try {
        final wishRes = await _client.get(ApiConfig.wishlistCount, token: token);
        wishlistCount = int.tryParse((wishRes['data']?['count'] ?? wishRes['count'] ?? 0).toString()) ?? 0;
      } catch (_) {}

      return StudentDashboardModel(
        studentName: defaultName ?? '',
        email: defaultEmail ?? '',
        photoUrl: defaultPhoto,
        myOrdersCount: ordersCount,
        wishlistCount: wishlistCount,
      );
    }
  }

  /// `GET /student/notifications.php`
  Future<List<StudentNotificationItem>> getNotifications({required String token}) async {
    final response = await _client.get(ApiConfig.studentNotifications, token: token);
    final rawList = response['data'] ?? response['notifications'] ?? [];
    if (rawList is List) {
      return rawList
          .whereType<Map<String, dynamic>>()
          .map((n) => StudentNotificationItem.fromJson(n))
          .toList();
    }
    return [];
  }

  /// `POST /student/notifications.php` (Mark all notifications as read)
  Future<bool> markNotificationsRead({required String token, int? notificationId}) async {
    final body = <String, dynamic>{};
    if (notificationId != null) {
      body['id'] = notificationId;
    } else {
      body['mark_all'] = '1';
    }
    final response = await _client.post(ApiConfig.studentNotifications, body: body, token: token);
    return response['success'] == true;
  }

  /// `GET /student/certificates.php`
  Future<List<StudentCertificateItem>> getCertificates({required String token}) async {
    final response = await _client.get(ApiConfig.studentCertificates, token: token);
    final rawList = response['data'] ?? response['certificates'] ?? [];
    if (rawList is List) {
      return rawList
          .whereType<Map<String, dynamic>>()
          .map((c) => StudentCertificateItem.fromJson(c))
          .toList();
    }
    return [];
  }

  /// `GET /free-trial/my_trials.php`
  Future<List<Map<String, dynamic>>> getMyTrials({required String token}) async {
    final response = await _client.get(ApiConfig.freeTrialMyTrials, token: token);
    final rawList = response['data'] ?? response['trials'] ?? [];
    if (rawList is List) {
      return rawList.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }
}
