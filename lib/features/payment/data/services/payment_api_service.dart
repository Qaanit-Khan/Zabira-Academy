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
    final response = await _client.get(
      ApiConfig.paymentsGateways,
      token: token,
    );
    final data = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : response;
    final rawList =
        data['gateways'] ?? response['gateways'] ?? response['data'] ?? [];
    if (rawList is List) {
      return rawList
          .whereType<Map<String, dynamic>>()
          .map((item) => PaymentGatewayInfo.fromJson(item))
          .where((gateway) => gateway.isActive && gateway.isConfigured)
          .toList();
    }
    return const [];
  }

  Future<Map<String, dynamic>> getPaymentConfigStatus({String? token}) {
    return _client.get(ApiConfig.paymentsConfigStatus, token: token);
  }

  /// Get flexible payment plans for a course
  Future<PaymentPlansData> getPaymentPlans({
    int? courseId,
    String? slug,
    String? token,
  }) async {
    final query = <String, dynamic>{};
    if (courseId != null) query['course_id'] = courseId;
    if (slug != null && slug.isNotEmpty) query['slug'] = slug;

    final response = await _client.get(
      ApiConfig.paymentsPaymentPlans,
      queryParameters: query,
      token: token,
    );
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

    final response = await _client.post(
      ApiConfig.paymentsCreateSession,
      body: body,
      token: token,
    );
    _ensureSuccess(response);
    return PaymentSessionModel.fromJson(
      response,
      orderId: orderId,
      productType: productType,
    );
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

    final response = await _client.post(
      ApiConfig.paymentsVerify,
      body: body,
      token: token,
    );
    _ensureSuccess(response);
    return PaymentVerificationResult.fromJson(response);
  }

  void _ensureSuccess(Map<String, dynamic> response) {
    if (response['success'] == false ||
        response['status'] == 'error' ||
        response['status'] == 'failed') {
      final message =
          response['message']?.toString() ??
          response['error']?.toString() ??
          'Payment request failed.';
      throw Exception(message);
    }
  }

  /// `GET /payments/checkout_summary.php`
  Future<Map<String, dynamic>> getCheckoutSummary({
    required int orderId,
    String? productType,
    String? token,
  }) async {
    final query = <String, dynamic>{'order_id': orderId};
    if (productType != null) query['product_type'] = productType;

    return _client.get(
      ApiConfig.paymentsCheckoutSummary,
      queryParameters: query,
      token: token,
    );
  }

  /// `GET /payments/my_orders.php`
  Future<List<MyOrderItem>> getMyOrders({
    int page = 1,
    int limit = 20,
    String? token,
  }) async {
    final allOrders = <MyOrderItem>[];
    final seenOrderIds = <int>{};
    var currentPage = page;
    var keepFetching = true;

    while (keepFetching) {
      final query = {'page': currentPage, 'limit': limit};
      final response = await _client.get(
        ApiConfig.paymentsMyOrders,
        queryParameters: query,
        token: token,
      );
      final data = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : response;
      final rawList =
          data['orders'] ??
          response['orders'] ??
          (response['data'] is List ? response['data'] : []);

      final pageOrders = <MyOrderItem>[];
      if (rawList is List) {
        pageOrders.addAll(
          rawList
              .whereType<Map<String, dynamic>>()
              .map((item) => MyOrderItem.fromJson(item))
              .where((item) => item.orderId > 0),
        );
      }

      for (final order in pageOrders) {
        if (seenOrderIds.add(order.orderId)) {
          allOrders.add(order);
        }
      }

      final pagination = data['pagination'] is Map<String, dynamic>
          ? data['pagination'] as Map<String, dynamic>
          : (response['pagination'] is Map<String, dynamic>
                ? response['pagination'] as Map<String, dynamic>
                : null);
      final totalPages = int.tryParse(
        pagination?['total_pages']?.toString() ?? '',
      );

      if (totalPages != null && totalPages > 0) {
        keepFetching = currentPage < totalPages;
      } else {
        keepFetching = pageOrders.length >= limit && currentPage < (page + 10);
      }

      currentPage++;
    }

    return allOrders;
  }

  /// `GET /payments/order_status.php`
  Future<Map<String, dynamic>> getOrderStatus({
    required int orderId,
    String? productType,
    String? token,
  }) async {
    final query = <String, dynamic>{'order_id': orderId};
    if (productType != null) query['product_type'] = productType;

    return _client.get(
      ApiConfig.paymentsOrderStatus,
      queryParameters: query,
      token: token,
    );
  }

  /// `GET /payments/invoice.php`
  Future<Map<String, dynamic>> getInvoice({
    required int orderId,
    String? format,
    String? token,
  }) async {
    final query = <String, dynamic>{'order_id': orderId};
    if (format != null) query['format'] = format;

    return _client.get(
      ApiConfig.paymentsInvoice,
      queryParameters: query,
      token: token,
    );
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
    return _client.post(
      ApiConfig.paymentsApplyCoupon,
      body: body,
      token: token,
    );
  }

  /// `POST /payments/cancel_order.php`
  Future<Map<String, dynamic>> cancelOrder({
    required int orderId,
    String? action,
    String? token,
  }) async {
    final body = <String, dynamic>{'order_id': orderId};
    if (action != null) {
      body['action'] = action;
    }
    return _client.post(
      ApiConfig.paymentsCancelOrder,
      body: body,
      token: token,
    );
  }
}
