import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';

/// Gold CTA button — primary action (e.g. "Sign In →")
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width = double.infinity,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: AppSpacing.buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          disabledBackgroundColor: AppColors.gold.withAlpha(153),
          foregroundColor: AppColors.navyText,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.navyText),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        style: AppTypography.labelLarge.copyWith(color: AppColors.navyText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Icon(icon, size: 18, color: AppColors.navyText),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Navy CTA button — secondary action (e.g. "Login as Teacher")
class NavyButton extends StatelessWidget {
  const NavyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width = double.infinity,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: AppSpacing.buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navyDark,
          foregroundColor: AppColors.textWhite,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.textWhite),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: AppColors.textWhite),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        style: AppTypography.labelLarge.copyWith(color: AppColors.textWhite),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
