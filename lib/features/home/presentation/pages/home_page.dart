import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/auth/auth_controller.dart';
import '../../../courses/data/models/enrolled_course_model.dart';
import '../../../courses/presentation/controllers/enrollment_controller.dart';
import '../../../store/presentation/controllers/cart_controller.dart';
import '../../../../shared/widgets/zabira_network_image.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../data/models/latest_launch_model.dart';
import '../../data/repositories/home_mock_repository.dart';
import '../widgets/home_header.dart';
import '../widgets/greeting_section.dart';
import '../widgets/hero_carousel.dart';
import '../widgets/quick_access_grid.dart';
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
  int _selectedNavIndex = 0;
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
    final enrollment = context.watch<EnrollmentController>();

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
        if (_selectedNavIndex != 0) {
          setState(() => _selectedNavIndex = 0);
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        key: _scaffoldKey,
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
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
              onSignIn: () => context.push(AppRoutes.login),
              onCartTap: () {
                if (isAuth) {
                  context.push(AppRoutes.cart);
                } else {
                  auth.setPendingReturnTo(AppRoutes.cart);
                  context.push(AppRoutes.login);
                }
              },
              onProfileTap: () {
                if (isAuth) {
                  context.push(AppRoutes.studentDash);
                } else {
                  auth.setPendingReturnTo(AppRoutes.studentDash);
                  context.push(AppRoutes.login);
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

                    // Continue Learning Section (only incomplete enrolled courses)
                    if (isAuth && enrollment.enrolledCourses.isNotEmpty) ...[
                      _ContinueLearningSection(courses: enrollment.enrolledCourses),
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

                    // Bottom breathing room above nav bar
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),

          // ── Fixed Bottom Navigation ───────────────────────────────────────
          HomeBottomNav(
            selectedIndex: _selectedNavIndex,
            onItemTapped: (i) {
              if (i == 0) {
                setState(() => _selectedNavIndex = 0);
              } else if (i == 1) {
                context.push(AppRoutes.courses);
              } else if (i == 2) {
                context.push('/kids');
              } else if (i == 3) {
                context.push(AppRoutes.library);
              } else if (i == 4) {
                if (isAuth) {
                  context.push(AppRoutes.studentDash);
                } else {
                  auth.setPendingReturnTo(AppRoutes.studentDash);
                  context.push(AppRoutes.login);
                }
              }
            },
          ),
        ],
      ),
    ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Horizontally scrolling Continue Learning row for enrolled courses.
class _ContinueLearningSection extends StatelessWidget {
  const _ContinueLearningSection({required this.courses});

  final List<EnrolledCourseModel> courses;

  @override
  Widget build(BuildContext context) {
    // Only show courses that are NOT completed and progress < 100%
    final activeIncomplete = courses.where((c) => !c.isCompleted && c.progressPercent < 100.0).toList();
    if (activeIncomplete.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Continue Learning',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDark,
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.myCourses),
                child: Text(
                  'My Courses',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 96,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: activeIncomplete.length,
            itemBuilder: (context, index) {
              final course = activeIncomplete[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < activeIncomplete.length - 1 ? 12.0 : 0,
                ),
                child: _ContinueLearningCard(course: course),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  const _ContinueLearningCard({required this.course});

  final EnrolledCourseModel course;

  @override
  Widget build(BuildContext context) {
    final effectiveId = course.courseId > 0 ? course.courseId : course.id;
    final lessonParam = course.lastLessonId != null && course.lastLessonId! > 0 ? '?lesson_id=${course.lastLessonId}' : '';

    return GestureDetector(
      onTap: () => context.push('/courses/$effectiveId/learn$lessonParam', extra: course),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFF071B36),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: course.resolvedImage != null
                    ? ZabiraNetworkImage(
                        imageUrl: course.resolvedImage,
                        fit: BoxFit.cover,
                        fallbackIcon: Icons.menu_book_rounded,
                      )
                    : const Center(
                        child: Icon(Icons.play_circle_outline_rounded, color: AppColors.gold, size: 28),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Info & Progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: (course.progressPercent / 100).clamp(0.0, 1.0),
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${course.progressPercentInt}%',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
