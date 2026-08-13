import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Promotional banner — displays the full promotional_banner.png asset as a
/// tappable card. The image itself contains all text and artwork; no overlay
/// text is rendered on top of it.
class PromotionalBanner extends StatelessWidget {
  const PromotionalBanner({super.key, this.onTap});

  final VoidCallback? onTap;

  static const String _imagePath =
      'assets/images/home/promotional/promotional_banner.png';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GestureDetector(
        onTap: onTap ?? () {
          // TODO: connect navigation when destination is ready
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.navyDark.withAlpha(60),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              _imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stack) => Container(
                height: 138,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF07152B), Color(0xFF0D213F)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_stories_rounded,
                    color: AppColors.gold,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
