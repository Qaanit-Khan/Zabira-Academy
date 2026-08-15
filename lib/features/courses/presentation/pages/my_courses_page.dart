import 'package:flutter/material.dart';
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

class MyCoursesPage extends StatefulWidget {
  const MyCoursesPage({super.key});

  @override
  State<MyCoursesPage> createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      context.read<EnrollmentController>().loadMyCourses(auth.currentToken);
    });
  }

  @override
  Widget build(BuildContext context) {
    final enrollment = context.watch<EnrollmentController>();
    final auth = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
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
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.navyDark,
          ),
        ),
        centerTitle: true,
      ),
      body: enrollment.isLoading && enrollment.enrolledCourses.isEmpty
          ? const Center(child: ZabiraLoader(size: 40))
          : enrollment.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => enrollment.loadMyCourses(auth.currentToken),
                  color: AppColors.gold,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: enrollment.enrolledCourses.length,
                    itemBuilder: (context, index) {
                      final course = enrollment.enrolledCourses[index];
                      return _buildCourseCard(course);
                    },
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
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore our rich catalog of Quran, Arabic, and Islamic studies courses to begin learning.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                  if (course.completed)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success,
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

          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Progress Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${course.progressPercentInt}% Completed',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gold,
                      ),
                    ),
                    if (course.lessonsCount > 0)
                      Text(
                        '${course.completedLessonsCount} / ${course.lessonsCount} lessons',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (course.progressPercent / 100).clamp(0.0, 1.0),
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                    minHeight: 6,
                  ),
                ),

                const SizedBox(height: 14),

                // Continue CTA
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/courses/${course.courseId}');
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: Text(
                      course.progressPercent > 0 ? 'Continue Learning' : 'Start Course',
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
}
