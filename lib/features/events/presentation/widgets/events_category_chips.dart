import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class EventsCategoryChips extends StatelessWidget {
  const EventsCategoryChips({
    super.key,
    required this.selectedCategory,
    required this.onSelectCategory,
  });

  final String? selectedCategory;
  final ValueChanged<String?> onSelectCategory;

  @override
  Widget build(BuildContext context) {
    // 5 category cards matching events_mobile.png:
    // Competitions, Workshops, Seminars, Webinars, Past Events
    final categories = [
      _EventCategoryUi(category: null, label: 'Competitions', icon: Icons.emoji_events_rounded, bg: const Color(0xFFE0F2FE), fg: const Color(0xFF0284C7)),
      _EventCategoryUi(category: 'Workshop', label: 'Workshops', icon: Icons.calendar_month_rounded, bg: const Color(0xFFDCFCE7), fg: const Color(0xFF16A34A)),
      _EventCategoryUi(category: 'Seminar', label: 'Seminars', icon: Icons.groups_rounded, bg: const Color(0xFFFFE4E6), fg: const Color(0xFFE11D48)),
      _EventCategoryUi(category: 'Webinar', label: 'Webinars', icon: Icons.location_on_rounded, bg: const Color(0xFFF3E8FF), fg: const Color(0xFF9333EA)),
      _EventCategoryUi(category: 'Past', label: 'Past Events', icon: Icons.photo_library_rounded, bg: const Color(0xFFFEF3C7), fg: const Color(0xFFD97706)),
    ];

    return Container(
      height: 94,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final item = categories[index];
          final isSelected = selectedCategory == item.category;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onSelectCategory(item.category),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: item.bg,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(color: AppColors.navyDark, width: 2)
                          : Border.all(color: Colors.transparent, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(8),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(item.icon, color: item.fg, size: 24),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    style: GoogleFonts.outfit(
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.navyDark : const Color(0xFF475569),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EventCategoryUi {
  const _EventCategoryUi({
    required this.category,
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
  });

  final String? category;
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
}
