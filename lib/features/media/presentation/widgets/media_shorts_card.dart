import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/zabira_network_image.dart';
import '../../data/models/media_item_model.dart';

class MediaShortsCard extends StatelessWidget {
  const MediaShortsCard({
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
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 9:16 aspect ratio vertical card ───────────────────────────
            AspectRatio(
              aspectRatio: 9 / 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ZabiraNetworkImage(
                      imageUrl: item.resolvedThumbnail,
                      fit: BoxFit.cover,
                    ),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withAlpha(40),
                            Colors.black.withAlpha(140),
                          ],
                        ),
                      ),
                    ),
                    // Center play icon
                    Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withAlpha(140),
                          border: Border.all(color: Colors.white.withAlpha(160), width: 1.2),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    // Duration badge bottom right
                    if (item.duration != null && item.duration!.isNotEmpty)
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(180),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.duration!,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Title & views
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.more_vert, size: 14, color: Color(0xFF94A3B8)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
