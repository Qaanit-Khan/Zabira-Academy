import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/auth/auth_controller.dart';
import '../../../../shared/buttons/primary_button.dart';
import '../../../../shared/loaders/zabira_loader.dart';
import '../../../../shared/widgets/zabira_network_image.dart';
import '../../data/models/enrolled_course_model.dart';
import '../controllers/enrollment_controller.dart';

/// Zabira Academy — Dedicated Mobile My Courses Screen
///
/// Designed exclusively for mobile adhering to the Zabira mobile design system:
/// - Dark Navy (#081D3A), Gold (#D19A42), Clean surfaces
/// - Displays real API-backed metadata (instructor, category, lessons, duration, level, progress)
/// - "Continue Learning" directly launches the native Course Learning Page (/courses/:id/learn)
class MyCoursesPage extends StatefulWidget {
  const MyCoursesPage({super.key});

  @override
  State<MyCoursesPage> createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // 'all', 'in_progress', 'completed'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      context.read<EnrollmentController>().loadMyCourses(auth.currentToken, forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EnrolledCourseModel> _filterCourses(List<EnrolledCourseModel> courses) {
    var list = List<EnrolledCourseModel>.from(courses);

    // Search query
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((c) {
        return c.title.toLowerCase().contains(query) ||
            (c.instructorName ?? '').toLowerCase().contains(query) ||
            (c.categoryName ?? '').toLowerCase().contains(query);
      }).toList();
    }

    // Status filter
    if (_selectedFilter == 'in_progress') {
      list = list.where((c) => !c.completed && c.progressPercent < 100.0).toList();
    } else if (_selectedFilter == 'completed') {
      list = list.where((c) => c.completed || c.progressPercent >= 100.0).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final enrollment = context.watch<EnrollmentController>();
    final auth = context.watch<AuthController>();

    final filteredList = _filterCourses(enrollment.enrolledCourses);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navyDark, size: 20),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              GoRouter.of(context).pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: Text(
          'My Courses',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.navyDark,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.navyDark, size: 22),
            tooltip: 'Refresh',
            onPressed: () => enrollment.loadMyCourses(auth.currentToken, forceRefresh: true),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: enrollment.isLoading && enrollment.enrolledCourses.isEmpty
          ? const Center(child: ZabiraLoader(size: 40))
          : RefreshIndicator(
              onRefresh: () => enrollment.loadMyCourses(auth.currentToken, forceRefresh: true),
              color: AppColors.gold,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  // Search & Filter Header
                  if (enrollment.enrolledCourses.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Search Box
                            Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                                style: GoogleFonts.outfit(fontSize: 13.5, color: AppColors.navyDark),
                                decoration: InputDecoration(
                                  hintText: 'Search my enrolled courses...',
                                  hintStyle: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF94A3B8)),
                                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {});
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Filter Tabs (All, In Progress, Completed)
                            Row(
                              children: [
                                _buildFilterPill('All (${enrollment.enrolledCourses.length})', 'all'),
                                const SizedBox(width: 8),
                                _buildFilterPill(
                                  'In Progress (${enrollment.enrolledCourses.where((c) => !c.completed && c.progressPercent < 100.0).length})',
                                  'in_progress',
                                ),
                                const SizedBox(width: 8),
                                _buildFilterPill(
                                  'Completed (${enrollment.enrolledCourses.where((c) => c.completed || c.progressPercent >= 100.0).length})',
                                  'completed',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Enrolled Courses List or Empty State
                  if (enrollment.enrolledCourses.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    )
                  else if (filteredList.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 12),
                              Text(
                                'No courses match your filter.',
                                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.navyDark),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _selectedFilter = 'all');
                                },
                                child: const Text('Reset Filter'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final course = filteredList[index];
                            return _buildCourseCard(course);
                          },
                          childCount: filteredList.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterPill(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navyDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.navyDark : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2l),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.gold.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_stories_outlined, color: AppColors.gold, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'No Enrolled Courses Yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore our rich catalog of Quran, Arabic, and Islamic studies programs to begin learning.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: PrimaryButton(
                label: 'Explore Courses',
                icon: Icons.school_outlined,
                onPressed: () => context.push(AppRoutes.courses),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(EnrolledCourseModel course) {
    final isDone = course.completed || course.progressPercent >= 100.0;
    final effectiveCourseId = course.courseId > 0 ? course.courseId : course.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image & Badges
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ZabiraNetworkImage(
                    imageUrl: course.resolvedImage,
                    fit: BoxFit.cover,
                    fallbackIcon: Icons.menu_book_rounded,
                  ),

                  // Top gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withAlpha(120), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  // Access Status Badge (Top Left)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: AppColors.navyDark.withAlpha(200),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.gold.withAlpha(140)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded, color: AppColors.gold, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            course.isActive ? 'Active Access' : course.status.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Completed Badge (Top Right)
                  if (isDone)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Completed',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
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
          ),

          // Content Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category & Meta Chips
                Row(
                  children: [
                    if (course.categoryName != null && course.categoryName!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF9E6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          course.categoryName!,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF926200),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    _buildMetaChip(Icons.schedule_rounded, course.duration),
                    const SizedBox(width: 8),
                    _buildMetaChip(Icons.bar_chart_rounded, course.level),
                  ],
                ),
                const SizedBox(height: 8),

                // Course Title
                Text(
                  course.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                if (course.instructorName != null && course.instructorName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Instructor: ${course.instructorName}',
                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
                  ),
                ],

                const SizedBox(height: 12),

                // Progress Info Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${course.progressPercentInt}% Completed',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDone ? const Color(0xFF10B981) : AppColors.gold,
                      ),
                    ),
                    if (course.lessonsCount > 0)
                      Text(
                        '${course.completedLessonsCount} of ${course.lessonsCount} lessons',
                        style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF64748B)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),

                // Sleek Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (course.progressPercent / 100).clamp(0.0, 1.0),
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDone ? const Color(0xFF10B981) : AppColors.gold,
                    ),
                    minHeight: 6.5,
                  ),
                ),

                const SizedBox(height: 16),

                // Action Buttons Row
                Row(
                  children: [
                    // Start / Continue Learning Button -> launches /courses/:id/learn
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.push('/courses/$effectiveCourseId/learn');
                          },
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: Text(
                            isDone ? 'Review Course' : (course.progressPercent > 0 ? 'Continue Learning' : 'Start Learning'),
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navyDark,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Course Details / Curriculum Overview
                    IconButton.filledTonal(
                      onPressed: () {
                        context.push('/courses/$effectiveCourseId');
                      },
                      icon: const Icon(Icons.info_outline_rounded, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        foregroundColor: AppColors.navyDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      tooltip: 'Course Overview',
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

  Widget _buildMetaChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF64748B)),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B)),
        ),
      ],
    );
  }
}
