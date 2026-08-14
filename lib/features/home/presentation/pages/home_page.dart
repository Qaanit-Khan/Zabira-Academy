import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/auth/auth_controller.dart';
import '../../data/models/latest_launch_model.dart';
import '../../data/repositories/home_mock_repository.dart';
import '../widgets/home_header.dart';
import '../widgets/hero_carousel.dart';
import '../widgets/quick_access_grid.dart';
import '../widgets/section_header.dart';
import '../widgets/daily_supplement_card.dart';
import '../widgets/daily_supplement_banner.dart';
import '../widgets/latest_launch_card.dart';
import '../widgets/home_bottom_nav.dart';
import '../widgets/from_zabira_store_section.dart';

/// Zabira Academy — Home Page
///
/// Vertical section order (matches reference image):
///   Header (fixed)
///   ↓ Hero Carousel (4 banners, auto-slide, pagination dots)
///   ↓ Category Grid (8 icons, 4×2)
///   ↓ Daily Nasheed Player (compact player card)
///   ↓ Daily Supplement Promotional Banner (daily_supplement_banner.png)
///   ↓ Latest Launches (5 square cards, horizontal scroll)
///   ↓ From Zabira Store (3 product cards)
///   Bottom Navigation (fixed)
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedNavIndex = 0;

  // ── Hero banner tap callbacks ─────────────────────────────────────────────
  void _onCoursesTap()    => debugPrint('Hero: Courses tapped');
  void _onKidsPortalTap() => debugPrint('Hero: Kids Portal tapped');
  void _onStoreTap()      => debugPrint('Hero: Store tapped');
  void _onHero4Tap()      => debugPrint('Hero: Banner 4 tapped');

  // ── Static data (API-ready) ───────────────────────────────────────────────
  late final _banners = HomeMockRepository.getHeroBanners(
    onCoursesTap:    _onCoursesTap,
    onKidsPortalTap: _onKidsPortalTap,
    onStoreTap:      _onStoreTap,
    onHero4Tap:      _onHero4Tap,
  );
  final _categories      = HomeMockRepository.getQuickAccessItems();
  final _dailySupplement = HomeMockRepository.getDailySupplementInfo();
  final _latestLaunches  = HomeMockRepository.getLatestLaunches();
  final _storeProducts   = HomeMockRepository.getStoreProducts();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final auth = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: Column(
        children: [
          // ── Fixed Header ──────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: HomeHeader(
              isAuthenticated: auth.isAuthenticated,
              notificationCount: 3,
              onSignIn: () => context.push(AppRoutes.login),
              onProfileTap: () {
                if (auth.isAuthenticated) {
                  // Ready for future Profile / Dashboard screen
                  debugPrint('Profile tapped: user is authenticated');
                } else {
                  context.push(AppRoutes.login);
                }
              },
            ),
          ),

          // ── Scrollable Content ────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.sm),

                  // 1. Hero Carousel — 4 banners
                  HeroCarousel(banners: _banners),

                  const SizedBox(height: AppSpacing.md),

                  // 2. Category Grid — 8 icons (4×2)
                  QuickAccessGrid(items: _categories),

                  const SizedBox(height: AppSpacing.md),

                  // 3. Daily Supplement / Nasheed — compact player card
                  DailySupplementCard(supplement: _dailySupplement),

                  const SizedBox(height: AppSpacing.md),

                  // 4. Daily Supplement Promotional Banner (daily_supplement_banner.png)
                  const DailySupplementBanner(),

                  const SizedBox(height: AppSpacing.lg),

                  // 5. Latest Launches — compact square image cards
                  SectionHeader(
                    title: 'Latest Launches',
                    onSeeAll: () {},
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _LatestLaunchesRow(launches: _latestLaunches),

                  const SizedBox(height: AppSpacing.lg),

                  // 6. From Zabira Store — 3 product cards
                  FromZabiraStoreSection(products: _storeProducts),

                  // Bottom breathing room above nav bar
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),

          // ── Fixed Bottom Navigation ───────────────────────────────────────
          HomeBottomNav(
            selectedIndex: _selectedNavIndex,
            onItemTapped: (i) => setState(() => _selectedNavIndex = i),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Horizontally scrolling Latest Launches row — compact square cards.
class _LatestLaunchesRow extends StatelessWidget {
  const _LatestLaunchesRow({required this.launches});

  final List<LatestLaunchModel> launches;

  @override
  Widget build(BuildContext context) {
    const cardSize = 88.0;

    return SizedBox(
      height: cardSize,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: launches.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              right: index < launches.length - 1 ? 10.0 : 0,
            ),
            child: LatestLaunchCard(
              launch: launches[index],
              size: cardSize,
            ),
          );
        },
      ),
    );
  }
}
