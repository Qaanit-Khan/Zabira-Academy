/// Central configuration for Zabira Academy Official API.
///
/// Matches the official API documentation at:
/// https://api.zabiraacademy.com/api-docs/
abstract final class ApiConfig {
  static const String baseUrl = 'https://api.zabiraacademy.com/api';
  static const String assetBaseUrl = 'https://api.zabiraacademy.com';

  // ── Auth Endpoints (Official OpenAPI Docs) ─────────────────────────────────
  static const String authLogin = '/auth/login';
  static const String authGoogleAuth = '/auth/google_auth';
  static const String authRegister = '/auth/register';
  static const String authForgotPassword = '/auth/forgot_password';
  static const String authValidateResetToken = '/auth/validate_reset_token';
  static const String authResetPassword = '/auth/reset_password';
  static const String authProfile = '/auth/profile';
  static const String authRefresh = '/auth/refresh';

  // ── Cart Endpoints (Official API Docs) ─────────────────────────────────────
  static const String cartList = '/cart/list';
  static const String cartAdd = '/cart/add';
  static const String cartRemove = '/cart/remove';
  static const String cartCount = '/cart/count';
  static const String cartClear = '/cart/clear';
  static const String cartCheckout = '/cart/checkout';
  static const String cartStatus = '/cart/status';

  // ── Enrollment Endpoints (Official API Docs) ───────────────────────────────
  static const String enrollmentMyCourses = '/enrollment/my_courses';
  static const String enrollmentEnroll = '/enrollment/enroll';
  static const String enrollmentWishlist = '/enrollment/wishlist';

  // ── Payments Endpoints (Official API Docs) ─────────────────────────────────
  static const String paymentsCreateSession = '/payments/create_session';
  static const String paymentsVerify = '/payments/verify';
  static const String paymentsGateways = '/payments/gateways';
  static const String paymentsCheckoutSummary = '/payments/checkout_summary';

  // ── Progress Endpoints (Official API Docs) ─────────────────────────────────
  static const String progressCourse = '/progress/course';
  static const String progressUpdate = '/progress/update';

  // ── Student Endpoints (Official API Docs) ──────────────────────────────────
  static const String studentProfile = '/student/profile';
  static const String studentDashboard = '/student/dashboard';

  // ── Store Endpoints (Official API Docs) ───────────────────────────────────
  static const String storeCategories = '/store/public_categories';
  static const String storeList = '/store/public_list';
  static const String storeDetails = '/store/public_details';
  static const String storeCollections = '/store/public_collections';
  static const String storePurchase = '/store/purchase';

  // ── Courses Endpoints (Official API Docs) ─────────────────────────────────
  static const String courseCategories = '/categories/list';
  static const String courseList = '/courses/public_list';
  static const String courseDetails = '/courses/public_details';
  static const String coursePreviewMedia = '/courses/preview_media';

  // ── Media Endpoints (Official API Docs) ───────────────────────────────────
  static const String mediaCategories = '/media/public_categories';
  static const String mediaList = '/media/public_list';
  static const String mediaDetails = '/media/public_details';
  static const String mediaStream = '/media/stream';

  // ── Nasheed Endpoints (Official API Docs) ─────────────────────────────────
  static const String nasheedCategories = '/nasheed/public_categories';
  static const String nasheedList = '/nasheed/public_list';
  static const String nasheedDetails = '/nasheed/public_details';
  static const String nasheedDownload = '/nasheed/download';

  // ── Library Endpoints (Official API Docs) ─────────────────────────────────
  static const String libraryCategories = '/library/public_categories';
  static const String libraryCollections = '/library/public_collections';
  static const String libraryList = '/library/public_list';
  static const String libraryDetails = '/library/public_details';
  static const String libraryStats = '/library/public_stats';

  // ── Events Endpoints (Official API Docs) ──────────────────────────────────
  static const String eventsFeatured = '/events/featured';
  static const String eventsList = '/events/public_list';
  static const String eventsDetails = '/events/public_details';
  static const String eventsRegister = '/events/register';
  static const String eventsRegistrationStatus = '/events/registration_status';

  /// Resolves relative image paths against [assetBaseUrl].
  static String? resolveImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      return '$assetBaseUrl$trimmed';
    }
    return '$assetBaseUrl/$trimmed';
  }
}
