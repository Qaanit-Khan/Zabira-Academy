import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/course_category_api_model.dart';

/// Filter selection state for Courses
class CourseFilterState {
  CourseFilterState({
    this.categoryId,
    this.level,
    this.language,
    this.sort = 'featured',
  });

  int? categoryId;
  String? level;
  String? language;
  String sort;

  bool get hasActiveFilters => categoryId != null || level != null || language != null || sort != 'featured';

  void reset() {
    categoryId = null;
    level = null;
    language = null;
    sort = 'featured';
  }

  CourseFilterState copy() {
    return CourseFilterState(
      categoryId: categoryId,
      level: level,
      language: language,
      sort: sort,
    );
  }
}

/// Mobile Bottom Sheet for filtering and sorting courses.
class CourseFilterSheet extends StatefulWidget {
  const CourseFilterSheet({
    super.key,
    required this.currentState,
    required this.categories,
    required this.onApply,
  });

  final CourseFilterState currentState;
  final List<CourseCategoryApiModel> categories;
  final ValueChanged<CourseFilterState> onApply;

  @override
  State<CourseFilterSheet> createState() => _CourseFilterSheetState();
}

class _CourseFilterSheetState extends State<CourseFilterSheet> {
  late CourseFilterState _filter;

  final _levels = ['All Levels', 'Beginner', 'Intermediate', 'Advanced'];
  final _languages = ['All Languages', 'Urdu', 'English', 'Arabic'];
  final _sortOptions = [
    {'key': 'featured', 'label': 'Featured'},
    {'key': 'newest', 'label': 'Newest'},
    {'key': 'price_asc', 'label': 'Price: Low to High'},
    {'key': 'price_desc', 'label': 'Price: High to Low'},
  ];

  @override
  void initState() {
    super.initState();
    _filter = widget.currentState.copy();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Top Handle & Header ─────────────────────────────────────────
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Text(
                    'Filter & Sort Courses',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => _filter.reset());
                    },
                    child: Text(
                      'Reset',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderLight),

            // ── Scrollable Filter Options ───────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Sort By
                    _buildSectionTitle('Sort By'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _sortOptions.map((opt) {
                        final isSelected = _filter.sort == opt['key'];
                        return _buildChip(
                          label: opt['label']!,
                          isSelected: isSelected,
                          onTap: () => setState(() => _filter.sort = opt['key']!),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // 2. Categories
                    if (widget.categories.isNotEmpty) ...[
                      _buildSectionTitle('Category'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildChip(
                            label: 'All Categories',
                            isSelected: _filter.categoryId == null,
                            onTap: () => setState(() => _filter.categoryId = null),
                          ),
                          ...widget.categories.map((c) {
                            final isSelected = _filter.categoryId == c.id;
                            return _buildChip(
                              label: c.name,
                              isSelected: isSelected,
                              onTap: () => setState(() => _filter.categoryId = c.id),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // 3. Level
                    _buildSectionTitle('Level'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _levels.map((lvl) {
                        final isAll = lvl == 'All Levels';
                        final isSelected = isAll ? _filter.level == null : _filter.level == lvl;
                        return _buildChip(
                          label: lvl,
                          isSelected: isSelected,
                          onTap: () => setState(() => _filter.level = isAll ? null : lvl),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // 4. Language
                    _buildSectionTitle('Language'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _languages.map((lng) {
                        final isAll = lng == 'All Languages';
                        final isSelected = isAll ? _filter.language == null : _filter.language == lng;
                        return _buildChip(
                          label: lng,
                          isSelected: isSelected,
                          onTap: () => setState(() => _filter.language = isAll ? null : lng),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // ── Apply Button ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderLight)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    widget.onApply(_filter);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyDark,
                    foregroundColor: AppColors.gold,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Apply Filters',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.navyDark,
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navyDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.navyDark : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.gold : AppColors.navyDark,
          ),
        ),
      ),
    );
  }
}
