import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
import '../../../../core/audio/global_audio_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/zabira_bottom_nav.dart';
import '../../../../shared/widgets/zabira_logo.dart';
import '../controllers/kids_controller.dart';
import '../../data/models/kids_models.dart';

class _KidsDuaItem {
  const _KidsDuaItem({
    required this.id,
    required this.category,
    required this.title,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.icon,
    required this.color,
    this.audioUrl,
  });

  final int id;
  final String category;
  final String title;
  final String arabic;
  final String transliteration;
  final String translation;
  final IconData icon;
  final Color color;
  final String? audioUrl;
}

/// Zabira Academy — Kids Learning Portal Screen
class KidsPortalPage extends StatefulWidget {
  const KidsPortalPage({super.key});

  @override
  State<KidsPortalPage> createState() => _KidsPortalPageState();
}

class _KidsPortalPageState extends State<KidsPortalPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Set<int> _learnedDuaIds = {};
  String? _selectedDuaCategory;

  static const List<_KidsDuaItem> _duasList = [
    _KidsDuaItem(
      id: 1,
      category: 'Morning',
      title: 'Waking Up Remembrance',
      arabic: 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
      transliteration: "Alhamdu lillahil-ladhee ahyana ba'da ma amatana wa-ilayhin-nushoor.",
      translation: 'All praise belongs to Allah who gave us life after having caused us to die, and unto Him is the resurrection.',
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFFF59E0B),
      audioUrl: 'https://api.zabiraacademy.com/storage/nasheed/sample_1.mp3',
    ),
    _KidsDuaItem(
      id: 2,
      category: 'Evening',
      title: 'Evening Remembrance',
      arabic: 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ',
      transliteration: "Amsayna wa-amsal-mulku lillah, walhamdu lillah.",
      translation: 'We have reached the evening and at this very time unto Allah belongs all sovereignty, and all praise is for Allah.',
      icon: Icons.nights_stay_rounded,
      color: Color(0xFF6366F1),
      audioUrl: 'https://api.zabiraacademy.com/storage/nasheed/sample_1.mp3',
    ),
    _KidsDuaItem(
      id: 3,
      category: 'Food',
      title: 'Before Eating Meal',
      arabic: 'بِسْمِ اللَّهِ وَعَلَى بَرَكَةِ اللَّهِ',
      transliteration: "Bismillahi wa 'ala barakatillah.",
      translation: 'In the name of Allah and with the blessings of Allah.',
      icon: Icons.restaurant_rounded,
      color: Color(0xFF10B981),
      audioUrl: 'https://api.zabiraacademy.com/storage/nasheed/sample_1.mp3',
    ),
    _KidsDuaItem(
      id: 4,
      category: 'Food',
      title: 'After Finishing Meal',
      arabic: 'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا وَجَعَلَنَا مُسْلِمِينَ',
      transliteration: "Alhamdu lillahil-lathee at'amana wa saqana wa ja'alana Muslimeen.",
      translation: 'All praise belongs to Allah who fed us and gave us drink and made us Muslims.',
      icon: Icons.soup_kitchen_rounded,
      color: Color(0xFF059669),
      audioUrl: 'https://api.zabiraacademy.com/storage/nasheed/sample_1.mp3',
    ),
    _KidsDuaItem(
      id: 5,
      category: 'Travel',
      title: 'Leaving Home & Travel',
      arabic: 'بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ، لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
      transliteration: "Bismillahi tawakkaltu 'alallahi, la hawla wa la quwwata illa billah.",
      translation: 'In the name of Allah, I trust in Allah; there is no power nor might except with Allah.',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF0284C7),
      audioUrl: 'https://api.zabiraacademy.com/storage/nasheed/sample_1.mp3',
    ),
    _KidsDuaItem(
      id: 6,
      category: 'Sleeping',
      title: 'Before Sleeping',
      arabic: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
      transliteration: "Bismika Allahumma amootu wa-ahya.",
      translation: 'In Your Name, O Allah, I die and I live.',
      icon: Icons.bedtime_rounded,
      color: Color(0xFF8B5CF6),
      audioUrl: 'https://api.zabiraacademy.com/storage/nasheed/sample_1.mp3',
    ),
    _KidsDuaItem(
      id: 7,
      category: 'Parents',
      title: 'Dua for Parents (Rabbir Humhuma)',
      arabic: 'رَّبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا',
      transliteration: "Rabbir-hamhuma kama rabbayani sagheera.",
      translation: 'My Lord, have mercy upon them as they brought me up when I was small.',
      icon: Icons.favorite_rounded,
      color: Color(0xFFEC4899),
      audioUrl: 'https://api.zabiraacademy.com/storage/nasheed/sample_1.mp3',
    ),
  ];

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
    final stories = kidsCtrl.stories;

    final selectedCat = kidsCtrl.selectedCategory;
    final filteredGames = (selectedCat == null || selectedCat == 'Islamic Games')
        ? games
        : games.where((g) => g.category?.toLowerCase() == selectedCat.toLowerCase()).toList();

    final filteredQuizzes = (selectedCat == null || selectedCat == 'Interactive Quizzes' || selectedCat.toLowerCase() == 'quiz' || selectedCat.toLowerCase() == 'quizzes')
        ? quizzes
        : quizzes.where((q) =>
            q.category?.toLowerCase() == selectedCat.toLowerCase() ||
            q.categoryName?.toLowerCase() == selectedCat.toLowerCase()).toList();

    final filteredStories = (selectedCat == null || selectedCat == 'Quran Stories' || selectedCat.toLowerCase() == 'stories' || selectedCat.toLowerCase() == 'story')
        ? stories
        : stories.where((s) =>
            s.categorySlug?.toLowerCase() == selectedCat.toLowerCase() ||
            s.categoryName?.toLowerCase() == selectedCat.toLowerCase()).toList();

    return Scaffold(
        extendBody: true,
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppDrawer(currentRoute: AppRoutes.kids),
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () => kidsCtrl.loadKidsPortal(forceRefresh: true),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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

                    if (kidsCtrl.isLoading)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: LinearProgressIndicator(color: AppColors.gold, minHeight: 3),
                      ),

                    if (kidsCtrl.errorMessage != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Text(
                          kidsCtrl.errorMessage!,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF991B1B),
                          ),
                        ),
                      ),

                    // ── 2. Primary 4 Categories Grid ─────────────────────────
                    _buildCategoriesGrid(context, categories, kidsCtrl),

                    const SizedBox(height: 24),

                    // ── 3. Category Filter Chips ─────────────────────────────
                    _buildCategoryFilterChips(categories, kidsCtrl),

                    const SizedBox(height: 20),

                    // ── 4. Daily Duas Section ────────────────────────────────
                    if (selectedCat == null || selectedCat == 'Daily Duas') ...[
                      _buildDuasSection(context),
                      const SizedBox(height: 24),
                    ],

                    // ── 5. Quran Stories Section ─────────────────────────────
                    if (selectedCat == null ||
                        selectedCat == 'Quran Stories' ||
                        selectedCat.toLowerCase() == 'stories' ||
                        selectedCat.toLowerCase() == 'story' ||
                        (filteredStories.isNotEmpty && selectedCat != 'Daily Duas' && selectedCat != 'Interactive Quizzes' && selectedCat != 'Islamic Games')) ...[
                      _buildStoriesSection(context, filteredStories),
                      const SizedBox(height: 24),
                    ],

                    // ── 6. Interactive Quizzes Section ───────────────────────
                    if (selectedCat == null ||
                        selectedCat == 'Interactive Quizzes' ||
                        selectedCat.toLowerCase() == 'quiz' ||
                        selectedCat.toLowerCase() == 'quizzes' ||
                        (filteredQuizzes.isNotEmpty && selectedCat != 'Daily Duas' && selectedCat != 'Quran Stories' && selectedCat != 'Islamic Games')) ...[
                      _buildQuizzesSection(context, filteredQuizzes),
                      const SizedBox(height: 24),
                    ],

                    // ── 7. Islamic Games Section ─────────────────────────────
                    if (selectedCat == null || selectedCat == 'Islamic Games') ...[
                      _buildGamesSection(context, filteredGames),
                      const SizedBox(height: 24),
                    ],

                    // ── 8. Kids Special Program Banner ───────────────────────
                    _buildSpecialProgramBanner(context),

                    const SizedBox(height: 24),

                    // ── 9. Kids Rewards & Gamification Preview ───────────────
                    _buildRewardsPreviewCard(),

                    const SizedBox(height: 24),

                    // ── 10. For Parents Trust Section ────────────────────────
                    _buildForParentsTrustSection(),

                    const SizedBox(height: 80),
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
                onPressed: () => AppDrawer.open(context, AppRoutes.kids),
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
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Main Title
          Text(
            'Islamic Learning Made Fun, Interactive & Rewarding',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w900,
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
                  onPressed: () => context.push('/kids/stories'),
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
        'Daily Duas',
        'Morning, food, travel & sleep duas',
        Icons.pan_tool_rounded,
        const Color(0xFFF59E0B),
        const Color(0xFFFFFBEB),
      ),
      (
        'Quran Stories',
        'Inspiring stories of the Prophets',
        Icons.auto_stories_rounded,
        const Color(0xFF3B82F6),
        const Color(0xFFEFF6FF),
      ),
      (
        'Islamic Games',
        'Memory match, trivia & puzzles',
        Icons.sports_esports_rounded,
        const Color(0xFF10B981),
        const Color(0xFFECFDF5),
      ),
      (
        'Interactive Quizzes',
        'Test knowledge & win XP',
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
          onTap: () {
            HapticFeedback.lightImpact();
            if (c.$1 == 'Daily Duas') {
              context.push('/kids/duas');
            } else if (c.$1 == 'Quran Stories') {
              context.push('/kids/stories');
            } else if (c.$1 == 'Islamic Games') {
              context.push('/kids/games');
            } else if (c.$1 == 'Interactive Quizzes') {
              context.push('/kids/quizzes');
            }
          },
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
      ('Daily Duas', 'Daily Duas'),
      ('Quran Stories', 'Quran Stories'),
      ('Islamic Games', 'Islamic Games'),
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
  // Daily Duas Section — Interactive Cards
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildDuasSection(BuildContext context) {
    final audioCtrl = context.read<GlobalAudioController>();

    final duaCategories = ['All', 'Morning', 'Evening', 'Food', 'Travel', 'Sleeping', 'Parents'];
    final displayedDuas = _selectedDuaCategory == null || _selectedDuaCategory == 'All'
        ? _duasList
        : _duasList.where((d) => d.category.toLowerCase() == _selectedDuaCategory!.toLowerCase()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daily Duas & Adhkar',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navyDark,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${_learnedDuaIds.length}/${_duasList.length} LEARNED',
                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFFB45309)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Sub-filter chips for Duas
        SizedBox(
          height: 32,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: duaCategories.length,
            itemBuilder: (context, index) {
              final cat = duaCategories[index];
              final isSel = (_selectedDuaCategory == null && cat == 'All') || _selectedDuaCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedDuaCategory = cat == 'All' ? null : cat),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFFFEF3C7) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSel ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    cat,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                      color: isSel ? const Color(0xFF92400E) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        // Duas Cards List
        ...displayedDuas.map((dua) {
          final isLearned = _learnedDuaIds.contains(dua.id);

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isLearned ? const Color(0xFF10B981).withAlpha(100) : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: isLearned ? const Color(0xFF10B981).withAlpha(15) : Colors.black.withAlpha(4),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: dua.color.withAlpha(22),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(dua.icon, color: dua.color, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            dua.category.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: dua.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dua.title,
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Learned Status Badge / Toggle
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          if (isLearned) {
                            _learnedDuaIds.remove(dua.id);
                          } else {
                            _learnedDuaIds.add(dua.id);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLearned ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLearned ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              size: 13,
                              color: isLearned ? Colors.white : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isLearned ? 'Learned' : 'Learn',
                              style: GoogleFonts.outfit(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isLearned ? Colors.white : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Arabic Text Container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Text(
                    dua.arabic,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyDark,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Transliteration
                Text(
                  dua.transliteration,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),

                // English Translation
                Text(
                  dua.translation,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),

                // Audio Play CTA
                Row(
                  children: [
                    SizedBox(
                      height: 34,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          if (dua.audioUrl != null) {
                            audioCtrl.play(
                              url: dua.audioUrl!,
                              title: '${dua.title} (Dua)',
                              artist: 'Zabira Kids Academy',
                            );
                          }
                        },
                        icon: const Icon(Icons.volume_up_rounded, size: 15),
                        label: Text('Listen Audio', style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: dua.color,
                          side: BorderSide(color: dua.color.withAlpha(120)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '+10 XP',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Quran Stories Section — Live API Driven
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStoriesSection(BuildContext context, List<KidsStoryItem> stories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stories of the Prophets',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Inspiring lessons and moral tales for young believers.',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            if (stories.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF3B82F6).withAlpha(100)),
                ),
                child: Text(
                  '${stories.length} STORIES',
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF2563EB)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        if (stories.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_stories_rounded, size: 32, color: Color(0xFFB45309)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Stories coming soon',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Our scholars and educators are crafting inspiring, illustrated stories. Check back soon!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      color: const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          // Featured Story (First story)
          _buildFeaturedStoryCard(context, stories.first),
          const SizedBox(height: 14),

          // Remaining Stories (if any)
          if (stories.length > 1) ...[
            ...stories.skip(1).map((story) => _buildStoryListItem(context, story)),
          ],
        ],
      ],
    );
  }

  Widget _buildFeaturedStoryCard(BuildContext context, KidsStoryItem story) {
    final coverUrl = story.resolvedCoverImage ?? story.resolvedThumbnail;

    return GestureDetector(
      onTap: () => context.push('/kids/story/${story.id}?slug=${story.slug}', extra: story),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Container(
                height: 160,
                width: double.infinity,
                color: AppColors.navyDark,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (coverUrl != null && coverUrl.isNotEmpty)
                      Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildStoryFallbackCover(story),
                      )
                    else
                      _buildStoryFallbackCover(story),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'FEATURED STORY',
                          style: GoogleFonts.outfit(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (story.prophetName != null && story.prophetName!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            story.prophetName!,
                            style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF1D4ED8)),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          story.readTimeLabel,
                          style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFFB45309)),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'AGES ${story.ageLabel.toUpperCase()}',
                          style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    story.title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (story.shortDescription != null && story.shortDescription!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      story.shortDescription!,
                      style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF64748B), height: 1.35),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'READ STORY',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.gold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, color: AppColors.gold, size: 16),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryListItem(BuildContext context, KidsStoryItem story) {
    final coverUrl = story.resolvedThumbnail ?? story.resolvedCoverImage;

    return GestureDetector(
      onTap: () => context.push('/kids/story/${story.id}?slug=${story.slug}', extra: story),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 54,
                height: 54,
                color: AppColors.navyDark,
                child: coverUrl != null && coverUrl.isNotEmpty
                    ? Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(Icons.auto_stories_rounded, color: AppColors.gold, size: 24),
                      )
                    : const Icon(Icons.auto_stories_rounded, color: AppColors.gold, size: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        story.readTimeLabel,
                        style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '· Ages ${story.ageLabel}',
                        style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => context.push('/kids/story/${story.id}?slug=${story.slug}', extra: story),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text('Read', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryFallbackCover(KidsStoryItem story) {
    return Container(
      color: AppColors.navyDark,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_stories_rounded, color: AppColors.gold, size: 36),
            const SizedBox(height: 6),
            Text(
              story.title,
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w700),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Interactive Quizzes Section
  // ───────────────────────────────────────────────────────────────────────────
  // ───────────────────────────────────────────────────────────────────────────
  // Interactive Quizzes Section — "Pick a Quiz" Rich Design
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildQuizzesSection(BuildContext context, List<KidsQuizItem> quizzes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pick a Quiz',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Choose a topic, start the quiz, and see how much you know.',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gold.withAlpha(120)),
              ),
              child: Text(
                '${quizzes.length} QUIZZES',
                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFFB45309)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (quizzes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.quiz_outlined, size: 40, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 8),
                  Text(
                    'No quizzes available right now.',
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          )
        else
          ...quizzes.map((quiz) => _buildPickAQuizCard(context, quiz)),
      ],
    );
  }

  Widget _buildPickAQuizCard(BuildContext context, KidsQuizItem quiz) {
    final coverUrl = quiz.resolvedThumbnail ?? quiz.resolvedCoverImage;

    return GestureDetector(
      onTap: () => context.push('/kids/quiz-detail/${quiz.id}?slug=${quiz.slug}', extra: quiz),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Cover Image / Banner ─────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Container(
                height: 150,
                width: double.infinity,
                color: AppColors.navyDark,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (coverUrl != null && coverUrl.isNotEmpty)
                      Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildQuizCardFallbackCover(quiz),
                      )
                    else
                      _buildQuizCardFallbackCover(quiz),
                    if (quiz.featured)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'FEATURED',
                            style: GoogleFonts.outfit(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.navyDark,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Card Content ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges Row: AGES 7-9 · 10 Qs
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'AGES ${quiz.ageLabel.toUpperCase()}',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.help_outline_rounded, size: 12, color: Color(0xFF475569)),
                            const SizedBox(width: 4),
                            Text(
                              '${quiz.questionsCount} Qs',
                              style: GoogleFonts.outfit(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (quiz.pointsReward > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+${quiz.pointsReward} XP',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    quiz.title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Description
                  if (quiz.description != null && quiz.description!.isNotEmpty)
                    Text(
                      quiz.description!,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 14),

                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),

                  // Bottom Action Row: DIFF: Easy · START ->
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'DIFF: ',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          Text(
                            quiz.difficulty,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: quiz.difficulty.toLowerCase() == 'easy'
                                  ? const Color(0xFF10B981)
                                  : (quiz.difficulty.toLowerCase() == 'medium' ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'START',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.gold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, color: AppColors.gold, size: 16),
                        ],
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
  }

  Widget _buildQuizCardFallbackCover(KidsQuizItem quiz) {
    return Container(
      color: AppColors.navyDark,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.quiz_rounded, color: AppColors.gold, size: 36),
            const SizedBox(height: 6),
            Text(
              quiz.title,
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w700),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Islamic Games Section — Rich Cards
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
        ...games.map((game) => _buildRichGameCard(context, game)),
      ],
    );
  }

  IconData _gameTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'memory_match': return Icons.dashboard_rounded;
      case 'dua_match': return Icons.pan_tool_rounded;
      case 'trivia':
      case 'prophets_quiz': return Icons.help_outline_rounded;
      case 'word_puzzle': return Icons.text_fields_rounded;
      case 'sort_it_right': return Icons.sort_rounded;
      case 'prophet_timeline': return Icons.timeline_rounded;
      default: return Icons.sports_esports_rounded;
    }
  }

  Color _difficultyColor(String? d) {
    switch (d?.toLowerCase()) {
      case 'easy': return const Color(0xFF10B981);
      case 'medium': return const Color(0xFFF59E0B);
      case 'hard': return const Color(0xFFEF4444);
      default: return const Color(0xFF10B981);
    }
  }

  Widget _buildRichGameCard(BuildContext context, KidsGameItem game) {
    final icon = _gameTypeIcon(game.gameType);
    final diffColor = _difficultyColor(game.difficulty);
    final hasImage = game.resolvedThumbnail != null && game.resolvedThumbnail!.isNotEmpty;

    return GestureDetector(
      onTap: () => context.push('/kids/game-detail/${game.id}', extra: game),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left: Thumbnail / Icon ─────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
              child: hasImage
                  ? Image.network(
                      game.resolvedThumbnail!,
                      width: 88,
                      height: 108,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _gameIconBox(icon, emoji: game.icon),
                    )
                  : _gameIconBox(icon, emoji: game.icon),
            ),

            // ── Right: Metadata ───────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (game.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          game.category!.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF059669),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    const SizedBox(height: 5),

                    Text(
                      game.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyDark,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),

                    if (game.shortDescription != null && game.shortDescription!.isNotEmpty)
                      Text(
                        game.shortDescription!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        _miniChip(game.ageGroup, const Color(0xFF3B82F6), const Color(0xFFEFF6FF)),
                        const SizedBox(width: 5),
                        _miniChip(game.difficulty, diffColor, diffColor.withAlpha(22)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+${game.pointsReward} XP',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/kids/game-detail/${game.id}', extra: game),
                        icon: const Icon(Icons.play_circle_filled_rounded, size: 16),
                        label: Text(
                          'View & Play',
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gameIconBox(IconData icon, {String? emoji}) {
    return Container(
      width: 88,
      height: 108,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF064E3B), Color(0xFF10B981)],
        ),
      ),
      child: Center(
        child: emoji != null && emoji.isNotEmpty
            ? Text(emoji, style: const TextStyle(fontSize: 38))
            : Icon(icon, color: Colors.white, size: 36),
      ),
    );
  }

  Widget _miniChip(String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
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
  // Kids Rewards & Gamification Preview Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildRewardsPreviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.emoji_events_rounded, color: Color(0xFFB45309), size: 24),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Earn Badges & Islamic XP',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyDark,
                      ),
                    ),
                    Text(
                      'Complete quizzes and games to unlock new ranks',
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _badgeItem('🌟', 'Star Learner', 'Level 1'),
              _badgeItem('📖', 'Quran Explorer', 'Level 2'),
              _badgeItem('🏆', 'Hadith Master', 'Level 3'),
              _badgeItem('🌙', 'Zabira Champion', 'Level 4'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badgeItem(String emoji, String title, String level) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.navyDark),
        ),
        Text(
          level,
          style: GoogleFonts.outfit(fontSize: 9.5, color: const Color(0xFF94A3B8)),
        ),
      ],
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
    return const ZabiraBottomNav(selectedIndex: 1);
  }
}

