import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../store/data/models/store_product_model.dart';
import '../../../store/data/repositories/store_repository.dart';

/// "From Zabira Store" horizontal product section on Home Screen.
///
/// Fetches live products from official Store API (`GET /store/public_list.php`).
/// Displays 3 real items with navigation to Product Details and Store Page.
class FromZabiraStoreSection extends StatefulWidget {
  const FromZabiraStoreSection({
    super.key,
    this.products,
  });

  final List<StoreProductModel>? products;

  @override
  State<FromZabiraStoreSection> createState() => _FromZabiraStoreSectionState();
}

class _FromZabiraStoreSectionState extends State<FromZabiraStoreSection> {
  final StoreRepository _repository = StoreRepository();

  List<StoreProductModel> _storeProducts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.products != null && widget.products!.isNotEmpty) {
      _storeProducts = widget.products!;
      _isLoading = false;
    } else {
      _fetchStoreProducts();
    }
  }

  Future<void> _fetchStoreProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _repository.getProducts(limit: 3);
      if (mounted) {
        setState(() {
          _storeProducts = items.take(3).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load products';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. Section Header ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Text(
                'From Zabira Store',
                style: GoogleFonts.poppins(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDark,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push(AppRoutes.store);
                },
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Store',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // ── 2. Horizontal Product Content ──────────────────────────────────
        SizedBox(
          height: 94,
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 216,
            height: 94,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.gold,
                ),
              ),
            ),
          );
        },
      );
    }

    if (_errorMessage != null || _storeProducts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Container(
          width: double.infinity,
          height: 94,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              const Icon(Icons.storefront_outlined, color: AppColors.textSecondary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Explore stationery, books and perfumes in Zabira Store.',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: _fetchStoreProducts,
                child: Text(
                  'Retry',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: _storeProducts.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(
            right: index < _storeProducts.length - 1 ? 10.0 : 0,
          ),
          child: _StoreProductCard(
            product: _storeProducts[index],
            onTap: () {
              context.push('/store/${_storeProducts[index].id}');
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Clean White Store Product Card.
class _StoreProductCard extends StatefulWidget {
  const _StoreProductCard({
    required this.product,
    required this.onTap,
  });

  final StoreProductModel product;
  final VoidCallback onTap;

  @override
  State<_StoreProductCard> createState() => _StoreProductCardState();
}

class _StoreProductCardState extends State<_StoreProductCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final imageUrl = p.fullThumbnailUrl;

    return Semantics(
      button: true,
      label: 'Buy ${p.name}',
      child: GestureDetector(
        onTapDown: (_) {
          HapticFeedback.lightImpact();
          setState(() => _pressed = true);
        },
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: Container(
            width: 216,
            height: 94,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _pressed
                    ? AppColors.gold.withAlpha(120)
                    : AppColors.borderLight.withAlpha(220),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyDark.withAlpha(8),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Left: Product Image placed directly inside white card ──
                Container(
                  width: 66,
                  height: 78,
                  alignment: Alignment.center,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppColors.gold,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, _) => _fallbackImage(p),
                        )
                      : _fallbackImage(p),
                ),

                const SizedBox(width: 8),

                // ── Right: Product Details & Cart Button ───────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title & Category
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: GoogleFonts.poppins(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyDark,
                              height: 1.15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            p.category,
                            style: GoogleFonts.outfit(
                              fontSize: 10.0,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      // Price + Circular Gold Cart Button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            p.formattedPrice,
                            style: GoogleFonts.poppins(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyDark,
                            ),
                          ),
                          const Spacer(),
                          // Compact Circular Gold Cart Button
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.shopping_cart_outlined,
                                color: Color(0xFF081D3A),
                                size: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallbackImage(StoreProductModel product) {
    if (product.localAssetFallback != null) {
      return Image.asset(
        product.localAssetFallback!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, _) => const Icon(
          Icons.auto_stories_rounded,
          color: AppColors.navyDark,
          size: 28,
        ),
      );
    }
    return const Icon(
      Icons.auto_stories_rounded,
      color: AppColors.navyDark,
      size: 28,
    );
  }
}
