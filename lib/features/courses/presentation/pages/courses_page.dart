import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
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
import '../../../store/presentation/controllers/cart_controller.dart';
import '../../data/models/course_api_model.dart';
import '../../data/models/course_category_api_model.dart';
import '../../data/repositories/course_repository.dart';
import '../controllers/wishlist_controller.dart';
import '../widgets/course_filter_sheet.dart';

/// Zabira Academy — Courses Page
class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final CourseRepository _repository = CourseRepository();

  List<CourseCategoryApiModel> _categories = List.from(CourseRepository.defaultCategories);
  List<CourseApiModel> _courses = List.from(CourseRepository.defaultCourses);
  List<CourseApiModel> _filteredCourses = List.from(CourseRepository.defaultCourses);

  final CourseFilterState _filterState = CourseFilterState();
  int? _selectedCategoryId; // null = All

  late final List<HeroBannerModel> _banners;

  static const Color brandGold = Color(0xFFC9A84C);
  static const Color brandNavy = Color(0xFF112039);

  @override
  void initState() {
    super.initState();
    _courses = List.from(CourseRepository.defaultCourses);
    _filteredCourses = List.from(CourseRepository.defaultCourses);
    _categories = List.from(CourseRepository.defaultCategories);
    _banners = HeroBannerRepository.getBannersForSection(
      section: HeroBannerSection.courses,
      onCoursesTap: () {},
      onKidsPortalTap: () => context.push(AppRoutes.kids),
      onStoreTap: () => context.push(AppRoutes.store),
      onHero4Tap: () {},
    );
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        _fetchAllCourses(),
        _repository.getCategories(),
      ]);

      if (mounted) {
        setState(() {
          final fetchedCourses = results[0] as List<CourseApiModel>;
          final fetchedCategories = results[1] as List<CourseCategoryApiModel>;
          if (fetchedCourses.isNotEmpty) {
            _courses = fetchedCourses;
          }
          if (fetchedCategories.isNotEmpty) {
            _categories = fetchedCategories;
          }
          _applyFilterAndSort();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _courses = List.from(CourseRepository.defaultCourses);
          _applyFilterAndSort();
        });
      }
    }
  }

  Future<List<CourseApiModel>> _fetchAllCourses() async {
    try {
      return await _repository.getCourses(limit: 50);
    } catch (_) {
      return CourseRepository.defaultCourses;
    }
  }

  void _applyFilterAndSort() {
    List<CourseApiModel> result = List.from(_courses);

    // Category filter
    final catId = _filterState.categoryId ?? _selectedCategoryId;
    if (catId != null) {
      result = result.where((c) => c.categoryId == catId).toList();
    }

    if (_filterState.level != null && _filterState.level != 'All') {
      result = result.where((c) => c.level.toLowerCase() == _filterState.level!.toLowerCase()).toList();
    }

    if (_filterState.language != null && _filterState.language != 'All') {
      result = result.where((c) {
        final selLang = _filterState.language!.toLowerCase();
        return c.language.toLowerCase().contains(selLang) ||
            c.languages.any((l) => l.toLowerCase().contains(selLang));
      }).toList();
    }

    // Sort order
    switch (_filterState.sort) {
      case 'popular':
        result.sort((a, b) => (b.isPopular ? 1 : 0).compareTo(a.isPopular ? 1 : 0));
        break;
      case 'rating':
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'newest':
        result.sort((a, b) => (b.isNew ? 1 : 0).compareTo(a.isNew ? 1 : 0));
        break;
      case 'price_low':
        result.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
        break;
      case 'price_high':
        result.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
        break;
      default:
        break;
    }

    setState(() {
      _filteredCourses = result;
    });
  }

  void _onCategorySelected(int? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _applyFilterAndSort();
  }

  Future<void> _addToCart(CourseApiModel course) async {
    HapticFeedback.mediumImpact();
    final cart = context.read<CartController>();
    final auth = context.read<AuthController>();

    if (!auth.isAuthenticated) {
      auth.setPendingReturnTo('/courses/${course.id}');
      showAuthBottomSheet(context);
      return;
    }

    final success = await cart.addItem(
      itemData: {
        'course_id': course.id,
        'title': course.title,
        'name': course.title,
        'image': course.fullThumbnailUrl ?? course.fullHeroBannerUrl,
        'product_type': 'course',
        'quantity': '1',
        'price': course.effectivePrice,
        'discount_price': course.effectivePrice,
      },
      token: auth.currentToken,
    );

    if (!mounted) return;

    // Fast auto-dismissing toast
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: brandGold, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                success ? 'Added "${course.title}" (₹${course.effectivePrice.toInt()})' : 'Item added to cart',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: brandNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(milliseconds: 1800),
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

  void _toggleFavorite(CourseApiModel course) {
    HapticFeedback.lightImpact();
    final wishlist = context.read<WishlistController>();
    final added = wishlist.toggleCourse(course);
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

  void _showQuickEnrollModal(CourseApiModel course) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuickEnrollSheet(
        course: course,
        onEnrollNow: (selectedPlan) {
          Navigator.pop(ctx);
          final auth = context.read<AuthController>();
          if (!auth.isAuthenticated) {
            auth.setPendingReturnTo('/courses/${course.id}');
            showAuthBottomSheet(context);
            return;
          }
          final effectivePrice = selectedPlan == 'monthly'
              ? (course.paymentOptions.length > 1 && course.paymentOptions[1].installmentAmount != null
                  ? course.paymentOptions[1].installmentAmount!
                  : (course.effectivePrice / 6).ceilToDouble())
              : course.effectivePrice;

          context.push(
            '/checkout',
            extra: {
              'orderId': course.id,
              'productType': 'course',
              'title': course.title,
              'amount': effectivePrice,
              'instructor': course.instructorName,
              'category': course.categoryName,
              'level': course.level,
              'language': course.language,
              'duration': course.duration,
              'mode': course.courseType,
              'planLabel': selectedPlan == 'monthly' ? 'Monthly Installment' : 'Pay in Full',
              'courseId': course.id,
            },
          );
        },
        onAddToCart: () {
          Navigator.pop(ctx);
          _addToCart(course);
        },
      ),
    );
  }

  void _openFilterSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CourseFilterSheet(
        currentState: _filterState,
        categories: _categories,
        onApply: (newState) {
          setState(() {
            _filterState.categoryId = newState.categoryId;
            _filterState.level = newState.level;
            _filterState.language = newState.language;
            _filterState.sort = newState.sort;
            if (newState.categoryId != null) {
              _selectedCategoryId = newState.categoryId;
            }
          });
          _applyFilterAndSort();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        context.go(AppRoutes.home);
      },
      child: Scaffold(
        extendBody: true,
        key: _scaffoldKey,
        drawer: const AppDrawer(),
        backgroundColor: const Color(0xFFF8FAFC),
        bottomNavigationBar: const ZabiraBottomNav(selectedIndex: 0),
        floatingActionButton: _buildFloatingFilterButton(),
        body: Column(
          children: [
            // ── 1. Top Header: Exact HomeHeader ─────────────────────────────
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

            // ── 2. Scrollable Body Content ──────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: brandGold,
                backgroundColor: Colors.white,
                onRefresh: _loadInitialData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Hero Banner Carousel ──────────────────────────────
                      HeroCarousel(banners: _banners),

                      const SizedBox(height: AppSpacing.sm),

                      // ── Store-style Horizontal Category Slider ─────────────
                      _buildCategorySlider(),

                      const SizedBox(height: AppSpacing.md),

                      // ── Programs Found Indicator ("14 Programs") ──────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Row(
                          children: [
                            Text(
                              '${_filteredCourses.length} Programs',
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF475569),
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _openFilterSheet,
                              child: Row(
                                children: [
                                  const Icon(Icons.tune_rounded, size: 15, color: brandNavy),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Filter',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: brandNavy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // ── Courses Content List ────────────────────────────────
                      _buildCoursesList(),

                      const SizedBox(height: AppSpacing.md),

                      // ── Universal Scholarship Promo Banner ──────────────────
                      const ScholarshipPromoBanner(),

                      // Bottom spacing for navigation dock
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

  // ── Floating Action Button for Web-style Filter Window ─────────────────────
  Widget _buildFloatingFilterButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 75),
      child: FloatingActionButton.extended(
        onPressed: _openFilterSheet,
        backgroundColor: brandNavy,
        elevation: 4,
        icon: const Icon(Icons.tune_rounded, color: brandGold, size: 18),
        label: Text(
          'Filter',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ── Store-Style Pastel Horizontal Category Slider ──────────────────────────
  Widget _buildCategorySlider() {
    final categoriesList = <_CourseCategoryDisplayData>[
      _CourseCategoryDisplayData(
        id: null,
        name: 'All',
        icon: Icons.grid_view_rounded,
        bgColor: const Color(0xFFF1F5F9),
        iconColor: brandNavy,
      ),
    ];

    for (final cat in _categories) {
      final nameLower = cat.name.toLowerCase();
      Color bg;
      Color iconCol;
      IconData icon;

      if (nameLower.contains('quran') || nameLower.contains('tajweed')) {
        bg = const Color(0xFFFEF3C7);
        iconCol = const Color(0xFFD97706);
        icon = Icons.auto_stories_rounded;
      } else if (nameLower.contains('arabic') || nameLower.contains('lang')) {
        bg = const Color(0xFFDCFCE7);
        iconCol = const Color(0xFF16A34A);
        icon = Icons.translate_rounded;
      } else if (nameLower.contains('hadith') || nameLower.contains('sunnah')) {
        bg = const Color(0xFFE0E7FF);
        iconCol = const Color(0xFF4F46E5);
        icon = Icons.menu_book_rounded;
      } else if (nameLower.contains('fiqh') || nameLower.contains('life') || nameLower.contains('namaz')) {
        bg = const Color(0xFFFCE7F3);
        iconCol = const Color(0xFFDB2777);
        icon = Icons.mosque_rounded;
      } else {
        bg = const Color(0xFFF3E8FF);
        iconCol = const Color(0xFF9333EA);
        icon = Icons.school_rounded;
      }

      categoriesList.add(
        _CourseCategoryDisplayData(
          id: cat.id,
          name: cat.name,
          icon: icon,
          bgColor: bg,
          iconColor: iconCol,
        ),
      );
    }

    return SizedBox(
      height: 78,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categoriesList.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = categoriesList[index];
          final isSelected = _selectedCategoryId == item.id;

          return GestureDetector(
            onTap: () => _onCategorySelected(item.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 76,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? brandNavy : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? brandNavy : const Color(0xFFE2E8F0),
                  width: isSelected ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected ? brandNavy.withValues(alpha: 0.16) : Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withValues(alpha: 0.15) : item.bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.icon,
                      color: isSelected ? brandGold : item.iconColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
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

  // ── Courses List ───────────────────────────────────────────────────────────
  Widget _buildCoursesList() {
    final wishlist = context.watch<WishlistController>();

    if (_filteredCourses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              'No courses match your filter',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: brandNavy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try changing your filters or selecting All categories.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedCategoryId = null;
                  _filterState.reset();
                });
                _applyFilterAndSort();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: brandNavy,
                foregroundColor: brandGold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Reset All Filters'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredCourses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final course = _filteredCourses[index];
        final isFav = wishlist.isWishlisted(course.id);

        return _CourseCard(
          course: course,
          isFavorite: isFav,
          onFavoriteToggle: () => _toggleFavorite(course),
          onStartLearning: () => _showQuickEnrollModal(course),
          onViewDetails: () => context.push('/courses/${course.id}'),
          onAddToCart: () => _addToCart(course),
        );
      },
    );
  }
}

// ── Course Category Display Data Helper ──────────────────────────────────────
class _CourseCategoryDisplayData {
  const _CourseCategoryDisplayData({
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

// ── Course Card Widget ──────────────────────────────────────────────────────
class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onStartLearning,
    required this.onViewDetails,
    required this.onAddToCart,
  });

  final CourseApiModel course;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onStartLearning;
  final VoidCallback onViewDetails;
  final VoidCallback onAddToCart;

  static const Color brandGold = Color(0xFFC9A84C);
  static const Color brandNavy = Color(0xFF112039);

  @override
  Widget build(BuildContext context) {
    final thumbUrl = course.fullThumbnailUrl ?? course.fullHeroBannerUrl;

    final isBestseller = course.isBestseller;
    final isPopular = course.isPopular;
    final isFeatured = course.isFeatured;
    final isNew = course.isNew;

    final discountPercent = course.discountPercent;
    final originalPriceFormatted = course.formattedOriginalPrice;
    final emiText = course.monthlyInstallmentText;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E9F0)),
        boxShadow: [
          BoxShadow(
            color: brandNavy.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 1. Top Course Banner Image ────────────────────────────────────
          GestureDetector(
            onTap: onViewDetails,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 195,
                  decoration: const BoxDecoration(
                    color: brandNavy,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                    child: thumbUrl != null && thumbUrl.isNotEmpty
                        ? Image.network(
                            thumbUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: brandGold,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, _) => _buildLocalFallbackImage(),
                          )
                        : _buildLocalFallbackImage(),
                  ),
                ),

                // ── Top-Left Badges ──────────────────────────────────────────
                Positioned(
                  top: 10,
                  left: 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPopular) ...[
                        _buildTagBadge('POPULAR', const Color(0xFF00A884), Colors.white),
                        const SizedBox(width: 5),
                      ],
                      if (isBestseller) ...[
                        _buildTagBadge('BESTSELLER', brandNavy, Colors.white),
                        const SizedBox(width: 5),
                      ],
                      if (isFeatured) ...[
                        _buildTagBadge('FEATURED', brandGold, brandNavy),
                        const SizedBox(width: 5),
                      ],
                      if (isNew) ...[
                        _buildTagBadge('NEW', Colors.white, brandNavy),
                      ],
                    ],
                  ),
                ),

                // ── Top-Right Badges ─────────────────────────────────────────
                Positioned(
                  top: 10,
                  right: 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTagBadge('EMI Available', brandNavy, brandGold, isBordered: true),
                      if (discountPercent != null) ...[
                        const SizedBox(width: 5),
                        _buildTagBadge('-$discountPercent%', const Color(0xFF00A884), Colors.white),
                      ],
                    ],
                  ),
                ),

                // ── Bottom-Left Wishlist Button: OFFICIAL GOLDEN COLOR #c4a95b ──
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: GestureDetector(
                    onTap: onFavoriteToggle,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: brandNavy.withValues(alpha: 0.75),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isFavorite ? brandGold : Colors.white.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFavorite ? brandGold : Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),

                // ── Bottom-Right Rating Pill ─────────────────────────────────
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: brandNavy.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: brandGold),
                        const SizedBox(width: 4),
                        Text(
                          course.rating.toStringAsFixed(1),
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 2. Card Content Area ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Price Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onViewDetails,
                        child: Text(
                          course.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: brandNavy,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          course.formattedPrice,
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: brandNavy,
                          ),
                        ),
                        if (originalPriceFormatted != null)
                          Text(
                            originalPriceFormatted,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // EMI Note
                if (emiText.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      emiText,
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // Instructor line
                if (course.instructorName != null && course.instructorName!.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 13, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(
                        course.instructorName!,
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      _buildDot(),
                      _buildMetaInline(Icons.menu_book_rounded, course.lessonsDisplay),
                      _buildDot(),
                      _buildMetaInline(Icons.access_time_rounded, course.duration),
                    ],
                  ),
                  const SizedBox(height: 5),
                ] else ...[
                  Row(
                    children: [
                      _buildMetaInline(Icons.menu_book_rounded, course.lessonsDisplay),
                      _buildDot(),
                      _buildMetaInline(Icons.access_time_rounded, course.duration),
                    ],
                  ),
                  const SizedBox(height: 5),
                ],

                // Metadata Row 2: Level · Language
                Row(
                  children: [
                    _buildMetaInline(Icons.signal_cellular_alt_rounded, course.level),
                    _buildDot(),
                    _buildMetaInline(Icons.translate_rounded, course.languagesDisplay),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // ── 3. Bottom Action Buttons Row ([Read More] [Quick Enroll] [Cart])
                Row(
                  children: [
                    // Read More Button (Golden style: #c4a95b)
                    Expanded(
                      flex: 6,
                      child: SizedBox(
                        height: 42,
                        child: ElevatedButton(
                          onPressed: onViewDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandGold,
                            foregroundColor: brandNavy,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const _LucideBookOpenIcon(size: 16, color: brandNavy),
                                const SizedBox(width: 6),
                                Text(
                                  'Read More',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: brandNavy,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Quick Enroll Button (Dark Navy style: #112039)
                    Expanded(
                      flex: 7,
                      child: SizedBox(
                        height: 42,
                        child: ElevatedButton(
                          onPressed: onStartLearning,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandNavy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.bolt_rounded, size: 17, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'Quick Enroll',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Cart Icon Button (White rounded square with border)
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: OutlinedButton(
                        onPressed: onAddToCart,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: brandNavy,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Icon(Icons.shopping_cart_outlined, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagBadge(String text, Color bg, Color textCol, {bool isBordered = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: isBordered ? Border.all(color: brandGold, width: 1.0) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: textCol,
        ),
      ),
    );
  }

  Widget _buildMetaInline(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDot() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: 3,
      height: 3,
      decoration: const BoxDecoration(
        color: Color(0xFFCBD5E1),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildLocalFallbackImage() {
    final titleLower = course.title.toLowerCase();
    String? asset;
    if (titleLower.contains('tajweed') || titleLower.contains('quran')) {
      asset = 'assets/images/home/courses/quran_tajweed.png';
    } else if (titleLower.contains('namaz') || titleLower.contains('dua')) {
      asset = 'assets/images/home/courses/namaz_dua.png';
    } else if (titleLower.contains('muslim') || titleLower.contains('life')) {
      asset = 'assets/images/home/courses/muslim_life.png';
    } else if (titleLower.contains('understand')) {
      asset = 'assets/images/home/courses/understand_quran.png';
    }

    if (asset != null) {
      return Image.asset(
        asset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, _) => const _CourseArtworkFallback(),
      );
    }
    return const _CourseArtworkFallback();
  }
}

class _CourseArtworkFallback extends StatelessWidget {
  const _CourseArtworkFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF112039),
      child: const Center(
        child: Icon(
          Icons.auto_stories_rounded,
          size: 40,
          color: Color(0xFFC9A84C),
        ),
      ),
    );
  }
}

// ── Web-Style Quick Enroll Bottom Sheet ──────────────────────────────────────
class _QuickEnrollSheet extends StatefulWidget {
  const _QuickEnrollSheet({
    required this.course,
    required this.onEnrollNow,
    required this.onAddToCart,
  });

  final CourseApiModel course;
  final Function(String plan) onEnrollNow;
  final VoidCallback onAddToCart;

  @override
  State<_QuickEnrollSheet> createState() => _QuickEnrollSheetState();
}

class _QuickEnrollSheetState extends State<_QuickEnrollSheet> {
  int _selectedPlanIndex = 0; // 0: Pay in Full, 1: Monthly
  static const Color brandGold = Color(0xFFC9A84C);
  static const Color brandNavy = Color(0xFF112039);
  static const Color brandNavyDark = Color(0xFF0D1B2E);
  static const Color brandNavyCard = Color(0xFF162744);

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    final fullPrice = c.effectivePrice.toInt();
    final originalPrice = (c.price > c.effectivePrice ? c.price : c.effectivePrice * 1.5).toInt();
    final savings = (originalPrice - fullPrice).clamp(0, originalPrice);

    final installmentAmount = c.paymentOptions.length > 1 && c.paymentOptions[1].installmentAmount != null
        ? c.paymentOptions[1].installmentAmount!.toInt()
        : (fullPrice / 6).ceil();

    final isMonthly = _selectedPlanIndex == 1;

    return Container(
      decoration: const BoxDecoration(
        color: brandNavyDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row: Course Title & Close
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QUICK ENROLLMENT',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: brandGold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Payment Plan Options (Side-by-side tabs)
            Row(
              children: [
                // Plan 1: Pay in Full
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedPlanIndex = 0);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: !isMonthly ? brandGold : brandNavyCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: !isMonthly ? brandGold : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Pay in Full',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: !isMonthly ? brandNavy : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹$fullPrice',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: !isMonthly ? brandNavy : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Plan 2: Monthly
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedPlanIndex = 1);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isMonthly ? brandGold : brandNavyCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isMonthly ? brandGold : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Monthly',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isMonthly ? brandNavy : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹$installmentAmount/mo',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isMonthly ? brandNavy : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Plan Summary Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: brandNavyCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: brandGold.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Amount Payable Today:',
                        style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFFCBD5E1)),
                      ),
                      Text(
                        '₹${isMonthly ? installmentAmount : fullPrice}',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: brandGold),
                      ),
                    ],
                  ),
                  if (!isMonthly && savings > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'You Save:',
                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF00A884)),
                        ),
                        Text(
                          '₹$savings (One-time offer)',
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF00A884)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => widget.onEnrollNow(isMonthly ? 'monthly' : 'full'),
                      icon: const Icon(Icons.bolt_rounded, size: 20, color: brandNavy),
                      label: Text(
                        'Proceed to Pay',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandGold,
                        foregroundColor: brandNavy,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: widget.onAddToCart,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: brandGold,
                      side: const BorderSide(color: brandGold, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.shopping_cart_outlined, size: 20, color: brandGold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Exact Lucide Book-Open Icon implementation
class _LucideBookOpenIcon extends StatelessWidget {
  const _LucideBookOpenIcon({this.size = 18, this.color = const Color(0xFF112039)});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _LucideBookOpenPainter(color),
    );
  }
}

class _LucideBookOpenPainter extends CustomPainter {
  final Color color;
  _LucideBookOpenPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Center spine: M12 5v16
    final p1 = Path();
    p1.moveTo(12 * scale, 5 * scale);
    p1.lineTo(12 * scale, 21 * scale);
    canvas.drawPath(p1, paint);

    // Left page
    final pLeft = Path();
    pLeft.moveTo(12 * scale, 5 * scale);
    pLeft.cubicTo(10 * scale, 3 * scale, 6 * scale, 3 * scale, 4 * scale, 3 * scale);
    pLeft.lineTo(2 * scale, 5 * scale);
    pLeft.lineTo(2 * scale, 17 * scale);
    pLeft.lineTo(4 * scale, 19 * scale);
    pLeft.cubicTo(6 * scale, 19 * scale, 10 * scale, 21 * scale, 12 * scale, 21 * scale);
    canvas.drawPath(pLeft, paint);

    // Right page
    final pRight = Path();
    pRight.moveTo(12 * scale, 5 * scale);
    pRight.cubicTo(14 * scale, 3 * scale, 18 * scale, 3 * scale, 20 * scale, 3 * scale);
    pRight.lineTo(22 * scale, 5 * scale);
    pRight.lineTo(22 * scale, 17 * scale);
    pRight.lineTo(20 * scale, 19 * scale);
    pRight.cubicTo(18 * scale, 19 * scale, 14 * scale, 21 * scale, 12 * scale, 21 * scale);
    canvas.drawPath(pRight, paint);
  }

  @override
  bool shouldRepaint(covariant _LucideBookOpenPainter oldDelegate) => oldDelegate.color != color;
}
