import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/zabira_bottom_nav.dart';
import '../../../../shared/widgets/zabira_network_image.dart';
import '../../../auth/auth_controller.dart';
import '../../../courses/data/models/enrolled_course_model.dart';
import '../../../courses/presentation/controllers/enrollment_controller.dart';
import '../controllers/student_controller.dart';
import '../widgets/student_breadcrumb.dart';
import '../widgets/student_hero_header.dart';
import '../widgets/student_nav_tabs_bar.dart';

/// Screen 2: Student My Courses (1:1 with `2 - profile course 2.pdf`)
class StudentMyCoursesPage extends StatefulWidget {
  const StudentMyCoursesPage({super.key});

  @override
  State<StudentMyCoursesPage> createState() => _StudentMyCoursesPageState();
}

class _StudentMyCoursesPageState extends State<StudentMyCoursesPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final auth = context.read<AuthController>();
    if (auth.isAuthenticated && auth.user != null) {
      context.read<StudentController>().loadDashboard(
            auth.currentToken,
            defaultName: auth.user!.displayName,
            defaultEmail: auth.user!.email,
            defaultPhoto: auth.user!.photoUrl,
          );
      context.read<EnrollmentController>().loadMyCourses(auth.currentToken);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final studentCtrl = context.watch<StudentController>();
    final enrollment = context.watch<EnrollmentController>();
    final user = auth.user;

    final enrolledCourses = enrollment.enrolledCourses;
    final dashboard = studentCtrl.dashboard;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppDrawer(),
      bottomNavigationBar: const ZabiraBottomNav(selectedIndex: -1),
      body: RefreshIndicator(
        color: const Color(0xFFC9A84C),
        onRefresh: () async {
          _loadData();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Dark Navy Top Hero Header
                StudentHeroHeader(user: user, dashboard: dashboard),

                // 2. Horizontal Nav Bar (Index 1: My Courses)
                const StudentNavTabsBar(selectedIndex: 1),

                // 3. Breadcrumb & Section Title
                StudentBreadcrumbHeader(
                  currentPage: 'My Courses',
                  title: 'My Courses',
                  subtitle: 'All programs you are enrolled in — continue anytime.',
                  actionWidget: ElevatedButton(
                    onPressed: () => context.go(AppRoutes.courses),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC9A84C),
                      foregroundColor: const Color(0xFF112039),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Browse catalog',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF112039),
                      ),
                    ),
                  ),
                ),

                // 4. Enrolled Courses Grid / List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: enrollment.isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(color: Color(0xFFC9A84C)),
                          ),
                        )
                      : enrolledCourses.isEmpty
                          ? _buildEmptyState(context)
                          : _buildCourseGrid(context, enrolledCourses),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFC9A84C).withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.bookOpen, size: 30, color: Color(0xFFC9A84C)),
          ),
          const SizedBox(height: 18),
          Text(
            'No courses enrolled yet',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Explore our Quran, Arabic, and Islamic studies courses to begin.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.courses),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF112039),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Browse Courses',
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseGrid(BuildContext context, List<EnrolledCourseModel> courses) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final course = courses[index];
        return _buildCourseCard(context, course);
      },
    );
  }

  Widget _buildCourseCard(BuildContext context, EnrolledCourseModel course) {
    final progress = (course.progressPercent / 100.0).clamp(0.0, 1.0);
    final isOneToOne = course.duration.toLowerCase().contains('one') || (course.categoryName?.toLowerCase().contains('quran') ?? false);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            final cid = course.courseId > 0 ? course.courseId : course.id;
            context.push('/courses/$cid/learn');
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Thumbnail Banner
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: SizedBox(
                  width: double.infinity,
                  height: 160,
                  child: ZabiraNetworkImage(
                    imageUrl: course.coverImage,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge: ONE-TO-ONE CLASS / SELF-PACED LEARNING
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isOneToOne ? 'ONE-TO-ONE CLASS' : 'SELF-PACED LEARNING',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF475569),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      course.title.isNotEmpty ? course.title : 'Course Name',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Lesson & Duration Info
                    Row(
                      children: [
                        const Icon(LucideIcons.clock, size: 13, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          '${course.duration.isNotEmpty ? course.duration : '6 months'}  ${course.lessonsCount > 0 ? '${course.lessonsCount} lessons' : '1 lessons'}',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Info Card Inner Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEDF2F7)),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(LucideIcons.calendar, 'Upcoming · ${course.duration.isNotEmpty ? course.duration : '6 months'}'),
                          const SizedBox(height: 8),
                          _buildInfoRow(LucideIcons.user, 'Teacher · ${(course.instructorName != null && course.instructorName!.isNotEmpty) ? course.instructorName! : 'Assigned teacher'}'),
                          const SizedBox(height: 8),
                          _buildInfoRow(LucideIcons.calendarCheck, 'Attendance · Tracked'),
                          const SizedBox(height: 8),
                          _buildInfoRow(LucideIcons.bookOpen, 'Homework · Assignments active'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Progress Bar & Percentage
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${course.progressPercent.toInt()}%',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC9A84C)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF475569),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
