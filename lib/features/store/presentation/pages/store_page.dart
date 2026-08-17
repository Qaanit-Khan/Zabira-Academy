import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../controllers/cart_controller.dart';
import '../../data/models/store_category_model.dart';
import '../../data/models/store_product_model.dart';
import '../../data/repositories/store_repository.dart';

/// Zabira Academy — Store Page
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

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);

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
        body: SafeArea(
          child: Column(
            children: [
              // ── 1. Store Header ─────────────────────────────────────────────
              _buildStoreHeader(context, cart.itemCount),

              // ── 2. Search & Filter Bar ──────────────────────────────────────
              _buildSearchBar(),

              // ── 3. Category Selector Pills ──────────────────────────────────
              _buildCategorySelector(),

              const SizedBox(height: AppSpacing.sm),

              // ── 4. Main Products Content ────────────────────────────────────
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.gold,
                  backgroundColor: AppColors.surfaceWhite,
                  onRefresh: _loadInitialData,
                  child: _buildBody(crossAxisCount),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreHeader(BuildContext context, int cartCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderLight.withAlpha(150),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, size: 24, color: AppColors.navyDark),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            tooltip: 'Menu',
          ),
          const SizedBox(width: AppSpacing.xs),
          GestureDetector(
            onTap: () => context.go(AppRoutes.home),
            child: Image.asset(
              'assets/images/branding/zabira_logo_horizontal.png',
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (context, error, _) => Text(
                'ZABIRA STORE',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyDark,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
          const Spacer(),
          // Cart Icon with Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined, size: 20, color: AppColors.navyDark),
                  onPressed: () => context.push(AppRoutes.cart),
                  tooltip: 'Cart',
                ),
              ),
              if (cartCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Center(
                      child: Text(
                        cartCount > 99 ? '99+' : '$cartCount',
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navyDark,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xs),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDark.withAlpha(8),
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
            fontSize: 14,
            color: AppColors.navyDark,
          ),
          decoration: InputDecoration(
            hintText: 'Search books, stationery, perfumes...',
            hintStyle: GoogleFonts.outfit(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
        itemCount: _categories.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final isSelected = isAll ? _selectedCategoryId == null : _selectedCategoryId == _categories[index - 1].id;
          final title = isAll ? 'All Items' : _categories[index - 1].name;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => _onCategorySelected(isAll ? null : _categories[index - 1].id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.navyDark : AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.navyDark : AppColors.borderLight,
                    width: 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.navyDark.withAlpha(25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.gold : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(int crossAxisCount) {
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
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.xxl),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        return _StoreGridProductCard(
          product: _products[index],
          onTap: () {
            context.push('/store/${_products[index].id}');
          },
        );
      },
    );
  }

  Widget _buildLoadingShimmer(int crossAxisCount) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(height: 10, width: 60, color: AppColors.surfaceLight),
                      Container(height: 14, width: 110, color: AppColors.surfaceLight),
                      Container(height: 12, width: 50, color: AppColors.surfaceLight),
                    ],
                  ),
                ),
              ),
            ],
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 54, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Unable to load Store',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _errorMessage ?? 'An error occurred while connecting to the Zabira Store.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _loadInitialData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyDark,
                foregroundColor: AppColors.gold,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w700)),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 52, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No Products Found',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Try selecting another category or refining your search term.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Individual Product Grid Card
class _StoreGridProductCard extends StatefulWidget {
  const _StoreGridProductCard({
    required this.product,
    required this.onTap,
  });

  final StoreProductModel product;
  final VoidCallback onTap;

  @override
  State<_StoreGridProductCard> createState() => _StoreGridProductCardState();
}

class _StoreGridProductCardState extends State<_StoreGridProductCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final imageUrl = p.fullThumbnailUrl;

    return Semantics(
      button: true,
      label: 'View details for ${p.name}',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _pressed ? AppColors.gold.withAlpha(120) : AppColors.borderLight,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyDark.withAlpha(8),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Thumbnail Container with Badges ─────────────────────────
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FA),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
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
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.gold,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, _) => _buildFallbackImage(p),
                                )
                              : _buildFallbackImage(p),
                        ),
                      ),

                      // Badge Tag (e.g. Sale / New / Bestseller)
                      if (p.hasDiscount)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${p.discountPercent}% OFF',
                              style: GoogleFonts.outfit(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      else if (p.isNew)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'NEW',
                              style: GoogleFonts.outfit(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      else if (p.isBestseller)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'BESTSELLER',
                              style: GoogleFonts.outfit(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navyDark,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Info Area ───────────────────────────────────────────────
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.category,
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              p.name,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navyDark,
                                height: 1.15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),

                        // Price Row + Cart Circle
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (p.formattedOriginalPrice != null)
                                  Text(
                                    p.formattedOriginalPrice!,
                                    style: GoogleFonts.outfit(
                                      fontSize: 10.5,
                                      color: AppColors.textTertiary,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                Text(
                                  p.formattedPrice,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navyDark,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: AppColors.gold,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 14,
                                  color: AppColors.navyDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackImage(StoreProductModel product) {
    if (product.localAssetFallback != null) {
      return Image.asset(
        product.localAssetFallback!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, _) => const _CodeFallbackIcon(),
      );
    }
    return const _CodeFallbackIcon();
  }
}

class _CodeFallbackIcon extends StatelessWidget {
  const _CodeFallbackIcon();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.auto_stories_rounded,
        size: 32,
        color: AppColors.navyDark,
      ),
    );
  }
}
