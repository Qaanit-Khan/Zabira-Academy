import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/store_product_model.dart';

/// "From Zabira Store" horizontal product section.
///
/// Shows a header row (title + "View Store >" link) above a horizontal
/// scrollable list of [_StoreProductCard] widgets.
class FromZabiraStoreSection extends StatelessWidget {
  const FromZabiraStoreSection({super.key, required this.products});

  final List<StoreProductModel> products;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Text(
                'From Zabira Store',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDark,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  // TODO: Navigate to Zabira Store
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

        // ── Product cards ──────────────────────────────────────────────────
        SizedBox(
          height: 148,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index < products.length - 1 ? AppSpacing.sm : 0,
                ),
                child: _StoreProductCard(product: products[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Individual store product card.
///
/// Layout: [Product Image] | [Name / Category / Price] | [Cart Button]
class _StoreProductCard extends StatefulWidget {
  const _StoreProductCard({required this.product});
  final StoreProductModel product;

  @override
  State<_StoreProductCard> createState() => _StoreProductCardState();
}

class _StoreProductCardState extends State<_StoreProductCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Buy ${widget.product.name}',
      child: GestureDetector(
        onTapDown: (_) {
          HapticFeedback.lightImpact();
          setState(() => _pressed = true);
        },
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: 220,
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _pressed
                    ? AppColors.gold.withAlpha(100)
                    : AppColors.borderLight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyDark.withAlpha(10),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Product image / art ─────────────────────────────────
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(13),
                  ),
                  child: _ProductArt(product: widget.product),
                ),

                // ── Product details ─────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.product.name,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navyDark,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.product.category,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              widget.product.price,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navyDark,
                              ),
                            ),
                            const Spacer(),
                            // Cart button
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: AppColors.gold,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.shopping_cart_outlined,
                                color: AppColors.navyDark,
                                size: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Left-side product image box — shows real asset if available,
/// otherwise falls back to a premium code-designed placeholder.
class _ProductArt extends StatelessWidget {
  const _ProductArt({required this.product});
  final StoreProductModel product;

  @override
  Widget build(BuildContext context) {
    if (product.imagePath != null) {
      return SizedBox(
        width: 80,
        height: 148,
        child: Image.asset(
          product.imagePath!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, _) => _PlaceholderArt(product: product),
        ),
      );
    }
    return _PlaceholderArt(product: product);
  }
}

class _PlaceholderArt extends StatelessWidget {
  const _PlaceholderArt({required this.product});
  final StoreProductModel product;

  // Each product type gets a distinct accent colour
  Color get _accentColor {
    switch (product.id) {
      case 'janamaz':
        return const Color(0xFF2E6B4F); // Islamic green
      case 'notebook':
        return const Color(0xFF0A1E3C); // deep navy
      default:
        return const Color(0xFF081D3A);
    }
  }

  IconData get _icon {
    switch (product.id) {
      case 'janamaz':
        return Icons.hotel_rounded;
      case 'notebook':
        return Icons.menu_book_rounded;
      default:
        return Icons.auto_stories_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 148,
      color: _accentColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_icon, color: AppColors.gold, size: 28),
          const SizedBox(height: 6),
          Container(
            width: 32,
            height: 2,
            color: AppColors.gold.withAlpha(140),
          ),
        ],
      ),
    );
  }
}
