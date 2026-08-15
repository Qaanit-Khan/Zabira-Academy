import '../models/payment_models.dart';
import '../models/payment_plans_model.dart';
import '../services/payment_api_service.dart';

/// Zabira Academy — Payment Repository
class PaymentRepository {
  PaymentRepository({PaymentApiService? apiService})
      : _api = apiService ?? PaymentApiService();

  final PaymentApiService _api;

  Future<PaymentSessionModel> createSession({
    required int orderId,
    required String productType,
    String gateway = 'cashfree',
    String? token,
  }) {
    return _api.createPaymentSession(
      orderId: orderId,
      productType: productType,
      gateway: gateway,
      token: token,
    );
  }

  Future<PaymentVerificationResult> verifyPayment({
    required int orderId,
    required String productType,
    String? gatewayOrderId,
    String? paymentId,
    String? signature,
    String? razorpayOrderId,
    String? token,
  }) {
    return _api.verifyPayment(
      orderId: orderId,
      productType: productType,
      gatewayOrderId: gatewayOrderId,
      paymentId: paymentId,
      signature: signature,
      razorpayOrderId: razorpayOrderId,
      token: token,
    );
  }

  Future<List<PaymentGatewayInfo>> getGateways({String? token}) {
    return _api.getPaymentGateways(token: token);
  }

  Future<PaymentPlansData> getPaymentPlans({int? courseId, String? slug, String? token}) {
    return _api.getPaymentPlans(courseId: courseId, slug: slug, token: token);
  }

  Future<List<MyOrderItem>> getMyOrders({int page = 1, int limit = 20, String? token}) {
    return _api.getMyOrders(page: page, limit: limit, token: token);
  }

  Future<Map<String, dynamic>> getInvoice({required int orderId, String? format, String? token}) {
    return _api.getInvoice(orderId: orderId, format: format, token: token);
  }

  Future<Map<String, dynamic>> getCheckoutSummary({required int orderId, String? productType, String? token}) {
    return _api.getCheckoutSummary(orderId: orderId, productType: productType, token: token);
  }

  Future<Map<String, dynamic>> applyCoupon({required int orderId, required String couponCode, bool remove = false, String? token}) {
    return _api.applyCoupon(orderId: orderId, couponCode: couponCode, remove: remove, token: token);
  }

  Future<Map<String, dynamic>> cancelOrder({required int orderId, String? action, String? token}) {
    return _api.cancelOrder(orderId: orderId, action: action, token: token);
  }
}
