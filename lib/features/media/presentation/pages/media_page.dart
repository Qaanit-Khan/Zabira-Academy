import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/auth/auth_controller.dart';
import '../../../../features/store/presentation/controllers/cart_controller.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../features/home/presentation/widgets/home_header.dart';
import '../../../../shared/loaders/zabira_loader.dart';
import '../../../../shared/widgets/scholarship_promo_banner.dart';
import '../../../../shared/widgets/zabira_error_state.dart';
import '../../data/models/media_item_model.dart';
import '../controllers/media_controller.dart';
import '../widgets/media_category_chips.dart';
import '../widgets/media_hero_card.dart';
import '../widgets/media_shorts_card.dart';
import '../widgets/media_video_card.dart';
import 'media_details_page.dart';

class MediaPage extends StatefulWidget {
  const MediaPage({super.key});

  @override
  State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final MediaController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MediaController();
    _controller.loadInitialData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openDetails(MediaItemModel item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MediaDetailsPage(
          mediaId: item.id,
          initialItem: item,
        ),
      ),
    );
  }

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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          _scaffoldKey.currentState?.closeDrawer();
          return;
        }
        context.go(AppRoutes.home);
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const AppDrawer(),
        backgroundColor: AppColors.surfaceLight,
        body: Column(
          children: [
            // ── Fixed Top Header ──────────────────────────────────────────────
            SafeArea(
              bottom: false,
              child: HomeHeader(
                isAuthenticated: auth.isAuthenticated,
                notificationCount: 2,
                cartCount: cart.itemCount,
                onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                onCartTap: () => context.push(AppRoutes.cart),
                onSignIn: () => context.push(AppRoutes.login),
                onProfileTap: () {
                  if (auth.isAuthenticated) {
                    context.go(AppRoutes.studentDash);
                  } else {
                    context.push(AppRoutes.login);
                  }
                },
              ),
            ),

          // ── Scrollable Body ───────────────────────────────────────────────
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (_controller.isLoading && _controller.mediaList.isEmpty) {
                  return const Center(child: ZabiraLoader(size: 40));
                }

                if (_controller.errorMessage != null && _controller.mediaList.isEmpty) {
                  return ZabiraErrorState(
                    title: 'Unable to Load Media',
                    message: _controller.errorMessage!,
                    onRetry: _controller.loadInitialData,
                  );
                }

                return RefreshIndicator(
                  onRefresh: _controller.loadInitialData,
                  color: AppColors.gold,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),

                        // 1. Hero Card
                        MediaHeroCard(
                          onExploreTap: () {
                            // scroll down or filter
                          },
                        ),

                        const SizedBox(height: 10),

                        // 2. Category Chips
                        MediaCategoryChips(
                          categories: _controller.categories,
                          selectedCategoryId: _controller.selectedCategoryId,
                          onSelectCategory: _controller.selectCategory,
                        ),

                        const SizedBox(height: 12),

                        // 3. Latest Videos Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Latest Videos',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navyDark,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {},
                                child: Row(
                                  children: [
                                    Text(
                                      'View All',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.navyDark,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.navyDark),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Latest Videos List
                        _buildLatestVideosList(),

                        const SizedBox(height: 20),

                        // 4. Shorts Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Shorts',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navyDark,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {},
                                child: Row(
                                  children: [
                                    Text(
                                      'View All',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.navyDark,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.navyDark),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Shorts List
                        _buildShortsList(),

                        const SizedBox(height: 16),

                        // 5. Promotional Banner
                        const ScholarshipPromoBanner(),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Fixed Bottom Navigation ───────────────────────────────────────
          _buildBottomNav(context),
        ],
      ),
    ),
    );
  }

  Widget _buildLatestVideosList() {
    final list = _controller.latestVideos;
    if (list.isEmpty) {
      if (_controller.mediaList.isNotEmpty) {
        // Show available media items as videos
        return _buildVideoHorizontalRow(_controller.mediaList);
      }
      return Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('No videos found in this category.', style: TextStyle(color: Color(0xFF64748B))),
        ),
      );
    }
    return _buildVideoHorizontalRow(list);
  }

  Widget _buildVideoHorizontalRow(List<MediaItemModel> items) {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: MediaVideoCard(
              item: item,
              onTap: () => _openDetails(item),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShortsList() {
    final list = _controller.shorts;
    if (list.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          return MediaShortsCard(
            item: item,
            onTap: () => _openDetails(item),
          );
        },
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad > 0 ? bottomPad + 4 : 14),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.borderLight.withAlpha(220), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyDark.withAlpha(14),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(child: _buildNavTab(0, Icons.home_rounded, 'Home', false, () => context.go(AppRoutes.home))),
                Expanded(child: _buildNavTab(1, Icons.auto_stories_outlined, 'Learn', false, () => context.push(AppRoutes.courses))),
                const SizedBox(width: 56), // Center gap
                Expanded(child: _buildNavTab(3, Icons.menu_book_outlined, 'Library', false, () => context.push(AppRoutes.library))),
                Expanded(child: _buildNavTab(4, Icons.smart_display_rounded, 'Media', true, () {})),
              ],
            ),
          ),
          Positioned(
            top: -10,
            child: GestureDetector(
              onTap: () => context.go(AppRoutes.home),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF081D3A),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF081D3A).withAlpha(40),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/home/footer/academy_footer_logo.png',
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.auto_stories_rounded, color: AppColors.gold, size: 24),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTab(int index, IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: isActive ? AppColors.navyDark : const Color(0xFF8FA0BB)),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 9.5,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? AppColors.navyDark : const Color(0xFF8FA0BB),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 4 : 0,
            height: isActive ? 4 : 0,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
