/// Central configuration for Zabira Academy Official API.
///
/// Matches the official OpenAPI documentation at:
/// https://api.zabiraacademy.com/api-docs/#/
abstract final class ApiConfig {
  static const String baseUrl = 'https://api.zabiraacademy.com/api';
  static const String assetBaseUrl = 'https://api.zabiraacademy.com';

  // ── Auth Endpoints ──────────────────────────────────────────────────────────
  static const String authLogin = '/auth/login.php';
  static const String authGoogleAuth = '/auth/google_auth.php';
  static const String authRegister = '/auth/register.php';
  static const String authForgotPassword = '/auth/forgot_password.php';
  static const String authValidateResetToken = '/auth/validate_reset_token.php';
  static const String authResetPassword = '/auth/reset_password.php';
  static const String authProfile = '/auth/profile.php';
  static const String authRefresh = '/auth/refresh.php';

  // ── Student & Dashboard Endpoints ──────────────────────────────────────────
  static const String studentDashboard = '/student/dashboard.php';
  static const String studentProfile = '/student/profile.php';
  static const String studentCompleteProfile = '/student/complete_profile.php';
  static const String studentChangePassword = '/student/change_password.php';
  static const String studentAvatar = '/student/avatar.php';
  static const String studentNotifications = '/student/notifications.php';
  static const String studentCertificates = '/student/certificates.php';
  static const String studentCertificatePdf = '/student/certificate_pdf.php';
  static const String studentAssignments = '/student/assignments.php';
  static const String studentLesson = '/student/lesson.php';

  // ── Courses Endpoints ───────────────────────────────────────────────────────
  static const String courseCategories = '/categories/list.php';
  static const String courseList = '/courses/public_list.php';
  static const String courseDetails = '/courses/public_details.php';
  static const String coursePreviewMedia = '/courses/preview_media.php';
  static const String courseReviews = '/reviews/list.php';

  // ── Enrollment & Progress Endpoints ─────────────────────────────────────────
  static const String enrollmentEnroll = '/enrollment/enroll.php';
  static const String enrollmentMyCourses = '/enrollment/my_courses.php';
  static const String enrollmentWishlist = '/enrollment/wishlist.php';
  static const String progressCourse = '/progress/course.php';
  static const String progressUpdate = '/progress/update.php';
  static const String quizSubmit = '/quiz/submit.php';

  // ── Payments & Checkout Endpoints ───────────────────────────────────────────
  static const String paymentsPaymentPlans = '/payments/payment_plans.php';
  static const String paymentsGateways = '/payments/gateways.php';
  static const String paymentsConfigStatus = '/payments/config_status.php';
  static const String paymentsCreateSession = '/payments/create_session.php';
  static const String paymentsVerify = '/payments/verify.php';
  static const String paymentsCheckoutSummary = '/payments/checkout_summary.php';
  static const String paymentsMyOrders = '/payments/my_orders.php';
  static const String paymentsOrderStatus = '/payments/order_status.php';
  static const String paymentsInvoice = '/payments/invoice.php';
  static const String paymentsApplyCoupon = '/payments/apply_coupon.php';
  static const String paymentsCancelOrder = '/payments/cancel_order.php';
  static const String paymentsMySchedules = '/payments/my_schedules.php';

  // ── Cart Endpoints ─────────────────────────────────────────────────────────
  static const String cartList = '/cart/list.php';
  static const String cartAdd = '/cart/add.php';
  static const String cartRemove = '/cart/remove.php';
  static const String cartCount = '/cart/count.php';
  static const String cartClear = '/cart/clear.php';
  static const String cartCheckout = '/cart/checkout.php';
  static const String cartStatus = '/cart/status.php';
  static const String cartMoveToWishlist = '/cart/move_to_wishlist.php';

  // ── Wishlist Endpoints ─────────────────────────────────────────────────────
  static const String wishlistCount = '/wishlist/count.php';
  static const String wishlistStatus = '/wishlist/status.php';
  static const String wishlistToggle = '/wishlist/toggle.php';

  // ── Kids Learning Portal Endpoints ─────────────────────────────────────────
  static const String kidsCategories = '/kids/public_categories.php';
  static const String kidsGames = '/kids/public_games.php';
  static const String kidsGame = '/kids/public_game.php';
  static const String kidsGameDetails = '/kids/public_game.php';
  static const String kidsGamePlay = '/kids/game_play.php';
  static const String kidsGameResult = '/kids/game_result.php';
  static const String kidsQuizzes = '/kids/public_quizzes.php';
  static const String kidsQuiz = '/kids/public_quiz.php';
  static const String kidsQuizDetails = '/kids/public_quiz.php';
  static const String kidsQuizStart = '/kids/quiz_start.php';
  static const String kidsQuizSubmit = '/kids/quiz_submit.php';

  // ── Store Endpoints ────────────────────────────────────────────────────────
  static const String storeCategories = '/store/public_categories.php';
  static const String storeList = '/store/public_list.php';
  static const String storeDetails = '/store/public_details.php';
  static const String storeCollections = '/store/public_collections.php';
  static const String storePurchase = '/store/purchase.php';
  static const String storePurchaseStatus = '/store/purchase_status.php';
  static const String storeDownload = '/store/download.php';

  // ── Nasheed Endpoints ───────────────────────────────────────────────────────
  static const String nasheedCategories = '/nasheed/public_categories.php';
  static const String nasheedList = '/nasheed/public_list.php';
  static const String nasheedDetails = '/nasheed/public_details.php';
  static const String nasheedDownload = '/nasheed/download.php';

  // ── Media Endpoints ─────────────────────────────────────────────────────────
  static const String mediaCategories = '/media/public_categories.php';
  static const String mediaList = '/media/public_list.php';
  static const String mediaDetails = '/media/public_details.php';
  static const String mediaTicket = '/media/ticket.php';
  static const String mediaStream = '/media/stream.php';

  // ── Library Endpoints ───────────────────────────────────────────────────────
  static const String libraryCategories = '/library/public_categories.php';
  static const String libraryCollections = '/library/public_collections.php';
  static const String libraryList = '/library/public_list.php';
  static const String libraryDetails = '/library/public_details.php';
  static const String libraryStats = '/library/public_stats.php';
  static const String libraryMyBooks = '/library/my_books.php';
  static const String libraryPdf = '/library/pdf.php';
  static const String libraryPurchase = '/library/purchase.php';
  static const String libraryPurchaseStatus = '/library/purchase_status.php';

  // ── Events Endpoints ────────────────────────────────────────────────────────
  static const String eventsFeatured = '/events/featured.php';
  static const String eventsList = '/events/public_list.php';
  static const String eventsDetails = '/events/public_details.php';
  static const String eventsRegister = '/events/register.php';
  static const String eventsRegistrationStatus = '/events/registration_status.php';
  static const String eventsMyRegistrations = '/events/my_registrations.php';

  // ── Free Trials & Live Classes ──────────────────────────────────────────────
  static const String freeTrialMyTrials = '/free-trial/my_trials.php';
  static const String freeTrialBook = '/free-trial/book.php';
  static const String freeTrialQuickEnroll = '/free-trial/quick_enroll.php';
  static const String freeTrialJoin = '/free-trial/join.php';
  static const String freeTrialAttendance = '/free-trial/attendance.php';
  static const String freeTrialStudentCancel = '/free-trial/student_cancel.php';

  // ── Scholarship Endpoints ───────────────────────────────────────────────────
  static const String scholarshipPublicContent = '/scholarship/public_content.php';
  static const String scholarshipPublicStats = '/scholarship/public_stats.php';
  static const String scholarshipPublicReports = '/scholarship/public_reports.php';
  static const String scholarshipApply = '/scholarship/apply.php';
  static const String scholarshipDonateCreate = '/scholarship/donate_create.php';
  static const String scholarshipDonateVerify = '/scholarship/donate_verify.php';
  static const String scholarshipDonateReceipt = '/scholarship/donate_receipt.php';

  // ── Announcements & General ─────────────────────────────────────────────────
  static const String announcementsActive = '/announcements/active.php';
  static const String homepageInsights = '/homepage_insights/public.php';
  static const String contactSubmit = '/contact/submit.php';

  /// Normalizes any endpoint path to ensure it contains .php and starts with /
  static String normalizePath(String path) {
    var p = path.trim();
    if (!p.startsWith('/')) p = '/$p';
    if (!p.endsWith('.php') && !p.contains('?')) {
      p = '$p.php';
    }
    return p;
  }

  /// Resolves relative image paths against [assetBaseUrl].
  static String? resolveImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();
    if (trimmed.startsWith('data:') || trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      return '$assetBaseUrl$trimmed';
    }
    return '$assetBaseUrl/$trimmed';
  }

  /// Resolves audio / media URLs against [assetBaseUrl].
  static String? resolveMediaUrl(String? url) {
    return resolveImageUrl(url);
  }
}
