import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/payment_models.dart';
import '../../data/models/payment_plans_model.dart';
import '../../data/repositories/payment_repository.dart';

/// Explicit 14-state Payment State Machine
enum PaymentStatus {
  idle,
  creatingOrder,
  loadingSummary,
  loadingGateways,
  creatingSession,
  launchingGateway,
  waitingForGateway,
  paymentReturned,
  verifying,
  checkingOrderStatus,
  success,
  awaitingConfirmation,
  failed,
  cancelled,
  timeout,
  apiUnavailable,
}

/// Zabira Academy — Production Payment Controller
class PaymentController extends ChangeNotifier {
  PaymentController({PaymentRepository? repository})
      : _repository = repository ?? PaymentRepository();

  final PaymentRepository _repository;

  PaymentStatus _status = PaymentStatus.idle;
  bool _isProcessing = false;
  String? _errorMessage;
  int? _currentOrderId;
  String? _appliedCoupon;
  double _couponDiscount = 0.0;
  PaymentSessionModel? _activeSession;
  PaymentVerificationResult? _lastResult;
  Map<String, dynamic>? _checkoutSummaryData;
  List<PaymentGatewayInfo> _gateways = const [];
  List<MyOrderItem> _myOrders = const [];
  PaymentPlansData? _currentCoursePlans;
  Map<String, dynamic>? _configStatus;

  PaymentStatus get status => _status;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  int? get currentOrderId => _currentOrderId;
  String? get appliedCoupon => _appliedCoupon;
  double get couponDiscount => _couponDiscount;
  PaymentSessionModel? get activeSession => _activeSession;
  PaymentVerificationResult? get lastResult => _lastResult;
  Map<String, dynamic>? get checkoutSummaryData => _checkoutSummaryData;
  List<PaymentGatewayInfo> get gateways => _gateways;
  List<MyOrderItem> get myOrders => _myOrders;
  PaymentPlansData? get currentCoursePlans => _currentCoursePlans;
  Map<String, dynamic>? get configStatus => _configStatus;

  String get statusMessage {
    switch (_status) {
      case PaymentStatus.creatingOrder:
        return 'Creating secure order...';
      case PaymentStatus.loadingSummary:
        return 'Loading order summary...';
      case PaymentStatus.loadingGateways:
        return 'Connecting to payment gateways...';
      case PaymentStatus.creatingSession:
        return 'Generating payment session...';
      case PaymentStatus.launchingGateway:
        return 'Launching payment gateway...';
      case PaymentStatus.waitingForGateway:
        return 'Waiting for payment confirmation...';
      case PaymentStatus.paymentReturned:
        return 'Payment returned from gateway...';
      case PaymentStatus.verifying:
        return 'Verifying transaction with Zabira server...';
      case PaymentStatus.checkingOrderStatus:
        return 'Confirming order status & activating access...';
      case PaymentStatus.success:
        return 'Payment verified & access granted!';
      case PaymentStatus.awaitingConfirmation:
        return 'Payment received, confirming your order...';
      case PaymentStatus.failed:
        return _errorMessage ?? 'Payment transaction failed.';
      case PaymentStatus.cancelled:
        return 'Payment was cancelled.';
      case PaymentStatus.timeout:
        return 'Request timed out. Please try again.';
      case PaymentStatus.apiUnavailable:
        return 'Payment service currently unavailable.';
      case PaymentStatus.idle:
        return '';
    }
  }

  void setStatus(PaymentStatus newStatus, {String? error}) {
    _status = newStatus;
    _isProcessing = (newStatus == PaymentStatus.creatingOrder ||
        newStatus == PaymentStatus.loadingSummary ||
        newStatus == PaymentStatus.loadingGateways ||
        newStatus == PaymentStatus.creatingSession ||
        newStatus == PaymentStatus.launchingGateway ||
        newStatus == PaymentStatus.waitingForGateway ||
        newStatus == PaymentStatus.paymentReturned ||
        newStatus == PaymentStatus.verifying ||
        newStatus == PaymentStatus.checkingOrderStatus);
    if (error != null) {
      _errorMessage = error;
    }
    notifyListeners();
  }

  void setCurrentOrderId(int? id) {
    _currentOrderId = id;
    notifyListeners();
  }

  Future<void> loadGateways(String? token) async {
    setStatus(PaymentStatus.loadingGateways);
    try {
      _configStatus = await _repository.getConfigStatus(token: token);
      _gateways = await _repository.getGateways(token: token);
      setStatus(PaymentStatus.idle);
    } catch (e) {
      _gateways = const [];
      setStatus(PaymentStatus.failed, error: 'Payment gateways are unavailable or not configured.');
    }
  }

  Future<PaymentPlansData?> loadCoursePaymentPlans({int? courseId, String? slug, String? token}) async {
    setStatus(PaymentStatus.loadingSummary);
    try {
      _currentCoursePlans = await _repository.getPaymentPlans(courseId: courseId, slug: slug, token: token);
      setStatus(PaymentStatus.idle);
      return _currentCoursePlans;
    } catch (_) {
      setStatus(PaymentStatus.idle);
      return null;
    }
  }

  Future<Map<String, dynamic>?> loadCheckoutSummary({
    required int orderId,
    required String productType,
    String? token,
  }) async {
    setStatus(PaymentStatus.loadingSummary);
    _errorMessage = null;

    try {
      final summary = await _repository
          .getCheckoutSummary(orderId: orderId, productType: productType, token: token)
          .timeout(const Duration(seconds: 20));

      _checkoutSummaryData = summary;
      _currentOrderId = orderId;
      setStatus(PaymentStatus.idle);
      return summary;
    } on TimeoutException {
      setStatus(PaymentStatus.idle);
      return null;
    } catch (e) {
      setStatus(PaymentStatus.idle);
      return null;
    }
  }

  Future<void> loadMyOrders(String? token, {bool forceRefresh = false}) async {
    if (token == null || token.isEmpty) return;
    try {
      _myOrders = await _repository.getMyOrders(token: token);
      notifyListeners();
    } catch (_) {}
  }

  /// Create a payment session on Zabira backend with 30s timeout
  Future<PaymentSessionModel?> createSession({
    required int orderId,
    required String productType,
    String gateway = 'cashfree',
    String? token,
  }) async {
    setStatus(PaymentStatus.creatingSession);
    _errorMessage = null;
    _currentOrderId = orderId;

    try {
      final session = await _repository
          .createSession(
            orderId: orderId,
            productType: productType,
            gateway: gateway,
            token: token,
          )
          .timeout(const Duration(seconds: 30));

      _activeSession = session;
      setStatus(PaymentStatus.launchingGateway);
      return session;
    } on TimeoutException {
      setStatus(PaymentStatus.timeout, error: 'Session creation timed out. Please try again.');
      return null;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception:', '').trim();
      setStatus(PaymentStatus.failed, error: msg.isNotEmpty ? msg : 'Unable to create payment session.');
      return null;
    }
  }

  /// Verify a completed payment transaction on Zabira backend with 30s timeout
  Future<bool> verifyPayment({
    required int orderId,
    required String productType,
    String? gatewayOrderId,
    String? paymentId,
    String? signature,
    String? razorpayOrderId,
    String? token,
  }) async {
    setStatus(PaymentStatus.verifying);
    _errorMessage = null;

    try {
      final result = await _repository
          .verifyPayment(
            orderId: orderId,
            productType: productType,
            gatewayOrderId: gatewayOrderId,
            paymentId: paymentId,
            signature: signature,
            razorpayOrderId: razorpayOrderId,
            token: token,
          )
          .timeout(const Duration(seconds: 30));

      _lastResult = result;

      if (result.isSuccess) {
        setStatus(PaymentStatus.checkingOrderStatus);
        return true;
      } else {
        setStatus(PaymentStatus.failed, error: result.message);
        return false;
      }
    } on TimeoutException {
      setStatus(PaymentStatus.timeout, error: 'Verification timed out. Please check your order status.');
      return false;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception:', '').trim();
      setStatus(PaymentStatus.failed, error: msg.isNotEmpty ? msg : 'Payment verification failed.');
      return false;
    }
  }

  /// Check real backend order status
  Future<Map<String, dynamic>?> checkOrderStatus({
    required int orderId,
    required String productType,
    String? token,
  }) async {
    setStatus(PaymentStatus.checkingOrderStatus);
    try {
      final status = await _repository.getOrderStatus(orderId: orderId, productType: productType, token: token);
      if (_isConfirmedOrderStatus(status, productType)) {
        setStatus(PaymentStatus.success);
      } else {
        setStatus(PaymentStatus.failed, error: _statusMessage(status));
      }
      return status;
    } catch (e) {
      setStatus(PaymentStatus.failed, error: e.toString().replaceAll('Exception:', '').trim());
      return null;
    }
  }

  bool isConfirmedOrderStatus(Map<String, dynamic>? response, String productType) {
    return response != null && _isConfirmedOrderStatus(response, productType);
  }

  bool isPendingOrderStatus(Map<String, dynamic>? response) {
    if (response == null) return false;
    final data = response['data'] is Map<String, dynamic> ? response['data'] as Map<String, dynamic> : response;
    final status = (data['status'] ?? data['order_status'] ?? data['purchase_status'] ?? '').toString().toLowerCase();
    final paymentStatus = (data['payment_status'] ?? data['paymentStatus'] ?? '').toString().toLowerCase();
    const pendingStates = {'pending', 'processing', 'initiated', 'created', 'verification_pending', 'awaiting_confirmation'};
    return pendingStates.contains(status) || pendingStates.contains(paymentStatus);
  }

  String orderDiagnostic(Map<String, dynamic>? response) {
    if (response == null) {
      return 'No order-status response received from backend.';
    }
    final data = response['data'] is Map<String, dynamic> ? response['data'] as Map<String, dynamic> : response;
    final status = data['status'] ?? data['order_status'] ?? 'unknown';
    final paymentStatus = data['payment_status'] ?? data['paymentStatus'] ?? 'unknown';
    final message = response['message']?.toString() ?? 'No backend message.';
    return 'order_status=$status, payment_status=$paymentStatus, message=$message';
  }

  bool _isConfirmedOrderStatus(Map<String, dynamic> response, String productType) {
    final data = response['data'] is Map<String, dynamic> ? response['data'] as Map<String, dynamic> : response;
    final status = (data['status'] ?? data['order_status'] ?? data['purchase_status'] ?? '').toString().toLowerCase();
    final paymentStatus = (data['payment_status'] ?? data['paymentStatus'] ?? '').toString().toLowerCase();
    final accessConfirmed = data['enrollment_confirmed'] == true ||
        data['enrolled'] == true ||
        data['ownership_confirmed'] == true ||
        data['owned'] == true ||
        data['purchase_confirmed'] == true;

    return response['success'] == true &&
        (accessConfirmed ||
            paymentStatus == 'paid' ||
            paymentStatus == 'success' ||
            paymentStatus == 'verified' ||
            status == 'confirmed' ||
            status == 'completed' ||
            status == 'paid' ||
            status == 'success');
  }

  String _statusMessage(Map<String, dynamic> response) {
    final data = response['data'] is Map<String, dynamic> ? response['data'] as Map<String, dynamic> : response;
    final status = data['payment_status'] ?? data['status'] ?? data['order_status'];
    return response['message']?.toString() ??
        (status == null ? 'Payment verified, but order is not confirmed yet.' : 'Order status is $status.');
  }

  /// Apply Coupon
  Future<bool> applyCoupon({
    required int orderId,
    required String couponCode,
    String? token,
  }) async {
    try {
      final res = await _repository.applyCoupon(
        orderId: orderId,
        couponCode: couponCode,
        token: token,
      );
      final success = res['success'] == true || res['status'] == 'success';
      if (success) {
        _appliedCoupon = couponCode;
        final data = res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : res;
        _couponDiscount = double.tryParse(data['discount_amount']?.toString() ?? data['discount']?.toString() ?? '0') ?? 0.0;
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Cancel Order
  Future<void> cancelOrder({
    required int orderId,
    String? token,
  }) async {
    try {
      await _repository.cancelOrder(orderId: orderId, token: token);
      setStatus(PaymentStatus.cancelled);
    } catch (_) {
      setStatus(PaymentStatus.cancelled);
    }
  }

  /// Get Invoice
  Future<Map<String, dynamic>?> getInvoice({
    required int orderId,
    String? format,
    String? token,
  }) async {
    try {
      return await _repository.getInvoice(orderId: orderId, format: format, token: token);
    } catch (_) {
      return null;
    }
  }

  void reset() {
    _status = PaymentStatus.idle;
    _isProcessing = false;
    _errorMessage = null;
    _currentOrderId = null;
    _checkoutSummaryData = null;
    _appliedCoupon = null;
    _couponDiscount = 0.0;
    _activeSession = null;
    _lastResult = null;
    notifyListeners();
  }
}
