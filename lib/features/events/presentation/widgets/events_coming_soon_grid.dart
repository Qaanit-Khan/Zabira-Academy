import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class EventsComingSoonGrid extends StatelessWidget {
  const EventsComingSoonGrid({super.key});

  @override
  Widget build(BuildContext context) {
    // 4 feature highlights matching events_mobile.png:
    // 1. Exciting Competitions with Amazing Prizes
    // 2. Interactive Workshops & Seminars
    // 3. Certificates for All Participants
    // 4. Rewards & Recognition for Top Performers
    final items = [
      _ComingSoonItem(icon: Icons.campaign_rounded, title: 'Exciting Competitions with Amazing Prizes', bg: const Color(0xFFFEF3C7), iconColor: const Color(0xFFD97706)),
      _ComingSoonItem(icon: Icons.groups_rounded, title: 'Interactive Workshops & Seminars', bg: const Color(0xFFFFEDD5), iconColor: const Color(0xFFEA580C)),
      _ComingSoonItem(icon: Icons.workspace_premium_rounded, title: 'Certificates for All Participants', bg: const Color(0xFFE0F2FE), iconColor: const Color(0xFF0284C7)),
      _ComingSoonItem(icon: Icons.card_giftcard_rounded, title: 'Rewards & Recognition for Top Performers', bg: const Color(0xFFFEF3C7), iconColor: const Color(0xFFD97706)),
    ];

    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            width: 155,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: item.iconColor.withAlpha(40), width: 1),
            ),
            child: Row(
              children: [
                Icon(item.icon, color: item.iconColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.title,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navyDark,
                      height: 1.2,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ComingSoonItem {
  const _ComingSoonItem({
    required this.icon,
    required this.title,
    required this.bg,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final Color bg;
  final Color iconColor;
}
