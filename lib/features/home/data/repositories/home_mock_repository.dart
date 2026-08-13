import '../models/hero_banner_model.dart';
import '../models/quick_access_model.dart';
import '../models/daily_supplement_model.dart';
import '../models/latest_launch_model.dart';

/// Static mock data source for the Home Page.
///
/// Replace this class with a real API repository when the backend is ready.
/// All method signatures remain identical — only swap the implementation.
class HomeMockRepository {
  const HomeMockRepository._();

  // ─── Greeting ─────────────────────────────────────────────────────────────

  static const String greetingSubtitle = 'Keep learning, keep growing.';

  // ─── Hero Banners ─────────────────────────────────────────────────────────

  static List<HeroBannerModel> getHeroBanners({
    void Function()? onKidsPortalTap,
    void Function()? onStoreTap,
    void Function()? onCoursesTap,
  }) => [
        HeroBannerModel(
          id: 'kids_portal',
          imagePath: 'assets/images/home/hero/kids_portal_banner.png',
          onTap: onKidsPortalTap,
        ),
        HeroBannerModel(
          id: 'zabira_store',
          imagePath: 'assets/images/home/hero/zabira_store_banner.png',
          onTap: onStoreTap,
        ),
        HeroBannerModel(
          id: 'quality_courses',
          imagePath: 'assets/images/home/hero/quality_courses_banner.png',
          onTap: onCoursesTap,
        ),
      ];

  // ─── Quick Access ─────────────────────────────────────────────────────────

  static List<QuickAccessModel> getQuickAccessItems() => const [
        // Row 1 — custom SVG icons
        QuickAccessModel(
          label: 'Courses',
          route: '/courses',
          semanticLabel: 'Open Courses',
          iconPath: 'assets/images/home/icons/lesson.svg',
          iconType: QaIconType.courses,
        ),
        QuickAccessModel(
          label: 'Kids Portal',
          route: '/kids',
          semanticLabel: 'Open Kids Portal',
          iconPath: 'assets/images/home/icons/users-alt.svg',
          iconType: QaIconType.kidsPortal,
        ),
        QuickAccessModel(
          label: 'Library',
          route: '/library',
          semanticLabel: 'Open Library',
          iconPath: 'assets/images/home/icons/books.svg',
          iconType: QaIconType.library,
        ),
        QuickAccessModel(
          label: 'Nasheed',
          route: '/nasheed',
          semanticLabel: 'Open Nasheed',
          iconPath: 'assets/images/home/icons/user-music.svg',
          iconType: QaIconType.nasheed,
        ),
        // Row 2
        QuickAccessModel(
          label: 'Store',
          route: '/store',
          semanticLabel: 'Open Store',
          iconPath: 'assets/images/home/icons/shopping-cart-favourite.svg',
          iconType: QaIconType.store,
        ),
        QuickAccessModel(
          label: 'Events',
          route: '/events',
          semanticLabel: 'Open Events',
          iconPath: 'assets/images/home/icons/calendar.svg',
          iconType: QaIconType.events,
        ),
        QuickAccessModel(
          label: 'Scholarship',
          route: '/scholarship',
          semanticLabel: 'Open Scholarship',
          iconPath: 'assets/images/home/icons/degree-credential.svg',
          iconType: QaIconType.scholarship,
        ),
        QuickAccessModel(
          label: 'Media',
          route: '/media',
          semanticLabel: 'Open Media',
          iconPath: 'assets/images/home/icons/screen-play.svg',
          iconType: QaIconType.media,
        ),
      ];

  // ─── Daily Supplement ─────────────────────────────────────────────────────

  /// Returns today's supplemental content item.
  /// API-ready: swap this with a real endpoint that returns the current
  /// daily piece (nasheed, qirat, dua, reminder, etc.).
  static DailySupplementModel getDailySupplementInfo() => const DailySupplementModel(
        sectionLabel: 'Daily Nasheed',
        contentTitle: 'Allah Knows',
        contentType: 'Nasheed',
        duration: '03:42',
        progress: 0.42,
        artType: DailySupplementArtType.nasheed,
      );

  // ─── Latest Launches ──────────────────────────────────────────────────────

  /// Returns the most recently launched content across all categories.
  /// Designed to show a mix of courses, nasheed, qirat, audiobooks, etc.
  static List<LatestLaunchModel> getLatestLaunches() => const [
        LatestLaunchModel(
          id: 'quran-tajweed',
          title: 'Quran with\nTajweed',
          contentType: LaunchContentType.course,
          supportingInfo: '1.2K Students',
          imagePath: 'assets/images/home/latest_launches/quran_tajweed.png',
        ),
        LatestLaunchModel(
          id: 'daily-quran-recitation',
          title: 'Daily Quran\nRecitation',
          contentType: LaunchContentType.qirat,
          supportingInfo: '28 min · New',
          imagePath: 'assets/images/home/latest_launches/daily_quran_recitation.png',
        ),
        LatestLaunchModel(
          id: 'morning-adhkar',
          title: 'Morning\nAdhkar',
          contentType: LaunchContentType.audio,
          supportingInfo: '15 min · Daily',
          imagePath: 'assets/images/home/latest_launches/morning_adhkar.png',
        ),
        LatestLaunchModel(
          id: 'stories-prophets',
          title: 'Stories of the\nProphets',
          contentType: LaunchContentType.audiobook,
          supportingInfo: '124 Episodes',
          imagePath: 'assets/images/home/latest_launches/stories_of_prophets.png',
        ),
      ];
}
