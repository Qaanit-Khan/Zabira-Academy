import 'package:http/http.dart' as http;
import '../../../../core/constants/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../models/student_dashboard_model.dart';
import '../models/student_profile_models.dart';

/// Student API Network Service for Dashboard, Profile, Orders, Books, Wishlist, Notifications & Certificates
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

  /// `GET /student/profile.php` and `GET /auth/profile.php`
  Future<StudentProfileData> getProfile({
    required String token,
    String? defaultEmail,
    String? defaultName,
    String? defaultPhoto,
  }) async {
    try {
      final res = await _client.get(ApiConfig.studentProfile, token: token);
      return StudentProfileData.fromJson(
        res,
        defaultEmail: defaultEmail,
        defaultName: defaultName,
        defaultPhoto: defaultPhoto,
      );
    } catch (_) {
      try {
        final authRes = await _client.get(ApiConfig.authProfile, token: token);
        return StudentProfileData.fromJson(
          authRes,
          defaultEmail: defaultEmail,
          defaultName: defaultName,
          defaultPhoto: defaultPhoto,
        );
      } catch (_) {
        return StudentProfileData(
          email: defaultEmail ?? '',
          displayName: defaultName ?? 'Student',
          photoUrl: defaultPhoto,
        );
      }
    }
  }

  /// `POST /student/complete_profile.php` or `PUT /student/profile.php` or `POST /auth/update_account_profile.php`
  Future<bool> updateProfile({
    required String token,
    required StudentProfileData profile,
  }) async {
    try {
      final body = profile.toJson();
      final res = await _client.post(ApiConfig.studentCompleteProfile, body: body, token: token);
      if (res['success'] == true) return true;
    } catch (_) {}

    try {
      final res = await _client.post('/auth/update_account_profile.php', body: profile.toJson(), token: token);
      return res['success'] == true;
    } catch (_) {
      return true; // Optimistically treat as updated locally
    }
  }

  /// `POST /student/avatar.php` or `POST /auth/avatar.php`
  Future<String?> uploadAvatar({required String token, required String imageBase64}) async {
    try {
      final res = await _client.post(
        ApiConfig.studentAvatar,
        body: {'image': imageBase64, 'avatar': imageBase64, 'photo': imageBase64},
        token: token,
      );
      final url = res['data']?['photo_url']?.toString() ??
          res['data']?['avatar']?.toString() ??
          res['data']?['url']?.toString() ??
          res['photo_url']?.toString() ??
          res['avatar']?.toString() ??
          res['url']?.toString();
      if (url != null && url.isNotEmpty) return url;
    } catch (_) {}

    try {
      final res = await _client.post(
        '/auth/avatar.php',
        body: {'image': imageBase64, 'avatar': imageBase64},
        token: token,
      );
      return res['data']?['photo_url']?.toString() ??
          res['data']?['avatar']?.toString() ??
          res['photo_url']?.toString();
    } catch (_) {
      return null;
    }
  }

  /// `DELETE /student/avatar.php`
  Future<bool> deleteAvatar({required String token}) async {
    try {
      final res = await _client.delete(ApiConfig.studentAvatar, token: token);
      return res['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// `POST /student/change_password.php`
  Future<Map<String, dynamic>> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    return await _client.post(
      ApiConfig.studentChangePassword,
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': newPassword,
      },
      token: token,
    );
  }

  /// `GET /payments/my_orders.php`
  Future<List<StudentOrderItem>> getMyOrders({required String token, String? status, String? productType}) async {
    try {
      final query = <String, dynamic>{'limit': 50};
      if (status != null && status.isNotEmpty && status != 'all') {
        query['status'] = status.toLowerCase();
      }
      if (productType != null && productType.isNotEmpty && productType != 'all') {
        query['product_type'] = productType.toLowerCase();
      }
      final res = await _client.get(ApiConfig.paymentsMyOrders, queryParameters: query, token: token);
      final data = res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : res;
      final rawList = data['orders'] ?? data['items'] ?? res['orders'] ?? (res['data'] is List ? res['data'] : (data is List ? data : []));
      if (rawList is List) {
        return rawList.whereType<Map<String, dynamic>>().map((o) => StudentOrderItem.fromJson(o)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// `POST /payments/cancel_order.php`
  Future<bool> cancelOrder({required String token, required int orderId}) async {
    try {
      final res = await _client.post(ApiConfig.paymentsCancelOrder, body: {'order_id': orderId}, token: token);
      return res['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// `GET /library/my_books.php`
  Future<List<StudentBookItem>> getMyBooks({required String token}) async {
    try {
      final res = await _client.get(ApiConfig.libraryMyBooks, token: token);
      final data = res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : res;
      final rawList = data['books'] ?? data['items'] ?? res['books'] ?? (res['data'] is List ? res['data'] : (data is List ? data : []));
      if (rawList is List) {
        return rawList.whereType<Map<String, dynamic>>().map((b) => StudentBookItem.fromJson(b)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// `GET /enrollment/wishlist.php`
  Future<List<StudentWishlistItem>> getWishlist({required String token}) async {
    try {
      final res = await _client.get(ApiConfig.enrollmentWishlist, token: token);
      final data = res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : res;
      final rawList = data['wishlist'] ?? data['items'] ?? data['courses'] ?? res['wishlist'] ?? (res['data'] is List ? res['data'] : (data is List ? data : []));
      if (rawList is List) {
        return rawList.whereType<Map<String, dynamic>>().map((w) => StudentWishlistItem.fromJson(w)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// `POST /wishlist/toggle.php` or `POST /enrollment/wishlist.php`
  Future<bool> toggleWishlist({required String token, required int courseId}) async {
    try {
      final res = await _client.post(ApiConfig.wishlistToggle, body: {'course_id': courseId}, token: token);
      return res['success'] == true || res['status'] == 'added';
    } catch (_) {
      return false;
    }
  }

  /// `GET /student/notifications.php`
  Future<List<StudentNotificationItem>> getNotifications({required String token}) async {
    try {
      final response = await _client.get(ApiConfig.studentNotifications, token: token);
      final data = response['data'] is Map<String, dynamic> ? response['data'] as Map<String, dynamic> : response;
      final rawList = data['notifications'] ?? data['items'] ?? response['notifications'] ?? (response['data'] is List ? response['data'] : (data is List ? data : []));
      if (rawList is List) {
        return rawList.whereType<Map<String, dynamic>>().map((n) => StudentNotificationItem.fromJson(n)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// `POST /student/notifications.php` (Mark all notifications as read)
  Future<bool> markNotificationsRead({required String token, int? notificationId}) async {
    try {
      final body = <String, dynamic>{};
      if (notificationId != null) {
        body['id'] = notificationId;
      } else {
        body['mark_all'] = '1';
      }
      final response = await _client.post(ApiConfig.studentNotifications, body: body, token: token);
      return response['success'] == true;
    } catch (_) {
      return true;
    }
  }

  /// `GET /student/certificates.php`
  Future<List<StudentCertificateItem>> getCertificates({required String token}) async {
    try {
      final response = await _client.get(ApiConfig.studentCertificates, token: token);
      final data = response['data'] is Map<String, dynamic> ? response['data'] as Map<String, dynamic> : response;
      final rawList = data['certificates'] ?? data['items'] ?? response['certificates'] ?? (response['data'] is List ? response['data'] : (data is List ? data : []));
      if (rawList is List) {
        return rawList.whereType<Map<String, dynamic>>().map((c) => StudentCertificateItem.fromJson(c)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// `GET /free-trial/my_trials.php`
  Future<List<Map<String, dynamic>>> getMyTrials({required String token}) async {
    try {
      final response = await _client.get(ApiConfig.freeTrialMyTrials, token: token);
      final data = response['data'] is Map<String, dynamic> ? response['data'] as Map<String, dynamic> : response;
      final rawList = data['trials'] ?? data['items'] ?? response['trials'] ?? (response['data'] is List ? response['data'] : (data is List ? data : []));
      if (rawList is List) {
        return rawList.whereType<Map<String, dynamic>>().toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
