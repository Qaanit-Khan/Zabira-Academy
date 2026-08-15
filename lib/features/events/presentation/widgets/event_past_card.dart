import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/zabira_network_image.dart';
import '../../data/models/event_item_model.dart';

class EventPastCard extends StatelessWidget {
  const EventPastCard({
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
        width: 135,
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
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 80,
                  width: double.infinity,
                  child: ZabiraNetworkImage(
                    imageUrl: event.resolvedFeaturedImage,
                    fit: BoxFit.cover,
                    fallbackIcon: Icons.photo_library_rounded,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                event.title,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDark,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${event.formattedDate} • ${event.formattedLocation}',
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  color: const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
