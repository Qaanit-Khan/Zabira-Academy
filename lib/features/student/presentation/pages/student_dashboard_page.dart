import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/auth_controller.dart';
import '../../../courses/data/models/enrolled_course_model.dart';
import '../../../courses/presentation/controllers/enrollment_controller.dart';
import '../../../store/presentation/controllers/cart_controller.dart';
import '../../../../shared/widgets/zabira_logo.dart';
import '../../../../shared/widgets/zabira_network_image.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../controllers/student_controller.dart';
import '../../data/models/student_dashboard_model.dart';

/// Zabira Academy — Authenticated Student Dashboard
///
/// Mobile-first adaptation of `Zabira Academy _ Student Dashboard.pdf`.
class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
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
    final cart = context.watch<CartController>();

    final user = auth.user;
    if (!auth.isAuthenticated || user == null) {
      return Scaffold(
        backgroundColor: AppColors.surfaceLight,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 48, color: AppColors.navyDark),
              const SizedBox(height: 16),
              Text('Please sign in to access your dashboard.', style: AppTypography.titleMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.login),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyDark,
                  foregroundColor: AppColors.gold,
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

    final continueCourses = (enrollment.enrolledCourses.isNotEmpty
            ? enrollment.enrolledCourses
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
        drawer: const AppDrawer(),
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () async {
          _loadData();
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Dark Navy Top Hero Header ──────────────────────────────
              _buildDarkHeroHeader(context, user, dashboard, cart.itemCount),

              // ── 2. Filter Navigation Pills ────────────────────────────────
              _buildFilterPills(context, studentCtrl),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),

                    // ── 3. KPI Metric Cards Grid (7 Cards) ──────────────────
                    _buildKpiMetricsGrid(context, dashboard, continueCourses),

                    const SizedBox(height: AppSpacing.x2l),

                    // ── 4. Continue Learning Section ────────────────────────
                    _buildContinueLearningSection(context, continueCourses),

                    const SizedBox(height: AppSpacing.x2l),

                    // ── 5. Recommended For You Catalog ──────────────────────
                    _buildRecommendedSection(context),

                    const SizedBox(height: AppSpacing.x2l),

                    // ── 6. Weekly Goal Card ─────────────────────────────────
                    _buildWeeklyGoalCard(dashboard),

                    const SizedBox(height: AppSpacing.lg),

                    // ── 7. Upcoming Live Class / Free Trial ─────────────────
                    _buildUpcomingLiveClassCard(context, dashboard),

                    const SizedBox(height: AppSpacing.lg),

                    // ── 8. Recent Certificates ──────────────────────────────
                    _buildRecentCertificatesCard(context, dashboard),

                    const SizedBox(height: AppSpacing.lg),

                    // ── 9. Notifications Inbox ──────────────────────────────
                    _buildNotificationsCard(context, studentCtrl, dashboard),

                    const SizedBox(height: AppSpacing.lg),

                    // ── 10. Quick Actions ───────────────────────────────────
                    _buildQuickActionsCard(context),

                    const SizedBox(height: AppSpacing.lg),

                    // ── 11. Achievements Preview ────────────────────────────
                    _buildAchievementsCard(),

                    const SizedBox(height: AppSpacing.x3l),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Dark Navy Hero Header
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildDarkHeroHeader(
    BuildContext context,
    dynamic user,
    StudentDashboardModel dashboard,
    int cartCount,
  ) {
    final initials = user.displayName.isNotEmpty
        ? user.displayName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'ST';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        MediaQuery.of(context).padding.top + 12,
        AppSpacing.screenHorizontal,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Logo + Icons
          Row(
            children: [
              GestureDetector(
                onTap: () => context.go(AppRoutes.home),
                child: const ZabiraLogo(size: LogoSize.small),
              ),
              const Spacer(),
              // Home button
              IconButton(
                icon: const Icon(Icons.home_outlined, color: Colors.white70, size: 22),
                tooltip: 'Home',
                onPressed: () => context.go(AppRoutes.home),
              ),
              // Cart button
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white70, size: 22),
                    tooltip: 'Cart',
                    onPressed: () => context.push(AppRoutes.cart),
                  ),
                  if (cartCount > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$cartCount',
                          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.navyDark),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              // Drawer Menu Hamburger
              IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
                tooltip: 'Menu',
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withAlpha(40)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.gold, size: 13),
                const SizedBox(width: 6),
                Text(
                  'ZABIRA ACADEMY · STUDENT',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // User Card
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.gold.withAlpha(40),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Greeting & Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getGreeting()} · Assalamu Alaikum',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.displayName,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      user.email,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Workspace Subtitle
          Text(
            'Your personal learning workspace — continue courses, track progress, and grow in knowledge with intention.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.white.withAlpha(200),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),

          // Quote Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.format_quote_rounded, color: AppColors.gold, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '“${dashboard.quote}”',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withAlpha(220),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.myCourses),
                  icon: const Icon(Icons.play_circle_filled_rounded, size: 18),
                  label: const Text('Continue Learning'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navyDark,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.courses),
                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                  label: const Text('Browse Courses'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Sub-Navigation Filter Pills
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildFilterPills(BuildContext context, StudentController ctrl) {
    final tabs = [
      ('Dashboard', Icons.dashboard_outlined, () {}),
      ('My Courses', Icons.menu_book_outlined, () => context.push(AppRoutes.myCourses)),
      ('My Books', Icons.library_books_outlined, () => context.push(AppRoutes.library)),
      ('Continue', Icons.play_circle_outline, () => context.push(AppRoutes.myCourses)),
      ('Certificates', Icons.workspace_premium_outlined, () {}),
      ('My Orders', Icons.receipt_long_outlined, () => context.push('/my-orders')),
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 14),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final isSelected = ctrl.selectedFilterIndex == index;
          final tab = tabs[index];
          return GestureDetector(
            onTap: () {
              ctrl.setFilterIndex(index);
              tab.$3();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.navyDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.navyDark : const Color(0xFFE2E8F0),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.navyDark.withAlpha(40),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    tab.$2,
                    size: 16,
                    color: isSelected ? AppColors.gold : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tab.$1,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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

  // ───────────────────────────────────────────────────────────────────────────
  // KPI Metrics Grid (7 Stats)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildKpiMetricsGrid(
    BuildContext context,
    StudentDashboardModel d,
    List<EnrolledCourseModel> enrolled,
  ) {
    final inProgCount = enrolled.where((c) => c.progressPercent > 0 && c.progressPercent < 100).length;
    final totalCourses = enrolled.isNotEmpty ? enrolled.length : d.myCoursesCount;

    double avgProgress = 0.0;
    if (enrolled.isNotEmpty) {
      avgProgress = enrolled.map((e) => e.progressPercent).reduce((a, b) => a + b) / enrolled.length;
    }

    final kpis = [
      ('My orders', '${d.myOrdersCount}', Icons.receipt_long_rounded, const Color(0xFF2563EB), () => context.push('/my-orders')),
      ('My courses', '$totalCourses', Icons.menu_book_rounded, const Color(0xFF0D9488), () => context.push(AppRoutes.myCourses)),
      ('In progress', '$inProgCount', Icons.play_arrow_rounded, const Color(0xFFE11D48), () => context.push(AppRoutes.myCourses)),
      ('Progress', '${avgProgress.toInt()}%', Icons.trending_up_rounded, const Color(0xFFD97706), () {}),
      ('Certificates', '${d.certificatesCount}', Icons.workspace_premium_rounded, const Color(0xFF7C3AED), () {}),
      ('Wishlist', '${d.wishlistCount}', Icons.favorite_rounded, const Color(0xFFEC4899), () {}),
      ('Live classes', '${d.liveClassesCount}', Icons.videocam_rounded, const Color(0xFF059669), () {}),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 16) / 3;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kpis.map((kpi) {
                return GestureDetector(
                  onTap: kpi.$5,
                  child: Container(
                    width: cardWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(6),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              kpi.$1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            Icon(kpi.$3, size: 14, color: kpi.$4),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          kpi.$2,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navyDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Continue Learning Section
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildContinueLearningSection(
    BuildContext context,
    List<EnrolledCourseModel> courses,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'CONTINUE LEARNING',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.gold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Pick up where you left off',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.navyDark,
          ),
        ),
        const SizedBox(height: 12),

        if (courses.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: AppColors.gold, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  'Nothing in progress yet',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Open a course and start a lesson — it will appear here for quick resume.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => context.push(AppRoutes.courses),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navyDark,
                    side: const BorderSide(color: AppColors.navyDark),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Browse Courses'),
                ),
              ],
            ),
          ),
        ] else ...[
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final c = courses[index];
                final effectiveId = c.courseId > 0 ? c.courseId : c.id;
                final lessonParam = c.lastLessonId != null && c.lastLessonId! > 0 ? '?lesson_id=${c.lastLessonId}' : '';
                return GestureDetector(
                  onTap: () => context.push('/courses/$effectiveId/learn$lessonParam'),
                  child: Container(
                    width: 260,
                    margin: EdgeInsets.only(right: index < courses.length - 1 ? 12 : 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(6),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.navyDark,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: c.resolvedImage != null
                                ? ZabiraNetworkImage(imageUrl: c.resolvedImage, fit: BoxFit.cover)
                                : const Center(
                                    child: Icon(Icons.menu_book_rounded, color: AppColors.gold, size: 28),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                c.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navyDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: (c.progressPercent / 100).clamp(0.0, 1.0),
                                        backgroundColor: const Color(0xFFE2E8F0),
                                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                                        minHeight: 5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${c.progressPercentInt}%',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Recommended Programs Section
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildRecommendedSection(BuildContext context) {
    final progs = [
      ('Quran with Tajweed', 'QURAN STUDIES', 'assets/images/home/courses/quran_tajweed.png', 5),
      ('Young Muslims Program', 'ISLAMIC STUDIES', 'assets/images/home/courses/muslim_life.png', 6),
      ('Stories from the Quran', 'SELF-PACED', 'assets/images/home/courses/understand_quran.png', 7),
      ('Namaz & Dua Masterclass', 'PRACTICAL ISLAM', 'assets/images/home/courses/namaz_dua.png', 8),
    ];

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
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'RECOMMENDED FOR YOU',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.gold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Programs students love right now',
                  style: GoogleFonts.outfit(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyDark,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.courses),
              child: Text(
                'Catalog',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.45,
          ),
          itemCount: progs.length,
          itemBuilder: (context, index) {
            final p = progs[index];
            return GestureDetector(
              onTap: () => context.push('/courses/${p.$4}'),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      p.$2,
                      style: GoogleFonts.outfit(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.gold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.$1,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Weekly Goal Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildWeeklyGoalCard(StudentDashboardModel d) {
    return Container(
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
              Text(
                'Weekly goal',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDark,
                ),
              ),
              const Icon(Icons.star_rounded, color: AppColors.gold, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${d.weeklyGoalCurrent} of ${d.weeklyGoalTarget} learning moments',
            style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (d.weeklyGoalCurrent / d.weeklyGoalTarget).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Average course completion · ${d.averageCourseCompletion.toInt()}%',
            style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Upcoming Live Class / Free Trial Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildUpcomingLiveClassCard(BuildContext context, StudentDashboardModel d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming live class',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.navyDark,
            ),
          ),
          const SizedBox(height: 8),
          if (d.upcomingLiveClass != null) ...[
            Row(
              children: [
                const Icon(Icons.videocam_outlined, color: AppColors.gold, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    d.upcomingLiveClass!.title,
                    style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.navyDark),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'No live sessions scheduled.',
              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => context.push(AppRoutes.courses),
              child: Text(
                'Book a free trial',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Recent Certificates Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildRecentCertificatesCard(BuildContext context, StudentDashboardModel d) {
    return Container(
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
              Text(
                'Recent certificates',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDark,
                ),
              ),
              Text(
                'All',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (d.recentCertificates.isNotEmpty) ...[
            ...d.recentCertificates.map(
              (cert) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cert.courseTitle,
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navyDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Text(
              'Complete a course to earn your first certificate.',
              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)),
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Notifications Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildNotificationsCard(
    BuildContext context,
    StudentController ctrl,
    StudentDashboardModel d,
  ) {
    final token = context.read<AuthController>().currentToken;
    return Container(
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
              Text(
                'Notifications',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDark,
                ),
              ),
              GestureDetector(
                onTap: () => ctrl.markNotificationsRead(token),
                child: Text(
                  'Mark all read',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (d.notifications.isNotEmpty) ...[
            ...d.notifications.take(3).map(
              (n) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.title,
                      style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.navyDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      n.message,
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Text(
              'No unread notifications.',
              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)),
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Quick Actions Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildQuickActionsCard(BuildContext context) {
    final actions = [
      ('Wishlist', Icons.favorite_border_rounded, () {}),
      ('Free trials', Icons.videocam_outlined, () {}),
      ('Certificates', Icons.workspace_premium_outlined, () {}),
      ('Browse catalog', Icons.menu_book_outlined, () => context.push(AppRoutes.courses)),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick actions',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.navyDark,
            ),
          ),
          const SizedBox(height: 10),
          ...actions.map(
            (act) => InkWell(
              onTap: act.$3,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(act.$2, size: 18, color: const Color(0xFF64748B)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        act.$1,
                        style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.navyDark),
                      ),
                    ),
                    const Icon(Icons.arrow_outward_rounded, size: 16, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Achievements Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildAchievementsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Achievements',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.navyDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Badges and learning milestones will appear here as you progress — stay consistent.',
            style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Bottom Navigation
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: EdgeInsets.fromLTRB(8, 8, 8, MediaQuery.of(context).padding.bottom + 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(context, 'Home', Icons.home_outlined, false, () => context.go(AppRoutes.home)),
          _navItem(context, 'Courses', Icons.menu_book_outlined, false, () => context.push(AppRoutes.courses)),
          _navItem(context, 'Library', Icons.library_books_outlined, false, () => context.push(AppRoutes.library)),
          _navItem(context, 'Store', Icons.storefront_outlined, false, () => context.push(AppRoutes.store)),
          _navItem(context, 'Kids', Icons.child_care_outlined, false, () => context.push('/kids')),
          _navItem(context, 'Dashboard', Icons.dashboard_rounded, true, () {}),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, String label, IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: isActive ? AppColors.gold : const Color(0xFF64748B)),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10.5,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              color: isActive ? AppColors.navyDark : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
