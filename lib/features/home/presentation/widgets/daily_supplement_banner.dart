import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Daily Supplement promotional banner card.
///
/// Displays the [daily_supplement_banner.png] asset in place of the former
/// scholarship section.
///
/// Features:
/// - Rounded corners (16px) with subtle shadow matching the home theme
/// - Full width with standard horizontal page margins
/// - Fully clickable/tappable for future navigation
/// - Natural aspect ratio rendering without distortion
class DailySupplementBanner extends StatefulWidget {
  const DailySupplementBanner({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  State<DailySupplementBanner> createState() => _DailySupplementBannerState();
}

class _DailySupplementBannerState extends State<DailySupplementBanner> {
  bool _pressed = false;

  static const String _imagePath =
      'assets/images/home/daily_supplement/daily_supplement_banner.png';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Semantics(
        button: true,
        label: 'Today at Zabira — One beautiful lesson can change the way we see the world',
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap?.call();
            // Ready for future navigation
          },
          onTapCancel: () => setState(() => _pressed = false),
          behavior: HitTestBehavior.opaque,
          child: AnimatedScale(
            scale: _pressed ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navyDark.withAlpha(50),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  _imagePath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, _) => Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFF081D3A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.auto_stories_rounded,
                        color: AppColors.gold,
                        size: 36,
                      ),
                    ),
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
