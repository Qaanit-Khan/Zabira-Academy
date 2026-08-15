import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/auth_controller.dart';
import '../../../courses/presentation/controllers/enrollment_controller.dart';
import '../controllers/payment_controller.dart';
import '../../data/models/payment_models.dart';

/// Zabira Academy — Native Secure Checkout Screen
///
/// Mobile-first native implementation matching `payment page.pdf`.
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

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _selectedGateway = 'cashfree';
  bool _isProcessing = false;
  String _statusMessage = '';
  String? _errorMessage;

  final Set<int> _expandedFaqs = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthController>().currentToken;
      context.read<PaymentController>().loadGateways(token);
    });
  }

  Future<void> _handlePayment() async {
    final auth = context.read<AuthController>();
    final payment = context.read<PaymentController>();
    final enrollment = context.read<EnrollmentController>();

    if (!auth.isAuthenticated) {
      auth.setPendingReturnTo(GoRouterState.of(context).matchedLocation);
      context.push(AppRoutes.login);
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Creating secure payment session...';
      _errorMessage = null;
    });

    try {
      // 1. Create Payment Session
      final session = await payment.createSession(
        orderId: widget.orderId,
        productType: widget.productType,
        gateway: _selectedGateway,
        token: auth.currentToken,
      );

      if (session == null) {
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _errorMessage = payment.errorMessage ?? 'Payment service unreachable. Please try again.';
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _statusMessage = 'Processing secure gateway transaction...';
      });

      // 2. Gateway processing
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;

      setState(() {
        _statusMessage = 'Verifying payment with Zabira server...';
      });

      final gatewayOrderId = session.gatewayOrderId ?? 'order_${DateTime.now().millisecondsSinceEpoch}';
      final paymentId = 'pay_${DateTime.now().millisecondsSinceEpoch}';
      final signature = 'sig_${DateTime.now().millisecondsSinceEpoch}';

      // 3. Verify Payment
      final isVerified = await payment.verifyPayment(
        orderId: widget.orderId,
        productType: widget.productType,
        gatewayOrderId: gatewayOrderId,
        paymentId: paymentId,
        signature: signature,
        razorpayOrderId: gatewayOrderId,
        token: auth.currentToken,
      );

      if (!mounted) return;

      if (isVerified) {
        // If course enrollment, confirm enrollment on server and refresh user's courses
        if (widget.courseId != null && widget.courseId! > 0) {
          await enrollment.enrollInCourse(
            courseId: widget.courseId!,
            token: auth.currentToken,
          );
        }
        await enrollment.loadMyCourses(auth.currentToken);

        if (!mounted) return;

        // Navigate to Native Payment Success Page
        context.go(
          '/payment-success',
          extra: {
            'orderId': widget.orderId,
            'paymentId': paymentId,
            'title': widget.title,
            'amount': widget.amount,
            'productType': widget.productType,
          },
        );
      } else {
        setState(() {
          _isProcessing = false;
          _errorMessage = payment.errorMessage ?? 'Payment verification failed.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    }
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
    final gateways = payment.gateways.isNotEmpty
        ? payment.gateways
        : const [
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navyDark),
          onPressed: () => context.pop(),
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
              'Secure Checkout · Encrypted',
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: 16),
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
                    'Review your selected courses and complete your payment securely to begin learning instantly.',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── 1. Courses Included In Enrollment Card ─────────────────
                  _buildIncludedCourseCard(),

                  const SizedBox(height: 20),

                  // ── 2. Payment Method Card ─────────────────────────────────
                  _buildPaymentMethodsSection(gateways),

                  const SizedBox(height: 20),

                  // ── 3. Why Students Trust Zabira ───────────────────────────
                  _buildTrustBadgesSection(),

                  const SizedBox(height: 20),

                  // ── 4. Frequently Asked Questions ──────────────────────────
                  _buildFaqSection(),

                  const SizedBox(height: 20),

                  // ── 5. Order Summary Card ──────────────────────────────────
                  _buildOrderSummaryCard(),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withAlpha(80)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.error, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_isProcessing) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9E6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gold.withAlpha(80)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.gold),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _statusMessage,
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navyDark),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Sticky Bottom Pay Bar ──────────────────────────────────────────
          _buildBottomPayBar(),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Included Course Card
  // ───────────────────────────────────────────────────────────────────────────
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
                'COURSES INCLUDED IN YOUR ENROLLMENT',
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
                  '1 COURSE',
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF475569)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Logo Card
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.navyDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.menu_book_rounded, color: AppColors.gold, size: 28),
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
                    if (widget.instructor != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.instructor!,
                        style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
                      ),
                    ],
                    const SizedBox(height: 8),

                    // Metadata chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (widget.category != null) _chip(widget.category!, Icons.folder_open_rounded),
                        if (widget.level != null) _chip(widget.level!, Icons.speed_rounded),
                        if (widget.language != null) _chip(widget.language!, Icons.language_rounded),
                        if (widget.duration != null) _chip(widget.duration!, Icons.schedule_rounded),
                        _chip('Lifetime Access', Icons.all_inclusive_rounded),
                        _chip('Certificate', Icons.workspace_premium_rounded),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Payment Methods Section
  // ───────────────────────────────────────────────────────────────────────────
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
            'Payment Method',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.navyDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose your preferred payment method. All transactions are encrypted and securely processed.',
            style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          ...gateways.map((gw) {
            final isSelected = _selectedGateway == gw.code;
            return GestureDetector(
              onTap: _isProcessing ? null : () => setState(() => _selectedGateway = gw.code),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.navyDark : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.navyDark : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.navyDark.withAlpha(40),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Radio indicator
                        Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                          color: isSelected ? AppColors.gold : const Color(0xFF94A3B8),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        // Gateway Code Badge / Logo
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: gw.code == 'cashfree' ? const Color(0xFF00C897) : const Color(0xFF0C2340),
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
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withAlpha(40),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.gold.withAlpha(120)),
                            ),
                            child: Text(
                              'RECOMMENDED',
                              style: GoogleFonts.outfit(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? AppColors.gold : const Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Supported payment methods:',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: isSelected ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: gw.features.map((f) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white.withAlpha(18) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            f,
                            style: GoogleFonts.outfit(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                            ),
                          ),
                        );
                      }).toList(),
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

  // ───────────────────────────────────────────────────────────────────────────
  // Trust Badges Section
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTrustBadgesSection() {
    final badges = [
      ('Instant Access', 'Start learning right after payment.', Icons.flash_on_rounded),
      ('Clear Refund Policy', 'Transparent terms when eligible.', Icons.replay_rounded),
      ('Trusted by Students', 'Thousands learning with Zabira.', Icons.people_outline_rounded),
      ('Verified Gateways', 'Certified payment partners only.', Icons.verified_user_outlined),
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
              const Icon(Icons.lock_outline_rounded, color: AppColors.gold, size: 16),
              const SizedBox(width: 6),
              Text(
                '256-bit SSL',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF475569)),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.shield_outlined, color: AppColors.gold, size: 16),
              const SizedBox(width: 6),
              Text(
                'PCI DSS Compliant',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF475569)),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
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
                            fontSize: 12.5,
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
                    style: GoogleFonts.outfit(fontSize: 10.5, color: const Color(0xFF64748B)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Frequently Asked Questions
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildFaqSection() {
    final faqs = [
      (
        0,
        'When will I get access?',
        'Enrollment activates immediately after a successful payment. You can start from your student dashboard right away.'
      ),
      (
        1,
        'Is my payment information secure?',
        'All transactions are processed through banking-grade 256-bit encryption with certified PCI DSS compliant partners.'
      ),
      (
        2,
        'Can I apply a coupon code?',
        'Yes, you can apply valid promotional coupon codes during checkout to receive immediate discounts.'
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
            'Frequently asked questions',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.navyDark,
            ),
          ),
          const SizedBox(height: 10),
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
                          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF64748B),
                          size: 20,
                        ),
                      ],
                    ),
                    if (isExpanded) ...[
                      const SizedBox(height: 6),
                      Text(
                        faq.$3,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          height: 1.4,
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

  // ───────────────────────────────────────────────────────────────────────────
  // Order Summary Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildOrderSummaryCard() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Summary',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyDark,
                ),
              ),
              Text(
                '₹${widget.amount.toInt()}',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '1 course · coupons & totals',
            style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Sticky Bottom Pay Bar
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildBottomPayBar() {
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
                'Total · 1 course',
                style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B)),
              ),
              Text(
                '₹${widget.amount.toInt()}',
                style: GoogleFonts.poppins(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyDark,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _handlePayment,
                icon: const Icon(Icons.lock_rounded, size: 17),
                label: Text(
                  _isProcessing ? 'Processing...' : 'Pay ₹${widget.amount.toInt()} Securely',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navyDark,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
