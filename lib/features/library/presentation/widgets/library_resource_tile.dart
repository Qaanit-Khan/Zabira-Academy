import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/zabira_network_image.dart';
import '../../data/models/library_item_model.dart';

class LibraryResourceTile extends StatelessWidget {
  const LibraryResourceTile({
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
        width: 125,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cover
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 95,
                  width: double.infinity,
                  child: ZabiraNetworkImage(
                    imageUrl: item.resolvedCoverImage,
                    fit: BoxFit.contain,
                    fallbackIcon: Icons.menu_book_rounded,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Title
              Text(
                item.title,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Price & Cart
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.formattedPrice,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyDark,
                    ),
                  ),
                  GestureDetector(
                    onTap: onAddToCart ?? onTap,
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      size: 16,
                      color: Color(0xFF081D3A),
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
