import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Zabira Academy branded loading indicator
class ZabiraLoader extends StatelessWidget {
  const ZabiraLoader({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
      ),
    );
  }
}

/// Full-screen loading overlay
class ZabiraLoadingOverlay extends StatelessWidget {
  const ZabiraLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.scrim,
      child: const Center(child: ZabiraLoader(size: 44)),
    );
  }
}
