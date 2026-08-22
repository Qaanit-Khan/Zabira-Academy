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
import '../../../store/presentation/controllers/cart_controller.dart';
import '../../data/models/course_api_model.dart';
import '../../data/models/course_category_api_model.dart';
import '../../data/repositories/course_repository.dart';
import '../controllers/enrollment_controller.dart';
import '../widgets/course_filter_sheet.dart';

/// Zabira Academy — Courses Page
///
/// Features:
/// - Displays full 14 courses dataset retrieved from official backend API
/// - Top header with dynamic "${_filteredCourses.length} Programs Found"
/// - Reusable Global Hero Banner slider
/// - Category selector pills + filter sheet modal
/// - Fixed-height, aligned course cards matching reference design
/// - Bottom Scholarship Promotional Banner
class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final CourseRepository _repository = CourseRepository();
  final TextEditingController _searchController = TextEditingController();

  List<CourseCategoryApiModel> _categories = List.from(CourseRepository.defaultCategories);
  List<CourseApiModel> _courses = List.from(CourseRepository.defaultCourses);
  List<CourseApiModel> _filteredCourses = List.from(CourseRepository.defaultCourses);
  bool _isLoading = false;
  String? _errorMessage;

  final CourseFilterState _filterState = CourseFilterState();
  int? _selectedCategoryPillIndex; // null or 0 = all
  final Set<int> _favorites = {};

  late final List<HeroBannerModel> _banners;

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
    _applyLocalFilterAndSort();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          } else {
            _courses = List.from(CourseRepository.defaultCourses);
          }
          if (fetchedCategories.isNotEmpty) _categories = fetchedCategories;
          _applyLocalFilterAndSort();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _courses = List.from(CourseRepository.defaultCourses);
          _isLoading = false;
          _applyLocalFilterAndSort();
        });
      }
    }
  }

  Future<List<CourseApiModel>> _fetchAllCourses() async {
    // Fetches all available courses from official API
    final query = _searchController.text.trim();
    final items = await _repository.getCourses(
      page: 1,
      limit: 50,
      search: query.isNotEmpty ? query : null,
      categoryId: _filterState.categoryId,
      level: _filterState.level,
      language: _filterState.language,
      sort: _filterState.sort,
    );
    return items;
  }

  List<_CategoryPillData> _getCategoryPills() {
    final pills = <_CategoryPillData>[
      const _CategoryPillData(
        label: 'All',
        categoryId: null,
        tintColor: Color(0xFFF1F5F9),
        iconColor: AppColors.navyDark,
        icon: Icons.grid_view_rounded,
      ),
    ];

    for (final cat in _categories) {
      final nameLower = cat.name.toLowerCase();
      Color tint;
      Color iconColor;
      IconData icon;

      if (nameLower.contains('quran')) {
        tint = const Color(0xFFFFF8E1);
        iconColor = const Color(0xFFD97706);
        icon = Icons.menu_book_rounded;
      } else if (nameLower.contains('islamic')) {
        tint = const Color(0xFFE8F5E9);
        iconColor = const Color(0xFF16A34A);
        icon = Icons.mosque_rounded;
      } else if (nameLower.contains('language') || nameLower.contains('arabic') || nameLower.contains('urdu')) {
        tint = const Color(0xFFE0F7FA);
        iconColor = const Color(0xFF0284C7);
        icon = Icons.translate_rounded;
      } else if (nameLower.contains('self') || nameLower.contains('paced')) {
        tint = const Color(0xFFEDE7F6);
        iconColor = const Color(0xFF7C3AED);
        icon = Icons.speed_rounded;
      } else if (nameLower.contains('workshop') || nameLower.contains('event')) {
        tint = const Color(0xFFFFF3E0);
        iconColor = const Color(0xFFEA580C);
        icon = Icons.event_note_rounded;
      } else if (nameLower.contains('kid')) {
        tint = const Color(0xFFFCE4EC);
        iconColor = const Color(0xFFE11D48);
        icon = Icons.child_care_rounded;
      } else {
        tint = const Color(0xFFE0F2FE);
        iconColor = const Color(0xFF0369A1);
        icon = Icons.auto_stories_rounded;
      }

      pills.add(_CategoryPillData(
        label: cat.name,
        categoryId: cat.id,
        tintColor: tint,
        iconColor: iconColor,
        icon: icon,
      ));
    }

    return pills;
  }

  void _applyLocalFilterAndSort() {
    var list = List<CourseApiModel>.from(_courses);
    final pills = _getCategoryPills();

    // Filter by category pill if selected
    if (_selectedCategoryPillIndex != null &&
        _selectedCategoryPillIndex! > 0 &&
        _selectedCategoryPillIndex! < pills.length) {
      final selectedPill = pills[_selectedCategoryPillIndex!];
      list = list.where((c) {
        if (selectedPill.categoryId != null && c.categoryId == selectedPill.categoryId) {
          return true;
        }
        final cat = (c.categoryName ?? '').toLowerCase();
        final pillLabel = selectedPill.label.toLowerCase();
        return cat.contains(pillLabel) || pillLabel.contains(cat);
      }).toList();
    }

    // Filter by search query
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((c) {
        return c.title.toLowerCase().contains(query) ||
            (c.shortDescription ?? '').toLowerCase().contains(query) ||
            (c.categoryName ?? '').toLowerCase().contains(query);
      }).toList();
    }

    // Filter by sheet level
    if (_filterState.level != null) {
      list = list.where((c) => c.level.toLowerCase() == _filterState.level!.toLowerCase()).toList();
    }

    // Filter by sheet language
    if (_filterState.language != null) {
      list = list.where((c) => c.language.toLowerCase() == _filterState.language!.toLowerCase()).toList();
    }

    // Sort
    switch (_filterState.sort) {
      case 'newest':
        list.sort((a, b) => b.id.compareTo(a.id));
        break;
      case 'price_asc':
        list.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
        break;
      case 'price_desc':
        list.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
        break;
      case 'featured':
      default:
        list.sort((a, b) {
          if (a.isFeatured && !b.isFeatured) return -1;
          if (!a.isFeatured && b.isFeatured) return 1;
          return b.rating.compareTo(a.rating);
        });
        break;
    }

    _filteredCourses = list;
  }

  void _onCategoryPillTapped(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedCategoryPillIndex == index) {
        _selectedCategoryPillIndex = 0; // default to All
      } else {
        _selectedCategoryPillIndex = index;
      }
      _applyLocalFilterAndSort();
    });
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
            _applyLocalFilterAndSort();
          });
        },
      ),
    );
  }

  void _onStartLearning(CourseApiModel course) {
    HapticFeedback.mediumImpact();
    final auth = context.read<AuthController>();
    final enrollment = context.read<EnrollmentController>();
    if (auth.isAuthenticated && enrollment.isEnrolled(course.id)) {
      context.push('/courses/${course.id}/learn');
    } else {
      context.push('/courses/${course.id}');
    }
  }

  void _toggleFavorite(int courseId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_favorites.contains(courseId)) {
        _favorites.remove(courseId);
      } else {
        _favorites.add(courseId);
      }
    });
  }

  Future<void> _addCourseToCart(CourseApiModel course) async {
    HapticFeedback.lightImpact();
    final auth = context.read<AuthController>();
    final cart = context.read<CartController>();

    final success = await cart.addItem(
      itemData: {
        'course_id': course.id,
        'product_type': 'course',
        'quantity': '1',
      },
      token: auth.currentToken,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? '${course.title} added to Cart' : 'Unable to add to cart',
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
        backgroundColor: AppColors.surfaceLight,
        bottomNavigationBar: const ZabiraBottomNav(selectedIndex: 0),
        body: Column(
          children: [
            // ── 1. Global App Header ──────────────────────────────────────────
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

            // ── 2. Scrollable Courses Content ─────────────────────────────────
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
                      // ── Top Title Row with Programs Count ───────────────────
                      _buildTopHeader(),

                      const SizedBox(height: AppSpacing.sm),

                      // ── Search & Filter Controls ────────────────────────────
                      _buildSearchAndFilterBar(),

                      const SizedBox(height: AppSpacing.sm),

                      // ── Hero Banner Carousel ────────────────────────────────
                      HeroCarousel(banners: _banners),

                      const SizedBox(height: AppSpacing.md),

                      // ── Category Selector Pills ─────────────────────────────
                      _buildCategoryPillsRow(),

                      const SizedBox(height: AppSpacing.md),

                      // ── Courses Content List ────────────────────────────────
                      _buildCoursesList(),

                      const SizedBox(height: AppSpacing.lg),

                      // ── Value Highlights ────────────────────────────────────
                      _buildValueHighlights(),

                      const SizedBox(height: AppSpacing.md),

                      // ── Universal Scholarship Promo Banner ──────────────────
                      const ScholarshipPromoBanner(),

                      // Bottom spacing for floating navigation dock
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

  // ── Top Header Row with dynamic count ──────────────────────────────────────
  Widget _buildTopHeader() {
    final count = _isLoading ? '...' : '${_filteredCourses.length}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Courses & Programs',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyDark,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$count Programs Found',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          // Clean sort indicator trigger
          GestureDetector(
            onTap: _openFilterSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sort_rounded, size: 16, color: AppColors.navyDark),
                  const SizedBox(width: 4),
                  Text(
                    'Sort',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
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

  // ── Search & Filter Bar ───────────────────────────────────────────────────
  Widget _buildSearchAndFilterBar() {
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
                onChanged: (_) => setState(_applyLocalFilterAndSort),
                style: GoogleFonts.outfit(fontSize: 13.5, color: AppColors.navyDark),
                decoration: InputDecoration(
                  hintText: 'Search courses, topics...',
                  hintStyle: GoogleFonts.outfit(fontSize: 13, color: AppColors.textTertiary),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            setState(_applyLocalFilterAndSort);
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
            onTap: _openFilterSheet,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _filterState.hasActiveFilters ? AppColors.navyDark : AppColors.gold,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 17,
                    color: _filterState.hasActiveFilters ? AppColors.gold : const Color(0xFF071B36),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'FILTER',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: _filterState.hasActiveFilters ? AppColors.gold : const Color(0xFF071B36),
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

  // ── Category Pills Row ─────────────────────────────────────────────────────
  Widget _buildCategoryPillsRow() {
    final pills = _getCategoryPills();
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: pills.length,
        itemBuilder: (context, index) {
          final cat = pills[index];
          final isSelected = (_selectedCategoryPillIndex ?? 0) == index;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => _onCategoryPillTapped(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.navyDark : AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.navyDark : AppColors.borderLight,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navyDark.withValues(alpha: isSelected ? 0.15 : 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat.icon,
                      size: 15,
                      color: isSelected ? AppColors.gold : cat.iconColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat.label,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? AppColors.gold : AppColors.navyDark,
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

  // ── Courses Content List ───────────────────────────────────────────────────
  Widget _buildCoursesList() {
    if (_isLoading) {
      return _buildCoursesSkeleton();
    }

    if (_errorMessage != null) {
      return _buildCoursesError();
    }

    if (_filteredCourses.isEmpty) {
      return _buildCoursesEmpty();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: _filteredCourses.length,
      separatorBuilder: (context, index) => const SizedBox(height: 18),
      itemBuilder: (context, index) {
        final course = _filteredCourses[index];
        return _CourseCard(
          course: course,
          isFavorite: _favorites.contains(course.id),
          onFavoriteToggle: () => _toggleFavorite(course.id),
          onStartLearning: () => _onStartLearning(course),
          onViewDetails: () => context.push('/courses/${course.id}'),
          onAddToCart: () => _addCourseToCart(course),
        );
      },
    );
  }

  Widget _buildCoursesSkeleton() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: 4,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return Container(
          height: 320,
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.gold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoursesError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded, size: 42, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _errorMessage ?? 'Error loading courses',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: _loadInitialData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyDark,
                foregroundColor: AppColors.gold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 44, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No courses match your criteria',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try adjusting your search query or removing active filters.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _selectedCategoryPillIndex = null;
                  _filterState.reset();
                  _applyLocalFilterAndSort();
                });
              },
              child: const Text('Reset All Filters'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Value Proposition Highlights ───────────────────────────────────────────
  Widget _buildValueHighlights() {
    const items = [
      _HighlightItem(
        icon: Icons.school_outlined,
        title: 'Expert Instructors',
        desc: 'Learn from qualified scholars.',
      ),
      _HighlightItem(
        icon: Icons.video_collection_outlined,
        title: 'Live & Recorded',
        desc: 'Classes & downloadable resources.',
      ),
      _HighlightItem(
        icon: Icons.verified_outlined,
        title: 'Certificate',
        desc: 'Get certified upon completion.',
      ),
      _HighlightItem(
        icon: Icons.all_inclusive_rounded,
        title: 'Lifetime Access',
        desc: 'Learn at your own pace.',
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildHighlightWidget(items[0])),
              const SizedBox(width: 8),
              Expanded(child: _buildHighlightWidget(items[1])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildHighlightWidget(items[2])),
              const SizedBox(width: 8),
              Expanded(child: _buildHighlightWidget(items[3])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightWidget(_HighlightItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(item.icon, size: 18, color: AppColors.navyDark),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDark,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                item.desc,
                style: GoogleFonts.outfit(
                  fontSize: 9.5,
                  color: AppColors.textSecondary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Course Card matching the provided reference screenshots:
/// - Course Banner with Top badges (Popular, Featured, New, Crash Course, EMI Available, Discount)
/// - Bottom banner badges (Heart favorite, Star rating)
/// - Content area (Title, Price, EMI note, Metadata chips)
/// - Aligned bottom action buttons row ([Read More] [Quick Enroll] [Cart])
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

  @override
  Widget build(BuildContext context) {
    final thumbUrl = course.fullHeroBannerUrl ?? course.fullThumbnailUrl;

    // Determine badges
    final isPopular = course.isPopular;
    final isFeatured = course.isFeatured;
    final isNew = course.isNew;
    final isCrashCourse = course.isCrashCourse;

    // Calculate discount percent
    int? discountPercent;
    if (course.discountPrice != null && course.discountPrice! > 0 && course.price > course.discountPrice!) {
      discountPercent = (((course.price - course.discountPrice!) / course.price) * 100).round();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF07192F).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 1. Top Course Banner Image ──────────────────────────────────────
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 175,
                decoration: const BoxDecoration(
                  color: Color(0xFF081D3A),
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
                                  color: AppColors.gold,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, _) => _buildLocalFallbackImage(),
                        )
                      : _buildLocalFallbackImage(),
                ),
              ),

              // ── Top-Left Badges (POPULAR, FEATURED, NEW, CRASH COURSE) ──────
              Positioned(
                top: 10,
                left: 10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPopular)
                      _buildTagBadge('POPULAR', const Color(0xFF0D9488), Colors.white),
                    if (isFeatured) ...[
                      if (isPopular) const SizedBox(width: 5),
                      _buildTagBadge('FEATURED', const Color(0xFFD97706), Colors.white),
                    ],
                    if (isNew) ...[
                      if (isPopular || isFeatured) const SizedBox(width: 5),
                      _buildTagBadge('NEW', Colors.white, const Color(0xFF07192F)),
                    ],
                    if (isCrashCourse) ...[
                      if (isPopular || isFeatured || isNew) const SizedBox(width: 5),
                      _buildTagBadge('CRASH COURSE', const Color(0xFF0284C7), Colors.white),
                    ],
                  ],
                ),
              ),

              // ── Top-Right Badges (EMI Available, Discount %) ────────────────
              Positioned(
                top: 10,
                right: 10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTagBadge('EMI Available', const Color(0xFF07192F).withValues(alpha: 0.85), Colors.white),
                    if (discountPercent != null && discountPercent > 0) ...[
                      const SizedBox(width: 5),
                      _buildTagBadge('-$discountPercent%', const Color(0xFF10B981), Colors.white),
                    ],
                  ],
                ),
              ),

              // ── Bottom-Left: Circular Favorite Heart Button ─────────────────
              Positioned(
                bottom: 10,
                left: 10,
                child: GestureDetector(
                  onTap: onFavoriteToggle,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF07192F).withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                    ),
                    child: Center(
                      child: Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 18,
                        color: isFavorite ? const Color(0xFFEF4444) : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Bottom-Right: Rating Badge ──────────────────────────────────
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF07192F).withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
                      const SizedBox(width: 4),
                      Text(
                        course.rating.toStringAsFixed(1),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── 2. Content & Metadata Section ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Price Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Title
                    Expanded(
                      child: Text(
                        course.title,
                        style: GoogleFonts.poppins(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navyDark,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Price Block
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          course.formattedPrice,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navyDark,
                          ),
                        ),
                        Text(
                          course.monthlyInstallmentText.isNotEmpty
                              ? 'Starting ${course.monthlyInstallmentText}'
                              : 'Starting from ₹250/mo EMI',
                          style: GoogleFonts.outfit(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Metadata Row 1: Instructor · Lessons · Duration
                Row(
                  children: [
                    if (course.instructorName != null && course.instructorName!.isNotEmpty) ...[
                      _buildMetaInline(Icons.person_outline_rounded, course.instructorName!),
                      _buildDot(),
                    ],
                    _buildMetaInline(Icons.menu_book_outlined, course.lessonsDisplay),
                    _buildDot(),
                    _buildMetaInline(Icons.access_time_rounded, course.duration),
                  ],
                ),

                const SizedBox(height: 6),

                // Metadata Row 2: Level · Language
                Row(
                  children: [
                    _buildMetaInline(Icons.signal_cellular_alt_rounded, course.level),
                    _buildDot(),
                    _buildMetaInline(Icons.translate_rounded, course.language),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // ── 3. Bottom Action Buttons Row ([Read More] [Quick Enroll] [Cart])
                Row(
                  children: [
                    // Read More Button (Gold/Amber style)
                    Expanded(
                      flex: 4,
                      child: SizedBox(
                        height: 42,
                        child: ElevatedButton.icon(
                          onPressed: onViewDetails,
                          icon: const Icon(Icons.menu_book_rounded, size: 16),
                          label: Text(
                            'Read More',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4A346),
                            foregroundColor: const Color(0xFF071B36),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Quick Enroll Button (Dark Navy style)
                    Expanded(
                      flex: 5,
                      child: SizedBox(
                        height: 42,
                        child: ElevatedButton.icon(
                          onPressed: onStartLearning,
                          icon: const Icon(Icons.bolt_rounded, size: 16),
                          label: Text(
                            'Quick Enroll',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF071B36),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
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
                          foregroundColor: AppColors.navyDark,
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

  Widget _buildTagBadge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
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
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
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
      color: const Color(0xFF081D3A),
      child: const Center(
        child: Icon(
          Icons.auto_stories_rounded,
          size: 40,
          color: AppColors.gold,
        ),
      ),
    );
  }
}

class _CategoryPillData {
  const _CategoryPillData({
    required this.label,
    this.categoryId,
    required this.tintColor,
    required this.iconColor,
    required this.icon,
  });

  final String label;
  final int? categoryId;
  final Color tintColor;
  final Color iconColor;
  final IconData icon;
}

class _HighlightItem {
  const _HighlightItem({
    required this.icon,
    required this.title,
    required this.desc,
  });

  final IconData icon;
  final String title;
  final String desc;
}
