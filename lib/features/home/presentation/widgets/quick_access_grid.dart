import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/quick_access_model.dart';
import 'quick_access_item.dart';

/// 2-row × 4-column quick access feature grid.
///
/// Ensures 4 mathematically equal columns across all device screen widths,
/// equal row spacing, uniform 54×54px icon container alignment, and clean text baselines.
class QuickAccessGrid extends StatelessWidget {
  const QuickAccessGrid({super.key, required this.items});

  final List<QuickAccessModel> items;

  @override
  Widget build(BuildContext context) {
    // Split 8 items into 2 rows of 4
    final row1 = items.take(4).toList();
    final row2 = items.skip(4).take(4).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDark.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 14.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRow(row1),
            const SizedBox(height: 14),
            _buildRow(row2),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<QuickAccessModel> rowItems) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rowItems.map((item) {
        return Expanded(
          child: QuickAccessItem(item: item),
        );
      }).toList(),
    );
  }
}
