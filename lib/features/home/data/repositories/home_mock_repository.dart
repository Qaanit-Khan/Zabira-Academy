import '../models/hero_banner_model.dart';
import '../models/quick_access_model.dart';
import '../models/daily_supplement_model.dart';
import '../models/latest_launch_model.dart';
import '../models/store_product_model.dart';

/// Static mock data source for the Home Page.
///
/// Replace this class with a real API repository when the backend is ready.
/// All method signatures remain identical — only swap the implementation.
class HomeMockRepository {
  const HomeMockRepository._();

  // ─── Hero Banners ─────────────────────────────────────────────────────────

  static List<HeroBannerModel> getHeroBanners({
    void Function()? onKidsPortalTap,
    void Function()? onStoreTap,
    void Function()? onCoursesTap,
    void Function()? onHero4Tap,
  }) => [
        HeroBannerModel(
          id: 'hero_1',
          imagePath: 'assets/images/home/hero/hero_1.png',
          onTap: onCoursesTap,
        ),
        HeroBannerModel(
          id: 'hero_2',
          imagePath: 'assets/images/home/hero/hero_2.png',
          onTap: onKidsPortalTap,
        ),
        HeroBannerModel(
          id: 'hero_3',
          imagePath: 'assets/images/home/hero/hero_3.png',
          onTap: onStoreTap,
        ),
        HeroBannerModel(
          id: 'hero_4',
          imagePath: 'assets/images/home/hero/hero_4.png',
          onTap: onHero4Tap,
        ),
      ];

  // ─── Quick Access (Category Grid) ─────────────────────────────────────────

  static List<QuickAccessModel> getQuickAccessItems() => const [
        // Row 1
        QuickAccessModel(
          label: 'Courses',
          route: '/courses',
          semanticLabel: 'Open Courses',
          imagePath: 'assets/images/home/categories/courses.png',
          iconType: QaIconType.courses,
        ),
        QuickAccessModel(
          label: 'Kids Portal',
          route: '/kids',
          semanticLabel: 'Open Kids Portal',
          imagePath: 'assets/images/home/categories/kids_portal.png',
          iconType: QaIconType.kidsPortal,
        ),
        QuickAccessModel(
          label: 'Library',
          route: '/library',
          semanticLabel: 'Open Library',
          imagePath: 'assets/images/home/categories/library.png',
          iconType: QaIconType.library,
        ),
        QuickAccessModel(
          label: 'Nasheed',
          route: '/nasheed',
          semanticLabel: 'Open Nasheed',
          imagePath: 'assets/images/home/categories/nasheed.png',
          iconType: QaIconType.nasheed,
        ),
        // Row 2
        QuickAccessModel(
          label: 'Store',
          route: '/store',
          semanticLabel: 'Open Store',
          imagePath: 'assets/images/home/categories/store.png',
          iconType: QaIconType.store,
        ),
        QuickAccessModel(
          label: 'Events',
          route: '/events',
          semanticLabel: 'Open Events',
          imagePath: 'assets/images/home/categories/events.png',
          iconType: QaIconType.events,
        ),
        QuickAccessModel(
          label: 'Scholarship',
          route: '/scholarship',
          semanticLabel: 'Open Scholarship',
          imagePath: 'assets/images/home/categories/scholarship.png',
          iconType: QaIconType.scholarship,
        ),
        QuickAccessModel(
          label: 'Media',
          route: '/media',
          semanticLabel: 'Open Media',
          imagePath: 'assets/images/home/categories/media.png',
          iconType: QaIconType.media,
        ),
      ];

  // ─── Daily Supplement ─────────────────────────────────────────────────────

  static DailySupplementModel getDailySupplementInfo() =>
      const DailySupplementModel(
        sectionLabel: 'Daily Nasheed',
        contentTitle: 'Allah Knows',
        contentType: 'Nasheed',
        duration: '03:42',
        progress: 0.42,
        artType: DailySupplementArtType.nasheed,
      );

  // ─── Latest Launches ──────────────────────────────────────────────────────

  static List<LatestLaunchModel> getLatestLaunches() => const [
        LatestLaunchModel(
          id: 'launch-1',
          title: 'Launch 1',
          contentType: LaunchContentType.course,
          supportingInfo: '',
          imagePath: 'assets/images/home/latest_launches/launch_1.png',
        ),
        LatestLaunchModel(
          id: 'launch-2',
          title: 'Launch 2',
          contentType: LaunchContentType.nasheed,
          supportingInfo: '',
          imagePath: 'assets/images/home/latest_launches/launch_2.png',
        ),
        LatestLaunchModel(
          id: 'launch-3',
          title: 'Launch 3',
          contentType: LaunchContentType.qirat,
          supportingInfo: '',
          imagePath: 'assets/images/home/latest_launches/launch_3.png',
        ),
        LatestLaunchModel(
          id: 'launch-4',
          title: 'Launch 4',
          contentType: LaunchContentType.media,
          supportingInfo: '',
          imagePath: 'assets/images/home/latest_launches/launch_4.png',
        ),
        LatestLaunchModel(
          id: 'launch-5',
          title: 'Launch 5',
          contentType: LaunchContentType.audiobook,
          supportingInfo: '',
          imagePath: 'assets/images/home/latest_launches/launch_5.png',
        ),
      ];

  // ─── Store Products ───────────────────────────────────────────────────────

  static List<StoreProductModel> getStoreProducts() => const [
        StoreProductModel(
          id: 101,
          name: 'The Quran Code',
          slug: 'the-quran-code',
          categoryName: 'Hardcover Book',
          price: 899,
          localAssetFallback: 'assets/images/home/store/quran_code.png',
        ),
        StoreProductModel(
          id: 102,
          name: 'Quran Reciter',
          slug: 'quran-reciter',
          categoryName: 'Zabira Edition',
          price: 1999,
          localAssetFallback: 'assets/images/home/store/quran_reciter.png',
        ),
        StoreProductModel(
          id: 103,
          name: 'Zabira Notebook',
          slug: 'zabira-notebook',
          categoryName: 'Premium Quality',
          price: 299,
          localAssetFallback: 'assets/images/home/store/zabira_notebook.png',
        ),
      ];
}
