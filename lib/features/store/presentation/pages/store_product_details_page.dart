import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/auth/auth_controller.dart';
import '../../../auth/presentation/widgets/auth_bottom_sheet.dart';
import '../../data/models/store_product_model.dart';
import '../../data/repositories/store_repository.dart';
import '../controllers/cart_controller.dart';

/// Zabira Academy — Store Product Details Page
class StoreProductDetailsPage extends StatefulWidget {
  const StoreProductDetailsPage({
    super.key,
    required this.productId,
  });

  final int productId;

  @override
  State<StoreProductDetailsPage> createState() => _StoreProductDetailsPageState();
}

class _StoreProductDetailsPageState extends State<StoreProductDetailsPage> {
  final StoreRepository _repository = StoreRepository();

  StoreProductModel? _product;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedImageIndex = 0;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final product = await _repository.getProductDetails(widget.productId);
      if (mounted) {
        setState(() {
          _product = product;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not load product details. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _incrementQuantity() {
    final maxStock = _product?.stock ?? 10;
    if (_quantity < maxStock && maxStock > 0) {
      HapticFeedback.selectionClick();
      setState(() => _quantity++);
    }
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      HapticFeedback.selectionClick();
      setState(() => _quantity--);
    }
  }

  String _cleanHtml(String? html) {
    if (html == null || html.isEmpty) return '';
    return html
        .replaceAll(RegExp(r'<p>|</p>|<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'<li>'), '• ')
        .replaceAll(RegExp(r'</li>'), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: _isLoading
            ? _buildLoading()
            : (_errorMessage != null || _product == null)
                ? _buildError()
                : _buildContent(),
      ),
      bottomNavigationBar: _product != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildLoading() {
    return Column(
      children: [
        _buildAppBar(title: 'Loading...'),
        const Expanded(
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.gold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      children: [
        _buildAppBar(title: 'Product Details'),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textTertiary),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _errorMessage ?? 'Product details not available.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: _loadProductDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyDark,
                      foregroundColor: AppColors.gold,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final p = _product!;
    final images = p.allImageUrls;
    final activeImageUrl = images.isNotEmpty && _selectedImageIndex < images.length
        ? images[_selectedImageIndex]
        : p.fullThumbnailUrl;

    return Column(
      children: [
        // ── Custom App Bar ──────────────────────────────────────────────────
        _buildAppBar(title: p.name),

        // ── Scrollable Body ─────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Main Gallery Container ───────────────────────────────
                Container(
                  width: double.infinity,
                  height: 260,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navyDark.withAlpha(8),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: activeImageUrl != null && activeImageUrl.isNotEmpty
                        ? Image.network(
                            activeImageUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                              );
                            },
                            errorBuilder: (context, error, _) => const Center(
                              child: Icon(Icons.inventory_2_outlined, size: 54, color: AppColors.navyDark),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.inventory_2_outlined, size: 54, color: AppColors.navyDark),
                          ),
                  ),
                ),

                // ── 2. Thumbnail Selector Row (if multiple) ─────────────────
                if (images.length > 1) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedImageIndex == index;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedImageIndex = index);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 60,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceWhite,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? AppColors.gold : AppColors.borderLight,
                                width: isSelected ? 2.0 : 1.0,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: Image.network(
                                images[index],
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, _) => const Icon(Icons.image, size: 20),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),

                // ── 3. Category & Stock Badges ──────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.navyDark.withAlpha(12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        p.category.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: p.inStock ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            p.inStock ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                            size: 13,
                            color: p.inStock ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            p.inStock ? 'In Stock (${p.stock} available)' : 'Out of Stock',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: p.inStock ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // ── 4. Product Name ─────────────────────────────────────────
                Text(
                  p.name,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark,
                    height: 1.25,
                  ),
                ),

                if (p.sku != null && p.sku!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'SKU: ${p.sku}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.md),

                // ── 5. Price Display ────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      p.formattedPrice,
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyDark,
                      ),
                    ),
                    if (p.formattedOriginalPrice != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        p.formattedOriginalPrice!,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: AppColors.textTertiary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                    if (p.hasDiscount) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${p.discountPercent}% OFF',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const Divider(height: 32, color: AppColors.borderLight),

                // ── 6. Quantity Selector ────────────────────────────────────
                Row(
                  children: [
                    Text(
                      'Quantity',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyDark,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_rounded, size: 18),
                            onPressed: p.inStock ? _decrementQuantity : null,
                            color: AppColors.navyDark,
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 28),
                            alignment: Alignment.center,
                            child: Text(
                              '$_quantity',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navyDark,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_rounded, size: 18),
                            onPressed: p.inStock ? _incrementQuantity : null,
                            color: AppColors.navyDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: 32, color: AppColors.borderLight),

                // ── 7. Description ──────────────────────────────────────────
                Text(
                  'About this item',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _cleanHtml(p.description).isNotEmpty
                      ? _cleanHtml(p.description)
                      : 'Authentic high-quality educational merchandise from Zabira Academy.',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar({required String title}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderLight.withAlpha(150),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.navyDark),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.store);
              }
            },
            tooltip: 'Back',
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final p = _product!;
    final effectivePrice = (p.salePrice != null && p.salePrice! > 0 ? p.salePrice! : p.price) * _quantity;
    final formattedTotal = effectivePrice == effectivePrice.roundToDouble()
        ? '₹${effectivePrice.toInt()}'
        : '₹${effectivePrice.toStringAsFixed(2)}';

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Price',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
              Text(
                formattedTotal,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyDark,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),

          // Add to Cart Button
          IconButton(
            tooltip: 'Add to Cart',
            icon: const Icon(Icons.add_shopping_cart_rounded, color: AppColors.navyDark),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(12),
            ),
            onPressed: p.inStock
                ? () async {
                    HapticFeedback.selectionClick();
                    final auth = context.read<AuthController>();
                    final cart = context.read<CartController>();
                    final messenger = ScaffoldMessenger.of(context);

                    final success = await cart.addItem(
                      itemData: {
                        'store_product_id': p.id,
                        'product_id': p.id,
                        'product_type': 'store',
                        'quantity': _quantity.toString(),
                      },
                      token: auth.currentToken,
                    );

                    if (!mounted) return;

                    if (success) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Added $_quantity × ${p.name} to Cart'),
                          backgroundColor: AppColors.navyDark,
                          duration: const Duration(seconds: 3),
                          action: SnackBarAction(
                            label: 'View Cart',
                            textColor: AppColors.gold,
                            onPressed: () {
                              if (mounted) context.push(AppRoutes.cart);
                            },
                          ),
                        ),
                      );
                    } else {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(cart.errorMessage ?? 'Could not add to cart.'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                : null,
          ),
          const SizedBox(width: 8),

          // Buy Now Button
          Expanded(
            child: ElevatedButton(
              onPressed: p.inStock
                  ? () async {
                      HapticFeedback.mediumImpact();
                      final auth = context.read<AuthController>();

                      if (!auth.isAuthenticated) {
                        auth.setPendingReturnTo('/store/${p.id}');
                        showAuthBottomSheet(context);
                        return;
                      }

                      final totalAmt = p.effectivePrice * _quantity;
                      context.push(
                        AppRoutes.checkout,
                        extra: {
                          'orderId': p.id,
                          'productType': 'store',
                          'title': '$_quantity × ${p.name}',
                          'amount': totalAmt,
                          'category': p.categoryName ?? 'Store Item',
                          'quantity': _quantity,
                        },
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: const Color(0xFF081D3A),
                disabledBackgroundColor: AppColors.borderLight,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                p.inStock ? 'Buy Now' : 'Out of Stock',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
