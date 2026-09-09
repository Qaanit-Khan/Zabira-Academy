import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/models/user_role.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/auth_page.dart';
import '../features/auth/presentation/pages/reset_password_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/auth/presentation/pages/teacher_login_page.dart';
import '../features/courses/presentation/pages/course_details_page.dart';
import '../features/courses/presentation/pages/course_learning_page.dart';
import '../features/courses/presentation/pages/courses_page.dart';
import '../features/events/presentation/pages/event_details_page.dart';
import '../features/events/presentation/pages/events_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/kids/data/models/kids_models.dart';
import '../features/kids/presentation/pages/kids_duas_page.dart';
import '../features/kids/presentation/pages/kids_game_detail_page.dart';
import '../features/kids/presentation/pages/kids_game_page.dart';
import '../features/kids/presentation/pages/kids_games_page.dart';
import '../features/kids/presentation/pages/kids_portal_page.dart';
import '../features/kids/presentation/pages/kids_quiz_detail_page.dart';
import '../features/kids/presentation/pages/kids_quiz_page.dart';
import '../features/kids/presentation/pages/kids_quizzes_page.dart';
import '../features/kids/presentation/pages/kids_stories_page.dart';
import '../features/kids/presentation/pages/kids_story_detail_page.dart';
import '../features/library/presentation/pages/library_item_details_page.dart';
import '../features/library/presentation/pages/library_page.dart';
import '../features/media/presentation/pages/media_details_page.dart';
import '../features/media/presentation/pages/media_page.dart';
import '../features/nasheed/presentation/pages/nasheed_page.dart';
import '../features/parent/presentation/pages/parent_dashboard_page.dart';
import '../features/payment/presentation/pages/checkout_page.dart';
import '../features/scholarship/presentation/pages/scholarship_page.dart';
import '../features/payment/presentation/pages/payment_success_page.dart';
import '../features/store/presentation/pages/cart_page.dart';
import '../features/store/presentation/pages/store_page.dart';
import '../features/store/presentation/pages/store_product_details_page.dart';
import '../features/student/presentation/pages/profile_page.dart';
import '../features/student/presentation/pages/student_certificates_page.dart';
import '../features/student/presentation/pages/student_continue_learning_page.dart';
import '../features/student/presentation/pages/student_dashboard_page.dart';
import '../features/student/presentation/pages/student_help_center_page.dart';
import '../features/student/presentation/pages/student_my_books_page.dart';
import '../features/student/presentation/pages/student_my_courses_page.dart';
import '../features/student/presentation/pages/student_my_orders_page.dart';
import '../features/student/presentation/pages/student_notifications_page.dart';
import '../features/student/presentation/pages/student_settings_page.dart';
import '../features/student/presentation/pages/student_wishlist_page.dart';
import '../features/teacher/presentation/pages/teacher_dashboard_page.dart';

/// Zabira Academy Route Names
abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String teacherLogin = '/teacher-login';
  static const String parentDash = '/parent';
  static const String studentDash = '/student';
  static const String teacherDash = '/teacher';
  static const String home = '/home';
  static const String courses = '/courses';
  static const String courseDetails = '/courses/:id';
  static const String courseLearn = '/courses/:id/learn';
  static const String myCourses = '/my-courses';
  static const String store = '/store';
  static const String storeDetails = '/store/:id';
  static const String cart = '/cart';
  static const String profile = '/profile';
  static const String media = '/media';
  static const String mediaDetails = '/media/:id';
  static const String nasheed = '/nasheed';
  static const String library = '/library';
  static const String libraryDetails = '/library/:id';
  static const String events = '/events';
  static const String eventDetails = '/events/:id';
  static const String kids = '/kids';
  static const String scholarship = '/scholarship';
  static const String checkout = '/checkout';
  static const String paymentSuccess = '/payment-success';
  static const String myOrders = '/my-orders';
  static const String studentDashboard = '/student/dashboard';
  static const String studentCourses = '/student/courses';
  static const String studentMyBooks = '/student/my-books';
  static const String studentContinue = '/student/continue';
  static const String studentCertificates = '/student/certificates';
  static const String studentProfile = '/student/profile';
  static const String studentOrders = '/student/orders';
  static const String studentWishlist = '/student/wishlist';
  static const String studentNotifications = '/student/notifications';
  static const String studentHelp = '/student/help';
  static const String studentSettings = '/student/settings';
}

/// Zabira Academy Router
GoRouter buildRouter(BuildContext context) {
  final authController = context.read<AuthController>();

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authController,
    redirect: (context, state) {
      final auth = context.read<AuthController>();
      final isAuth = auth.isAuthenticated;
      final isInitial = auth.status == AuthStatus.initial;

      // On splash — allow
      if (state.matchedLocation == AppRoutes.splash) return null;

      // Public pages — always allow unauthenticated visitors
      final loc = state.matchedLocation;
      final isPublicPage = loc == AppRoutes.home ||
          loc == AppRoutes.courses ||
          loc.startsWith('/courses/') ||
          loc == AppRoutes.store ||
          loc.startsWith('/store/') ||
          loc == AppRoutes.cart ||
          loc == AppRoutes.profile ||
          loc == AppRoutes.myCourses ||
          loc.startsWith('/student') ||
          loc == AppRoutes.media ||
          loc.startsWith('/media/') ||
          loc == AppRoutes.nasheed ||
          loc == AppRoutes.library ||
          loc.startsWith('/library/') ||
          loc == AppRoutes.events ||
          loc.startsWith('/events/') ||
          loc == AppRoutes.kids ||
          loc.startsWith('/kids/') ||
          loc == AppRoutes.scholarship ||
          loc == AppRoutes.checkout ||
          loc == AppRoutes.paymentSuccess ||
          loc == AppRoutes.myOrders ||
          loc == AppRoutes.resetPassword;

      if (isPublicPage) return null;

      // Still loading
      if (isInitial) return null;

      final authRoutes = [
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
        AppRoutes.teacherLogin,
      ];

      final isOnAuthPage = authRoutes.contains(state.matchedLocation);

      if (!isAuth && !isOnAuthPage) {
        return AppRoutes.home;
      }

      if (isAuth && isOnAuthPage) {
        final returnTo = auth.consumePendingReturnTo();
        if (returnTo != null && returnTo.isNotEmpty) {
          return returnTo;
        }
        if (auth.user?.role == UserRole.teacher) {
          return AppRoutes.teacherDash;
        }
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashPage()),
      GoRoute(path: AppRoutes.home, builder: (context, state) => const HomePage()),
      GoRoute(path: AppRoutes.courses, builder: (context, state) => const CoursesPage()),
      GoRoute(
        path: AppRoutes.courseDetails,
        builder: (context, state) {
          final idParam = state.pathParameters['id'];
          final id = int.tryParse(idParam ?? '') ?? 0;
          return CourseDetailsPage(courseId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.courseLearn,
        builder: (context, state) {
          final idParam = state.pathParameters['id'];
          final id = int.tryParse(idParam ?? '') ?? 0;
          final lessonId = int.tryParse(state.uri.queryParameters['lesson_id'] ?? '');
          return CourseLearningPage(courseId: id, initialLessonId: lessonId);
        },
      ),
      GoRoute(path: AppRoutes.myCourses, builder: (context, state) => const StudentMyCoursesPage()),
      GoRoute(path: AppRoutes.store, builder: (context, state) => const StorePage()),
      GoRoute(
        path: AppRoutes.storeDetails,
        builder: (context, state) {
          final idParam = state.pathParameters['id'];
          final id = int.tryParse(idParam ?? '') ?? 0;
          return StoreProductDetailsPage(productId: id);
        },
      ),
      GoRoute(path: AppRoutes.cart, builder: (context, state) => const CartPage()),
      GoRoute(path: AppRoutes.profile, builder: (context, state) => const ProfilePage()),
      GoRoute(path: AppRoutes.studentDash, builder: (context, state) => const StudentDashboardPage()),
      GoRoute(path: AppRoutes.studentDashboard, builder: (context, state) => const StudentDashboardPage()),
      GoRoute(path: AppRoutes.studentCourses, builder: (context, state) => const StudentMyCoursesPage()),
      GoRoute(path: AppRoutes.studentMyBooks, builder: (context, state) => const StudentMyBooksPage()),
      GoRoute(path: AppRoutes.studentContinue, builder: (context, state) => const StudentContinueLearningPage()),
      GoRoute(path: AppRoutes.studentCertificates, builder: (context, state) => const StudentCertificatesPage()),
      GoRoute(path: AppRoutes.studentProfile, builder: (context, state) => const ProfilePage()),
      GoRoute(path: AppRoutes.studentOrders, builder: (context, state) => const StudentMyOrdersPage()),
      GoRoute(path: AppRoutes.myOrders, builder: (context, state) => const StudentMyOrdersPage()),
      GoRoute(path: AppRoutes.studentWishlist, builder: (context, state) => const StudentWishlistPage()),
      GoRoute(path: AppRoutes.studentNotifications, builder: (context, state) => const StudentNotificationsPage()),
      GoRoute(path: AppRoutes.studentHelp, builder: (context, state) => const StudentHelpCenterPage()),
      GoRoute(path: AppRoutes.studentSettings, builder: (context, state) => const StudentSettingsPage()),
      GoRoute(path: AppRoutes.media, builder: (context, state) => const MediaPage()),
      GoRoute(
        path: AppRoutes.mediaDetails,
        builder: (context, state) {
          final idParam = state.pathParameters['id'];
          final id = int.tryParse(idParam ?? '') ?? 0;
          return MediaDetailsPage(mediaId: id);
        },
      ),
      GoRoute(path: AppRoutes.nasheed, builder: (context, state) => const NasheedPage()),
      GoRoute(path: AppRoutes.library, builder: (context, state) => const LibraryPage()),
      GoRoute(
        path: AppRoutes.libraryDetails,
        builder: (context, state) {
          final idParam = state.pathParameters['id'];
          final id = int.tryParse(idParam ?? '') ?? 0;
          return LibraryItemDetailsPage(itemId: id);
        },
      ),
      GoRoute(path: AppRoutes.events, builder: (context, state) => const EventsPage()),
      GoRoute(
        path: AppRoutes.eventDetails,
        builder: (context, state) {
          final idParam = state.pathParameters['id'];
          final id = int.tryParse(idParam ?? '') ?? 0;
          final scrollToRegister = state.uri.queryParameters['register'] == 'true' || state.extra == true;
          return EventDetailsPage(eventId: id, scrollToRegister: scrollToRegister);
        },
      ),
      GoRoute(path: AppRoutes.kids, builder: (context, state) => const KidsPortalPage()),
      GoRoute(path: '/kids/duas', builder: (context, state) => const KidsDuasPage()),
      GoRoute(path: '/kids/stories', builder: (context, state) => const KidsStoriesPage()),
      GoRoute(path: '/kids/games', builder: (context, state) => const KidsGamesPage()),
      GoRoute(path: '/kids/quizzes', builder: (context, state) => const KidsQuizzesPage()),
      GoRoute(path: AppRoutes.scholarship, builder: (context, state) => const ScholarshipPage()),
      GoRoute(
        path: '/kids/quiz-detail/:id',
        builder: (context, state) {
          final idParam = state.pathParameters['id'];
          final id = int.tryParse(idParam ?? '') ?? 0;
          final slug = state.uri.queryParameters['slug'];
          final quiz = state.extra is KidsQuizItem ? state.extra as KidsQuizItem : null;
          return KidsQuizDetailPage(quizId: id, slug: slug, initialQuiz: quiz);
        },
      ),
      GoRoute(
        path: '/kids/quiz/:id',
        builder: (context, state) {
          final idParam = state.pathParameters['id'];
          final id = int.tryParse(idParam ?? '') ?? 0;
          final quiz = state.extra is KidsQuizItem ? state.extra as KidsQuizItem : null;
          return KidsQuizPage(quizId: id, quiz: quiz);
        },
      ),
      GoRoute(
        path: '/kids/game/:id',
        builder: (context, state) {
          final idParam = state.pathParameters['id'];
          final id = int.tryParse(idParam ?? '') ?? 0;
          final game = state.extra is KidsGameItem ? state.extra as KidsGameItem : null;
          return KidsGamePage(gameId: id, game: game);
        },
      ),
      GoRoute(
        path: '/kids/game-detail/:id',
        builder: (context, state) {
          final idParam = state.pathParameters['id'];
          final id = int.tryParse(idParam ?? '') ?? 0;
          final game = state.extra is KidsGameItem ? state.extra as KidsGameItem : null;
          return KidsGameDetailPage(gameId: id, game: game);
        },
      ),
      GoRoute(
        path: '/kids/story/:id',
        builder: (context, state) {
          final idParam = state.pathParameters['id'];
          final id = int.tryParse(idParam ?? '') ?? 0;
          final slug = state.uri.queryParameters['slug'];
          final story = state.extra is KidsStoryItem ? state.extra as KidsStoryItem : null;
          return KidsStoryDetailPage(storyId: id, slug: slug, initialStory: story);
        },
      ),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CheckoutPage(
            orderId: int.tryParse(extra['orderId']?.toString() ?? '0') ?? 0,
            productType: extra['productType']?.toString() ?? 'course',
            title: extra['title']?.toString() ?? 'Course Enrollment',
            amount: double.tryParse(extra['amount']?.toString() ?? '0') ?? 0.0,
            instructor: extra['instructor']?.toString(),
            category: extra['category']?.toString(),
            level: extra['level']?.toString(),
            language: extra['language']?.toString(),
            duration: extra['duration']?.toString(),
            mode: extra['mode']?.toString(),
            planLabel: extra['planLabel']?.toString(),
            courseId: int.tryParse(extra['courseId']?.toString() ?? ''),
            quantity: int.tryParse(extra['quantity']?.toString() ?? '1') ?? 1,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.paymentSuccess,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return PaymentSuccessPage(
            orderId: int.tryParse(extra['orderId']?.toString() ?? '0') ?? 0,
            paymentId: extra['paymentId']?.toString() ?? '',
            title: extra['title']?.toString() ?? 'Course Enrollment',
            amount: double.tryParse(extra['amount']?.toString() ?? '0') ?? 0.0,
            productType: extra['productType']?.toString() ?? 'course',
            verified: extra['verified'] == true,
            courseId: int.tryParse(extra['courseId']?.toString() ?? ''),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const AuthPage(initialTab: 0),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const AuthPage(initialTab: 1),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) {
          final token = state.uri.queryParameters['token'];
          return ResetPasswordPage(initialToken: token);
        },
      ),
      GoRoute(path: AppRoutes.teacherLogin, builder: (context, state) => const TeacherLoginPage()),
      GoRoute(path: AppRoutes.parentDash, builder: (context, state) => const ParentDashboardPage()),
      GoRoute(
        path: AppRoutes.teacherDash,
        builder: (context, state) => const TeacherDashboardPage(),
      ),
    ],
  );
}
