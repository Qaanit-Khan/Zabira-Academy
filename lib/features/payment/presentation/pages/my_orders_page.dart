import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../auth/auth_controller.dart';
import '../controllers/payment_controller.dart';
import '../../data/models/payment_models.dart';

/// Zabira Academy — My Orders Screen
class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final token = context.read<AuthController>().currentToken;
    setState(() => _isLoading = true);
    await context.read<PaymentController>().loadMyOrders(token);
    if (mounted) setState(() => _isLoading = false);
  }

  void _showInvoiceDialog(MyOrderItem order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.receipt_long_rounded, color: AppColors.gold, size: 22),
            const SizedBox(width: 8),
            Text(
              'Invoice Summary',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navyDark),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order #${order.orderId}', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 4),
            Text('Item: ${order.title}', style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B))),
            const SizedBox(height: 4),
            Text('Amount: ₹${order.amount.toInt()}', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.navyDark)),
            const SizedBox(height: 4),
            Text('Status: ${order.paymentStatus.toUpperCase()}', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 12, color: order.isPaid ? const Color(0xFF10B981) : AppColors.gold)),
            if (order.date != null) ...[
              const SizedBox(height: 4),
              Text('Date: ${order.date!.toLocal().toString().split(' ').first}', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8))),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<PaymentController>().myOrders;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navyDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My Orders & Invoices',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navyDark),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.navyDark, size: 24),
            tooltip: 'Menu',
            onPressed: () => AppDrawer.open(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : orders.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 54, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 14),
                        Text(
                          'No orders found',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navyDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'When you enroll in courses or make purchases, they will appear here.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.gold,
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final o = orders[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: o.isPaid ? const Color(0xFF10B981).withAlpha(20) : const Color(0xFFFFF9E6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Icon(
                                  o.isPaid ? Icons.check_circle_outline_rounded : Icons.pending_actions_rounded,
                                  color: o.isPaid ? const Color(0xFF10B981) : AppColors.gold,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    o.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navyDark),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Order #${o.orderId} · ${o.paymentStatus.toUpperCase()}',
                                    style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${o.amount.toInt()}',
                                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navyDark),
                                ),
                                GestureDetector(
                                  onTap: () => _showInvoiceDialog(o),
                                  child: Text(
                                    'Invoice',
                                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
