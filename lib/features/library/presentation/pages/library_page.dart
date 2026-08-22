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
import '../../../../features/home/data/repositories/hero_banner_repository.dart';
import '../../../../features/home/presentation/widgets/hero_carousel.dart';
import '../../../../features/home/presentation/widgets/home_header.dart';
import '../../../../shared/loaders/zabira_loader.dart';
import '../../../../shared/widgets/scholarship_promo_banner.dart';
import '../../../../shared/widgets/zabira_bottom_nav.dart';
import '../../../../shared/widgets/zabira_error_state.dart';
import '../../../auth/presentation/widgets/auth_bottom_sheet.dart';
import '../../data/models/library_item_model.dart';
import '../controllers/library_controller.dart';
import '../widgets/library_book_card.dart';
import '../widgets/library_category_chips.dart';
import '../widgets/library_hero_card.dart';
import '../widgets/library_resource_tile.dart';
import 'library_item_details_page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final LibraryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LibraryController();
    _controller.loadInitialData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openDetails(LibraryItemModel item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LibraryItemDetailsPage(
          itemId: item.id,
          initialItem: item,
        ),
      ),
    );
  }

  Future<void> _addLibraryItemToCart(LibraryItemModel item) async {
    final auth = context.read<AuthController>();
    final cart = context.read<CartController>();

    if (!auth.isAuthenticated) {
      auth.setPendingReturnTo('/library/${item.id}');
      if (!mounted) return;
      showAuthBottomSheet(context);
      return;
    }

    final format = item.formats.isNotEmpty ? item.formats.first.format : 'pdf';
    final success = await cart.addItem(
      itemData: {
        'book_id': item.id,
        'format': format,
        'book_format': format,
        'product_type': 'library',
        'quantity': '1',
      },
      token: auth.currentToken,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Added "${item.title}" to cart.' : (cart.errorMessage ?? 'Could not add to cart.')),
        backgroundColor: success ? AppColors.navyDark : AppColors.error,
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
        extendBody: true,
        key: _scaffoldKey,
        drawer: const AppDrawer(),
        backgroundColor: AppColors.surfaceLight,
        bottomNavigationBar: const ZabiraBottomNav(selectedIndex: 4),
        body: Column(
          children: [
            // ── Fixed Top Header ──────────────────────────────────────────────
            SafeArea(
              bottom: false,
              child: HomeHeader(
                isAuthenticated: auth.isAuthenticated,
                notificationCount: 2,
                cartCount: cart.itemCount,
                onMenuTap: () => AppDrawer.open(context),
                onCartTap: () => context.push(AppRoutes.cart),
                onSignIn: () => showAuthBottomSheet(context),
                onProfileTap: () {
                  if (auth.isAuthenticated) {
                    context.go(AppRoutes.studentDash);
                  } else {
                    showAuthBottomSheet(context);
                  }
                },
              ),
            ),

          // ── Scrollable Body ───────────────────────────────────────────────
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (_controller.isLoading && _controller.items.isEmpty) {
                  return const Center(child: ZabiraLoader(size: 40));
                }

                if (_controller.errorMessage != null && _controller.items.isEmpty) {
                  return ZabiraErrorState(
                    title: 'Unable to Load Library',
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

                        // 1. Global Hero Banner Carousel
                        HeroCarousel(
                          banners: HeroBannerRepository.getBannersForSection(
                            section: HeroBannerSection.library,
                            onCoursesTap: () => context.push(AppRoutes.courses),
                            onKidsPortalTap: () => context.push(AppRoutes.kids),
                            onStoreTap: () => context.push(AppRoutes.store),
                            onHero4Tap: () => context.push(AppRoutes.courses),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 2. Library Hero Card
                        LibraryHeroCard(
                          onExploreTap: () {},
                        ),

                        const SizedBox(height: 10),

                        // 2. Category Chips
                        LibraryCategoryChips(
                          categories: _controller.categories,
                          selectedCategoryId: _controller.selectedCategoryId,
                          onSelectCategory: _controller.selectCategory,
                        ),

                        const SizedBox(height: 12),

                        // 3. Featured Books Section Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Featured Books',
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

                        // 2x2 Grid of Featured Books
                        _buildFeaturedBooksGrid(),

                        const SizedBox(height: 20),

                        // 4. Other Learning Resources Section Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Other Learning Resources',
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

                        // Horizontal List of Other Resources
                        _buildOtherResourcesList(),

                        const SizedBox(height: 16),

                        // 5. Promotional Banner
                        const ScholarshipPromoBanner(),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildFeaturedBooksGrid() {
    final books = _controller.featuredBooks;
    if (books.isEmpty) {
      return Container(
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('No books found in this category.', style: TextStyle(color: Color(0xFF64748B))),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final item = books[index];
          return LibraryBookCard(
            item: item,
            onTap: () => _openDetails(item),
            onAddToCart: () => _addLibraryItemToCart(item),
          );
        },
      ),
    );
  }

  Widget _buildOtherResourcesList() {
    final resources = _controller.otherResources.isNotEmpty ? _controller.otherResources : _controller.items;
    if (resources.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: resources.length,
        itemBuilder: (context, index) {
          final item = resources[index];
          return LibraryResourceTile(
            item: item,
            onTap: () => _openDetails(item),
            onAddToCart: () => _addLibraryItemToCart(item),
          );
        },
      ),
    );
  }
}

