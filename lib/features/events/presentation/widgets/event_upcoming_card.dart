import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/zabira_network_image.dart';
import '../../data/models/event_item_model.dart';

class EventUpcomingCard extends StatelessWidget {
  const EventUpcomingCard({
    super.key,
    required this.event,
    this.onTap,
  });

  final EventItemModel event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Top Image Banner with Date Badge ─────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ZabiraNetworkImage(
                      imageUrl: event.resolvedFeaturedImage,
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.event_rounded,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withAlpha(20),
                            Colors.black.withAlpha(120),
                          ],
                        ),
                      ),
                    ),
                    // Date Badge (Navy rectangle)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF071B36),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.gold.withAlpha(140), width: 1),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              event.dateDay,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              event.dateMonth,
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gold,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Card Body ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Date | Time | Location row
                  Text(
                    '📅 ${event.formattedDate}  |  🕒 ${event.formattedTime}  |  📍 ${event.formattedLocation}',
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.shortDescription.isNotEmpty ? event.shortDescription : 'Join this exciting Zabira Academy event.',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: const Color(0xFF475569),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'View Details',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyDark,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: AppColors.navyDark,
                      ),
                    ],
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
