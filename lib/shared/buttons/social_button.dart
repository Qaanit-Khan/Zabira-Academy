import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';

/// Google Sign-In button matching the Zabira Academy design reference
/// White background, light border, Google "G" color logo
class SocialButton extends StatelessWidget {
  const SocialButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surfaceWhite,
          side: const BorderSide(color: AppColors.borderLight, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.gold),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google "G" logo using colored stack
                  _GoogleLogo(),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    label,
                    style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 20, height: 20, child: _GoogleLogoIcon());
  }
}

class _GoogleLogoIcon extends StatelessWidget {
  const _GoogleLogoIcon();

  @override
  Widget build(BuildContext context) {
    // Google G logo using a custom painter
    return CustomPaint(painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Draw colored segments approximating Google G logo
    final colors = [
      const Color(0xFF4285F4), // Blue - top
      const Color(0xFF34A853), // Green - bottom right
      const Color(0xFFFBBC04), // Yellow - bottom left
      const Color(0xFFEA4335), // Red - top left
    ];

    for (int i = 0; i < 4; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;
      final startAngle = (i * 90 - 45) * (3.14159 / 180.0);
      const sweepAngle = 90 * (3.14159 / 180.0);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
    }

    // White inner circle
    canvas.drawCircle(Offset(cx, cy), r * 0.6, Paint()..color = Colors.white);

    // Blue G bar
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - r * 0.15, r * 0.9, r * 0.3),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
