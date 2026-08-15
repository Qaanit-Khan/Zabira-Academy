import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/auth/auth_controller.dart';
import '../../../../shared/buttons/primary_button.dart';
import '../../../../shared/loaders/zabira_loader.dart';
import '../../../../shared/widgets/zabira_network_image.dart';
import '../../data/models/cart_item_model.dart';
import '../controllers/cart_controller.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      context.read<CartController>().loadCart(auth.currentToken);
    });
  }

  void _handleCheckout() {
    final auth = context.read<AuthController>();
    if (!auth.isAuthenticated) {
      auth.setPendingReturnTo(AppRoutes.cart);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to proceed with checkout.')),
      );
      context.push(AppRoutes.login);
      return;
    }

    // Checkout dialog / modal
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Checkout Order',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.navyDark),
        ),
        content: Text(
          'Proceed to secure checkout for total ₹${context.read<CartController>().total.toStringAsFixed(0)}?',
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyDark,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order processing initiated!')),
              );
            },
            child: const Text('Confirm & Pay'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final auth = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navyDark, size: 20),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              GoRouter.of(context).pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: Text(
          'Shopping Cart',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.navyDark,
          ),
        ),
        centerTitle: true,
        actions: [
          if (cart.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
              tooltip: 'Clear Cart',
              onPressed: () => cart.clearCart(auth.currentToken),
            ),
        ],
      ),
      body: cart.isLoading && cart.items.isEmpty
          ? const Center(child: ZabiraLoader(size: 40))
          : cart.isEmpty
              ? _buildEmptyCart()
              : _buildCartContent(cart, auth),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2l),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.gold.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_bag_outlined, color: AppColors.gold, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'Your Cart is Empty',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore our store and library to add books, courses, and educational items to your cart.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: PrimaryButton(
                label: 'Explore Store',
                icon: Icons.storefront_rounded,
                onPressed: () => context.push(AppRoutes.store),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent(CartController cart, AuthController auth) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: cart.items.length,
            itemBuilder: (context, index) {
              final item = cart.items[index];
              return _buildCartItemTile(item, cart, auth);
            },
          ),
        ),

        // ── Bottom Checkout Summary ─────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal (${cart.itemCount} items)',
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                  ),
                  Text(
                    '₹${cart.subtotal.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navyDark),
                  ),
                ],
              ),
              if (cart.discount > 0) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Discount', style: GoogleFonts.inter(fontSize: 13, color: AppColors.success)),
                    Text('-₹${cart.discount.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.success)),
                  ],
                ),
              ],
              const Divider(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navyDark),
                  ),
                  Text(
                    '₹${cart.total.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.gold),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _handleCheckout,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        auth.isAuthenticated ? 'Proceed to Checkout' : 'Sign In to Checkout',
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCartItemTile(CartItemModel item, CartController cart, AuthController auth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 60,
              height: 60,
              child: ZabiraNetworkImage(
                imageUrl: item.resolvedImage,
                fit: BoxFit.cover,
                fallbackIcon: Icons.shopping_bag_outlined,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.variantName != null || item.bookFormat != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.variantName ?? item.bookFormat ?? '',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '₹${item.effectivePrice.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                      ),
                    ),
                    if (item.quantity > 1) ...[
                      const SizedBox(width: 6),
                      Text(
                        '× ${item.quantity}',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Remove Button
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF94A3B8), size: 20),
            onPressed: () => cart.removeItem(item, auth.currentToken),
          ),
        ],
      ),
    );
  }
}
