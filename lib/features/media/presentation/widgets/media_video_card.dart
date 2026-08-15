import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/zabira_network_image.dart';
import '../../data/models/media_item_model.dart';

class MediaVideoCard extends StatelessWidget {
  const MediaVideoCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final MediaItemModel item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 16:9 Thumbnail with duration & play button ────────────────
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ZabiraNetworkImage(
                    imageUrl: item.resolvedThumbnail,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    fit: BoxFit.cover,
                  ),
                  // Center play button
                  Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withAlpha(120),
                        border: Border.all(color: Colors.white.withAlpha(180), width: 1.5),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  // Duration badge
                  if (item.duration != null && item.duration!.isNotEmpty)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(190),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.duration!,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Info section ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyDark,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.more_vert, size: 16, color: Color(0xFF94A3B8)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (item.categoryName != null && item.categoryName!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.categoryName!,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  Text(
                    item.language.isNotEmpty ? '${item.language} • Zabira Media' : 'Zabira Academy Media',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
