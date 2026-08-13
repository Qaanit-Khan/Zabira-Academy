import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/models/user_role.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/auth_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/auth/presentation/pages/teacher_login_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/parent/presentation/pages/parent_dashboard_page.dart';
import '../features/student/presentation/pages/student_dashboard_page.dart';
import '../features/teacher/presentation/pages/teacher_dashboard_page.dart';

/// Zabira Academy Route Names
abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String teacherLogin = '/teacher-login';
  static const String parentDash = '/parent';
  static const String studentDash = '/student';
  static const String teacherDash = '/teacher';
  static const String home = '/home';
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

      // Public Home page — always allow unauthenticated visitors
      if (state.matchedLocation == AppRoutes.home) return null;

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
        // Authenticated user trying to access auth pages -> redirect to role dashboard
        return _dashboardForRole(auth.user?.role);
      }

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashPage()),
      GoRoute(path: AppRoutes.home, builder: (context, state) => const HomePage()),
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
    _ => AppRoutes.studentDash,
  };
}
