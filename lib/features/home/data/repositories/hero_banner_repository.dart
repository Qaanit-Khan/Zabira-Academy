import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_config.dart';
import '../models/hero_banner_model.dart';
import 'home_mock_repository.dart';

/// Section identifier for page-specific hero banners.
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
/// Fully connected to the Official Admin API endpoint:
/// `GET /mobile/home_banners.php` (max 5 banners configured by Admin).
class HeroBannerRepository {
  HeroBannerRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Fetch dynamic 5 hero banners from Admin API `GET /mobile/home_banners.php`.
  /// Gracefully falls back to 5 curated high-resolution slides if empty or offline.
  Future<List<HeroBannerModel>> fetchHomeBanners({
    VoidCallback? onCoursesTap,
    VoidCallback? onKidsPortalTap,
    VoidCallback? onStoreTap,
    VoidCallback? onLibraryTap,
    VoidCallback? onEventsTap,
    VoidCallback? onHero4Tap,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/mobile/home_banners.php');
      debugPrint('[HERO BANNERS API] GET $uri');
      final res = await _client.get(
        uri,
        headers: {'Accept': 'application/json', 'User-Agent': 'ZabiraAcademy-Flutter/1.0'},
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'];
          final rawBanners = data is Map<String, dynamic> ? data['banners'] : (decoded['banners'] ?? data);
          if (rawBanners is List && rawBanners.isNotEmpty) {
            final list = <HeroBannerModel>[];
            for (final b in rawBanners) {
              if (b is Map<String, dynamic>) {
                final linkType = (b['link_type'] ?? b['type'] ?? '').toString().toLowerCase();
                VoidCallback? tapAction;
                if (linkType.contains('course')) {
                  tapAction = onCoursesTap;
                } else if (linkType.contains('kid')) {
                  tapAction = onKidsPortalTap;
                } else if (linkType.contains('store')) {
                  tapAction = onStoreTap;
                } else if (linkType.contains('lib')) {
                  tapAction = onLibraryTap ?? onHero4Tap;
                } else if (linkType.contains('event')) {
                  tapAction = onEventsTap;
                } else {
                  tapAction = onCoursesTap;
                }

                list.add(HeroBannerModel.fromJson(b, onTap: tapAction));
              }
            }
            if (list.isNotEmpty) {
              return list.take(5).toList();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[HERO BANNERS API EXCEPTION] $e');
    }

    return getBannersForSection(
      section: HeroBannerSection.home,
      onCoursesTap: onCoursesTap,
      onKidsPortalTap: onKidsPortalTap,
      onStoreTap: onStoreTap,
      onLibraryTap: onLibraryTap,
      onEventsTap: onEventsTap,
      onHero4Tap: onHero4Tap,
    );
  }

  /// Synchronous banner retriever for immediate page building (with 5 slides).
  static List<HeroBannerModel> getBannersForSection({
    required HeroBannerSection section,
    VoidCallback? onCoursesTap,
    VoidCallback? onKidsPortalTap,
    VoidCallback? onStoreTap,
    VoidCallback? onLibraryTap,
    VoidCallback? onEventsTap,
    VoidCallback? onHero4Tap,
  }) {
    return HomeMockRepository.getHeroBanners(
      onCoursesTap: onCoursesTap,
      onKidsPortalTap: onKidsPortalTap,
      onStoreTap: onStoreTap,
      onLibraryTap: onLibraryTap,
      onEventsTap: onEventsTap,
      onHero4Tap: onHero4Tap,
    );
  }
}
