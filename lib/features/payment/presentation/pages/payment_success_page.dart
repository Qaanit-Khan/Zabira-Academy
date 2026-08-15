import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Zabira Academy — Native Payment Success Screen
class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({
    super.key,
    required this.orderId,
    required this.paymentId,
    required this.title,
    required this.amount,
    this.productType = 'course',
  });

  final int orderId;
  final String paymentId;
  final String title;
  final double amount;
  final String productType;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
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
                  'Your enrollment has been confirmed on Zabira Academy.',
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
                      _receiptRow('Enrollment Status', 'Activated · Lifetime', statusColor: const Color(0xFF10B981)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // CTAs
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go(AppRoutes.myCourses),
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                    label: const Text('Start Learning Now'),
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
                    onPressed: () => context.go(AppRoutes.studentDash),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navyDark,
                      side: const BorderSide(color: AppColors.navyDark),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Go to Student Dashboard'),
                  ),
                ),
                const SizedBox(height: 12),

                TextButton.icon(
                  onPressed: () => context.push('/my-orders'),
                  icon: const Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFF64748B)),
                  label: Text(
                    'View Order & Invoice',
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                  ),
                ),
              ],
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
