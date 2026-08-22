import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/auth/auth_controller.dart';
import '../../../auth/presentation/widgets/auth_bottom_sheet.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/scholarship_promo_banner.dart';
import '../../../../shared/widgets/zabira_bottom_nav.dart';
import '../../../home/data/models/hero_banner_model.dart';
import '../../../home/data/repositories/hero_banner_repository.dart';
import '../../../home/presentation/widgets/hero_carousel.dart';
import '../../../home/presentation/widgets/home_header.dart';
import '../controllers/cart_controller.dart';
import '../../data/models/store_category_model.dart';
import '../../data/models/store_product_model.dart';
import '../../data/repositories/store_repository.dart';

/// Zabira Academy — Store Page
///
/// Features:
/// - Exact visual layout from reference screenshot
/// - Title & Subtitle + Search & Filter
/// - Global Hero Banner Carousel
/// - Soft pastel category cards
/// - Featured Products section header
/// - 2-column equal-height product cards
/// - 3 action buttons arranged in 2 rows:
///     Row 1: [Add to Cart (50%)] [View Details (50%)]
///     Row 2: [Buy Now (100% orange)]
/// - Trust/Service badges
/// - Universal Scholarship Promotional Banner
class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final StoreRepository _repository = StoreRepository();
  final TextEditingController _searchController = TextEditingController();

  List<StoreCategoryModel> _categories = [];
  List<StoreProductModel> _products = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _selectedCategoryId; // null = "All"
  String _searchQuery = '';
  final Set<int> _favorites = {};

  late final List<HeroBannerModel> _banners;

  @override
  void initState() {
    super.initState();
    _banners = HeroBannerRepository.getBannersForSection(
      section: HeroBannerSection.store,
      onCoursesTap: () => context.push(AppRoutes.courses),
      onKidsPortalTap: () => context.push(AppRoutes.kids),
      onStoreTap: () {},
      onHero4Tap: () => context.push(AppRoutes.courses),
    );
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _repository.getCategories(),
        _repository.getProducts(
          categoryId: _selectedCategoryId,
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
        ),
      ]);

      if (mounted) {
        setState(() {
          _categories = results[0] as List<StoreCategoryModel>;
          _products = results[1] as List<StoreProductModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final errStr = e.toString();
          if (errStr.contains('XMLHttpRequest') || errStr.contains('ClientException')) {
            _errorMessage = 'Backend CORS Restriction:\napi.zabiraacademy.com did not include Access-Control-Allow-Origin header for browser requests.';
          } else {
            _errorMessage = 'Failed to load store: $e';
          }
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchFilteredProducts() async {
    setState(() => _isLoading = true);
    try {
      final prods = await _repository.getProducts(
        categoryId: _selectedCategoryId,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      if (mounted) {
        setState(() {
          _products = prods;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final errStr = e.toString();
          if (errStr.contains('XMLHttpRequest') || errStr.contains('ClientException')) {
            _errorMessage = 'Backend CORS Restriction:\napi.zabiraacademy.com did not include Access-Control-Allow-Origin header for browser requests.';
          } else {
            _errorMessage = 'Failed to load products: $e';
          }
          _isLoading = false;
        });
      }
    }
  }

  void _onCategorySelected(int? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _fetchFilteredProducts();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim();
    });
    _fetchFilteredProducts();
  }

  void _toggleFavorite(int productId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_favorites.contains(productId)) {
        _favorites.remove(productId);
      } else {
        _favorites.add(productId);
      }
    });
  }

  Future<void> _addToCart(StoreProductModel product) async {
    HapticFeedback.lightImpact();
    final auth = context.read<AuthController>();
    final cart = context.read<CartController>();

    final success = await cart.addItem(
      itemData: {
        'product_id': product.id,
        'product_type': 'store',
        'quantity': '1',
      },
      token: auth.currentToken,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? '${product.name} added to cart' : 'Unable to add to cart',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          backgroundColor: success ? AppColors.navyDark : Colors.red,
          duration: const Duration(seconds: 2),
          action: success
              ? SnackBarAction(
                  label: 'View Cart',
                  textColor: AppColors.gold,
                  onPressed: () => context.push(AppRoutes.cart),
                )
              : null,
        ),
      );
    }
  }

  Future<void> _buyNow(StoreProductModel product) async {
    HapticFeedback.mediumImpact();
    final auth = context.read<AuthController>();
    final cart = context.read<CartController>();

    if (!auth.isAuthenticated) {
      auth.setPendingReturnTo('/checkout');
      showAuthBottomSheet(context);
      return;
    }

    await cart.addItem(
      itemData: {
        'product_id': product.id,
        'product_type': 'store',
        'quantity': '1',
      },
      token: auth.currentToken,
    );

    if (mounted) {
      context.push('/checkout');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final auth = context.watch<AuthController>();
    final user = auth.user;
    final isAuth = auth.isAuthenticated && user != null;

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);

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
        bottomNavigationBar: const ZabiraBottomNav(selectedIndex: 3),
        body: Column(
          children: [
            // ── 1. Store Global Header ──────────────────────────────────────
            SafeArea(
              bottom: false,
              child: HomeHeader(
                isAuthenticated: isAuth,
                notificationCount: isAuth ? 2 : 0,
                cartCount: cart.itemCount,
                userInitial: isAuth && user.displayName.isNotEmpty ? user.displayName[0] : null,
                onMenuTap: () => AppDrawer.open(context),
                onCartTap: () => context.push(AppRoutes.cart),
                onSignIn: () => showAuthBottomSheet(context),
                onProfileTap: () {
                  if (isAuth) {
                    context.push(AppRoutes.studentDash);
                  } else {
                    showAuthBottomSheet(context);
                  }
                },
              ),
            ),

            // ── 2. Scrollable Store Content ─────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: AppColors.gold,
                backgroundColor: AppColors.surfaceWhite,
                onRefresh: _loadInitialData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Title & Subtitle ──────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Store',
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navyDark,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Quality products that inspire faith, productivity and a better lifestyle.',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // ── Search & Filter Bar ───────────────────────────────
                      _buildSearchBar(),

                      const SizedBox(height: AppSpacing.sm),

                      // ── Hero Banner Carousel ──────────────────────────────
                      HeroCarousel(banners: _banners),

                      const SizedBox(height: AppSpacing.md),

                      // ── Category Selector Pills / Cards ───────────────────
                      _buildCategorySelector(),

                      const SizedBox(height: AppSpacing.lg),

                      // ── Featured Products Header ──────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Featured Products',
                              style: GoogleFonts.poppins(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navyDark,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                _onCategorySelected(null);
                              },
                              child: Row(
                                children: [
                                  Text(
                                    'View All',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.navyDark,
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.navyDark),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // ── Main Products Grid ────────────────────────────────
                      _buildProductsGrid(crossAxisCount),

                      const SizedBox(height: AppSpacing.lg),

                      // ── Trust & Service Information Row ───────────────────
                      _buildTrustInfoRow(),

                      const SizedBox(height: AppSpacing.sm),

                      // ── Universal Scholarship Promotional Banner ──────────
                      const ScholarshipPromoBanner(),

                      // Bottom breathing room above floating nav bar
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search & Filter Bar ───────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navyDark.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: _onSearchChanged,
                textInputAction: TextInputAction.search,
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  color: AppColors.navyDark,
                ),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppColors.textTertiary,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              // Open filter or toggle category
            },
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navyDark.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tune_rounded, size: 16, color: AppColors.navyDark),
                  const SizedBox(width: 4),
                  Text(
                    'Filter',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Horizontal Pastel Category Cards ──────────────────────────────────────
  Widget _buildCategorySelector() {
    final categoriesList = <_StoreCategoryDisplayData>[
      const _StoreCategoryDisplayData(
        id: null,
        name: 'All',
        icon: Icons.grid_view_rounded,
        bgColor: Color(0xFFF1F5F9),
        iconColor: AppColors.navyDark,
      ),
    ];

    for (final cat in _categories) {
      final nameLower = cat.name.toLowerCase();
      Color bg;
      Color iconCol;
      IconData icon;

      if (nameLower.contains('stationery') || nameLower.contains('book')) {
        bg = const Color(0xFFFEF3C7);
        iconCol = const Color(0xFFD97706);
        icon = Icons.edit_note_rounded;
      } else if (nameLower.contains('cloth') || nameLower.contains('hoodie') || nameLower.contains('wear')) {
        bg = const Color(0xFFDCFCE7);
        iconCol = const Color(0xFF16A34A);
        icon = Icons.checkroom_rounded;
      } else if (nameLower.contains('gift')) {
        bg = const Color(0xFFF3E8FF);
        iconCol = const Color(0xFF9333EA);
        icon = Icons.card_giftcard_rounded;
      } else if (nameLower.contains('perfume') || nameLower.contains('attar') || nameLower.contains('oud')) {
        bg = const Color(0xFFFCE7F3);
        iconCol = const Color(0xFFDB2777);
        icon = Icons.spa_rounded;
      } else {
        bg = const Color(0xFFE0F2FE);
        iconCol = const Color(0xFF0284C7);
        icon = Icons.mosque_rounded;
      }

      categoriesList.add(_StoreCategoryDisplayData(
        id: cat.id,
        name: cat.name,
        icon: icon,
        bgColor: bg,
        iconColor: iconCol,
      ));
    }

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: categoriesList.length,
        itemBuilder: (context, index) {
          final item = categoriesList[index];
          final isSelected = _selectedCategoryId == item.id;

          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () => _onCategorySelected(item.id),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.navyDark : item.bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.gold : Colors.transparent,
                        width: isSelected ? 2.0 : 0.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.navyDark.withValues(alpha: isSelected ? 0.2 : 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        item.icon,
                        color: isSelected ? AppColors.gold : item.iconColor,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 66,
                    child: Text(
                      item.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? AppColors.navyDark : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Products Grid ─────────────────────────────────────────────────────────
  Widget _buildProductsGrid(int crossAxisCount) {
    if (_isLoading) {
      return _buildLoadingShimmer(crossAxisCount);
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_products.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.53, // Provides ample consistent room for image + title + price + 2 button rows
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return _StoreProductCard(
          product: product,
          isFavorite: _favorites.contains(product.id),
          onFavoriteToggle: () => _toggleFavorite(product.id),
          onViewDetails: () => context.push('/store/${product.id}'),
          onAddToCart: () => _addToCart(product),
          onBuyNow: () => _buyNow(product),
        );
      },
    );
  }

  // ── Trust & Service Badges ────────────────────────────────────────────────
  Widget _buildTrustInfoRow() {
    const trustItems = [
      _TrustItem(
        icon: Icons.local_shipping_outlined,
        title: 'Fast Delivery',
        desc: 'Across India',
      ),
      _TrustItem(
        icon: Icons.verified_user_outlined,
        title: 'Secure Payment',
        desc: '100% Safe & Secure',
      ),
      _TrustItem(
        icon: Icons.workspace_premium_outlined,
        title: 'Premium Quality',
        desc: 'Carefully Selected',
      ),
      _TrustItem(
        icon: Icons.assignment_return_outlined,
        title: 'Easy Returns',
        desc: 'Hassle Free',
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: trustItems.map((item) {
          return Expanded(
            child: Column(
              children: [
                Icon(item.icon, size: 22, color: AppColors.navyDark),
                const SizedBox(height: 4),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.desc,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 8.5,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoadingShimmer(int crossAxisCount) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.53,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.gold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Unable to load Store',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _errorMessage ?? 'An error occurred while connecting to the Store.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: _loadInitialData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyDark,
                foregroundColor: AppColors.gold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No Products Found',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try selecting another category or refining your search term.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Redesigned Store Product Card:
/// - Exact fixed height & aspect ratio
/// - Top-left rating badge, top-right favorite heart button
/// - Title with 2 fixed lines, price & strikethrough price
/// - 3 actions in 2 rows:
///     Row 1: [Add to Cart (50%)] [View Details (50%)] (compact black/white style)
///     Row 2: [Buy Now (100% full-width orange primary CTA)]
class _StoreProductCard extends StatelessWidget {
  const _StoreProductCard({
    required this.product,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onViewDetails,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  final StoreProductModel product;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onViewDetails;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.fullThumbnailUrl;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF07192F).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Product Image Area ──────────────────────────────────────────
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.gold,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, _) => _buildFallbackImage(product),
                          )
                        : _buildFallbackImage(product),
                  ),
                ),

                // ── Top-Left: Rating Badge ──────────────────────────────────
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 13, color: AppColors.gold),
                        const SizedBox(width: 2),
                        Text(
                          '4.8',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navyDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Top-Right: Favorite Heart Button ────────────────────────
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onFavoriteToggle,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 15,
                          color: isFavorite ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 2. Content & Pricing Area ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Title (2-line fixed height)
                SizedBox(
                  height: 32,
                  child: Text(
                    product.name,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 3),

                // Price Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      product.formattedPrice,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyDark,
                      ),
                    ),
                    if (product.formattedOriginalPrice != null) ...[
                      const SizedBox(width: 5),
                      Text(
                        product.formattedOriginalPrice!,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // ── 3. Action Buttons Section (3 buttons in 2 rows) ────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: [Add to Cart (50%)] [View Details (50%)]
                Row(
                  children: [
                    // Add to Cart (50%)
                    Expanded(
                      child: SizedBox(
                        height: 30,
                        child: OutlinedButton.icon(
                          onPressed: onAddToCart,
                          icon: const Icon(Icons.shopping_cart_outlined, size: 12),
                          label: Text(
                            'Add to Cart',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF071B36),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // View Details (50%)
                    Expanded(
                      child: SizedBox(
                        height: 30,
                        child: OutlinedButton.icon(
                          onPressed: onViewDetails,
                          icon: const Icon(Icons.info_outline_rounded, size: 12),
                          label: Text(
                            'View Details',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF071B36),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Row 2: [Buy Now (100% full-width orange primary CTA)]
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: ElevatedButton(
                    onPressed: onBuyNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC8C1A),
                      foregroundColor: const Color(0xFF071B36),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Buy Now',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackImage(StoreProductModel product) {
    if (product.localAssetFallback != null) {
      return Image.asset(
        product.localAssetFallback!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, _) => const _StoreFallbackIcon(),
      );
    }
    return const _StoreFallbackIcon();
  }
}

class _StoreFallbackIcon extends StatelessWidget {
  const _StoreFallbackIcon();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.shopping_bag_outlined,
        size: 32,
        color: Color(0xFF94A3B8),
      ),
    );
  }
}

class _StoreCategoryDisplayData {
  const _StoreCategoryDisplayData({
    required this.id,
    required this.name,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });

  final int? id;
  final String name;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
}

class _TrustItem {
  const _TrustItem({
    required this.icon,
    required this.title,
    required this.desc,
  });

  final IconData icon;
  final String title;
  final String desc;
}
