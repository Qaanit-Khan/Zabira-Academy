import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zabira_academy/features/auth/auth_controller.dart';
import 'package:zabira_academy/features/auth/data/auth_repository.dart';
import 'package:zabira_academy/features/auth/data/services/auth_api_service.dart';
import 'package:zabira_academy/features/store/presentation/controllers/cart_controller.dart';
import 'package:zabira_academy/shared/widgets/app_drawer.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  AuthController createTestAuthController({Map<String, dynamic>? userJson}) {
    final mockClient = MockClient((request) async {
      if (userJson != null) {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Login successful',
            'data': {
              'token': 'test_token_123',
              'user': userJson,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('{"success": false}', 401);
    });
    final authService = AuthApiService(client: mockClient);
    final repo = AuthRepository(apiService: authService);
    return AuthController(authRepository: repo);
  }

  testWidgets('AppDrawer renders guest state with Welcome and Sign In', (tester) async {
    final authController = createTestAuthController();
    final cartController = CartController();

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(
            drawer: AppDrawer(),
            body: Center(child: Text('Home Content')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>.value(value: authController),
          ChangeNotifierProvider<CartController>.value(value: cartController),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    // Open Drawer
    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    // Verify top shortcuts
    expect(find.text('Wishlist'), findsOneWidget);

    // Verify guest state has bottom Sign In / Register button and no duplicate card
    expect(find.text('Sign In / Register'), findsOneWidget);

    // Verify EXPLORE section header and items
    expect(find.text('EXPLORE'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Media'), findsOneWidget);
    expect(find.text('Events'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Courses'), findsOneWidget);
    expect(find.text('Nasheed'), findsOneWidget);
    expect(find.text('Kids Portal'), findsOneWidget);
    expect(find.text('Scholarship'), findsOneWidget);

    // Verify SUPPORT section header and items
    expect(find.text('SUPPORT'), findsOneWidget);
    expect(find.text('FAQs'), findsOneWidget);
    expect(find.text('Blogs'), findsOneWidget);
    expect(find.text('Careers'), findsOneWidget);
    expect(find.text('About Us'), findsOneWidget);
    expect(find.text('Contact Us'), findsOneWidget);
    expect(find.text('Help Center'), findsOneWidget);
  });

  testWidgets('AppDrawer renders authenticated state with user profile and Logout button', (tester) async {
    final authController = createTestAuthController(
      userJson: {
        'id': 1,
        'name': 'Qaanit Khan',
        'email': 'qaanitumar77@gmail.com',
        'role': 'student',
      },
    );
    await authController.signIn(email: 'qaanitumar77@gmail.com', password: 'Password123!');

    final cartController = CartController();

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(
            drawer: AppDrawer(),
            body: Center(child: Text('Home Content')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>.value(value: authController),
          ChangeNotifierProvider<CartController>.value(value: cartController),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    // Open Drawer
    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    // Verify user profile info
    expect(find.text('Qaanit Khan'), findsOneWidget);
    expect(find.text('qaanitumar77@gmail.com'), findsOneWidget);
    expect(find.text('STUDENT'), findsOneWidget);

    // Verify EXPLORE items
    expect(find.text('EXPLORE'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Media'), findsOneWidget);
    expect(find.text('Events'), findsOneWidget);

    // Verify SUPPORT items
    expect(find.text('SUPPORT'), findsOneWidget);
    expect(find.text('FAQs'), findsOneWidget);

    // Verify fixed red Logout button
    expect(find.text('Logout'), findsOneWidget);
  });
}
