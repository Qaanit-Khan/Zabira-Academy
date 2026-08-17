import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zabira_academy/features/payment/data/services/payment_api_service.dart';
import 'package:zabira_academy/features/payment/data/repositories/payment_repository.dart';
import 'package:zabira_academy/features/payment/presentation/controllers/payment_controller.dart';
import 'package:zabira_academy/features/nasheed/data/services/nasheed_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PaymentApiService Tests', () {
    test('createPaymentSession sends correct payload with Bearer token', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.headers['Authorization'], equals('Bearer mock_valid_token'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['order_id'], equals(105));
        expect(body['product_type'], equals('course'));
        expect(body['gateway'], equals('cashfree'));

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Session created',
            'data': {
              'order_id': 105,
              'gateway_order_id': 'order_rzp_789',
              'amount': 1999,
              'currency': 'INR',
              'gateway': 'razorpay',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = PaymentApiService(client: mockClient);
      final session = await service.createPaymentSession(
        orderId: 105,
        productType: 'course',
        token: 'mock_valid_token',
      );

      expect(session.orderId, equals(105));
      expect(session.gatewayOrderId, equals('order_rzp_789'));
      expect(session.amount, equals(1999.0));
      expect(session.currency, equals('INR'));
    });

    test('verifyPayment sends verification signature and returns success', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.headers['Authorization'], equals('Bearer mock_valid_token'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['order_id'], equals(105));
        expect(body['gateway_order_id'], equals('order_rzp_789'));
        expect(body['razorpay_payment_id'], equals('pay_123'));

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Payment verified and enrollment confirmed',
            'data': {
              'order_id': 105,
              'transaction_id': 'pay_123',
              'enrollment_confirmed': true,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = PaymentApiService(client: mockClient);
      final result = await service.verifyPayment(
        orderId: 105,
        productType: 'course',
        gatewayOrderId: 'order_rzp_789',
        paymentId: 'pay_123',
        token: 'mock_valid_token',
      );

      expect(result.isSuccess, isTrue);
      expect(result.enrollmentConfirmed, isTrue);
      expect(result.transactionId, equals('pay_123'));
    });
  });

  group('PaymentController Tests', () {
    test('createSession and verifyPayment transitions state correctly', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('create_session')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'order_id': 200, 'gateway_order_id': 'rzp_order_200', 'amount': 499}
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'order_id': 200, 'transaction_id': 'pay_200', 'enrollment_confirmed': true}
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = PaymentRepository(apiService: PaymentApiService(client: mockClient));
      final controller = PaymentController(repository: repo);

      final session = await controller.createSession(
        orderId: 200,
        productType: 'course',
        token: 'token_abc',
      );

      expect(session, isNotNull);
      expect(controller.status, equals(PaymentStatus.launchingGateway));
      expect(controller.activeSession?.orderId, equals(200));

      final isVerified = await controller.verifyPayment(
        orderId: 200,
        productType: 'course',
        paymentId: 'pay_200',
        token: 'token_abc',
      );

      expect(isVerified, isTrue);
      expect(controller.status, equals(PaymentStatus.checkingOrderStatus));
      expect(controller.lastResult?.isSuccess, isTrue);
    });
  });

  group('NasheedApiService Tests', () {
    test('Falls back gracefully to local curated track on network error', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection failed');
      });

      final service = NasheedApiService(client: mockClient);
      final track = await service.getDailyNasheed();

      expect(track.contentTitle, equals('Allah Knows'));
      expect(track.sectionLabel, equals('DAILY NASHEED'));
      expect(track.duration, isNotEmpty);
    });
  });
}
