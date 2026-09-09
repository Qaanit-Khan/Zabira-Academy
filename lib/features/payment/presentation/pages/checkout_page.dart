import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/network/debug_logger.dart';
import '../../../auth/auth_controller.dart';
import '../../../auth/presentation/widgets/auth_bottom_sheet.dart';
import '../../../courses/presentation/controllers/enrollment_controller.dart';
import '../../../store/presentation/controllers/cart_controller.dart';
import '../../../student/presentation/controllers/student_controller.dart';
import '../../../store/data/services/store_service.dart';
import '../../../library/data/services/library_api_service.dart';
import '../../data/services/payment_gateway_launcher.dart';
import '../../data/utils/order_response_utils.dart';
import '../controllers/payment_controller.dart';
import '../../data/models/payment_models.dart';

/// Zabira Academy — Native Secure Checkout Screen
///
/// Full state machine implementation with real backend Order ID preservation,
/// coupon application, gateway launching, and bulletproof error/timeout recovery.
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    super.key,
    required this.orderId,
    required this.productType,
    required this.title,
    required this.amount,
    this.instructor,
    this.category,
    this.level,
    this.language,
    this.duration,
    this.mode,
    this.planLabel,
    this.courseId,
    this.quantity = 1,
  });

  final int orderId;
  final String productType; // 'course', 'store', 'cart', 'library'
  final String title;
  final double amount;
  final String? instructor;
  final String? category;
  final String? level;
  final String? language;
  final String? duration;
  final String? mode;
  final String? planLabel;
  final int? courseId;
  final int quantity;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _selectedGateway = 'cashfree';
  final TextEditingController _couponController = TextEditingController();
  bool _isApplyingCoupon = false;
  String? _couponMessage;
  bool _isCouponSuccess = false;
  final PaymentGatewayLauncher _gatewayLauncher = PaymentGatewayLauncher();

  final Set<int> _expandedFaqs = {};

  String _sanitizeError(Object error) {
    return error.toString().replaceAll('Exception:', '').trim();
  }

  Future<Map<String, dynamic>?> _pollOrderConfirmation({
    required PaymentController payment,
    required int orderId,
    required String productType,
    required String? token,
  }) async {
    const delays = <Duration>[
      Duration.zero,
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 8),
    ];

    Map<String, dynamic>? latest;
    for (var i = 0; i < delays.length; i++) {
      final delay = delays[i];
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }

      latest = await payment.checkOrderStatus(
        orderId: orderId,
        productType: productType,
        token: token,
      );

      if (payment.isConfirmedOrderStatus(latest, productType)) {
        return latest;
      }

      DebugLogger.logError(
        context: 'PAYMENT ORDER_STATUS POLL #${i + 1}',
        error: payment.orderDiagnostic(latest),
      );
    }

    return latest;
  }

  Future<void> _refreshPostPaymentState({
    required AuthController auth,
    required PaymentController payment,
    required EnrollmentController enrollment,
    required CartController cart,
  }) async {
    await Future.wait([
      enrollment.loadMyCourses(auth.currentToken, forceRefresh: true),
      payment.loadMyOrders(auth.currentToken, forceRefresh: true),
      if (widget.productType == 'cart') cart.clearCart(auth.currentToken),
    ]);

    if (!mounted) return;

    final student = context.read<StudentController>();
    final user = auth.user;
    await student.loadDashboard(
      auth.currentToken,
      defaultName: user?.displayName,
      defaultEmail: user?.email,
      defaultPhoto: user?.photoUrl,
      forceRefresh: true,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthController>().currentToken;
      context.read<PaymentController>().loadGateways(token);
    });
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCouponCode(int effectiveOrderId) async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isApplyingCoupon = true;
      _couponMessage = null;
    });

    final token = context.read<AuthController>().currentToken;
    final payment = context.read<PaymentController>();
    final success = await payment.applyCoupon(
      orderId: effectiveOrderId > 0 ? effectiveOrderId : 1,
      couponCode: code,
      token: token,
    );

    if (!mounted) return;
    setState(() {
      _isApplyingCoupon = false;
      _isCouponSuccess = success;
      _couponMessage = success
          ? 'Coupon applied! Saved ₹${payment.couponDiscount.toInt()}'
          : 'Invalid or expired coupon code.';
    });
  }

  Future<void> _handlePayment() async {
    final auth = context.read<AuthController>();
    final payment = context.read<PaymentController>();
    final enrollment = context.read<EnrollmentController>();
    final cart = context.read<CartController>();

    if (!auth.isAuthenticated) {
      auth.setPendingReturnTo(GoRouterState.of(context).matchedLocation);
      showAuthBottomSheet(context);
      return;
    }

    final effectiveCourseId = widget.productType == 'course'
        ? (widget.courseId ?? widget.orderId)
        : null;

    try {
      payment.setStatus(PaymentStatus.creatingOrder);
      DebugLogger.logPaymentStage(
        stage: 'order_creation_start',
        productType: widget.productType,
        productId: effectiveCourseId ?? widget.orderId,
        orderId: widget.orderId,
      );

      int effectiveOrderId = widget.orderId;

      // 1. Resolve real backend Order ID based on product type
      if (widget.productType == 'cart') {
        if (effectiveOrderId <= 0) {
          final cartOrderId = await cart.checkout(auth.currentToken);
          if (cartOrderId != null && cartOrderId > 0) {
            effectiveOrderId = cartOrderId;
          } else {
            payment.setStatus(
              PaymentStatus.failed,
              error: 'Unable to create cart checkout order.',
            );
            return;
          }
        }
      } else if (widget.productType == 'store') {
        try {
          final storeSvc = StoreService();
          final purchaseRes = await storeSvc.purchaseProduct(
            storeProductId: widget.orderId,
            quantity: widget.quantity,
            authToken: auth.currentToken,
          );
          final realId = extractOrderId(purchaseRes) ?? 0;
          if (realId > 0) effectiveOrderId = realId;
        } catch (e) {
          DebugLogger.logPaymentStage(
            stage: 'store_order_creation_failed',
            productType: 'store',
            productId: widget.orderId,
            data: {'error': _sanitizeError(e)},
          );
          payment.setStatus(
            PaymentStatus.failed,
            error: 'Unable to initiate store order. ${_sanitizeError(e)}',
          );
          return;
        }
      } else if (widget.productType == 'library') {
        if (effectiveOrderId <= 0) {
          try {
            final libSvc = LibraryApiService();
            final format = widget.planLabel?.toLowerCase() ?? 'pdf';
            final purchaseRes = await libSvc.purchaseLibraryItem(
              bookId: widget.orderId,
              format: format,
              token: auth.currentToken,
            );
            final realId = extractOrderId(purchaseRes) ?? 0;
            if (realId > 0) effectiveOrderId = realId;
          } catch (e) {
            DebugLogger.logPaymentStage(
              stage: 'library_order_creation_failed',
              productType: 'library',
              productId: widget.orderId,
              data: {'error': _sanitizeError(e)},
            );
          }
        }
      } else if (widget.productType == 'course' &&
          (effectiveOrderId <= 0 || effectiveOrderId == widget.courseId)) {
        // Create real backend enrollment order
        final courseIdToEnroll = effectiveCourseId ?? widget.orderId;
        if (courseIdToEnroll > 0) {
          final planType =
              (widget.planLabel?.toLowerCase().contains('month') ?? false)
              ? 'monthly'
              : 'full';
          final enrollRes = await enrollment.enrollInCourse(
            courseId: courseIdToEnroll,
            paymentPlan: planType,
            planType: planType,
            token: auth.currentToken,
          );
          if (enrollment.lastOrderId != null && enrollment.lastOrderId! > 0) {
            effectiveOrderId = enrollment.lastOrderId!;
          } else {
            final orderIdFromEnroll = extractOrderId(enrollRes);
            if (orderIdFromEnroll != null && orderIdFromEnroll > 0) {
              effectiveOrderId = orderIdFromEnroll;
            }
          }
          DebugLogger.logPaymentStage(
            stage: 'course_order_resolution',
            productType: 'course',
            productId: courseIdToEnroll,
            orderId: effectiveOrderId,
            data: {'plan': planType},
          );
        }
      }

      if (effectiveOrderId <= 0) {
        payment.setStatus(
          PaymentStatus.failed,
          error: 'Invalid order: unable to resolve backend order ID.',
        );
        return;
      }

      payment.setCurrentOrderId(effectiveOrderId);
      DebugLogger.logPaymentStage(
        stage: 'order_id_resolved',
        productType: widget.productType,
        orderId: effectiveOrderId,
      );

      // 2. Fetch checkout summary using the real order ID (optional / non-blocking)
      payment.setStatus(PaymentStatus.loadingSummary);
      try {
        await payment.loadCheckoutSummary(
          orderId: effectiveOrderId,
          productType: widget.productType,
          token: auth.currentToken,
        );
      } catch (e) {
        DebugLogger.logPaymentStage(
          stage: 'checkout_summary_skipped',
          productType: widget.productType,
          orderId: effectiveOrderId,
          data: {'note': _sanitizeError(e)},
        );
      }

      // 3. Create Payment Session
      final session = await payment.createSession(
        orderId: effectiveOrderId,
        productType: widget.productType,
        gateway: _selectedGateway,
        token: auth.currentToken,
      );

      if (session == null) {
        return; // payment.status is already set to failed/timeout with error message
      }
      if (!mounted) return;

      // 4. Launch the real native gateway checkout and wait for its callback.
      payment.setStatus(PaymentStatus.waitingForGateway);
      final gatewayResult = await _gatewayLauncher.launch(
        context: context,
        session: session,
        title: widget.title,
        amount: widget.amount,
      );
      if (!mounted) return;
      payment.setStatus(PaymentStatus.paymentReturned);

      DebugLogger.logPaymentStage(
        stage: 'gateway_return',
        productType: widget.productType,
        orderId: effectiveOrderId,
        gateway: gatewayResult.gateway,
        data: {
          'gateway_order_id': gatewayResult.gatewayOrderId,
          'payment_id': gatewayResult.paymentId ?? 'null',
          'razorpay_order_id': gatewayResult.razorpayOrderId ?? 'null',
          'has_signature':
              gatewayResult.signature != null &&
              gatewayResult.signature!.isNotEmpty,
        },
      );

      // 5. Verify Payment with backend using real gateway callback identifiers.
      final isVerified = await payment.verifyPayment(
        orderId: effectiveOrderId,
        productType: widget.productType,
        gatewayOrderId: gatewayResult.gatewayOrderId,
        paymentId: gatewayResult.paymentId,
        signature: gatewayResult.signature,
        razorpayOrderId: gatewayResult.razorpayOrderId,
        token: auth.currentToken,
      );

      if (!mounted) return;

      if (isVerified) {
        final orderStatus = await _pollOrderConfirmation(
          payment: payment,
          orderId: effectiveOrderId,
          productType: widget.productType,
          token: auth.currentToken,
        );
        if (!payment.isConfirmedOrderStatus(orderStatus, widget.productType)) {
          payment.setStatus(
            PaymentStatus.awaitingConfirmation,
            error:
                'Payment received, but backend confirmation is still pending. Order ID: #$effectiveOrderId',
          );
          return;
        }

        await _refreshPostPaymentState(
          auth: auth,
          payment: payment,
          enrollment: enrollment,
          cart: cart,
        );

        if (!mounted) return;

        // Navigate to Native Payment Success Page
        final effectiveTotal = (widget.amount - payment.couponDiscount).clamp(
          0.0,
          double.infinity,
        );
        context.go(
          '/payment-success',
          extra: {
            'orderId': effectiveOrderId,
            'paymentId':
                gatewayResult.paymentId ?? gatewayResult.gatewayOrderId,
            'title': widget.title,
            'amount': effectiveTotal,
            'productType': widget.productType,
            'verified': true,
            'courseId': effectiveCourseId,
          },
        );
      } else {
        payment.setStatus(PaymentStatus.awaitingConfirmation);
        final orderStatus = await _pollOrderConfirmation(
          payment: payment,
          orderId: effectiveOrderId,
          productType: widget.productType,
          token: auth.currentToken,
        );

        if (!mounted) return;

        if (payment.isConfirmedOrderStatus(orderStatus, widget.productType)) {
          await _refreshPostPaymentState(
            auth: auth,
            payment: payment,
            enrollment: enrollment,
            cart: cart,
          );

          if (!mounted) return;

          final effectiveTotal = (widget.amount - payment.couponDiscount).clamp(
            0.0,
            double.infinity,
          );
          context.go(
            '/payment-success',
            extra: {
              'orderId': effectiveOrderId,
              'paymentId':
                  gatewayResult.paymentId ?? gatewayResult.gatewayOrderId,
              'title': widget.title,
              'amount': effectiveTotal,
              'productType': widget.productType,
              'verified': true,
              'courseId': effectiveCourseId,
            },
          );
          return;
        }

        payment.setStatus(
          PaymentStatus.awaitingConfirmation,
          error:
              'Payment received, but order confirmation is pending. Order ID: #$effectiveOrderId. Use Refresh Status to check again.',
        );
      }
    } on PaymentGatewayLaunchException catch (e) {
      // Gateway failed to launch OR user cancelled — no payment was made.
      // This is distinct from "payment received but verification failed".
      if (!mounted) return;
      DebugLogger.logPaymentStage(
        stage: 'gateway_launch_failed',
        productType: widget.productType,
        orderId: payment.currentOrderId,
        data: {'error': e.message},
      );
      payment.setStatus(PaymentStatus.failed, error: e.message);
    } catch (e) {
      // Unexpected error — could be network, backend, or unknown.
      // If a payment_id was already obtained from the gateway (stored in
      // payment state), do NOT say "Payment Failed" — say "awaiting confirmation".
      if (!mounted) return;
      final hasPaymentId =
          payment.lastResult?.transactionId != null &&
          (payment.lastResult?.transactionId?.isNotEmpty ?? false);
      DebugLogger.logPaymentStage(
        stage: hasPaymentId
            ? 'post_payment_exception'
            : 'pre_payment_exception',
        productType: widget.productType,
        orderId: payment.currentOrderId,
        data: {'error': _sanitizeError(e), 'has_payment_id': hasPaymentId},
      );
      if (hasPaymentId) {
        // Payment was received by gateway but something failed after.
        // Do NOT show "Payment Failed" — show "awaiting confirmation".
        payment.setStatus(
          PaymentStatus.awaitingConfirmation,
          error:
              'Payment received, but confirmation could not be completed. '
              'Your Order ID is #${payment.currentOrderId ?? 'unknown'}. '
              'Contact support if not resolved within 24 hours.',
        );
      } else {
        payment.setStatus(PaymentStatus.failed, error: _sanitizeError(e));
      }
    }
  }

  Future<void> _refreshOrderStatus() async {
    final auth = context.read<AuthController>();
    final payment = context.read<PaymentController>();
    final enrollment = context.read<EnrollmentController>();
    final cart = context.read<CartController>();
    final orderId = payment.currentOrderId;
    if (orderId == null || orderId <= 0) return;

    payment.setStatus(PaymentStatus.awaitingConfirmation);
    final status = await _pollOrderConfirmation(
      payment: payment,
      orderId: orderId,
      productType: widget.productType,
      token: auth.currentToken,
    );

    if (!mounted) return;

    if (payment.isConfirmedOrderStatus(status, widget.productType)) {
      await _refreshPostPaymentState(
        auth: auth,
        payment: payment,
        enrollment: enrollment,
        cart: cart,
      );

      if (!mounted) return;
      final effectiveTotal = (widget.amount - payment.couponDiscount).clamp(
        0.0,
        double.infinity,
      );
      context.go(
        '/payment-success',
        extra: {
          'orderId': orderId,
          'paymentId': payment.lastResult?.transactionId ?? '',
          'title': widget.title,
          'amount': effectiveTotal,
          'productType': widget.productType,
          'verified': true,
        },
      );
      return;
    }

    payment.setStatus(
      PaymentStatus.awaitingConfirmation,
      error:
          'Payment received, but backend confirmation is still pending. Order ID: #$orderId',
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final payment = context.watch<PaymentController>();
    final gateways = payment.gateways;

    final effectiveTotal = (widget.amount - payment.couponDiscount).clamp(
      0.0,
      double.infinity,
    );

    return PopScope(
      canPop: !payment.isProcessing,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.navyDark,
            ),
            onPressed: payment.isProcessing
                ? null
                : () {
                    payment.reset();
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.home);
                    }
                  },
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Secure Checkout · 256-bit SSL',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title & Description
                        Text(
                          'Secure Checkout',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navyDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Review your order and complete payment securely to activate instant access.',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── 1. Order Item Card ─────────────────────────────────
                        _buildIncludedCourseCard(),

                        const SizedBox(height: 20),

                        // ── 2. Payment Method Card ─────────────────────────────
                        _buildPaymentMethodsSection(gateways),

                        const SizedBox(height: 20),

                        // ── 3. Coupon Code Input ───────────────────────────────
                        _buildCouponSection(payment),

                        const SizedBox(height: 20),

                        // ── 4. Why Students Trust Zabira ───────────────────────
                        _buildTrustBadgesSection(),

                        const SizedBox(height: 20),

                        // ── 5. Frequently Asked Questions ──────────────────────
                        _buildFaqSection(),

                        const SizedBox(height: 20),

                        // ── 6. Order Summary Card ──────────────────────────────
                        _buildOrderSummaryCard(payment, effectiveTotal),

                        // ── 7. Error / Failure Message Banner ──────────────────
                        if (payment.status == PaymentStatus.failed ||
                            payment.status == PaymentStatus.timeout ||
                            payment.status == PaymentStatus.cancelled ||
                            payment.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          _buildErrorBanner(payment),
                        ],

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // ── Sticky Bottom Pay Bar ──────────────────────────────────────
                _buildBottomPayBar(payment, effectiveTotal),
              ],
            ),

            // ── Processing Overlay ─────────────────────────────────────────────
            if (payment.isProcessing) _buildProcessingOverlay(payment),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay(PaymentController payment) {
    return Container(
      color: Colors.black.withAlpha(120),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                payment.statusMessage.isNotEmpty
                    ? payment.statusMessage
                    : 'Processing securely...',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Please do not close or refresh this page.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(PaymentController payment) {
    final isPendingConfirmation =
        payment.status == PaymentStatus.awaitingConfirmation;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPendingConfirmation
            ? const Color(0xFFFFFBEB)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPendingConfirmation
              ? const Color(0xFFFDE68A)
              : const Color(0xFFFECACA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPendingConfirmation
                    ? Icons.hourglass_top_rounded
                    : Icons.error_outline_rounded,
                color: isPendingConfirmation
                    ? const Color(0xFFD97706)
                    : const Color(0xFFDC2626),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isPendingConfirmation
                    ? 'Confirmation Pending'
                    : payment.status == PaymentStatus.timeout
                    ? 'Transaction Timed Out'
                    : payment.status == PaymentStatus.cancelled
                    ? 'Payment Cancelled'
                    : 'Payment Failed',
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: isPendingConfirmation
                      ? const Color(0xFF92400E)
                      : const Color(0xFF991B1B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            payment.errorMessage ?? payment.statusMessage,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              color: isPendingConfirmation
                  ? const Color(0xFFB45309)
                  : const Color(0xFFB91C1C),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton(
                onPressed: isPendingConfirmation
                    ? _refreshOrderStatus
                    : () {
                        payment.reset();
                        _handlePayment();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navyDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isPendingConfirmation ? 'Refresh Status' : 'Retry Payment',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () {
                  payment.reset();
                  if (context.canPop()) context.pop();
                },
                child: Text(
                  'Cancel',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCouponSection(PaymentController payment) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_offer_outlined,
                color: AppColors.gold,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Have a Promo Code or Coupon?',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: _couponController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Enter coupon code (e.g. ZABIRA20)',
                      hintStyle: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: _isApplyingCoupon
                      ? null
                      : () => _applyCouponCode(widget.orderId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: _isApplyingCoupon
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Apply',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
            ],
          ),
          if (_couponMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _couponMessage!,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _isCouponSuccess
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIncludedCourseCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.productType == 'course'
                    ? 'COURSE INCLUDED IN ENROLLMENT'
                    : widget.productType == 'store'
                    ? 'STORE ITEM IN ORDER'
                    : 'CART ITEMS IN CHECKOUT',
                style: GoogleFonts.outfit(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.productType == 'course' ? '1 COURSE' : 'ITEM',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.navyDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.productType == 'course'
                      ? Icons.menu_book_rounded
                      : widget.productType == 'store'
                      ? Icons.inventory_2_rounded
                      : Icons.shopping_bag_rounded,
                  color: AppColors.gold,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navyDark,
                              height: 1.2,
                            ),
                          ),
                        ),
                        Text(
                          '₹${widget.amount.toInt()}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navyDark,
                          ),
                        ),
                      ],
                    ),
                    if (widget.planLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Plan: ${widget.planLabel}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                    ],
                    if (widget.instructor != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.instructor!,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSection(List<PaymentGatewayInfo> gateways) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Payment Gateway',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.navyDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'All payments are processed securely via banking-grade encryption.',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),

          if (gateways.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                'No configured payment gateway is currently available.',
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFB91C1C),
                ),
              ),
            ),

          ...gateways.map((gw) {
            final isSelected = _selectedGateway == gw.code;
            return GestureDetector(
              onTap: () => setState(() => _selectedGateway = gw.code),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.navyDark : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.navyDark
                        : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_off_rounded,
                          color: isSelected
                              ? AppColors.gold
                              : const Color(0xFF94A3B8),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: gw.code == 'cashfree'
                                ? const Color(0xFF00C897)
                                : const Color(0xFF0C2340),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            gw.name,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (gw.isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withAlpha(40),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'RECOMMENDED',
                              style: GoogleFonts.outfit(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? AppColors.gold
                                    : const Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTrustBadgesSection() {
    final badges = [
      (
        'Instant Access',
        'Start learning right after payment.',
        Icons.flash_on_rounded,
      ),
      (
        'Transparent Terms',
        'Clear policies and support.',
        Icons.replay_rounded,
      ),
      (
        'Verified Security',
        'Certified PCI DSS compliant.',
        Icons.verified_user_outlined,
      ),
      (
        'Direct Support',
        '24/7 student assistance.',
        Icons.support_agent_rounded,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.gold,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                '256-bit SSL Encrypted',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFE2E8F0)),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.1,
            ),
            itemCount: badges.length,
            itemBuilder: (context, index) {
              final b = badges[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(b.$3, size: 15, color: AppColors.gold),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          b.$1,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    b.$2,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 10.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFaqSection() {
    final faqs = [
      (
        0,
        'When will I get access?',
        'Access activates immediately after successful payment verification. You will be redirected right away.',
      ),
      (
        1,
        'Is my payment information secure?',
        'All transactions are processed through banking-grade 256-bit encryption with certified PCI DSS compliant partners.',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequently Asked Questions',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.navyDark,
            ),
          ),
          const SizedBox(height: 8),
          ...faqs.map((faq) {
            final isExpanded = _expandedFaqs.contains(faq.$1);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedFaqs.remove(faq.$1);
                  } else {
                    _expandedFaqs.add(faq.$1);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            faq.$2,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyDark,
                            ),
                          ),
                        ),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF64748B),
                          size: 18,
                        ),
                      ],
                    ),
                    if (isExpanded) ...[
                      const SizedBox(height: 4),
                      Text(
                        faq.$3,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(
    PaymentController payment,
    double effectiveTotal,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.navyDark,
            ),
          ),
          const SizedBox(height: 12),
          _summaryRow('Subtotal', '₹${widget.amount.toInt()}'),
          if (payment.couponDiscount > 0) ...[
            const SizedBox(height: 6),
            _summaryRow(
              'Coupon Discount',
              '-₹${payment.couponDiscount.toInt()}',
              isDiscount: true,
            ),
          ],
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _summaryRow(
            'Total Due Today',
            '₹${effectiveTotal.toInt()}',
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: isBold ? 14 : 12.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? AppColors.navyDark : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isDiscount
                ? const Color(0xFF10B981)
                : (isBold ? AppColors.navyDark : const Color(0xFF334155)),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPayBar(PaymentController payment, double effectiveTotal) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        12,
        AppSpacing.screenHorizontal,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total Amount',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                ),
              ),
              Text(
                '₹${effectiveTotal.toInt()}',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyDark,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: payment.isProcessing || payment.gateways.isEmpty
                    ? null
                    : _handlePayment,
                icon: const Icon(Icons.lock_rounded, size: 17),
                label: Text(
                  payment.isProcessing
                      ? 'Processing...'
                      : 'Pay ₹${effectiveTotal.toInt()} Securely',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navyDark,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
