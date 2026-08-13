import 'package:flutter/material.dart';
import 'package:zabira_academy/core/theme/app_colors.dart';
import 'package:zabira_academy/core/theme/app_typography.dart';
import 'package:zabira_academy/core/theme/app_spacing.dart';

/// Sign In / Create Account tab switcher
/// Matches the rounded card segmented control from the design reference
class AuthTabSwitcher extends StatelessWidget {
  const AuthTabSwitcher({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.tabs,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.surfaceWhite : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.navyDark.withAlpha(18),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
