import 'package:flutter/foundation.dart';

/// Data model for a single Hero Carousel slide.
///
/// Holds the local asset image path and an optional tap callback.
/// API-ready: swap [HomeMockRepository] with a real repo.
class HeroBannerModel {
  const HeroBannerModel({
    required this.id,
    required this.imagePath,
    this.onTap,
  });

  /// Unique banner identifier (e.g. 'kids_portal', 'zabira_store', 'quality_courses')
  final String id;

  /// Local asset path for the hero banner image
  final String imagePath;

  /// Tappable button callback for banner navigation
  final VoidCallback? onTap;
}
