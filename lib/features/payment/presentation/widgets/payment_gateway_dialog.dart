import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/auth_controller.dart';
import '../../data/services/payment_gateway_launcher.dart';
import '../controllers/payment_controller.dart';
import '../../data/models/payment_models.dart';

/// Zabira Academy — Secure Payment Gateway Dialog / Sheet
class PaymentGatewayDialog extends StatefulWidget {
  const PaymentGatewayDialog({
    super.key,
    required this.orderId,
    required this.productType,
    required this.title,
    required this.amount,
    this.subtitle,
    this.planLabel,
  });

  final int orderId;
  final String productType; // 'course', 'store', 'cart', 'library'
  final String title;
  final double amount;
  final String? subtitle;
  final String? planLabel;

  static Future<bool> show({
    required BuildContext context,
    required int orderId,
    required String productType,
    required String title,
    required double amount,
    String? subtitle,
    String? planLabel,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaymentGatewayDialog(
        orderId: orderId,
        productType: productType,
        title: title,
        amount: amount,
        subtitle: subtitle,
        planLabel: planLabel,
      ),
    );
    return result == true;
  }

  @override
  State<PaymentGatewayDialog> createState() => _PaymentGatewayDialogState();
}

class _PaymentGatewayDialogState extends State<PaymentGatewayDialog> {
  String _selectedGateway = 'razorpay';
  bool _isProcessing = false;
  String _statusStep = '';
  String? _errorMsg;
  final PaymentGatewayLauncher _gatewayLauncher = PaymentGatewayLauncher();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthController>().currentToken;
      context.read<PaymentController>().loadGateways(token);
    });
  }

  Future<void> _processPayment() async {
    final auth = context.read<AuthController>();
    final payment = context.read<PaymentController>();

    if (!auth.isAuthenticated) {
      setState(() => _errorMsg = 'Authentication required. Please sign in.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusStep = 'Creating secure payment session...';
      _errorMsg = null;
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
          _errorMsg = payment.errorMessage ?? 'Failed to initialize payment session.';
        });
        return;
      }

      if (!mounted) return;
      setState(() => _statusStep = 'Opening payment gateway...');
      payment.setStatus(PaymentStatus.waitingForGateway);

      final gatewayResult = await _gatewayLauncher.launch(
        context: context,
        session: session,
        title: widget.title,
        amount: widget.amount,
      );
      if (!mounted) return;

      setState(() {
        _statusStep = 'Verifying payment with Zabira server...';
      });

      // 3. Verify Payment
      final isVerified = await payment.verifyPayment(
        orderId: widget.orderId,
        productType: widget.productType,
        gatewayOrderId: gatewayResult.gatewayOrderId,
        paymentId: gatewayResult.paymentId,
        signature: gatewayResult.signature,
        razorpayOrderId: gatewayResult.razorpayOrderId,
        token: auth.currentToken,
      );

      if (!mounted) return;

      if (isVerified) {
        final status = await payment.checkOrderStatus(
          orderId: widget.orderId,
          productType: widget.productType,
          token: auth.currentToken,
        );
        if (!payment.isConfirmedOrderStatus(status, widget.productType)) {
          setState(() {
            _isProcessing = false;
            _errorMsg = payment.errorMessage ?? 'Payment verified, but order is not confirmed.';
          });
          return;
        }
        setState(() {
          _isProcessing = false;
          _statusStep = 'Payment verified successfully!';
        });
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _isProcessing = false;
          _errorMsg = payment.errorMessage ?? 'Payment verification failed.';
        });
      }
    } on PaymentGatewayLaunchException catch (e) {
      // Gateway launch failure or user cancellation — no payment was made
      payment.setStatus(PaymentStatus.failed, error: e.message);
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMsg = e.message;
      });
    } catch (e) {
      // If payment was already received (has payment_id), don't say "Payment Failed"
      final hasPaymentId = payment.lastResult?.transactionId != null &&
          (payment.lastResult?.transactionId?.isNotEmpty ?? false);
      if (hasPaymentId) {
        payment.setStatus(
          PaymentStatus.awaitingConfirmation,
          error: 'Payment received, but confirmation pending. Order ID: #${widget.orderId}.',
        );
      } else {
        payment.setStatus(PaymentStatus.failed, error: e.toString().replaceAll('Exception:', '').trim());
      }
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMsg = payment.errorMessage ?? e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final payment = context.watch<PaymentController>();
    final gateways = payment.gateways.isNotEmpty
        ? payment.gateways
        : const [
            PaymentGatewayInfo(id: 1, code: 'razorpay', name: 'Razorpay (Cards, UPI, NetBanking, Wallets)'),
          ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lock_outline_rounded, color: AppColors.gold, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secure Checkout',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyDark,
                        ),
                      ),
                      Text(
                        '256-bit SSL Encrypted Payment',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textTertiary),
                  onPressed: _isProcessing ? null : () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const Divider(height: 28, color: Color(0xFFE2E8F0)),

            // Summary Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '₹${widget.amount.toInt()}',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navyDark,
                        ),
                      ),
                    ],
                  ),
                  if (widget.planLabel != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withAlpha(35),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.planLabel!,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF926200),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Select Gateway
            Text(
              'PAYMENT METHOD',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),

            ...gateways.map((gw) {
              final isSelected = _selectedGateway == gw.code;
              return GestureDetector(
                onTap: _isProcessing
                    ? null
                    : () => setState(() => _selectedGateway = gw.code),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFFF9E6) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.gold : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                        color: isSelected ? AppColors.gold : const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          gw.name,
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: AppColors.navyDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            if (_errorMsg != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMsg!,
                        style: GoogleFonts.outfit(fontSize: 12, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_isProcessing) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _statusStep,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navyDark,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 18),

            // Pay Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: const Color(0xFF081D3A),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _isProcessing ? 'Processing...' : 'Pay ₹${widget.amount.toInt()} Securely',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
