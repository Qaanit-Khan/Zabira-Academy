import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/auth_controller.dart';
import '../controllers/payment_controller.dart';

/// Zabira Academy — Native Payment Success Screen
class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({
    super.key,
    required this.orderId,
    required this.paymentId,
    required this.title,
    required this.amount,
    this.productType = 'course',
    this.verified = false,
    this.courseId,
  });

  final int orderId;
  final String paymentId;
  final String title;
  final double amount;
  final String productType;
  final bool verified;
  final int? courseId;

  void _showInvoiceBottomSheet(BuildContext context) async {
    final token = context.read<AuthController>().currentToken;
    final payment = context.read<PaymentController>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: payment.getInvoice(orderId: orderId, token: token),
          builder: (context, snapshot) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded, color: AppColors.gold, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Tax Invoice & Receipt',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navyDark,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Color(0xFFE2E8F0)),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
                    )
                  else ...[
                    _invoiceRow('Order ID', '#$orderId'),
                    _invoiceRow('Transaction ID', paymentId.length > 20 ? '${paymentId.substring(0, 20)}...' : paymentId),
                    _invoiceRow('Item', title),
                    _invoiceRow('Category', productType.toUpperCase()),
                    _invoiceRow('Amount Paid', '₹${amount.toInt()}', isBold: true, highlight: true),
                    _invoiceRow('Status', 'PAID · CONFIRMED', statusColor: const Color(0xFF10B981)),
                    _invoiceRow('Date', DateTime.now().toLocal().toString().split(' ').first),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navyDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _invoiceRow(String label, String value, {bool isBold = false, bool highlight = false, Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B))),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.outfit(
                fontSize: highlight ? 15 : 13,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: statusColor ?? (highlight ? AppColors.gold : AppColors.navyDark),
              ),
            ),
          ),
        ],
      ),
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

    final isCourse = productType == 'course';

    if (!verified || orderId <= 0 || paymentId.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navyDark),
            onPressed: () => context.go(AppRoutes.home),
          ),
          title: Text(
            'Payment Not Confirmed',
            style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.navyDark),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                const SizedBox(height: 14),
                Text(
                  'Payment success is unavailable until the transaction is verified and the order is confirmed.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navyDark),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go(isCourse ? AppRoutes.myCourses : AppRoutes.store);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success Badge
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF10B981),
                        size: 58,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Payment Successful!',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isCourse
                        ? 'Your course enrollment is confirmed and activated.'
                        : 'Your order has been placed and is being prepared.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Order & Transaction Receipt Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      children: [
                        _receiptRow('Item', title, isBold: true),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _receiptRow('Amount Paid', '₹${amount.toInt()}', isBold: true, highlight: true),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _receiptRow('Order ID', '#$orderId'),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _receiptRow('Payment Reference', paymentId.length > 18 ? '${paymentId.substring(0, 18)}...' : paymentId),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _receiptRow(
                          'Access Status',
                          isCourse ? 'Activated · Lifetime Access' : 'Confirmed · Processing Order',
                          statusColor: const Color(0xFF10B981),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // CTAs
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (isCourse) {
                          if (courseId != null && courseId! > 0) {
                            context.go('/courses/$courseId/learn');
                          } else {
                            context.go(AppRoutes.myCourses);
                          }
                        } else {
                          context.go('/my-orders');
                        }
                      },
                      icon: Icon(isCourse ? Icons.play_circle_fill_rounded : Icons.inventory_2_rounded, size: 18),
                      label: Text(isCourse ? 'Start Learning Now' : 'View My Orders'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.navyDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                        textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => context.go(isCourse ? AppRoutes.studentDash : AppRoutes.store),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navyDark,
                        side: const BorderSide(color: AppColors.navyDark),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        textStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      child: Text(isCourse ? 'Go to Student Dashboard' : 'Continue Shopping'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextButton.icon(
                    onPressed: () => _showInvoiceBottomSheet(context),
                    icon: const Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFF64748B)),
                    label: Text(
                      'View Invoice & Receipt',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isBold = false, bool highlight = false, Color? statusColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.outfit(
              fontSize: highlight ? 15 : 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: statusColor ?? (highlight ? AppColors.gold : AppColors.navyDark),
            ),
          ),
        ),
      ],
    );
  }
}
