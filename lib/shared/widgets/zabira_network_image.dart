import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants/api_config.dart';
import '../../core/theme/app_colors.dart';

/// Reusable network image with smooth loading indicator and graceful fallback.
class ZabiraNetworkImage extends StatelessWidget {
  const ZabiraNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.image_outlined,
  });

  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final raw = imageUrl?.trim();
    if (raw == null || raw.isEmpty) {
      return _wrapBorderRadius(_buildFallback());
    }

    // Handle Data URI / base64 image
    if (raw.startsWith('data:image') || (!raw.startsWith('http') && !raw.startsWith('/') && raw.length > 100)) {
      try {
        final commaIdx = raw.indexOf(',');
        final b64 = commaIdx != -1 ? raw.substring(commaIdx + 1) : raw;
        final bytes = base64Decode(b64);
        return _wrapBorderRadius(
          Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _buildFallback(),
          ),
        );
      } catch (_) {
        return _wrapBorderRadius(_buildFallback());
      }
    }

    final resolved = ApiConfig.resolveImageUrl(raw);
    if (resolved == null || resolved.isEmpty) {
      return _wrapBorderRadius(_buildFallback());
    }

    Widget imageWidget = Image.network(
      resolved,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: const Color(0xFFF0F4F8),
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildFallback();
      },
    );

    return _wrapBorderRadius(imageWidget);
  }

  Widget _wrapBorderRadius(Widget child) {
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: child,
      );
    }
    return child;
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFE8EDF2),
      child: Center(
        child: Icon(
          fallbackIcon,
          size: 26,
          color: const Color(0xFF8FA0BB),
        ),
      ),
    );
  }
}
