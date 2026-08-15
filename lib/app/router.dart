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
import '../features/courses/presentation/pages/courses_page.dart';
import '../features/courses/presentation/pages/my_courses_page.dart';
import '../features/events/presentation/pages/event_details_page.dart';
import '../features/events/presentation/pages/events_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/library/presentation/pages/library_item_details_page.dart';
import '../features/library/presentation/pages/library_page.dart';
import '../features/media/presentation/pages/media_details_page.dart';
import '../features/media/presentation/pages/media_page.dart';
import '../features/nasheed/presentation/pages/nasheed_page.dart';
import '../features/parent/presentation/pages/parent_dashboard_page.dart';
import '../features/store/presentation/pages/cart_page.dart';
import '../features/store/presentation/pages/store_page.dart';
import '../features/store/presentation/pages/store_product_details_page.dart';
import '../features/student/presentation/pages/profile_page.dart';
import '../features/student/presentation/pages/student_dashboard_page.dart';
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
          loc == AppRoutes.media ||
          loc.startsWith('/media/') ||
          loc == AppRoutes.nasheed ||
          loc == AppRoutes.library ||
          loc.startsWith('/library/') ||
          loc == AppRoutes.events ||
          loc.startsWith('/events/') ||
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
        // Not authenticated and trying to access protected dashboard -> redirect to public Home Page
        return AppRoutes.home;
      }

      if (isAuth && isOnAuthPage) {
        // Authenticated user trying to access auth pages -> redirect to intended home or role dashboard
        final returnTo = auth.consumePendingReturnTo();
        if (returnTo != null && returnTo.isNotEmpty) {
          return returnTo;
        }
        return _dashboardForRole(auth.user?.role);
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
      GoRoute(path: AppRoutes.myCourses, builder: (context, state) => const MyCoursesPage()),
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
          return EventDetailsPage(eventId: id);
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
        path: AppRoutes.studentDash,
        builder: (context, state) => const StudentDashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.teacherDash,
        builder: (context, state) => const TeacherDashboardPage(),
      ),
    ],
  );
}

String _dashboardForRole(UserRole? role) {
  return switch (role) {
    UserRole.parent => AppRoutes.parentDash,
    UserRole.teacher => AppRoutes.teacherDash,
    _ => AppRoutes.home,
  };
}
