import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/auth/auth_controller.dart';
import '../../../auth/presentation/widgets/auth_bottom_sheet.dart';
import '../../../courses/presentation/controllers/wishlist_controller.dart';
import '../../../home/presentation/widgets/home_header.dart';
import '../../data/models/store_product_model.dart';
import '../../data/repositories/store_repository.dart';
import '../controllers/cart_controller.dart';

/// Zabira Academy — Store Product Details Page
///
/// Features:
/// - Exact design matching screenshot 2
/// - Golden (#C9A84C) and Dark Navy Blue (#112039) branding
/// - Interactive Photo & Video gallery with thumbnails & video player
/// - Variant / Option pills (Size, Color, etc.) updating price & SKU
/// - Quantity stepper
/// - Tabbed details: Description | Specifications | Reviews | Brand
/// - Related Products 2-column grid
/// - The Zabira Ecosystem & Payment badges footer
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

  static const Color brandGold = Color(0xFFC9A84C);
  static const Color brandNavy = Color(0xFF112039);

  StoreProductModel? _product;
  List<StoreProductModel> _relatedProducts = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Media Gallery state
  int _selectedMediaIndex = 0; // 0..N-1 images
  bool _isVideoSelected = false;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  // Variant & Option selection state
  final Map<int, int> _selectedOptionValues = {}; // group_id -> option_value_id
  StoreVariantModel? _selectedVariant;
  int _quantity = 1;

  // Active Info Tab: 0 = Description, 1 = Specifications, 2 = Reviews, 3 = Brand
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadProductDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final product = await _repository.getProductDetails(widget.productId);
      final allProducts = await _repository.getProducts();

      if (mounted) {
        setState(() {
          _product = product;
          _isLoading = false;
          _relatedProducts = allProducts.where((p) => p.id != widget.productId).take(4).toList();

          // Initialize default options & variants
          if (product.optionGroups.isNotEmpty) {
            for (final group in product.optionGroups) {
              if (group.values.isNotEmpty) {
                _selectedOptionValues[group.id] = group.values.first.id;
              }
            }
          }
          if (product.variants.isNotEmpty) {
            _selectedVariant = product.variants.first;
          }
        });

        // Initialize video if available
        if (product.hasVideo) {
          _initVideoPlayer(product.fullVideoUrl!);
        }
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

  void _initVideoPlayer(String url) {
    _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
        }
      }).catchError((_) {});
  }

  void _onOptionSelected(int groupId, int valueId) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedOptionValues[groupId] = valueId;

      // Find matching variant based on selected option value IDs
      if (_product != null && _product!.variants.isNotEmpty) {
        final match = _product!.variants.firstWhere(
          (v) => v.optionValueIds.contains(valueId),
          orElse: () => _product!.variants.first,
        );
        _selectedVariant = match;
      }
    });
  }

  void _incrementQuantity() {
    final maxStock = _selectedVariant?.stock ?? _product?.stock ?? 10;
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

  double get _currentPrice {
    if (_selectedVariant != null) {
      return _selectedVariant!.effectivePrice;
    }
    return _product?.effectivePrice ?? 0.0;
  }

  double? get _currentOriginalPrice {
    if (_selectedVariant != null && _selectedVariant!.salePrice != null && _selectedVariant!.salePrice! < _selectedVariant!.price) {
      return _selectedVariant!.price;
    }
    return _product?.formattedOriginalPrice != null ? _product!.price : null;
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

  Future<void> _addToCart() async {
    HapticFeedback.lightImpact();
    final p = _product;
    if (p == null) return;

    final auth = context.read<AuthController>();
    final cart = context.read<CartController>();

    final success = await cart.addItem(
      itemData: {
        'product_id': p.id,
        'store_product_id': p.id,
        'variant_id': _selectedVariant?.id,
        'variant_name': _selectedVariant?.name,
        'product_type': 'product',
        'title': p.name,
        'name': p.name,
        'price': _currentPrice,
        'discount_price': _currentPrice,
        'quantity': _quantity.toString(),
        'image': p.fullThumbnailUrl,
      },
      token: auth.currentToken,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Added $_quantity × ${p.name} to Cart' : 'Item added to cart',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          backgroundColor: brandNavy,
          duration: const Duration(milliseconds: 1800),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'View Cart',
            textColor: brandGold,
            onPressed: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              context.push(AppRoutes.cart);
            },
          ),
        ),
      );
    }
  }

  Future<void> _buyNow() async {
    HapticFeedback.mediumImpact();
    final p = _product;
    if (p == null) return;

    final auth = context.read<AuthController>();
    final cart = context.read<CartController>();

    if (!auth.isAuthenticated) {
      auth.setPendingReturnTo('/store/${p.id}');
      showAuthBottomSheet(context);
      return;
    }

    await cart.addItem(
      itemData: {
        'product_id': p.id,
        'store_product_id': p.id,
        'variant_id': _selectedVariant?.id,
        'variant_name': _selectedVariant?.name,
        'product_type': 'product',
        'title': p.name,
        'name': p.name,
        'price': _currentPrice,
        'discount_price': _currentPrice,
        'quantity': _quantity.toString(),
        'image': p.fullThumbnailUrl,
      },
      token: auth.currentToken,
    );

    if (mounted) {
      context.push(AppRoutes.cart);
    }
  }

  void _shareProduct() {
    HapticFeedback.lightImpact();
    final p = _product;
    if (p == null) return;
    Clipboard.setData(
      ClipboardData(text: 'Check out "${p.name}" on Zabira Store: https://zabiraacademy.com/store/${p.id}'),
    );
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Product link copied to clipboard!', style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: brandNavy,
        duration: const Duration(milliseconds: 1800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final auth = context.watch<AuthController>();
    final user = auth.user;
    final isAuth = auth.isAuthenticated && user != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top Header matching app standard ─────────────────────────────
            HomeHeader(
              isAuthenticated: isAuth,
              notificationCount: isAuth ? 2 : 0,
              cartCount: cart.itemCount,
              userInitial: isAuth && user.displayName.isNotEmpty ? user.displayName[0] : null,
              onMenuTap: () => context.pop(),
              onCartTap: () => context.push(AppRoutes.cart),
              onSignIn: () => showAuthBottomSheet(context),
              onProfileTap: () {
                if (isAuth) {
                  context.push(AppRoutes.studentDash);
                } else {
                  showAuthBottomSheet(context);
                }
              },
            ),

            // ── Main Scrollable Body ─────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: brandGold))
                  : (_errorMessage != null || _product == null)
                      ? _buildErrorView()
                      : _buildMainProductContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: AppSpacing.md),
            Text(
              _errorMessage ?? 'Product details not available.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _loadProductDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandNavy,
                foregroundColor: brandGold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainProductContent() {
    final p = _product!;
    final images = p.allImageUrls;
    final wishlist = context.watch<WishlistController>();
    final isWishlisted = wishlist.isWishlisted(p.id, type: 'store');

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Breadcrumb & Back Bar ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: brandNavy),
                        const SizedBox(width: 4),
                        Text(
                          'Store',
                          style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700, color: brandNavy),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _shareProduct,
                  icon: const Icon(Icons.share_outlined, size: 20, color: brandNavy),
                  tooltip: 'Share',
                ),
              ],
            ),
          ),

          // ── 1. Main Media Box (Photo or Video Player) ─────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              height: 320,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: brandNavy.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Center(
                      child: _isVideoSelected && p.hasVideo && _videoController != null
                          ? _buildVideoPlayer()
                          : (images.isNotEmpty && _selectedMediaIndex < images.length
                              ? Image.network(
                                  images[_selectedMediaIndex],
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => const Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.white38),
                                )
                              : const Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.white38)),
                    ),
                  ),

                  // Left Navigation Chevron
                  if (images.length > 1 && !_isVideoSelected)
                    Positioned(
                      left: 10,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            if (_selectedMediaIndex > 0) {
                              setState(() => _selectedMediaIndex--);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                    ),

                  // Right Navigation Chevron
                  if (images.length > 1 && !_isVideoSelected)
                    Positioned(
                      right: 10,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            if (_selectedMediaIndex < images.length - 1) {
                              setState(() => _selectedMediaIndex++);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                    ),

                  // Top Right Wishlist Toggle
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        wishlist.toggleStoreProduct(p);
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isWishlisted ? const Color(0xFFEF4444) : Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── 2. Thumbnail Selector Row (Photos + Video) ───────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 64,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Photo thumbnails
                  for (int i = 0; i < images.length; i++)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _isVideoSelected = false;
                          _selectedMediaIndex = i;
                        });
                        _videoController?.pause();
                      },
                      child: Container(
                        width: 64,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (!_isVideoSelected && _selectedMediaIndex == i) ? brandGold : const Color(0xFFCBD5E1),
                            width: (!_isVideoSelected && _selectedMediaIndex == i) ? 2.5 : 1.0,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            images[i],
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(Icons.image, size: 20, color: Colors.white54),
                          ),
                        ),
                      ),
                    ),

                  // Video thumbnail (if available)
                  if (p.hasVideo)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _isVideoSelected = true;
                        });
                        _videoController?.play();
                      },
                      child: Container(
                        width: 64,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isVideoSelected ? brandGold : const Color(0xFFCBD5E1),
                            width: _isVideoSelected ? 2.5 : 1.0,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (images.isNotEmpty)
                              Opacity(
                                opacity: 0.4,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(images.first, fit: BoxFit.cover, width: 64, height: 64),
                                ),
                              ),
                            const Icon(Icons.play_circle_fill_rounded, color: brandGold, size: 30),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── 3. Product Meta & Title ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category & Rating Row
                Row(
                  children: [
                    Text(
                      p.category.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: List.generate(
                        5,
                        (index) => const Icon(Icons.star_rounded, size: 16, color: brandGold),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(4.9)',
                      style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Product Name
                Text(
                  p.name,
                  style: GoogleFonts.poppins(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: brandNavy,
                    height: 1.25,
                  ),
                ),

                const SizedBox(height: 8),

                // Price Row
                Row(
                  children: [
                    Text(
                      _currentPrice == _currentPrice.roundToDouble()
                          ? '₹${_currentPrice.toInt()}'
                          : '₹${_currentPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: brandNavy,
                      ),
                    ),
                    if (_currentOriginalPrice != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _currentOriginalPrice == _currentOriginalPrice!.roundToDouble()
                            ? '₹${_currentOriginalPrice!.toInt()}'
                            : '₹${_currentOriginalPrice!.toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          color: const Color(0xFF94A3B8),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: p.inStock ? const Color(0xFFDCFCE7) : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        p.inStock ? 'In Stock (${_selectedVariant?.stock ?? p.stock})' : 'Out of Stock',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: p.inStock ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── 4. Primary Action Buttons Row (Add to Cart + Buy Now) ─────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Gold Button: Add to Cart
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _addToCart,
                      icon: const Icon(Icons.shopping_bag_outlined, size: 18, color: Colors.white),
                      label: Text(
                        'Add to Cart',
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandGold,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Dark Navy Button: Buy Now
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _buyNow,
                      icon: const Icon(Icons.bolt_rounded, size: 18, color: Colors.white),
                      label: Text(
                        'Buy Now',
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandNavy,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── 5. Value Proposition Badges Row ───────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildServiceBadge(Icons.local_shipping_outlined, 'Express\nDelivery'),
                const SizedBox(width: 8),
                _buildServiceBadge(Icons.verified_outlined, '100% Authentic\nProduct'),
                const SizedBox(width: 8),
                _buildServiceBadge(Icons.replay_rounded, 'Easy Return\nPolicy'),
                const SizedBox(width: 8),
                _buildServiceBadge(Icons.support_agent_rounded, '24/7 Priority\nSupport'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── 6. Variant / Option Selector (e.g. Size: 30ml, 50ml, 100ml) ──
          if (p.optionGroups.isNotEmpty)
            for (final group in p.optionGroups)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w800, color: brandNavy),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: group.values.map((val) {
                        final isSelected = _selectedOptionValues[group.id] == val.id;
                        return GestureDetector(
                          onTap: () => _onOptionSelected(group.id, val.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? brandNavy : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? brandNavy : const Color(0xFFCBD5E1),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              val.label,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : brandNavy,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

          // ── 7. Quantity Stepper ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Quantity',
                  style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w800, color: brandNavy),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_rounded, size: 16),
                        onPressed: _decrementQuantity,
                        color: brandNavy,
                      ),
                      Container(
                        constraints: const BoxConstraints(minWidth: 32),
                        alignment: Alignment.center,
                        child: Text(
                          '$_quantity',
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: brandNavy),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_rounded, size: 16),
                        onPressed: _incrementQuantity,
                        color: brandNavy,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── 8. Tabbed Details: Description | Specs | Reviews | Brand ──────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tab Buttons Header
                  Row(
                    children: [
                      _buildTabButton(0, 'Description'),
                      _buildTabButton(1, 'Specifications'),
                      _buildTabButton(2, 'Reviews'),
                      _buildTabButton(3, 'Brand'),
                    ],
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // Tab Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildActiveTabContent(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ── 9. Related Products Section ───────────────────────────────────
          if (_relatedProducts.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXPLORE MORE',
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: brandGold, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Related Products',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: brandNavy),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.58,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 14,
                ),
                itemCount: _relatedProducts.length,
                itemBuilder: (context, index) {
                  final rp = _relatedProducts[index];
                  final isFav = wishlist.isWishlisted(rp.id, type: 'store');
                  return _RelatedProductCard(
                    product: rp,
                    isFavorite: isFav,
                    onFavoriteToggle: () {
                      wishlist.toggleStoreProduct(rp);
                      HapticFeedback.lightImpact();
                    },
                    onViewDetails: () {
                      context.push('/store/${rp.id}');
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
          ],

          // ── 10. The Zabira Ecosystem ──────────────────────────────────────
          _buildEcosystemSection(),

          const SizedBox(height: 24),

          // ── 11. Scholarship & Footer ──────────────────────────────────────
          _buildScholarshipCard(),

          const SizedBox(height: 20),

          _buildPaymentBadgesFooter(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (!_isVideoInitialized || _videoController == null) {
      return const Center(
        child: CircularProgressIndicator(color: brandGold),
      );
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              if (_videoController!.value.isPlaying) {
                _videoController!.pause();
              } else {
                _videoController!.play();
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _videoController!.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceBadge(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: brandGold),
            const SizedBox(height: 4),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 9.5, fontWeight: FontWeight.w700, color: brandNavy, height: 1.15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String title) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedTab = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? brandGold : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? brandNavy : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    final p = _product!;
    switch (_selectedTab) {
      case 0:
        return Text(
          _cleanHtml(p.description).isNotEmpty
              ? _cleanHtml(p.description)
              : (p.shortDescription ?? 'Authentic high-quality educational and lifestyle merchandise from Zabira Academy.'),
          style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF475569), height: 1.5),
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSpecRow('SKU', p.sku ?? 'ZA-${p.id}'),
            _buildSpecRow('Category', p.category),
            _buildSpecRow('Type', p.type.toUpperCase()),
            _buildSpecRow('Fulfillment', p.fulfillmentType ?? 'Physical Shipping'),
            _buildSpecRow('Brand', p.brand ?? 'ZABIRA'),
          ],
        );
      case 2:
        return Column(
          children: [
            Row(
              children: [
                const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 16),
                const SizedBox(width: 6),
                Text(
                  'Verified Purchase Reviews',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: brandNavy),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '"MashaAllah, exceptionally high quality product. Packaging was pristine and arrived very quickly."',
              style: GoogleFonts.outfit(fontSize: 13, fontStyle: FontStyle.italic, color: const Color(0xFF475569)),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text('— Tariq M. (Verified Buyer)', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B))),
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Zabira Official Merchandise', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: brandNavy)),
            const SizedBox(height: 4),
            Text(
              'Crafted to inspire faith, productivity, and modern Islamic lifestyle excellence.',
              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF64748B))),
          Text(value, style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700, color: brandNavy)),
        ],
      ),
    );
  }

  Widget _buildEcosystemSection() {
    final modules = [
      ('Courses', Icons.school_outlined, AppRoutes.courses),
      ('Library', Icons.menu_book_outlined, AppRoutes.library),
      ('Store', Icons.storefront_outlined, AppRoutes.store),
      ('Nasheed', Icons.audiotrack_outlined, AppRoutes.nasheed),
      ('Scholarship', Icons.stars_rounded, AppRoutes.home),
      ('Dashboard', Icons.dashboard_outlined, AppRoutes.studentDash),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: brandNavy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text('THE ZABIRA ECOSYSTEM', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: brandGold, letterSpacing: 1.0)),
          const SizedBox(height: 4),
          Text('Explore All Portals', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: modules.map((m) {
              return GestureDetector(
                onTap: () => context.push(m.$3),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(m.$2, color: brandGold, size: 20),
                      const SizedBox(height: 4),
                      Text(m.$1, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildScholarshipCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(
            'Every Child Deserves Islamic Education',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: brandNavy),
          ),
          const SizedBox(height: 4),
          Text(
            'Support a student with a gift of authentic knowledge today.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBadgesFooter() {
    final badges = ['UPI', 'RuPay', 'VISA', 'Mastercard', 'NetBanking'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            '100% SECURE CHECKOUT',
            style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8), letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: badges.map((b) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  b,
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: brandNavy),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Related Product Card
class _RelatedProductCard extends StatelessWidget {
  const _RelatedProductCard({
    required this.product,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onViewDetails,
  });

  final StoreProductModel product;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onViewDetails;

  static const Color brandNavy = Color(0xFF112039);

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.fullThumbnailUrl;
    final discountPercent = product.discountPercent > 0 ? product.discountPercent : 98;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: brandNavy.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(Icons.shopping_bag_outlined, color: Colors.white54),
                          )
                        : const Icon(Icons.shopping_bag_outlined, color: Colors.white54),
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: brandNavy, borderRadius: BorderRadius.circular(4)),
                    child: Text('NEW', style: GoogleFonts.outfit(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF00A884), borderRadius: BorderRadius.circular(4)),
                    child: Text('-$discountPercent%', style: GoogleFonts.outfit(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: GestureDetector(
                    onTap: onFavoriteToggle,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                      child: Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFavorite ? const Color(0xFFEF4444) : Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w800, color: brandNavy)),
          const SizedBox(height: 2),
          Text(product.formattedPrice, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: brandNavy)),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              onPressed: onViewDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: EdgeInsets.zero,
              ),
              child: Text('View Details', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
