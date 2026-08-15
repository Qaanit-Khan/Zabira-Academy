import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/media_category_model.dart';

class MediaCategoryChips extends StatelessWidget {
  const MediaCategoryChips({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelectCategory,
  });

  final List<MediaCategoryModel> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onSelectCategory;

  @override
  Widget build(BuildContext context) {
    // Standard visual presets matching the 5 pastel category cards in media_mobile.png
    final staticCategories = [
      _CategoryUiItem(id: null, label: 'All Videos', icon: Icons.smart_display_rounded, bg: const Color(0xFFE0F2FE), fg: const Color(0xFF0284C7)),
      _CategoryUiItem(id: 1, label: 'Lectures', icon: Icons.school_rounded, bg: const Color(0xFFDCFCE7), fg: const Color(0xFF16A34A)),
      _CategoryUiItem(id: 2, label: 'Shorts', icon: Icons.bolt_rounded, bg: const Color(0xFFFFE4E6), fg: const Color(0xFFE11D48)),
      _CategoryUiItem(id: 3, label: 'Quran', icon: Icons.auto_stories_rounded, bg: const Color(0xFFF3E8FF), fg: const Color(0xFF9333EA)),
      _CategoryUiItem(id: 4, label: 'Islamic Learning', icon: Icons.account_balance_rounded, bg: const Color(0xFFFEF3C7), fg: const Color(0xFFD97706)),
    ];

    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: categories.isNotEmpty ? categories.length + 1 : staticCategories.length,
        itemBuilder: (context, index) {
          int? catId;
          String label;
          IconData icon;
          Color bg;
          Color fg;

          if (categories.isNotEmpty) {
            if (index == 0) {
              catId = null;
              label = 'All Videos';
              icon = Icons.smart_display_rounded;
              bg = const Color(0xFFE0F2FE);
              fg = const Color(0xFF0284C7);
            } else {
              final cat = categories[index - 1];
              catId = cat.id;
              label = cat.name;
              final preset = staticCategories[index % staticCategories.length];
              icon = preset.icon;
              bg = preset.bg;
              fg = preset.fg;
            }
          } else {
            final item = staticCategories[index];
            catId = item.id;
            label = item.label;
            icon = item.icon;
            bg = item.bg;
            fg = item.fg;
          }

          final isSelected = selectedCategoryId == catId;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onSelectCategory(catId),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: bg,
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
                      child: Icon(icon, color: fg, size: 24),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
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

class _CategoryUiItem {
  const _CategoryUiItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
  });

  final int? id;
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
}
