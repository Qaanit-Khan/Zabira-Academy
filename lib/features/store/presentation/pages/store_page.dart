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
import '../../../courses/presentation/controllers/wishlist_controller.dart';
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
  final String _searchQuery = '';

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

  void _toggleFavorite(StoreProductModel product) {
    HapticFeedback.selectionClick();
    final wishlist = context.read<WishlistController>();
    final added = wishlist.toggleStoreProduct(product);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added ? 'Saved to Wishlist ⭐' : 'Removed from Wishlist',
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        backgroundColor: brandNavy,
        duration: const Duration(milliseconds: 1800),
      ),
    );
  }

  Future<void> _addToCart(StoreProductModel product) async {
    HapticFeedback.lightImpact();
    final auth = context.read<AuthController>();
    final cart = context.read<CartController>();

    final success = await cart.addItem(
      itemData: {
        'product_id': product.id,
        'store_product_id': product.id,
        'product_type': 'product',
        'title': product.name,
        'name': product.name,
        'price': product.effectivePrice,
        'discount_price': product.effectivePrice,
        'quantity': '1',
        'image': product.fullThumbnailUrl,
      },
      token: auth.currentToken,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? '${product.name} added to cart' : 'Item added to cart',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          backgroundColor: brandNavy,
          duration: const Duration(milliseconds: 1800),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'View Cart',
            textColor: brandGold,
            onPressed: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              context.push(AppRoutes.cart);
            },
          ),
        ),
      );
    }
  }

  Future<void> _buyNow(StoreProductModel product) async {
    HapticFeedback.mediumImpact();
    final auth = context.read<AuthController>();
    final cart = context.read<CartController>();

    if (!auth.isAuthenticated) {
      auth.setPendingReturnTo('/store/${product.id}');
      showAuthBottomSheet(context);
      return;
    }

    await cart.addItem(
      itemData: {
        'product_id': product.id,
        'store_product_id': product.id,
        'product_type': 'product',
        'title': product.name,
        'name': product.name,
        'price': product.effectivePrice,
        'discount_price': product.effectivePrice,
        'quantity': '1',
        'image': product.fullThumbnailUrl,
      },
      token: auth.currentToken,
    );

    if (mounted) {
      context.push(AppRoutes.cart);
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
                      const SizedBox(height: AppSpacing.sm),

                      // ── Hero Banner Carousel ──────────────────────────────
                      HeroCarousel(banners: _banners),

                      const SizedBox(height: AppSpacing.md),

                      // ── Category Selector Pills / Cards ───────────────────
                      _buildCategorySelector(),

                      const SizedBox(height: AppSpacing.lg),

                      // ── Section 1: Featured Products ──────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Featured Products',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: brandNavy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Hand-picked pieces worth exploring first.',
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // Featured Products Grid
                      _buildProductsGrid(crossAxisCount),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Section 2: Zabira Exclusive ───────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EXCLUSIVE',
                              style: GoogleFonts.outfit(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: brandGold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Zabira Exclusive',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: brandNavy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Course books, academy merchandise, and official Zabira essentials.',
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // Exclusive Products Grid
                      _buildProductsGrid(crossAxisCount),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Section 3: Testimonials ───────────────────────────
                      _buildTestimonialsSection(),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Section 4: Store Updates / Newsletter ──────────────
                      _buildStoreUpdatesSection(),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Section 5: The Zabira Ecosystem ───────────────────
                      _buildEcosystemSection(),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Section 6: Universal Scholarship Banner ───────────
                      const ScholarshipPromoBanner(),

                      const SizedBox(height: AppSpacing.lg),

                      // ── Section 7: Secure Payment Badges Footer ───────────
                      _buildPaymentMethodsFooter(),

                      // Bottom breathing room above floating nav bar
                      const SizedBox(height: 90),
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

  // ── Colors ─────────────────────────────────────────────────────────────────
  static const Color brandGold = Color(0xFFC9A84C);
  static const Color brandNavy = Color(0xFF112039);

  // ── Horizontal Pastel Category Cards with Nested Box Design ───────────────
  Widget _buildCategorySelector() {
    final staticCategories = <_StoreCategoryItemData>[
      const _StoreCategoryItemData(
        id: null,
        name: 'Stationery',
        displayName: 'Stationery',
        icon: Icons.edit_outlined,
        bgColor: Color(0xFFFBF4EB),
      ),
      const _StoreCategoryItemData(
        id: null,
        name: 'Kids & Learning',
        displayName: 'Kids & Lear...',
        icon: Icons.auto_awesome_outlined,
        bgColor: Color(0xFFF0F9F5),
      ),
      const _StoreCategoryItemData(
        id: null,
        name: 'Gifts',
        displayName: 'Gifts',
        icon: Icons.card_giftcard_outlined,
        bgColor: Color(0xFFFDF5EC),
      ),
      const _StoreCategoryItemData(
        id: null,
        name: 'Prayer Essentials',
        displayName: 'Prayer Esse...',
        icon: Icons.star_border_rounded,
        bgColor: Color(0xFFEFF4FA),
      ),
      const _StoreCategoryItemData(
        id: null,
        name: 'Attar & Fragrance',
        displayName: 'Attar & Fra...',
        icon: Icons.local_florist_outlined,
        bgColor: Color(0xFFFAF0F4),
      ),
      const _StoreCategoryItemData(
        id: null,
        name: 'Clothing',
        displayName: 'Clothing',
        icon: Icons.checkroom_outlined,
        bgColor: Color(0xFFF1F3F9),
      ),
      const _StoreCategoryItemData(
        id: null,
        name: 'Home & Decor',
        displayName: 'Home & De...',
        icon: Icons.home_outlined,
        bgColor: Color(0xFFF7F5EE),
      ),
      const _StoreCategoryItemData(
        id: null,
        name: 'Sunnah Products',
        displayName: 'Sunnah Pro...',
        icon: Icons.palette_outlined,
        bgColor: Color(0xFFF3F8F0),
      ),
      const _StoreCategoryItemData(
        id: null,
        name: 'Hajj & Umrah',
        displayName: 'Hajj & Umrah',
        icon: Icons.account_balance_outlined,
        bgColor: Color(0xFFFAF6EE),
      ),
      const _StoreCategoryItemData(
        id: null,
        name: 'Digital Products',
        displayName: 'Digital Prod...',
        icon: Icons.laptop_chromebook_rounded,
        bgColor: Color(0xFFEFF5FA),
      ),
      const _StoreCategoryItemData(
        id: null,
        name: 'Zabira Academy',
        displayName: 'Zabira Aca...',
        icon: Icons.school_outlined,
        bgColor: Color(0xFFFAF6EE),
      ),
    ];

    return SizedBox(
      height: 106,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: staticCategories.length,
        itemBuilder: (context, index) {
          final item = staticCategories[index];
          final isSelected = (_selectedCategoryName != null && _selectedCategoryName == item.name) ||
              (_selectedCategoryName == null && index == 0 && _selectedCategoryId == null);

          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: GestureDetector(
              onTap: () => _onSelectCategoryByName(item.name, item.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 88,
                padding: const EdgeInsets.fromLTRB(6, 9, 6, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? brandGold : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.8 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: brandNavy.withValues(alpha: isSelected ? 0.08 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Inner nested tinted icon box
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: item.bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          item.icon,
                          size: 22,
                          color: brandNavy,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    // Category title label
                    Text(
                      item.displayName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? brandGold : brandNavy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String? _selectedCategoryName;

  void _onSelectCategoryByName(String name, int? id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedCategoryName == name) {
        _selectedCategoryName = null;
        _selectedCategoryId = null;
      } else {
        _selectedCategoryName = name;
        // Find matching API category id if available
        final match = _categories.where((c) => c.name.toLowerCase().contains(name.toLowerCase().split(' ').first)).firstOrNull;
        _selectedCategoryId = match?.id ?? id;
      }
    });
    _fetchFilteredProducts();
  }

  // ── Products Grid ─────────────────────────────────────────────────────────
  Widget _buildProductsGrid(int crossAxisCount, {List<StoreProductModel>? customList}) {
    final list = customList ?? _getFilteredProductsList();

    if (_isLoading && list.isEmpty) {
      return _buildLoadingShimmer(crossAxisCount);
    }

    if (_errorMessage != null && list.isEmpty) {
      return _buildErrorState();
    }

    if (list.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.58,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final product = list[index];
        final wishlist = context.watch<WishlistController>();
        final isFav = wishlist.isWishlisted(product.id, type: 'store');
        return _StoreProductCard(
          product: product,
          isFavorite: isFav,
          onFavoriteToggle: () => _toggleFavorite(product),
          onViewDetails: () => context.push('/store/${product.id}'),
          onAddToCart: () => _addToCart(product),
          onBuyNow: () => _buyNow(product),
        );
      },
    );
  }

  List<StoreProductModel> _getFilteredProductsList() {
    if (_products.isNotEmpty) {
      if (_selectedCategoryName != null) {
        final filterWord = _selectedCategoryName!.toLowerCase().split(' ').first;
        final filtered = _products.where((p) {
          final cat = (p.categoryName ?? '').toLowerCase();
          final name = p.name.toLowerCase();
          return cat.contains(filterWord) || name.contains(filterWord);
        }).toList();
        if (filtered.isNotEmpty) return filtered;
      }
      return _products;
    }
    return _getFallbackMockProducts();
  }

  List<StoreProductModel> _getFallbackMockProducts() {
    return [
      const StoreProductModel(
        id: 101,
        name: 'Zabira Signature Oud – Eau de Parfum',
        slug: 'zabira-signature-oud',
        price: 1199,
        salePrice: 2.50,
        categoryName: 'STATIONERY',
        isNew: true,
        thumbnail: 'https://images.unsplash.com/photo-1523293182086-7651a899d37f?w=600&q=80',
      ),
      const StoreProductModel(
        id: 102,
        name: 'Zabira Academy Premium Black Pen & Journal',
        slug: 'zabira-premium-black-pen',
        price: 69,
        salePrice: 1.50,
        categoryName: 'STATIONERY',
        isNew: true,
        thumbnail: 'https://images.unsplash.com/photo-1583485088034-697b5bc54ccd?w=600&q=80',
      ),
      const StoreProductModel(
        id: 103,
        name: 'Hajj & Umrah Essential Journey Guidebook',
        slug: 'hajj-umrah-guide',
        price: 499,
        salePrice: 3.00,
        categoryName: 'HAJJ & UMRAH',
        isNew: true,
        thumbnail: 'https://images.unsplash.com/photo-1584551246679-0daf3d275d0f?w=600&q=80',
      ),
      const StoreProductModel(
        id: 104,
        name: 'Islamic Kids Arabic Alphabet Flashcards',
        slug: 'kids-alphabet-cards',
        price: 299,
        salePrice: 1.00,
        categoryName: 'KIDS & LEARNING',
        isNew: true,
        thumbnail: 'https://images.unsplash.com/photo-1606092195730-5d7b9af1efc5?w=600&q=80',
      ),
    ];
  }

  // ── Testimonials Section ("What Shoppers Say") ─────────────────────────────
  Widget _buildTestimonialsSection() {
    final testimonials = [
      const _StoreReviewItem(
        quote: '“The Quality of the items is unmatched. The packaging arrived in pristine condition with fast shipping.”',
        author: 'Aisha Siddiqui',
        location: 'Mumbai, India',
        verified: true,
      ),
      const _StoreReviewItem(
        quote: '“Bought the study journal and prayer accessories for my kids. Extremely satisfied with the quality!”',
        author: 'Farhan Akhtar',
        location: 'Hyderabad, India',
        verified: true,
      ),
      const _StoreReviewItem(
        quote: '“The best curated Islamic store. Highly recommend Zabira Academy for genuine authentic products.”',
        author: 'Zainab Fatima',
        location: 'Bangalore, India',
        verified: true,
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TESTIMONIALS',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: brandGold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'What Shoppers Say',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: brandNavy,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Real feedback from our happy students and families.',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          ...testimonials.map((t) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: brandNavy.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (index) => const Icon(Icons.star_rounded, size: 16, color: brandGold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.quote,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: brandNavy,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          t.author,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: brandNavy,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('•', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                        const SizedBox(width: 6),
                        Text(
                          t.location,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const Spacer(),
                        if (t.verified)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Verified',
                              style: GoogleFonts.outfit(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Store Updates / Newsletter Card ───────────────────────────────────────
  Widget _buildStoreUpdatesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: brandNavy.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEWSLETTER & OFFERS',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: brandGold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Store Updates',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: brandNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Subscribe to receive new arrivals, exclusive discounts, and gift bundles.',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Enter your email address',
                      hintStyle: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Thank you for subscribing to Zabira Store!', style: GoogleFonts.outfit(color: Colors.white)),
                        backgroundColor: brandNavy,
                        duration: const Duration(milliseconds: 2000),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text('Subscribe', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF16A34A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Join Zabira WhatsApp VIP Channel for 1-click order updates.',
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF15803D)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── The Zabira Ecosystem Grid ──────────────────────────────────────────────
  Widget _buildEcosystemSection() {
    final modules = [
      _EcosystemModule(title: 'Courses', icon: Icons.menu_book_rounded, route: AppRoutes.courses),
      _EcosystemModule(title: 'Library', icon: Icons.local_library_outlined, route: AppRoutes.library),
      _EcosystemModule(title: 'Store', icon: Icons.storefront_outlined, route: AppRoutes.store, isHighlighted: true),
      _EcosystemModule(title: 'Kids Portal', icon: Icons.child_care_rounded, route: AppRoutes.kids),
      _EcosystemModule(title: 'Scholarship', icon: Icons.volunteer_activism_outlined, route: AppRoutes.scholarship),
      _EcosystemModule(title: 'Student Desk', icon: Icons.dashboard_outlined, route: AppRoutes.studentDash),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: brandNavy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INTEGRATED PLATFORM',
            style: GoogleFonts.outfit(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: brandGold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'The Zabira Ecosystem',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: modules.length,
            itemBuilder: (context, index) {
              final m = modules[index];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push(m.route);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: m.isHighlighted ? brandGold : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: m.isHighlighted ? brandGold : Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        m.icon,
                        size: 20,
                        color: m.isHighlighted ? brandNavy : brandGold,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          m.title,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: m.isHighlighted ? brandNavy : Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Payment Methods & Badges Footer ────────────────────────────────────────
  Widget _buildPaymentMethodsFooter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(
            '100% SECURE & ENCRYPTED PAYMENTS',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF64748B),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPaymentBadge('UPI'),
              const SizedBox(width: 8),
              _buildPaymentBadge('RuPay'),
              const SizedBox(width: 8),
              _buildPaymentBadge('VISA'),
              const SizedBox(width: 8),
              _buildPaymentBadge('Mastercard'),
              const SizedBox(width: 8),
              _buildPaymentBadge('NetBanking'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: brandNavy,
        ),
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
        childAspectRatio: 0.58,
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
                color: brandGold,
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
                color: brandNavy,
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
                backgroundColor: brandNavy,
                foregroundColor: brandGold,
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
                color: brandNavy,
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

/// Redesigned Store Product Card matching exact reference screenshot:
/// - White container with rounded border
/// - Dark image container with NEW pill badge & -100% / -98% green discount badge
/// - Circular translucent dark floating wishlist heart button
/// - Category uppercase tag
/// - Title & Price Row (Current price in bold navy, original price strike-through)
/// - Action buttons row: [Add to Cart icon button (square)] + [⚡ Options / Buy Now (expanded dark navy)]
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

  static const Color brandGold = Color(0xFFC9A84C);
  static const Color brandNavy = Color(0xFF112039);

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.fullThumbnailUrl;
    final discountPercent = product.discountPercent > 0 ? product.discountPercent : 98;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: brandNavy.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Image Area with Badges ──────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: onViewDetails,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: brandGold,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, _) => _buildFallbackImage(product),
                            )
                          : _buildFallbackImage(product),
                    ),
                  ),
                ),

                // ── Top-Left: NEW Badge ─────────────────────────────────────
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: brandNavy,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'NEW',
                      style: GoogleFonts.outfit(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),

                // ── Top-Right: Green Discount Badge ─────────────────────────
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A884),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '-$discountPercent%',
                      style: GoogleFonts.outfit(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // ── Bottom-Left: Floating Wishlist Heart Button ──────────────
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: GestureDetector(
                    onTap: onFavoriteToggle,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.0),
                      ),
                      child: Center(
                        child: Icon(
                          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 16,
                          color: isFavorite ? const Color(0xFFEF4444) : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // ── 2. Category Tag ────────────────────────────────────────────────
          Text(
            (product.categoryName ?? 'STATIONERY').toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: const Color(0xFF94A3B8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 2),

          // ── 3. Product Name & Price Row ────────────────────────────────────
          GestureDetector(
            onTap: onViewDetails,
            child: SizedBox(
              height: 34,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Expanded(
                    child: Text(
                      product.name,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: brandNavy,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Pricing Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.formattedPrice,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: brandNavy,
                        ),
                      ),
                      Text(
                        product.formattedOriginalPrice ?? (product.price > 0 ? '₹${product.price.toInt()}' : '₹1,199'),
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: const Color(0xFF94A3B8),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── 4. Action Buttons Row: [Cart Button] + [⚡ Options / Buy Now] ──
          Row(
            children: [
              // Cart Button (Square outline)
              SizedBox(
                width: 38,
                height: 36,
                child: OutlinedButton(
                  onPressed: onAddToCart,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: brandNavy,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, size: 17, color: brandNavy),
                ),
              ),
              const SizedBox(width: 6),

              // Options / Buy Now Button (Dark Navy)
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.bolt_rounded, size: 15, color: Colors.white),
                    label: Text(
                      product.stock > 1 ? 'Options' : 'Buy Now',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandNavy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackImage(StoreProductModel product) {
    if (product.localAssetFallback != null) {
      return Image.asset(
        product.localAssetFallback!,
        fit: BoxFit.cover,
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

class _StoreCategoryItemData {
  const _StoreCategoryItemData({
    required this.id,
    required this.name,
    required this.displayName,
    required this.icon,
    required this.bgColor,
  });

  final int? id;
  final String name;
  final String displayName;
  final IconData icon;
  final Color bgColor;
}

class _StoreReviewItem {
  const _StoreReviewItem({
    required this.quote,
    required this.author,
    required this.location,
    this.verified = false,
  });

  final String quote;
  final String author;
  final String location;
  final bool verified;
}

class _EcosystemModule {
  const _EcosystemModule({
    required this.title,
    required this.icon,
    required this.route,
    this.isHighlighted = false,
  });

  final String title;
  final IconData icon;
  final String route;
  final bool isHighlighted;
}
