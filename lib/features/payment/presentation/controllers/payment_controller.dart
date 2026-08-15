import 'package:flutter/foundation.dart';
import '../../data/models/payment_models.dart';
import '../../data/models/payment_plans_model.dart';
import '../../data/repositories/payment_repository.dart';

enum PaymentStatus { idle, loading, creatingSession, awaitingGateway, verifying, success, error }

/// Zabira Academy — Payment Controller
class PaymentController extends ChangeNotifier {
  PaymentController({PaymentRepository? repository})
      : _repository = repository ?? PaymentRepository();

  final PaymentRepository _repository;

  PaymentStatus _status = PaymentStatus.idle;
  bool _isProcessing = false;
  String? _errorMessage;
  PaymentSessionModel? _activeSession;
  PaymentVerificationResult? _lastResult;
  List<PaymentGatewayInfo> _gateways = const [];
  List<MyOrderItem> _myOrders = const [];
  PaymentPlansData? _currentCoursePlans;

  PaymentStatus get status => _status;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  PaymentSessionModel? get activeSession => _activeSession;
  PaymentVerificationResult? get lastResult => _lastResult;
  List<PaymentGatewayInfo> get gateways => _gateways;
  List<MyOrderItem> get myOrders => _myOrders;
  PaymentPlansData? get currentCoursePlans => _currentCoursePlans;

  Future<void> loadGateways(String? token) async {
    try {
      _gateways = await _repository.getGateways(token: token);
      notifyListeners();
    } catch (_) {}
  }

  Future<PaymentPlansData?> loadCoursePaymentPlans({int? courseId, String? slug, String? token}) async {
    try {
      _currentCoursePlans = await _repository.getPaymentPlans(courseId: courseId, slug: slug, token: token);
      notifyListeners();
      return _currentCoursePlans;
    } catch (_) {
      return null;
    }
  }

  Future<void> loadMyOrders(String? token) async {
    if (token == null || token.isEmpty) return;
    try {
      _myOrders = await _repository.getMyOrders(token: token);
      notifyListeners();
    } catch (_) {}
  }

  /// Create a payment session on Zabira backend
  Future<PaymentSessionModel?> createSession({
    required int orderId,
    required String productType,
    String gateway = 'cashfree',
    String? token,
  }) async {
    _isProcessing = true;
    _status = PaymentStatus.creatingSession;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await _repository.createSession(
        orderId: orderId,
        productType: productType,
        gateway: gateway,
        token: token,
      );
      _activeSession = session;
      _status = PaymentStatus.awaitingGateway;
      _isProcessing = false;
      notifyListeners();
      return session;
    } catch (e) {
      _isProcessing = false;
      _status = PaymentStatus.error;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return null;
    }
  }

  /// Verify a completed payment transaction on Zabira backend
  Future<bool> verifyPayment({
    required int orderId,
    required String productType,
    String? gatewayOrderId,
    String? paymentId,
    String? signature,
    String? razorpayOrderId,
    String? token,
  }) async {
    _isProcessing = true;
    _status = PaymentStatus.verifying;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.verifyPayment(
        orderId: orderId,
        productType: productType,
        gatewayOrderId: gatewayOrderId,
        paymentId: paymentId,
        signature: signature,
        razorpayOrderId: razorpayOrderId,
        token: token,
      );
      _lastResult = result;
      _isProcessing = false;

      if (result.isSuccess) {
        _status = PaymentStatus.success;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _status = PaymentStatus.error;
        _errorMessage = result.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isProcessing = false;
      _status = PaymentStatus.error;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _status = PaymentStatus.idle;
    _isProcessing = false;
    _errorMessage = null;
    _activeSession = null;
    _lastResult = null;
    notifyListeners();
  }
}
