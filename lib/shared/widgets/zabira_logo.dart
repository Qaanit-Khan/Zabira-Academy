import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';

/// Zabira Academy Branded Logo Widget
///
/// Displays the Zabira Academy logo mark + wordmark text.
/// Used on splash screen, login panel header, and dashboard app bars.
/// Replace with Image.asset('assets/images/logo.png') when official logo is available.
class ZabiraLogo extends StatelessWidget {
  const ZabiraLogo({
    super.key,
    this.size = LogoSize.medium,
    this.showTagline = false,
    this.dark = false,
  });

  final LogoSize size;
  final bool showTagline;

  /// If true, uses navy on white (for light backgrounds)
  /// If false, uses white on dark (for navy backgrounds)
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final textColor = dark ? AppColors.navyDark : AppColors.textWhite;
    final goldColor = AppColors.gold;

    final double iconSize = switch (size) {
      LogoSize.small => 28,
      LogoSize.medium => 40,
      LogoSize.large => 56,
    };
    final double titleSize = switch (size) {
      LogoSize.small => 14,
      LogoSize.medium => 18,
      LogoSize.large => 24,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Logo Icon ─────────────────────────────────────────────────
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: goldColor.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.auto_stories_rounded, color: goldColor, size: iconSize * 0.65),
            ),
            const SizedBox(width: AppSpacing.sm),
            // ── Wordmark ──────────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ZABIRA',
                  style: AppTypography.labelLarge.copyWith(
                    color: textColor,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.5,
                  ),
                ),
                Text(
                  'ACADEMY',
                  style: AppTypography.labelSmall.copyWith(
                    color: goldColor,
                    fontSize: titleSize * 0.55,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3.0,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'LEARN · LIVE · INSPIRE',
            style: AppTypography.labelSmall.copyWith(
              color: textColor.withAlpha(153),
              fontSize: 9,
              letterSpacing: 1.8,
            ),
          ),
        ],
      ],
    );
  }
}

enum LogoSize { small, medium, large }

/// "LEARNING PORTAL" badge — gold bordered pill
class LearningPortalBadge extends StatelessWidget {
  const LearningPortalBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gold, width: 1.0),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        color: AppColors.gold.withAlpha(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_rounded, color: AppColors.gold, size: 13),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'LEARNING PORTAL',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.gold,
              fontSize: 9,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
