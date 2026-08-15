import 'package:http/http.dart' as http;
import '../../../../core/constants/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../models/payment_models.dart';
import '../models/payment_plans_model.dart';

/// Zabira Academy — Payment API Service
/// Interacts with official `/payments/*` endpoints using runtime Bearer authentication.
class PaymentApiService {
  PaymentApiService({http.Client? client, ApiClient? apiClient})
      : _client = apiClient ?? ApiClient(client: client);

  final ApiClient _client;

  /// Get active payment gateways configured on Zabira server.
  Future<List<PaymentGatewayInfo>> getPaymentGateways({String? token}) async {
    try {
      final response = await _client.get(ApiConfig.paymentsGateways, token: token);
      final data = response['data'] is Map<String, dynamic> ? response['data'] as Map<String, dynamic> : response;
      final rawList = data['gateways'] ?? response['gateways'] ?? response['data'] ?? [];
      if (rawList is List) {
        return rawList
            .whereType<Map<String, dynamic>>()
            .map((item) => PaymentGatewayInfo.fromJson(item))
            .toList();
      }
    } catch (_) {}

    // Also try config status endpoint
    try {
      final statusResp = await _client.get(ApiConfig.paymentsConfigStatus, token: token);
      final data = statusResp['data'] is Map<String, dynamic> ? statusResp['data'] as Map<String, dynamic> : statusResp;
      final rawList = data['gateways'] ?? statusResp['gateways'] ?? [];
      if (rawList is List) {
        return rawList
            .whereType<Map<String, dynamic>>()
            .map((item) => PaymentGatewayInfo.fromJson(item))
            .toList();
      }
    } catch (_) {}

    return const [
      PaymentGatewayInfo(
        id: 1,
        code: 'cashfree',
        name: 'Cashfree',
        isRecommended: true,
        features: ['UPI', 'Credit Cards', 'Debit Cards', 'Net Banking', 'Wallets'],
      ),
      PaymentGatewayInfo(
        id: 2,
        code: 'razorpay',
        name: 'Razorpay',
        isRecommended: false,
        features: ['UPI', 'Credit Cards', 'Debit Cards', 'Net Banking', 'Wallets'],
      ),
    ];
  }

  /// Get flexible payment plans for a course
  Future<PaymentPlansData> getPaymentPlans({int? courseId, String? slug, String? token}) async {
    final query = <String, dynamic>{};
    if (courseId != null) query['course_id'] = courseId;
    if (slug != null && slug.isNotEmpty) query['slug'] = slug;

    final response = await _client.get(ApiConfig.paymentsPaymentPlans, queryParameters: query, token: token);
    return PaymentPlansData.fromJson(response);
  }

  /// Create a payment session for a course, store item, or cart checkout.
  Future<PaymentSessionModel> createPaymentSession({
    required int orderId,
    required String productType,
    String gateway = 'cashfree',
    String? token,
  }) async {
    final body = {
      'order_id': orderId,
      'gateway': gateway,
      'product_type': productType,
    };

    final response = await _client.post(ApiConfig.paymentsCreateSession, body: body, token: token);
    return PaymentSessionModel.fromJson(response, orderId: orderId, productType: productType);
  }

  /// Verify a completed payment transaction.
  Future<PaymentVerificationResult> verifyPayment({
    required int orderId,
    required String productType,
    String? gatewayOrderId,
    String? paymentId,
    String? signature,
    String? razorpayOrderId,
    String? token,
  }) async {
    final body = <String, dynamic>{
      'order_id': orderId,
      'product_type': productType,
    };
    if (gatewayOrderId != null) body['gateway_order_id'] = gatewayOrderId;
    if (paymentId != null) body['razorpay_payment_id'] = paymentId;
    if (signature != null) body['razorpay_signature'] = signature;
    if (razorpayOrderId != null) body['razorpay_order_id'] = razorpayOrderId;

    final response = await _client.post(ApiConfig.paymentsVerify, body: body, token: token);
    return PaymentVerificationResult.fromJson(response);
  }

  /// `GET /payments/checkout_summary.php`
  Future<Map<String, dynamic>> getCheckoutSummary({
    required int orderId,
    String? productType,
    String? token,
  }) async {
    final query = <String, dynamic>{'order_id': orderId};
    if (productType != null) query['product_type'] = productType;

    return _client.get(ApiConfig.paymentsCheckoutSummary, queryParameters: query, token: token);
  }

  /// `GET /payments/my_orders.php`
  Future<List<MyOrderItem>> getMyOrders({
    int page = 1,
    int limit = 20,
    String? token,
  }) async {
    final query = {'page': page, 'limit': limit};
    final response = await _client.get(ApiConfig.paymentsMyOrders, queryParameters: query, token: token);
    final data = response['data'] is Map<String, dynamic> ? response['data'] as Map<String, dynamic> : response;
    final rawList = data['orders'] ?? response['orders'] ?? (response['data'] is List ? response['data'] : []);
    if (rawList is List) {
      return rawList
          .whereType<Map<String, dynamic>>()
          .map((item) => MyOrderItem.fromJson(item))
          .toList();
    }
    return [];
  }

  /// `GET /payments/order_status.php`
  Future<Map<String, dynamic>> getOrderStatus({
    required int orderId,
    String? productType,
    String? token,
  }) async {
    final query = <String, dynamic>{'order_id': orderId};
    if (productType != null) query['product_type'] = productType;

    return _client.get(ApiConfig.paymentsOrderStatus, queryParameters: query, token: token);
  }

  /// `GET /payments/invoice.php`
  Future<Map<String, dynamic>> getInvoice({
    required int orderId,
    String? format,
    String? token,
  }) async {
    final query = <String, dynamic>{'order_id': orderId};
    if (format != null) query['format'] = format;

    return _client.get(ApiConfig.paymentsInvoice, queryParameters: query, token: token);
  }

  /// `POST /payments/apply_coupon.php`
  Future<Map<String, dynamic>> applyCoupon({
    required int orderId,
    required String couponCode,
    bool remove = false,
    String? token,
  }) async {
    final body = <String, dynamic>{
      'order_id': orderId,
      'coupon_code': couponCode.trim(),
    };
    if (remove) {
      body['remove'] = '1';
    }
    return _client.post(ApiConfig.paymentsApplyCoupon, body: body, token: token);
  }

  /// `POST /payments/cancel_order.php`
  Future<Map<String, dynamic>> cancelOrder({
    required int orderId,
    String? action,
    String? token,
  }) async {
    final body = <String, dynamic>{
      'order_id': orderId,
    };
    if (action != null) {
      body['action'] = action;
    }
    return _client.post(ApiConfig.paymentsCancelOrder, body: body, token: token);
  }
}
