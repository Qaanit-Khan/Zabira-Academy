import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zabira_academy/core/constants/api_config.dart';
import 'package:zabira_academy/features/auth/data/auth_repository.dart';
import 'package:zabira_academy/features/auth/data/services/auth_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Google Auth API Service Tests', () {
    test(
      'googleAuth sends correct body and headers to /auth/google_auth.php',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.method, equals('POST'));
          expect(request.url.path, endsWith('/auth/google_auth.php'));
          expect(request.headers.containsKey('authorization'), isFalse);

          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['id_token'], equals('mock_google_id_token_jwt'));
          expect(body.keys, equals({'id_token'}));

          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Google authentication successful',
              'data': {
                'token': 'zabira_jwt_session_token_999',
                'user': {
                  'id': 127,
                  'email': 'existing.user@gmail.com',
                  'name': 'Existing User',
                  'role': 'student',
                  'photo_url': 'https://api.zabiraacademy.com/avatars/127.jpg',
                },
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final service = AuthApiService(client: mockClient);
        final result = await service.googleAuth(
          idToken: 'mock_google_id_token_jwt',
        );

        expect(result['success'], isTrue);
        expect(result['data']['token'], equals('zabira_jwt_session_token_999'));
        expect(result['data']['user']['id'], equals(127));
        expect(
          result['data']['user']['email'],
          equals('existing.user@gmail.com'),
        );
      },
    );

    test(
      'googleAuth handles backend rejection with 401 AuthApiException',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': false,
              'message': 'Invalid or expired Google sign-in. Please try again.',
            }),
            401,
            headers: {'content-type': 'application/json'},
          );
        });

        final service = AuthApiService(client: mockClient);

        expect(
          () => service.googleAuth(idToken: 'invalid_token'),
          throwsA(
            isA<AuthApiException>().having(
              (e) => e.message,
              'message',
              contains('Invalid or expired Google sign-in'),
            ),
          ),
        );
      },
    );
  });

  group('Google Auth Session Persistence & Repository Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'Session token and canonical user profile are persisted after Google login',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.path.endsWith('/auth/google_auth.php')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'token': 'persisted_zabira_token_777',
                  'user': {
                    'id': 127,
                    'email': 'student@gmail.com',
                    'name': 'Student One',
                    'role': 'student',
                  },
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('{}', 404);
        });

        final service = AuthApiService(client: mockClient);
        final repo = AuthRepository(apiService: service);

        // Verify initial state
        expect(repo.isSignedIn, isFalse);
        expect(repo.currentToken, isNull);
        expect(repo.currentUser, isNull);
      },
    );
  });

  group('ApiConfig Constants Verification', () {
    test('googleServerClientId is populated with valid web client format', () {
      expect(ApiConfig.googleServerClientId, isNotEmpty);
      expect(
        ApiConfig.googleServerClientId,
        contains('.apps.googleusercontent.com'),
      );
      expect(
        ApiConfig.googleServerClientId,
        isNot(contains('YOUR_WEB_CLIENT_ID')),
      );
    });

    test('authGoogleAuth endpoint path is correct', () {
      expect(ApiConfig.authGoogleAuth, equals('/auth/google_auth.php'));
    });
  });
}
