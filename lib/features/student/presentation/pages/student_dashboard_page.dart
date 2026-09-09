import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/zabira_bottom_nav.dart';
import '../../../../shared/widgets/zabira_network_image.dart';
import '../../../auth/auth_controller.dart';
import '../../../auth/presentation/widgets/auth_bottom_sheet.dart';
import '../../../courses/data/models/course_api_model.dart';
import '../../../courses/data/models/enrolled_course_model.dart';
import '../../../courses/data/services/course_service.dart';
import '../../../courses/presentation/controllers/enrollment_controller.dart';
import '../../../courses/presentation/controllers/wishlist_controller.dart';
import '../../../store/presentation/controllers/cart_controller.dart';
import '../controllers/student_controller.dart';
import '../../data/models/student_dashboard_model.dart';
import '../widgets/student_hero_header.dart';
import '../widgets/student_nav_tabs_bar.dart';

/// Screen 1: Student Profile Dashboard (1:1 with `1 - profile dashboard 1.pdf`)
class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final CourseService _courseService = CourseService();
  List<CourseApiModel> _recommendedCourses = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final auth = context.read<AuthController>();
    if (auth.isAuthenticated && auth.user != null) {
      final user = auth.user!;
      context.read<StudentController>().loadDashboard(
            auth.currentToken,
            defaultName: user.displayName,
            defaultEmail: user.email,
            defaultPhoto: user.photoUrl,
          );
      context.read<EnrollmentController>().loadMyCourses(auth.currentToken);
      context.read<CartController>().loadCart(auth.currentToken);
      _loadRecommendedCourses();
    }
  }

  Future<void> _loadRecommendedCourses() async {
    try {
      final res = await _courseService.getCourses(limit: 6);
      final rawList = res['data'] ?? res['courses'] ?? [];
      if (rawList is List) {
        final parsed = rawList
            .whereType<Map<String, dynamic>>()
            .map((c) => CourseApiModel.fromJson(c))
            .toList();
        if (mounted) {
          setState(() {
            _recommendedCourses = parsed;
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final auth = context.watch<AuthController>();
    final studentCtrl = context.watch<StudentController>();
    final enrollment = context.watch<EnrollmentController>();
    final wishlistCtrl = context.watch<WishlistController>();

    final user = auth.user;
    if (!auth.isAuthenticated || user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.lock, size: 48, color: Color(0xFF112039)),
              const SizedBox(height: 16),
              Text(
                'Please sign in to access your dashboard.',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => showAuthBottomSheet(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF112039),
                  foregroundColor: const Color(0xFFC9A84C),
                ),
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    final dashboard = studentCtrl.dashboard ??
        StudentDashboardModel(
          studentName: user.displayName,
          email: user.email,
          photoUrl: user.photoUrl,
          myCoursesCount: enrollment.enrolledCourses.length,
          continueLearningCourses: enrollment.enrolledCourses,
        );

    final enrolledCourses = enrollment.enrolledCourses;
    final continueCourses = (enrolledCourses.isNotEmpty
            ? enrolledCourses
            : dashboard.continueLearningCourses)
        .where((c) => !c.isCompleted && c.progressPercent < 100.0)
        .toList();

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
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: const AppDrawer(currentRoute: AppRoutes.studentDash),
        bottomNavigationBar: const ZabiraBottomNav(selectedIndex: -1),
        body: RefreshIndicator(
          color: const Color(0xFFC9A84C),
          onRefresh: () async {
            _loadData();
            await Future.delayed(const Duration(milliseconds: 600));
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Dark Navy Top Hero Header ────────────────────────────
                StudentHeroHeader(user: user, dashboard: dashboard),

                // ── 2. Filter Navigation Pills (Index 0: Dashboard) ─────────
                const StudentNavTabsBar(selectedIndex: 0),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18),

                      // ── 3. KPI Metric Cards Grid (7 Cards) ────────────────
                      _buildKpiMetricsGrid(
                        context,
                        dashboard,
                        continueCourses,
                        enrolledCourses,
                        wishlistCount: wishlistCtrl.count > 0 ? wishlistCtrl.count : dashboard.wishlistCount,
                      ),

                      const SizedBox(height: 28),

                      // ── 4. Continue Learning Section ──────────────────────
                      _buildContinueLearningSection(context, continueCourses),

                      const SizedBox(height: 28),

                      // ── 5. Enrolled Programs Section ──────────────────────
                      _buildEnrolledProgramsSection(context, enrolledCourses),

                      const SizedBox(height: 28),

                      // ── 6. Recommended For You Catalog ────────────────────
                      _buildRecommendedSection(context),

                      const SizedBox(height: 24),

                      // ── 7. Weekly Goal Card ───────────────────────────────
                      _buildWeeklyGoalCard(dashboard),

                      const SizedBox(height: 16),

                      // ── 8. Upcoming Live Class / Free Trial ───────────────
                      _buildUpcomingLiveClassCard(context, dashboard),

                      const SizedBox(height: 16),

                      // ── 9. Recent Certificates ────────────────────────────
                      _buildRecentCertificatesCard(context, dashboard),

                      const SizedBox(height: 16),

                      // ── 10. Notifications Inbox ───────────────────────────
                      _buildNotificationsCard(context, dashboard),

                      const SizedBox(height: 16),

                      // ── 11. Quick Actions ─────────────────────────────────
                      _buildQuickActionsCard(context),

                      const SizedBox(height: 16),

                      // ── 12. Achievements Preview ──────────────────────────
                      _buildAchievementsCard(),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. KPI Metric Cards Grid
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildKpiMetricsGrid(
    BuildContext context,
    StudentDashboardModel dashboard,
    List<EnrolledCourseModel> continueCourses,
    List<EnrolledCourseModel> enrolledCourses, {
    required int wishlistCount,
  }) {
    final overallProgress = enrolledCourses.isNotEmpty
        ? (enrolledCourses.map((c) => c.progressPercent).reduce((a, b) => a + b) / enrolledCourses.length).toInt()
        : dashboard.progressPercent.toInt();

    final metrics = [
      {'label': 'My orders', 'value': '${dashboard.myOrdersCount}', 'icon': LucideIcons.banknote, 'route': '/student/orders'},
      {'label': 'My courses', 'value': '${enrolledCourses.isNotEmpty ? enrolledCourses.length : dashboard.myCoursesCount}', 'icon': LucideIcons.bookOpen, 'route': '/student/courses'},
      {'label': 'In progress', 'value': '${continueCourses.isNotEmpty ? continueCourses.length : dashboard.inProgressCount}', 'icon': LucideIcons.play, 'route': '/student/continue'},
      {'label': 'Progress', 'value': '$overallProgress%', 'icon': LucideIcons.trendingUp, 'route': null},
      {'label': 'Certificates', 'value': '${dashboard.certificatesCount}', 'icon': LucideIcons.award, 'route': '/student/certificates'},
      {'label': 'Wishlist', 'value': '$wishlistCount', 'icon': LucideIcons.heart, 'route': '/student/wishlist'},
      {'label': 'Live classes', 'value': '${dashboard.liveClassesCount}', 'icon': LucideIcons.video, 'route': '/student/help'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 82,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final item = metrics[index];
        final route = item['route'] as String?;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: route != null ? () => context.go(route) : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              child: Row(
                children: [
                  Icon(item['icon'] as IconData, size: 20, color: const Color(0xFF1E293B)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item['label'] as String,
                          style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['value'] as String,
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
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

  // ───────────────────────────────────────────────────────────────────────────
  // 4. Continue Learning Section
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildContinueLearningSection(BuildContext context, List<EnrolledCourseModel> courses) {
    final firstCourse = courses.isNotEmpty ? courses.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('CONTINUE LEARNING', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 0.8)),
                  ],
                ),
                const SizedBox(height: 3),
                Text('Pick up where you left off', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
              ],
            ),
            GestureDetector(
              onTap: () => context.go('/student/continue'),
              child: Text('View all', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (firstCourse != null)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: SizedBox(
                    width: double.infinity,
                    height: 160,
                    child: ZabiraNetworkImage(imageUrl: firstCourse.coverImage, fit: BoxFit.cover),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (firstCourse.categoryName != null && firstCourse.categoryName!.isNotEmpty)
                            ? firstCourse.categoryName!.toUpperCase()
                            : 'LANGUAGE OF QURAN',
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFC9A84C), letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        firstCourse.title,
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last watched lesson · 1 lesson remaining · ~18 min left',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Course progress', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                          Text('${firstCourse.progressPercent.toInt()}%', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (firstCourse.progressPercent / 100.0).clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC9A84C)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                final cid = firstCourse.courseId > 0 ? firstCourse.courseId : firstCourse.id;
                                context.push('/courses/$cid/learn');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC9A84C),
                                foregroundColor: const Color(0xFF112039),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              child: Text('Resume lesson', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF112039))),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                final cid = firstCourse.courseId > 0 ? firstCourse.courseId : firstCourse.id;
                                context.push('/courses/$cid');
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              child: Text('Open course', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Center(
              child: Text('No courses in progress.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
            ),
          ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 5. Enrolled Programs Section
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildEnrolledProgramsSection(BuildContext context, List<EnrolledCourseModel> enrolledCourses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('MY COURSES', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 0.8)),
                  ],
                ),
                const SizedBox(height: 3),
                Text('Your enrolled programs', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
              ],
            ),
            GestureDetector(
              onTap: () => context.go('/student/courses'),
              child: Text('View all', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (enrolledCourses.isNotEmpty)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: enrolledCourses.take(2).length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final course = enrolledCourses[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 60,
                            height: 60,
                            child: ZabiraNetworkImage(imageUrl: course.coverImage, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                                child: Text('ONE-TO-ONE CLASS', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF475569))),
                              ),
                              const SizedBox(height: 3),
                              Text(course.title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                              Text('1 lessons · 6 months', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Progress', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                        Text('${course.progressPercent.toInt()}%', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (course.progressPercent / 100.0).clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC9A84C)),
                      ),
                    ),
                  ],
                ),
              );
            },
          )
        else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Center(
              child: Text('No enrolled programs yet.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
            ),
          ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 6. Recommended For You Section
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildRecommendedSection(BuildContext context) {
    final recCourses = _recommendedCourses.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('RECOMMENDED FOR YOU', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 0.8)),
                  ],
                ),
                const SizedBox(height: 3),
                Text('Programs students love right now', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
              ],
            ),
            GestureDetector(
              onTap: () => context.go(AppRoutes.courses),
              child: Text('Catalog', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (recCourses.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: recCourses.length,
            itemBuilder: (context, index) {
              final c = recCourses[index];
              return InkWell(
                onTap: () => context.push('/courses/${c.id}'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                        child: SizedBox(
                          width: double.infinity,
                          height: 90,
                          child: ZabiraNetworkImage(imageUrl: c.thumbnail, fit: BoxFit.cover),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.courseType.isNotEmpty ? c.courseType.toUpperCase() : 'QURAN STUDIES',
                              style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFFC9A84C), letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              c.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A), height: 1.2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          )
        else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Center(
              child: Text('Loading recommendations...', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
            ),
          ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 7. Weekly Goal Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildWeeklyGoalCard(StudentDashboardModel dashboard) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Weekly goal', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
              const Icon(LucideIcons.sparkles, size: 18, color: Color(0xFFC9A84C)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${dashboard.weeklyGoalCurrent} of ${dashboard.weeklyGoalTarget} learning moments',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (dashboard.weeklyGoalCurrent / dashboard.weeklyGoalTarget.toDouble()).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC9A84C)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Average course completion · ${dashboard.averageCourseCompletion.toInt()}%',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 8. Upcoming Live Class / Free Trial Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildUpcomingLiveClassCard(BuildContext context, StudentDashboardModel dashboard) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upcoming live class', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Text('No live sessions scheduled.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.courses),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF112039),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Book a free trial', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 9. Recent Certificates Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildRecentCertificatesCard(BuildContext context, StudentDashboardModel dashboard) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent certificates', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
              GestureDetector(
                onTap: () => context.go('/student/certificates'),
                child: Text('All', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Complete a course to earn your first certificate.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 10. Notifications Inbox Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildNotificationsCard(BuildContext context, StudentDashboardModel dashboard) {
    final notifs = dashboard.notifications.take(4).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Notifications', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
              GestureDetector(
                onTap: () => context.go('/student/notifications'),
                child: Text('Inbox', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (notifs.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notifs.length,
              separatorBuilder: (_, _) => const Divider(height: 16, thickness: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final n = notifs[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title, style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text(n.message, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                  ],
                );
              },
            )
          else
            Text('No new notifications.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 11. Quick Actions Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildQuickActionsCard(BuildContext context) {
    final actions = [
      {'label': 'Wishlist', 'icon': LucideIcons.heart, 'route': '/student/wishlist'},
      {'label': 'Free trials', 'icon': LucideIcons.video, 'route': '/courses'},
      {'label': 'Certificates', 'icon': LucideIcons.award, 'route': '/student/certificates'},
      {'label': 'Browse catalog', 'icon': LucideIcons.bookOpen, 'route': AppRoutes.courses},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick actions', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: List.generate(actions.length, (index) {
              final a = actions[index];
              final isLast = index == actions.length - 1;

              return Column(
                children: [
                  ListTile(
                    leading: Icon(a['icon'] as IconData, size: 18, color: const Color(0xFF1E293B)),
                    title: Text(a['label'] as String, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                    trailing: const Icon(LucideIcons.arrowUpRight, size: 16, color: Color(0xFF94A3B8)),
                    onTap: () => context.go(a['route'] as String),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  ),
                  if (!isLast) const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 12. Achievements Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildAchievementsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Achievements', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Text(
            'Badges and learning milestones will appear here as you progress — stay consistent.',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), height: 1.4),
          ),
        ],
      ),
    );
  }
}
