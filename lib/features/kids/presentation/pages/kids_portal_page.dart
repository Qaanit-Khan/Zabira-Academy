import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/zabira_logo.dart';
import '../controllers/kids_controller.dart';
import '../../data/models/kids_models.dart';

/// Zabira Academy — Kids Learning Portal Screen
///
/// Mobile-first native implementation matching `Zabira Academy _ Kids Learning Portal.pdf`.
class KidsPortalPage extends StatefulWidget {
  const KidsPortalPage({super.key});

  @override
  State<KidsPortalPage> createState() => _KidsPortalPageState();
}

class _KidsPortalPageState extends State<KidsPortalPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KidsController>().loadKidsPortal();
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final kidsCtrl = context.watch<KidsController>();
    final categories = kidsCtrl.categories;
    final games = kidsCtrl.games;
    final quizzes = kidsCtrl.quizzes;

    final selectedCat = kidsCtrl.selectedCategory;
    final filteredGames = selectedCat == null
        ? games
        : games.where((g) => g.category?.toLowerCase() == selectedCat.toLowerCase()).toList();

    final filteredQuizzes = selectedCat == null
        ? quizzes
        : quizzes.where((q) => q.category?.toLowerCase() == selectedCat.toLowerCase()).toList();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () => kidsCtrl.loadKidsPortal(forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Playful Dark Navy Hero Header ──────────────────────────
              _buildKidsHeroHeader(context),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // ── 2. Primary 4 Categories Grid ─────────────────────────
                    _buildCategoriesGrid(context, categories, kidsCtrl),

                    const SizedBox(height: 24),

                    // ── 3. Category Filter Chips ─────────────────────────────
                    _buildCategoryFilterChips(categories, kidsCtrl),

                    const SizedBox(height: 20),

                    // ── 4. Interactive Quizzes Section ───────────────────────
                    _buildQuizzesSection(context, filteredQuizzes),

                    const SizedBox(height: 24),

                    // ── 5. Islamic Games Section ─────────────────────────────
                    _buildGamesSection(context, filteredGames),

                    const SizedBox(height: 24),

                    // ── 6. Kids Special Program Banner ───────────────────────
                    _buildSpecialProgramBanner(context),

                    const SizedBox(height: 24),

                    // ── 7. Kids Rewards & Gamification Preview ───────────────
                    _buildRewardsPreviewCard(),

                    const SizedBox(height: 24),

                    // ── 8. For Parents Trust Section ─────────────────────────
                    _buildForParentsTrustSection(),

                    const SizedBox(height: AppSpacing.x3l),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Kids Dark Navy Hero Header
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildKidsHeroHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        MediaQuery.of(context).padding.top + 12,
        AppSpacing.screenHorizontal,
        28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Menu Row
          Row(
            children: [
              GestureDetector(
                onTap: () => context.go(AppRoutes.home),
                child: const ZabiraLogo(size: LogoSize.small),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.home_outlined, color: Colors.white70, size: 22),
                tooltip: 'Home',
                onPressed: () => context.go(AppRoutes.home),
              ),
              IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
                tooltip: 'Menu',
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Age Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withAlpha(40),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                const SizedBox(width: 6),
                Text(
                  '5–12 YEARS · KIDS PORTAL',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFF59E0B),
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Title & Subtitle
          Text(
            'Safe • Fun • Interactive\nIslamic Learning',
            style: GoogleFonts.outfit(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Interactive Quran stories, gamified Arabic learning, animated Hadith, and Islamic values designed specifically for young Muslim hearts.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.white.withAlpha(200),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),

          // CTAs
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.auto_stories_rounded, size: 16),
                  label: const Text('EXPLORE STORIES'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navyDark,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.courses),
                  icon: const Icon(Icons.child_care_rounded, size: 16),
                  label: const Text('JOIN PROGRAM'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
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
  // Primary 4 Categories Grid
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildCategoriesGrid(BuildContext context, List<KidsCategoryItem> categories, KidsController ctrl) {
    final catData = [
      (
        'Quran Stories',
        'Inspiring stories from the Quran',
        Icons.auto_stories_rounded,
        const Color(0xFF3B82F6),
        const Color(0xFFEFF6FF),
      ),
      (
        'Islamic Games',
        'Interactive games & fun puzzles',
        Icons.sports_esports_rounded,
        const Color(0xFF10B981),
        const Color(0xFFECFDF5),
      ),
      (
        'Daily Duas',
        'Morning & daily prayers for kids',
        Icons.pan_tool_rounded,
        const Color(0xFFF59E0B),
        const Color(0xFFFFFBEB),
      ),
      (
        'Interactive Quizzes',
        'Test and level up knowledge',
        Icons.extension_rounded,
        const Color(0xFF8B5CF6),
        const Color(0xFFF5F3FF),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemCount: catData.length,
      itemBuilder: (context, index) {
        final c = catData[index];
        return GestureDetector(
          onTap: () => ctrl.selectCategory(c.$1),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: c.$5,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(c.$3, color: c.$4, size: 22),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      c.$2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Category Filter Chips
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildCategoryFilterChips(List<KidsCategoryItem> categories, KidsController ctrl) {
    final list = [
      ('All', null),
      ('Quran Stories', 'Quran Stories'),
      ('Islamic Games', 'Islamic Games'),
      ('Daily Duas', 'Daily Duas'),
      ('Interactive Quizzes', 'Interactive Quizzes'),
    ];

    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          final isSelected = ctrl.selectedCategory == item.$2;
          return GestureDetector(
            onTap: () => ctrl.selectCategory(item.$2),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.navyDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.navyDark : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                item.$1,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Interactive Quizzes Section
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildQuizzesSection(BuildContext context, List<KidsQuizItem> quizzes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Interactive Quizzes',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navyDark,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${quizzes.length} QUIZZES',
                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF8B5CF6)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...quizzes.map((quiz) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.extension_rounded, color: Color(0xFF8B5CF6), size: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${quiz.questionsCount} Questions · ${quiz.difficulty}',
                            style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '+${quiz.pointsReward} XP',
                              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFFB45309)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => context.push('/kids/quiz/${quiz.id}', extra: quiz),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Play',
                    style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Islamic Games Section
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildGamesSection(BuildContext context, List<KidsGameItem> games) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Islamic Games',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navyDark,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${games.length} GAMES',
                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF10B981)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...games.map((game) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.sports_esports_rounded, color: Color(0xFF10B981), size: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${game.difficulty} · ${game.ageGroup}',
                            style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '+${game.pointsReward} XP',
                              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFFB45309)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => context.push('/kids/game/${game.id}', extra: game),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Play',
                    style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Kids Special Program Banner
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSpecialProgramBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              Text(
                'Kids Special Program',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Live 1-to-1 classes tailored for kids 5–12 years. Learn Quran with Tajweed, Islamic values, and Arabic with certified teachers.',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              color: Colors.white.withAlpha(200),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          _programPerk('Live 1-to-1 Teacher Guidance'),
          _programPerk('Personalized Weekly Learning Plan'),
          _programPerk('Homework, Quizzes & Assessments'),
          _programPerk('Certificates Upon Level Completion'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => context.push(AppRoutes.courses),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.navyDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                'Book a Free Trial Class',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _programPerk(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 15),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.white.withAlpha(220)),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Kids Rewards & Gamification Preview
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildRewardsPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Guest Explorer · Level 1',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '0 XP · 0 COINS',
                  style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFFB45309)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Complete quizzes and games to earn coins, unlock badges, and level up your Islamic knowledge!',
            style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // For Parents Trust Section
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildForParentsTrustSection() {
    final trusts = [
      ('Curated by Scholars', '100% authentic Islamic content vetted by experts.', Icons.verified_user_rounded),
      ('Safe & Ad-Free', 'Zero ads, external popups, or inappropriate media.', Icons.security_rounded),
      ('Progress Tracking', 'Monitor learning milestones from Parent Dashboard.', Icons.trending_up_rounded),
      ('Certified Instructors', 'Trained male & female teachers for young minds.', Icons.school_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why Parents Trust Zabira Kids',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.navyDark,
            ),
          ),
          const SizedBox(height: 12),
          ...trusts.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(t.$3, color: AppColors.gold, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.$1,
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navyDark),
                        ),
                        Text(
                          t.$2,
                          style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF64748B)),
                        ),
                      ],
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
          _navItem(context, 'Kids', Icons.child_care_rounded, true, () {}),
          _navItem(context, 'Dashboard', Icons.dashboard_outlined, false, () => context.push(AppRoutes.studentDash)),
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
