import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/zabira_network_image.dart';
import '../../data/models/library_item_model.dart';

class LibraryBookCard extends StatelessWidget {
  const LibraryBookCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onAddToCart,
    this.onBuyNow,
    this.onFavoriteToggle,
    this.isFavorite = false,
  });

  final LibraryItemModel item;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final VoidCallback? onBuyNow;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;

  static const Color brandGold = Color(0xFFC9A84C);
  static const Color brandNavy = Color(0xFF112039);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: brandNavy.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── 1. Book Cover Image with Badges ─────────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: AspectRatio(
                      aspectRatio: 3 / 3.8,
                      child: item.resolvedCoverImage != null && item.resolvedCoverImage!.isNotEmpty
                          ? ZabiraNetworkImage(
                              imageUrl: item.resolvedCoverImage,
                              fit: BoxFit.cover,
                              fallbackIcon: Icons.menu_book_rounded,
                            )
                          : Container(
                              color: const Color(0xFFF1F5F9),
                              child: const Center(
                                child: Icon(Icons.menu_book_rounded, color: brandNavy, size: 42),
                              ),
                            ),
                    ),
                  ),

                  // Top Gradient Overlay for Badge Contrast
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Top Left Badges: PREMIUM (if applicable)
                  if (item.premium)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: brandNavy,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: brandGold, width: 0.8),
                        ),
                        child: Text(
                          'PREMIUM',
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: brandGold,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),

                  // Top Right Badge: Language (e.g. URDU, ENGLISH, ARABIC)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        item.displayLanguage,
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: brandNavy,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),

                  // Bottom Left: Floating Heart (Wishlist in Gold)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onFavoriteToggle?.call();
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                        child: Center(
                          child: Icon(
                            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 16,
                            color: isFavorite ? brandGold : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom Right: Rating Badge (★ 4.7)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 12, color: brandGold),
                          const SizedBox(width: 3),
                          Text(
                            item.rating.toStringAsFixed(1),
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ── 2. Content Section ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title & Price Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: brandNavy,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.formattedPrice,
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: brandNavy,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Short Description Snippet
                    Text(
                      item.cleanDescription.isNotEmpty
                          ? item.cleanDescription
                          : 'Carefully curated Islamic literature for young minds and families.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: const Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── 3. Bottom Actions: Cart Icon + BUY NOW Button ─────────
                    Row(
                      children: [
                        // Cart Outlined Button
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onAddToCart();
                          },
                          child: Container(
                            width: 36,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.shopping_cart_outlined,
                                size: 15,
                                color: brandNavy,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        // BUY NOW Button (Dark Navy #112039)
                        Expanded(
                          child: SizedBox(
                            height: 34,
                            child: ElevatedButton(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                if (onBuyNow != null) {
                                  onBuyNow!();
                                } else {
                                  onTap();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brandNavy,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.bolt_rounded, size: 14, color: brandGold),
                                  const SizedBox(width: 2),
                                  Text(
                                    'BUY NOW',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
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
    );
  }
}
