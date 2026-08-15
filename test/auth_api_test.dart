import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zabira_academy/features/auth/data/auth_repository.dart';
import 'package:zabira_academy/features/auth/data/services/auth_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthApiService Tests', () {
    test('Successful login returns parsed JSON and token', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], equals('test@zabiraacademy.com'));
        expect(body['portal'], equals('student'));

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Login successful',
            'data': {
              'token': 'jwt_mock_token_123',
              'user': {
                'id': 42,
                'email': 'test@zabiraacademy.com',
                'name': 'Student Tester',
                'role': 'student',
              }
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthApiService(client: mockClient);
      final result = await service.login(
        email: 'test@zabiraacademy.com',
        password: 'Password123!',
        portal: 'student',
      );

      expect(result['success'], isTrue);
      expect(result['data']['token'], equals('jwt_mock_token_123'));
    });

    test('401 invalid credentials throws AuthApiException with remaining attempts', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Invalid email or password.',
            'data': {'attempts_remaining': 3}
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthApiService(client: mockClient);

      expect(
        () => service.login(
          email: 'wrong@zabiraacademy.com',
          password: 'wrong',
          portal: 'student',
        ),
        throwsA(isA<AuthApiException>().having(
          (e) => e.message,
          'message',
          contains('Invalid email or password.'),
        )),
      );
    });

    test('429 rate limit throws AuthApiException with wait notice', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Too many failed sign-in attempts.',
            'data': {'retry_after': 900, 'attempts_remaining': 0}
          }),
          429,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthApiService(client: mockClient);

      expect(
        () => service.login(
          email: 'blocked@zabiraacademy.com',
          password: 'pass',
          portal: 'student',
        ),
        throwsA(isA<AuthApiException>().having(
          (e) => e.message,
          'message',
          contains('Too many failed sign-in attempts.'),
        )),
      );
    });

    test('Google Auth sends id_token and returns parsed token and user', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['id_token'], equals('google_jwt_sample_xyz'));
        expect(body['portal'], equals('student'));

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Google Sign-In successful',
            'data': {
              'token': 'zabira_jwt_session_token',
              'user': {
                'id': 77,
                'email': 'google_user@zabiraacademy.com',
                'name': 'Google Learner',
                'role': 'student',
              }
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthApiService(client: mockClient);
      final result = await service.googleAuth(
        idToken: 'google_jwt_sample_xyz',
        portal: 'student',
      );

      expect(result['success'], isTrue);
      expect(result['data']['token'], equals('zabira_jwt_session_token'));
      expect(result['data']['user']['name'], equals('Google Learner'));
    });
  });

  group('AuthRepository Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('signInWithApi stores token and user session', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'OK',
            'data': {
              'token': 'saved_token_xyz',
              'user': {
                'id': 100,
                'email': 'student@zabira.com',
                'name': 'Active Student',
                'role': 'student',
              }
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = AuthRepository(apiService: AuthApiService(client: mockClient));
      final user = await repo.signInWithApi(
        email: 'student@zabira.com',
        password: 'Pass',
        portal: 'student',
      );

      expect(user.displayName, equals('Active Student'));
      expect(repo.isSignedIn, isTrue);
      expect(repo.currentToken, equals('saved_token_xyz'));

      // Test session restoration
      final restoredRepo = AuthRepository(apiService: AuthApiService(client: mockClient));
      final restoredUser = await restoredRepo.initSession();
      expect(restoredUser?.displayName, equals('Active Student'));
      expect(restoredRepo.isSignedIn, isTrue);
    });
  });
}
