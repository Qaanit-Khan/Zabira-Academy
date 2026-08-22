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
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    // 1. Blue (#4285F4)
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final bluePath = Path()
      ..moveTo(23.745, 12.27)
      ..cubicTo(23.745, 11.48, 23.675, 10.73, 23.55, 10.0)
      ..lineTo(12.0, 10.0)
      ..lineTo(12.0, 14.51)
      ..lineTo(18.59, 14.51)
      ..cubicTo(18.3, 16.03, 17.43, 17.31, 16.14, 18.17)
      ..lineTo(16.14, 21.27)
      ..lineTo(20.06, 21.27)
      ..cubicTo(22.36, 19.16, 23.745, 16.02, 23.745, 12.27)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // 2. Green (#34A853)
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    final greenPath = Path()
      ..moveTo(12.0, 24.0)
      ..cubicTo(15.24, 24.0, 17.96, 22.92, 20.06, 20.99)
      ..lineTo(16.14, 17.89)
      ..cubicTo(15.05, 18.62, 13.65, 19.06, 12.0, 19.06)
      ..cubicTo(8.87, 19.06, 6.22, 16.94, 5.27, 14.09)
      ..lineTo(1.23, 14.09)
      ..lineTo(1.23, 17.22)
      ..cubicTo(3.26, 21.26, 7.37, 24.0, 12.0, 24.0)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // 3. Yellow (#FBBC05)
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final yellowPath = Path()
      ..moveTo(5.27, 14.29)
      ..cubicTo(5.02, 13.57, 4.89, 12.8, 4.89, 12.0)
      ..cubicTo(4.89, 11.2, 5.03, 10.43, 5.27, 9.71)
      ..lineTo(5.27, 6.58)
      ..lineTo(1.23, 6.58)
      ..cubicTo(0.45, 8.24, 0.0, 10.06, 0.0, 12.0)
      ..cubicTo(0.0, 13.94, 0.45, 15.76, 1.23, 17.42)
      ..lineTo(5.27, 14.29)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // 4. Red (#EA4335)
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    final redPath = Path()
      ..moveTo(12.0, 4.94)
      ..cubicTo(13.77, 4.94, 15.35, 5.55, 16.6, 6.74)
      ..lineTo(20.14, 3.2)
      ..cubicTo(17.95, 1.16, 15.24, 0.0, 12.0, 0.0)
      ..cubicTo(7.37, 0.0, 3.26, 2.74, 1.23, 6.78)
      ..lineTo(5.27, 9.91)
      ..cubicTo(6.22, 7.06, 8.87, 4.94, 12.0, 4.94)
      ..close();
    canvas.drawPath(redPath, redPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
