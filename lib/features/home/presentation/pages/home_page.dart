import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/auth/auth_controller.dart';
import '../../../courses/presentation/controllers/enrollment_controller.dart';
import '../../../store/presentation/controllers/cart_controller.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../data/models/latest_launch_model.dart';
import '../../data/repositories/home_mock_repository.dart';
import '../widgets/home_header.dart';
import '../widgets/greeting_section.dart';
import '../widgets/hero_carousel.dart';
import '../widgets/quick_access_grid.dart';
import '../../../auth/presentation/widgets/auth_bottom_sheet.dart';
import '../widgets/section_header.dart';
import '../widgets/daily_supplement_card.dart';
import '../widgets/daily_supplement_banner.dart';
import '../widgets/latest_launch_card.dart';
import '../widgets/home_bottom_nav.dart';
import '../widgets/from_zabira_store_section.dart';
import '../../data/models/daily_supplement_model.dart';
import '../../../nasheed/data/services/nasheed_api_service.dart';

/// Zabira Academy — Home Page
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedNavIndex = 2;
  final _nasheedService = NasheedApiService();
  DailySupplementModel _dailySupplement = HomeMockRepository.getDailySupplementInfo();

  @override
  void initState() {
    super.initState();
    _loadDailyNasheed();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      if (auth.isAuthenticated) {
        context.read<EnrollmentController>().loadMyCourses(auth.currentToken);
        context.read<CartController>().loadCart(auth.currentToken);
      }
    });
  }

  Future<void> _loadDailyNasheed() async {
    try {
      final item = await _nasheedService.getDailyNasheed();
      if (mounted) {
        setState(() => _dailySupplement = item);
      }
    } catch (_) {}
  }

  // ── Hero banner tap callbacks ─────────────────────────────────────────────
  void _onCoursesTap() => context.push(AppRoutes.courses);
  void _onKidsPortalTap() => context.push('/kids');
  void _onStoreTap() => context.push(AppRoutes.store);
  void _onHero4Tap() => context.push(AppRoutes.courses);

  late final _banners = HomeMockRepository.getHeroBanners(
    onCoursesTap: _onCoursesTap,
    onKidsPortalTap: _onKidsPortalTap,
    onStoreTap: _onStoreTap,
    onHero4Tap: _onHero4Tap,
  );
  final _categories = HomeMockRepository.getQuickAccessItems();
  final _latestLaunches = HomeMockRepository.getLatestLaunches();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final auth = context.watch<AuthController>();
    final cart = context.watch<CartController>();

    final user = auth.user;
    final isAuth = auth.isAuthenticated && user != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          _scaffoldKey.currentState?.closeDrawer();
          return;
        }
        if (_selectedNavIndex != 2) {
          setState(() => _selectedNavIndex = 2);
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        key: _scaffoldKey,
        extendBody: true,
        backgroundColor: AppColors.surfaceLight,
        drawer: const AppDrawer(),
        body: Column(
          children: [
            // ── Fixed Header ──────────────────────────────────────────────────
            SafeArea(
              bottom: false,
              child: HomeHeader(
                isAuthenticated: isAuth,
                notificationCount: isAuth ? 3 : 0,
                cartCount: cart.itemCount,
                userInitial: isAuth && user.displayName.isNotEmpty ? user.displayName[0] : null,
                onMenuTap: () => AppDrawer.open(context),
                onSignIn: () => showAuthBottomSheet(context),
                onCartTap: () {
                  if (isAuth) {
                    context.push(AppRoutes.cart);
                  } else {
                    auth.setPendingReturnTo(AppRoutes.cart);
                    showAuthBottomSheet(context);
                  }
                },
                onProfileTap: () {
                  if (isAuth) {
                    context.push(AppRoutes.studentDash);
                  } else {
                    auth.setPendingReturnTo(AppRoutes.studentDash);
                    showAuthBottomSheet(context);
                  }
                },
              ),
            ),

            // ── Scrollable Content ────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: AppColors.gold,
                backgroundColor: AppColors.surfaceWhite,
                onRefresh: () async {
                  final auth = context.read<AuthController>();
                  if (auth.isAuthenticated) {
                    await Future.wait([
                      context.read<EnrollmentController>().loadMyCourses(auth.currentToken, forceRefresh: true),
                      context.read<CartController>().loadCart(auth.currentToken),
                      _loadDailyNasheed(),
                    ]);
                  } else {
                    await _loadDailyNasheed();
                  }
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personalized Greeting Section (only if authenticated)
                      if (isAuth) ...[
                        GreetingSection(
                          userName: user.displayName,
                          subtitle: 'Keep learning, keep growing.',
                        ),
                        const SizedBox(height: AppSpacing.xs),
                      ] else ...[
                        const SizedBox(height: AppSpacing.sm),
                      ],

                      // 1. Hero Carousel — 4 banners
                      HeroCarousel(banners: _banners),

                      const SizedBox(height: AppSpacing.md),

                      // 2. Category Grid — 8 icons (4×2)
                      QuickAccessGrid(items: _categories),

                      const SizedBox(height: AppSpacing.md),

                      // 3. Daily Supplement / Nasheed — live API player card
                      DailySupplementCard(supplement: _dailySupplement),

                      const SizedBox(height: AppSpacing.md),

                      // 4. Daily Supplement Promotional Banner
                      const DailySupplementBanner(),

                      const SizedBox(height: AppSpacing.lg),

                      // 5. Latest Launches — compact square image cards
                      SectionHeader(
                        title: 'Latest Launches',
                        onSeeAll: () => context.push(AppRoutes.courses),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _LatestLaunchesRow(launches: _latestLaunches),

                      const SizedBox(height: AppSpacing.lg),

                      // 6. From Zabira Store — dynamic live products from official API
                      const FromZabiraStoreSection(),

                      // Bottom breathing room above floating nav bar
                      const SizedBox(height: 75),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: HomeBottomNav(
          selectedIndex: _selectedNavIndex,
          onItemTapped: (i) {
            if (i == 0) {
              context.push(AppRoutes.courses);
            } else if (i == 1) {
              context.push(AppRoutes.kids);
            } else if (i == 2) {
              setState(() => _selectedNavIndex = 2);
            } else if (i == 3) {
              context.push(AppRoutes.store);
            } else if (i == 4) {
              context.push(AppRoutes.library);
            }
          },
        ),
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
