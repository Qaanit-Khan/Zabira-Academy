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

/// Screen 4: Student Continue Learning (1:1 with `4 - profile continue watching 4.pdf`)
class StudentContinueLearningPage extends StatefulWidget {
  const StudentContinueLearningPage({super.key});

  @override
  State<StudentContinueLearningPage> createState() => _StudentContinueLearningPageState();
}

class _StudentContinueLearningPageState extends State<StudentContinueLearningPage> {
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
    final dashboard = studentCtrl.dashboard;

    final continueCourses = (enrollment.enrolledCourses.isNotEmpty
            ? enrollment.enrolledCourses
            : (dashboard?.continueLearningCourses ?? <EnrolledCourseModel>[]))
        .where((c) => !c.isCompleted && c.progressPercent < 100.0)
        .toList();

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

                // 2. Horizontal Nav Bar (Index 3: Continue Learning)
                const StudentNavTabsBar(selectedIndex: 3),

                // 3. Breadcrumb & Section Title
                const StudentBreadcrumbHeader(
                  currentPage: 'Continue Learning',
                  title: 'Continue Learning',
                  subtitle: 'Pick up where you left off across your enrolled programs.',
                ),

                // 4. In-progress Courses List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: enrollment.isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(color: Color(0xFFC9A84C)),
                          ),
                        )
                      : continueCourses.isEmpty
                          ? _buildEmptyState(context)
                          : _buildContinueList(context, continueCourses),
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
            child: const Icon(LucideIcons.playCircle, size: 30, color: Color(0xFFC9A84C)),
          ),
          const SizedBox(height: 18),
          Text(
            'All caught up!',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You do not have any active lessons in progress.',
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
            child: Text('Browse Catalog', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueList(BuildContext context, List<EnrolledCourseModel> courses) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final course = courses[index];
        final progress = (course.progressPercent / 100.0).clamp(0.0, 1.0);
        final category = (course.categoryName != null && course.categoryName!.isNotEmpty)
            ? course.categoryName!.toUpperCase()
            : 'COURSE';

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
                  // Full width banner image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: SizedBox(
                      width: double.infinity,
                      height: 180,
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
                        // Category pill / text in golden
                        Text(
                          category,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFC9A84C),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Course Title
                        Text(
                          course.title.isNotEmpty ? course.title : 'Course Title',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Progress percentage text
                        Text(
                          '${course.progressPercent.toInt()}% complete',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Progress bar
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
      },
    );
  }
}
