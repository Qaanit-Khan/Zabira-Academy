import 'package:flutter/foundation.dart';
import '../models/hero_banner_model.dart';
import 'home_mock_repository.dart';

/// Section identifier for future Admin API page-specific hero banners.
enum HeroBannerSection {
  home,
  courses,
  store,
  nasheed,
  library,
  media,
  events,
  scholarship,
}

/// Global repository for Hero Banners across all major pages.
///
/// Current behavior:
/// - Returns existing Home hero banners with page-contextual callbacks for all sections.
///
/// Future Admin API behavior:
/// - Fetches section-specific banners independently from the backend (e.g. `GET /banners/public_list.php?section=courses`).
/// - If a section's custom banners are not configured, gracefully falls back to Home banners.
class HeroBannerRepository {
  const HeroBannerRepository._();

  /// Retrieve hero banners for a specific [HeroBannerSection].
  static List<HeroBannerModel> getBannersForSection({
    required HeroBannerSection section,
    VoidCallback? onCoursesTap,
    VoidCallback? onKidsPortalTap,
    VoidCallback? onStoreTap,
    VoidCallback? onHero4Tap,
  }) {
    // Currently all pages reuse the existing high-quality Home banners
    // with section-appropriate navigation callbacks.
    switch (section) {
      case HeroBannerSection.home:
      case HeroBannerSection.courses:
      case HeroBannerSection.store:
      case HeroBannerSection.nasheed:
      case HeroBannerSection.library:
      case HeroBannerSection.media:
      case HeroBannerSection.events:
      case HeroBannerSection.scholarship:
        return HomeMockRepository.getHeroBanners(
          onCoursesTap: onCoursesTap,
          onKidsPortalTap: onKidsPortalTap,
          onStoreTap: onStoreTap,
          onHero4Tap: onHero4Tap,
        );
    }
  }
}
