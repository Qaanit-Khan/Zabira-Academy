import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/zabira_network_image.dart';
import '../../data/models/library_item_model.dart';

class LibraryBookCard extends StatelessWidget {
  const LibraryBookCard({
    super.key,
    required this.item,
    this.onTap,
    this.onAddToCart,
  });

  final LibraryItemModel item;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image
              Expanded(
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ZabiraNetworkImage(
                      imageUrl: item.resolvedCoverImage,
                      fit: BoxFit.contain,
                      fallbackIcon: Icons.menu_book_rounded,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                item.title,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDark,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),

              // Short description
              Text(
                item.cleanDescription.isNotEmpty ? item.cleanDescription : 'Authentic Islamic resource.',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: const Color(0xFF64748B),
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Price & Cart Button row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.formattedPrice,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyDark,
                    ),
                  ),
                  GestureDetector(
                    onTap: onAddToCart ?? onTap,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF081D3A),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.shopping_cart_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
