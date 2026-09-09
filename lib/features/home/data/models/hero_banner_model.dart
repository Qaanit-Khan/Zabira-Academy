import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_config.dart';

/// Data model for a single Hero Carousel slide.
///
/// Supports dynamic Admin API banners (`/mobile/home_banners.php`) as well as
/// high-resolution curated asset fallbacks.
class HeroBannerModel {
  const HeroBannerModel({
    required this.id,
    this.imagePath = 'assets/images/home/hero_banners/hero_banner_1.png',
    this.imageUrl,
    this.title,
    this.linkType,
    this.linkUrl,
    this.onTap,
  });

  /// Unique banner identifier
  final String id;

  /// Local asset fallback path
  final String imagePath;

  /// Remote image URL from Admin API
  final String? imageUrl;

  /// Optional banner title
  final String? title;

  /// Link target category/type ('course', 'kids', 'store', 'library', 'event', 'url', etc.)
  final String? linkType;

  /// Deep link URL or ID
  final String? linkUrl;

  /// Tappable action callback
  final VoidCallback? onTap;

  /// Factory constructor from Admin API JSON response
  factory HeroBannerModel.fromJson(Map<String, dynamic> json, {VoidCallback? onTap}) {
    final rawImage = json['image_url']?.toString() ??
        json['image']?.toString() ??
        json['banner_image']?.toString() ??
        json['thumbnail']?.toString();

    return HeroBannerModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      imageUrl: ApiConfig.resolveImageUrl(rawImage),
      title: json['title']?.toString() ?? json['name']?.toString(),
      linkType: json['link_type']?.toString() ?? json['type']?.toString(),
      linkUrl: json['link_url']?.toString() ?? json['url']?.toString() ?? json['target']?.toString(),
      onTap: onTap,
    );
  }
}
