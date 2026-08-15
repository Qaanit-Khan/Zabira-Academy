import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/auth/auth_controller.dart';
import '../../../home/presentation/widgets/home_bottom_nav.dart';
import '../../data/models/course_api_model.dart';
import '../../data/models/course_category_api_model.dart';
import '../../data/repositories/course_repository.dart';
import '../widgets/course_filter_sheet.dart';

/// Zabira Academy — Courses Page
///
/// Responsive:
/// - Mobile follows `course_mobile_reference.png`
/// - Desktop/Web follows `course_web_reference.pdf`
class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  final CourseRepository _repository = CourseRepository();
  final TextEditingController _searchController = TextEditingController();

  List<CourseCategoryApiModel> _categories = [];
  List<CourseApiModel> _courses = [];
  List<CourseApiModel> _filteredCourses = [];
  bool _isLoading = true;
  String? _errorMessage;

  final CourseFilterState _filterState = CourseFilterState();
  int? _selectedCategoryPillIndex; // null = all
  final Set<int> _favorites = {};

  final List<_CategoryPillData> _mobileReferenceCategories = const [
    _CategoryPillData(
      label: 'Quran',
      tintColor: Color(0xFFFFF8E1),
      iconColor: Color(0xFFD97706),
      icon: Icons.menu_book_rounded,
    ),
    _CategoryPillData(
      label: 'Tajweed',
      tintColor: Color(0xFFE0F7FA),
      iconColor: Color(0xFF0284C7),
      icon: Icons.auto_stories_rounded,
    ),
    _CategoryPillData(
      label: 'Islamic Studies',
      tintColor: Color(0xFFE8F5E9),
      iconColor: Color(0xFF16A34A),
      icon: Icons.mosque_rounded,
    ),
    _CategoryPillData(
      label: 'Seerah',
      tintColor: Color(0xFFEDE7F6),
      iconColor: Color(0xFF7C3AED),
      icon: Icons.account_balance_rounded,
    ),
    _CategoryPillData(
      label: 'Kids Special',
      tintColor: Color(0xFFFCE4EC),
      iconColor: Color(0xFFE11D48),
      icon: Icons.child_care_rounded,
    ),
  ];

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
        _repository.getCourses(
          search: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
          categoryId: _filterState.categoryId,
          level: _filterState.level,
          language: _filterState.language,
          sort: _filterState.sort,
        ),
      ]);

      if (mounted) {
        setState(() {
          _categories = results[0] as List<CourseCategoryApiModel>;
          _courses = results[1] as List<CourseApiModel>;
          _applyLocalFilterAndSort();
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
            _errorMessage = 'Unable to load courses: $e';
          }
          _isLoading = false;
        });
      }
    }
  }

  void _applyLocalFilterAndSort() {
    var list = List<CourseApiModel>.from(_courses);

    // Filter by category pill if selected
    if (_selectedCategoryPillIndex != null && _selectedCategoryPillIndex! < _mobileReferenceCategories.length) {
      final selectedPill = _mobileReferenceCategories[_selectedCategoryPillIndex!].label.toLowerCase();
      list = list.where((c) {
        final cat = (c.categoryName ?? '').toLowerCase();
        final title = c.title.toLowerCase();
        if (selectedPill == 'quran') return cat.contains('quran') || title.contains('quran');
        if (selectedPill == 'tajweed') return cat.contains('tajweed') || title.contains('tajweed');
        if (selectedPill == 'islamic studies') return cat.contains('islamic') || title.contains('hadith') || title.contains('fiqh');
        if (selectedPill == 'seerah') return cat.contains('seerah') || title.contains('seerah') || title.contains('prophet');
        if (selectedPill == 'kids special') return cat.contains('kid') || title.contains('young') || title.contains('child') || title.contains('kid');
        return true;
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
        list.sort((a, b) => (a.discountPrice ?? a.price).compareTo(b.discountPrice ?? b.price));
        break;
      case 'price_desc':
        list.sort((a, b) => (b.discountPrice ?? b.price).compareTo(a.discountPrice ?? a.price));
        break;
      case 'featured':
      default:
        list.sort((a, b) {
          if (a.isFeatured && !b.isFeatured) return -1;
          if (!a.isFeatured && b.isFeatured) return 1;
          return (b.rating).compareTo(a.rating);
        });
        break;
    }

    _filteredCourses = list;
  }

  void _onCategoryPillTapped(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedCategoryPillIndex == index) {
        _selectedCategoryPillIndex = null; // deselect
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
    if (auth.isAuthenticated) {
      context.push('/courses/${course.id}');
    } else {
      context.push(AppRoutes.login);
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: Column(
        children: [
          // ── 1. Mobile Header (Matches mobile reference, No Assalamu Alaikum)
          SafeArea(
            bottom: false,
            child: _buildHeader(context),
          ),

          // ── 2. Scrollable Courses Content ─────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: AppColors.gold,
              backgroundColor: AppColors.surfaceWhite,
              onRefresh: _loadInitialData,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Section
                    _buildHeroSection(isDesktop),

                    const SizedBox(height: AppSpacing.md),

                    // Categories Selector
                    _buildCategoryPillsRow(),

                    const SizedBox(height: AppSpacing.lg),

                    // All Courses Header + Sort Dropdown
                    _buildCoursesHeader(),

                    const SizedBox(height: AppSpacing.sm),

                    // Courses List / Grid
                    _buildCoursesContent(isDesktop),

                    const SizedBox(height: AppSpacing.xl),

                    // Feature Highlights Row (4 items)
                    _buildValueHighlights(isDesktop),

                    const SizedBox(height: AppSpacing.lg),

                    // Scholarship Banner
                    _buildScholarshipBanner(),

                    // Bottom spacing for floating navigation dock
                    const SizedBox(height: AppSpacing.xxl + 24),
                  ],
                ),
              ),
            ),
          ),

          // ── 3. Bottom Dock Navigation (Learn tab active) ──────────────────
          HomeBottomNav(
            selectedIndex: 1,
            onItemTapped: (index) {
              if (index == 0) {
                context.go(AppRoutes.home);
              } else if (index == 1) {
                // Already on Learn
              } else if (index == 2) {
                // Center Kids Portal
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening Kids Portal...'), duration: Duration(seconds: 1)),
                );
              } else if (index == 3) {
                // Library
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening Library...'), duration: Duration(seconds: 1)),
                );
              } else if (index == 4) {
                final auth = context.read<AuthController>();
                if (auth.isAuthenticated) {
                  // Profile
                } else {
                  context.push(AppRoutes.login);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Header Widget ──────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderLight.withAlpha(120),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // Left: Hamburger Menu + Logo
          IconButton(
            icon: const Icon(Icons.menu_rounded, size: 24, color: AppColors.navyDark),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Zabira Academy Menu'), duration: Duration(seconds: 1)),
              );
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32),
          ),
          const SizedBox(width: 8),
          Image.asset(
            'assets/images/branding/zabira_logo_horizontal.png',
            height: 34,
            fit: BoxFit.contain,
            errorBuilder: (context, error, _) => Text(
              'ZABIRA ACADEMY',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.navyDark,
                letterSpacing: 1.1,
              ),
            ),
          ),

          const Spacer(),

          // Right: Cart, Notification, Profile
          // 1. Cart
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, size: 22, color: AppColors.navyDark),
            onPressed: () => context.push(AppRoutes.store),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36),
          ),

          // 2. Notification
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, size: 22, color: AppColors.navyDark),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 4),

          // 3. Profile Avatar
          GestureDetector(
            onTap: () {
              if (auth.isAuthenticated) {
                // Profile
              } else {
                context.push(AppRoutes.login);
              }
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF081D3A),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.person, size: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Section ───────────────────────────────────────────────────────────
  Widget _buildHeroSection(bool isDesktop) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Courses',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyDark,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Structured Islamic learning\nfor all ages. Learn. Practice. Grow.',
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              // Decorative Islamic artwork on right
              _buildIslamicHeroArtwork(),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Search Bar + Filter Button
          Row(
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
                        color: AppColors.navyDark.withAlpha(6),
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
                    color: _filterState.hasActiveFilters ? AppColors.navyDark : AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _filterState.hasActiveFilters ? AppColors.navyDark : AppColors.borderLight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navyDark.withAlpha(6),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 17,
                        color: _filterState.hasActiveFilters ? AppColors.gold : AppColors.navyDark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Filter',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _filterState.hasActiveFilters ? AppColors.gold : AppColors.navyDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIslamicHeroArtwork() {
    return Container(
      width: 125,
      height: 95,
      padding: const EdgeInsets.all(4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background arch outline
          Container(
            width: 100,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E6).withAlpha(150),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(50),
                bottom: Radius.circular(8),
              ),
              border: Border.all(color: AppColors.gold.withAlpha(80), width: 1),
            ),
          ),
          // Layered Islamic Study visual: Rehal + Lantern
          Positioned(
            bottom: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.menu_book_rounded, color: AppColors.navyDark, size: 36),
                const SizedBox(width: 4),
                Icon(Icons.lightbulb_outline_rounded, color: AppColors.gold.withAlpha(220), size: 24),
              ],
            ),
          ),
          Positioned(
            top: 10,
            child: Icon(Icons.star_rounded, color: AppColors.gold.withAlpha(160), size: 16),
          ),
        ],
      ),
    );
  }

  // ── Category Pills Row ─────────────────────────────────────────────────────
  Widget _buildCategoryPillsRow() {
    return SizedBox(
      height: 84,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: _mobileReferenceCategories.length,
        itemBuilder: (context, index) {
          final cat = _mobileReferenceCategories[index];
          final isSelected = _selectedCategoryPillIndex == index;

          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () => _onCategoryPillTapped(index),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.navyDark : cat.tintColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.gold : Colors.transparent,
                        width: isSelected ? 2.0 : 0.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.navyDark.withAlpha(isSelected ? 20 : 6),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        cat.icon,
                        color: isSelected ? AppColors.gold : cat.iconColor,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat.label,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.navyDark : AppColors.textSecondary,
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

  // ── Courses Header Row ─────────────────────────────────────────────────────
  Widget _buildCoursesHeader() {
    final sortLabel = switch (_filterState.sort) {
      'newest' => 'Newest',
      'price_asc' => 'Price: Low to High',
      'price_desc' => 'Price: High to Low',
      _ => 'Featured',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Text(
            'All Courses',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.navyDark,
            ),
          ),
          const SizedBox(width: 8),
          if (!_isLoading)
            Text(
              '(${_filteredCourses.length})',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
              ),
            ),
          const Spacer(),
          GestureDetector(
            onTap: _openFilterSheet,
            child: Row(
              children: [
                Text(
                  'Sort By: ',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  sortLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.navyDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Courses Content (List / Grid) ──────────────────────────────────────────
  Widget _buildCoursesContent(bool isDesktop) {
    if (_isLoading) {
      return _buildCoursesSkeleton();
    }

    if (_errorMessage != null) {
      return _buildCoursesError();
    }

    if (_filteredCourses.isEmpty) {
      return _buildCoursesEmpty();
    }

    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _filteredCourses.length,
          itemBuilder: (context, index) {
            final course = _filteredCourses[index];
            return _CourseCard(
              course: course,
              isFavorite: _favorites.contains(course.id),
              onFavoriteToggle: () => _toggleFavorite(course.id),
              onStartLearning: () => _onStartLearning(course),
              onViewDetails: () => context.push('/courses/${course.id}'),
            );
          },
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: _filteredCourses.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final course = _filteredCourses[index];
        return _CourseCard(
          course: course,
          isFavorite: _favorites.contains(course.id),
          onFavoriteToggle: () => _toggleFavorite(course.id),
          onStartLearning: () => _onStartLearning(course),
          onViewDetails: () => context.push('/courses/${course.id}'),
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
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          height: 120,
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
  Widget _buildValueHighlights(bool isDesktop) {
    const items = [
      _HighlightItem(
        icon: Icons.school_outlined,
        title: 'Expert Instructors',
        desc: 'Learn from qualified and experienced scholars.',
      ),
      _HighlightItem(
        icon: Icons.video_collection_outlined,
        title: 'Live & Recorded',
        desc: 'Live classes, recordings and downloadable resources.',
      ),
      _HighlightItem(
        icon: Icons.verified_outlined,
        title: 'Certificate',
        desc: 'Get certified after completing the course.',
      ),
      _HighlightItem(
        icon: Icons.all_inclusive_rounded,
        title: 'Lifetime Access',
        desc: 'Learn at your own pace anytime, anywhere.',
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
              const SizedBox(height: 2),
              Text(
                item.desc,
                style: GoogleFonts.outfit(
                  fontSize: 9.5,
                  color: AppColors.textSecondary,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Scholarship Banner ─────────────────────────────────────────────────────
  Widget _buildScholarshipBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF081D3A),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF081D3A).withAlpha(40),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Illustration / Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.volunteer_activism_rounded, color: AppColors.gold, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SCHOLARSHIP PROGRAM',
                  style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Support a Child's Future",
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Your contribution helps a child receive quality Islamic education.',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening Scholarship Contribution...'), duration: Duration(seconds: 1)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: const Color(0xFF081D3A),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Donate',
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                const Icon(Icons.chevron_right_rounded, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Course Card matching `course_mobile_reference.png`.
class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onStartLearning,
    required this.onViewDetails,
  });

  final CourseApiModel course;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onStartLearning;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final thumbUrl = course.fullThumbnailUrl;
    final badge = course.badgeLabel;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: Thumbnail + Badge + Play Icon ───────────────────────────
          Stack(
            children: [
              Container(
                width: 96,
                height: 116,
                decoration: BoxDecoration(
                  color: const Color(0xFF081D3A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: thumbUrl != null && thumbUrl.isNotEmpty
                      ? Image.network(
                          thumbUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, _) => const _CourseArtworkFallback(),
                        )
                      : const _CourseArtworkFallback(),
                ),
              ),

              // Badge (Bestseller, New, Popular)
              if (badge != null)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badge == 'Bestseller'
                          ? AppColors.gold
                          : (badge == 'New' ? const Color(0xFF10B981) : const Color(0xFF0284C7)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: GoogleFonts.outfit(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: badge == 'Bestseller' ? AppColors.navyDark : Colors.white,
                      ),
                    ),
                  ),
                ),

              // Play Icon Button overlay on bottom-left
              Positioned(
                bottom: 6,
                left: 6,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(160),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.play_arrow_rounded, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 10),

          // ── Middle: Title, Short Description, Meta Row ────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  course.shortDescription ?? 'Complete structured learning path.',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Meta Row (Lessons, Duration, Level)
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    _buildMetaChip(Icons.menu_book_outlined, course.lessonsDisplay),
                    _buildMetaChip(Icons.schedule_rounded, course.duration),
                    _buildMetaChip(Icons.signal_cellular_alt_rounded, course.level),
                  ],
                ),

                const SizedBox(height: 4),

                // Rating Row
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
                    const SizedBox(width: 2),
                    Text(
                      course.ratingDisplay,
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ── Right: Price, Favorite, CTAs ──────────────────────────────────
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Heart Icon
                GestureDetector(
                  onTap: onFavoriteToggle,
                  child: Icon(
                    isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 18,
                    color: isFavorite ? const Color(0xFFE53935) : AppColors.textTertiary,
                  ),
                ),

                const SizedBox(height: 2),

                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      course.formattedPrice,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyDark,
                      ),
                    ),
                    if (course.monthlyInstallmentText.isNotEmpty)
                      Text(
                        course.monthlyInstallmentText,
                        style: GoogleFonts.outfit(
                          fontSize: 8,
                          color: AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),

                const SizedBox(height: 6),

                // Start Learning > Button
                SizedBox(
                  width: double.infinity,
                  height: 26,
                  child: ElevatedButton(
                    onPressed: onStartLearning,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: const Color(0xFF081D3A),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Start Learning',
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 8),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // View Details Button
                SizedBox(
                  width: double.infinity,
                  height: 24,
                  child: OutlinedButton(
                    onPressed: onViewDetails,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navyDark,
                      side: const BorderSide(color: AppColors.borderLight),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Text(
                      'View Details',
                      style: GoogleFonts.outfit(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
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

  Widget _buildMetaChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: AppColors.textTertiary),
        const SizedBox(width: 2),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 9,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _CourseArtworkFallback extends StatelessWidget {
  const _CourseArtworkFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.auto_stories_rounded,
        size: 32,
        color: AppColors.gold,
      ),
    );
  }
}

class _CategoryPillData {
  const _CategoryPillData({
    required this.label,
    required this.tintColor,
    required this.iconColor,
    required this.icon,
  });

  final String label;
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
