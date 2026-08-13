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
import '../widgets/greeting_section.dart';
import '../widgets/hero_carousel.dart';
import '../widgets/quick_access_grid.dart';
import '../widgets/section_header.dart';
import '../widgets/daily_supplement_card.dart';
import '../widgets/latest_launch_card.dart';
import '../widgets/promotional_banner.dart';
import '../widgets/home_bottom_nav.dart';

/// Zabira Academy — Premium Native Mobile Home Page
///
/// Home Page Section Order:
///   Header → Greeting → Hero Carousel → Categories → Daily Supplement
///   → Latest Launches → Promotional Banner → Bottom Navigation
///
/// Auth state:
///   • Logged out : Shows neutral greeting ("Assalamu Alaikum" / "Discover, learn and grow.")
///   • Logged in  : Displays personalized greeting with user's actual name.
///
/// "Continue Learning" has been replaced by "Daily Supplement" — a compact
/// audio player card for today's featured Islamic content (no auth required).
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedNavIndex = 0;

  // Placeholder navigation callbacks for hero banners
  void _onKidsPortalTap() {
    // TODO: Navigate to Kids Portal destination page
    debugPrint('Hero Banner Tapped: Kids Portal');
  }

  void _onStoreTap() {
    // TODO: Navigate to Zabira Store destination page
    debugPrint('Hero Banner Tapped: Zabira Store');
  }

  void _onCoursesTap() {
    // TODO: Navigate to Quality Courses destination page
    debugPrint('Hero Banner Tapped: Quality Courses');
  }

  // Static content loaded once — API-ready via HomeMockRepository
  late final _banners = HomeMockRepository.getHeroBanners(
    onKidsPortalTap: _onKidsPortalTap,
    onStoreTap: _onStoreTap,
    onCoursesTap: _onCoursesTap,
  );
  final _quickItems      = HomeMockRepository.getQuickAccessItems();
  final _dailySupplement = HomeMockRepository.getDailySupplementInfo();
  final _latestLaunches  = HomeMockRepository.getLatestLaunches();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    // Read auth state from AuthController
    final auth = context.watch<AuthController>();
    final isAuthenticated = auth.isAuthenticated;
    final user = auth.user;
    final userName = isAuthenticated && user != null
        ? (user.displayName.isNotEmpty ? user.displayName : user.email.split('@').first)
        : null;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: Column(
        children: [
          // ── Header Bar ───────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: HomeHeader(
              isAuthenticated: isAuthenticated,
              notificationCount: 3,
              onSignIn: () => context.push(AppRoutes.login),
            ),
          ),

          // ── Scrollable Content ───────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.xs),

                  // 1. Greeting Section
                  GreetingSection(userName: userName),

                  const SizedBox(height: AppSpacing.sm),

                  // 2. Hero Carousel
                  HeroCarousel(banners: _banners),

                  const SizedBox(height: AppSpacing.lg),

                  // 3. Categories (Quick Access Grid)
                  QuickAccessGrid(items: _quickItems),

                  const SizedBox(height: AppSpacing.lg),

                  // 4. Daily Supplement
                  SectionHeader(title: 'Daily Supplement'),
                  const SizedBox(height: AppSpacing.sm),
                  DailySupplementCard(supplement: _dailySupplement),

                  const SizedBox(height: AppSpacing.lg),

                  // 5. Latest Launches (with subtle bottom-fade transition)
                  SectionHeader(title: 'Latest Launches', onSeeAll: () {}),
                  const SizedBox(height: AppSpacing.sm),
                  _LatestLaunchesSection(launches: _latestLaunches),

                  const SizedBox(height: AppSpacing.md),

                  // 6. Promotional Banner — image-only, no text above
                  const PromotionalBanner(),

                  // Bottom breathing room above nav bar
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),

          // ── Dark Navy Bottom Navigation Bar ─────────────────────────────
          HomeBottomNav(
            selectedIndex: _selectedNavIndex,
            onItemTapped: (index) => setState(() => _selectedNavIndex = index),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Latest Launches horizontal scroll row with a subtle bottom-edge fade
/// that eases the transition toward the bottom navigation.
class _LatestLaunchesSection extends StatelessWidget {
  const _LatestLaunchesSection({required this.launches});

  final List<LatestLaunchModel> launches;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Cards row ──────────────────────────────────────────────────────
        _LatestLaunchesRow(launches: launches),

        // ── Subtle bottom fade overlay — background only, does NOT blur
        //    text or images. Creates a smooth transition toward the nav bar.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 32,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.surfaceLight.withAlpha(0),
                    AppColors.surfaceLight.withAlpha(180),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Horizontally scrolling Latest Launches row with uniform spacing.
class _LatestLaunchesRow extends StatelessWidget {
  const _LatestLaunchesRow({required this.launches});

  final List<LatestLaunchModel> launches;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 204,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: launches.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              right: index < launches.length - 1 ? AppSpacing.md : 0,
            ),
            child: LatestLaunchCard(launch: launches[index]),
          );
        },
      ),
    );
  }
}
