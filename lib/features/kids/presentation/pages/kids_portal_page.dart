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

class _KidsStoryItem {
  const _KidsStoryItem({
    required this.id,
    required this.title,
    required this.prophet,
    required this.moral,
    required this.readTime,
    required this.icon,
    required this.color,
    required this.body,
  });

  final int id;
  final String title;
  final String prophet;
  final String moral;
  final String readTime;
  final IconData icon;
  final Color color;
  final String body;
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

  static const List<_KidsStoryItem> _storiesList = [
    _KidsStoryItem(
      id: 1,
      title: 'The Great Ark of Faith',
      prophet: 'Prophet Nuh (AS)',
      moral: 'Trust in Allah with patience and perseverance.',
      readTime: '4 min read',
      icon: Icons.sailing_rounded,
      color: Color(0xFF0284C7),
      body: 'Allah commanded Prophet Nuh (AS) to build a massive ship on dry land. Despite ridicule from the disbelievers, Prophet Nuh followed Allah\'s guidance faithfully. When the great flood came, the Ark was saved by Allah\'s divine decree, teaching us to always trust Allah\'s commands even when others do not understand.',
    ),
    _KidsStoryItem(
      id: 2,
      title: 'The Cool Fire & Kaaba',
      prophet: 'Prophet Ibrahim (AS)',
      moral: 'True devotion and courage in Allah alone.',
      readTime: '5 min read',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFF59E0B),
      body: 'When thrown into the raging fire by King Nimrod, Prophet Ibrahim (AS) placed all his trust in Allah. Allah commanded the fire: "O fire, be cool and peaceful for Ibrahim!" Later in life, alongside his son Ismail (AS), he built the Holy Kaaba in Makkah as a sanctuary for pure worship.',
    ),
    _KidsStoryItem(
      id: 3,
      title: 'The Splitting of the Sea',
      prophet: 'Prophet Musa (AS)',
      moral: 'Allah provides a way out for the believers.',
      readTime: '4 min read',
      icon: Icons.waves_rounded,
      color: Color(0xFF10B981),
      body: 'Trapped between the Red Sea and Pharaoh\'s marching army, Prophet Musa (AS) said with unshakeable conviction: "Indeed, my Lord is with me; He will guide me!" Allah commanded Musa to strike the sea with his staff, miraculously parting the deep waters into towering walls of safety.',
    ),
    _KidsStoryItem(
      id: 4,
      title: 'In the Belly of the Whale',
      prophet: 'Prophet Yunus (AS)',
      moral: 'The power of sincere repentance (Istighfar).',
      readTime: '3 min read',
      icon: Icons.water_rounded,
      color: Color(0xFF6366F1),
      body: 'In the deepest darkness of the ocean inside the whale, Prophet Yunus (AS) called out to Allah: "La ilaha illa Anta, Subhanaka, inni kuntu minaz-zalimeen" (There is no deity except You; exalted are You. Indeed, I have been of the wrongdoers). Allah heard his prayer and brought him safely to the shore.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KidsController>().loadKidsPortal();
    });
  }

  void _showStoryDialog(_KidsStoryItem story) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: story.color.withAlpha(25), shape: BoxShape.circle),
              child: Icon(story.icon, color: story.color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(story.title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navyDark)),
                  Text(story.prophet, style: GoogleFonts.outfit(fontSize: 12, color: story.color, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_rounded, color: Color(0xFFB45309), size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Moral: ${story.moral}', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF92400E)))),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                story.body,
                style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF334155), height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.navyDark),
            child: const Text('Done Reading'),
          ),
        ],
      ),
    );
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
                    if (selectedCat == null || selectedCat == 'Quran Stories') ...[
                      _buildStoriesSection(context),
                      const SizedBox(height: 24),
                    ],

                    // ── 6. Interactive Quizzes Section ───────────────────────
                    if (selectedCat == null || selectedCat == 'Interactive Quizzes') ...[
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
                  onPressed: () {
                    context.read<KidsController>().selectCategory('Quran Stories');
                  },
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
        final isSelected = ctrl.selectedCategory == c.$1;
        return GestureDetector(
          onTap: () => ctrl.selectCategory(isSelected ? null : c.$1),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.navyDark : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isSelected ? AppColors.gold : const Color(0xFFE2E8F0), width: isSelected ? 1.5 : 1.0),
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
                    color: isSelected ? Colors.white.withAlpha(20) : c.$5,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(c.$3, color: isSelected ? AppColors.gold : c.$4, size: 22),
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
                        color: isSelected ? Colors.white : AppColors.navyDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      c.$2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: isSelected ? Colors.white70 : const Color(0xFF64748B),
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
  // Quran Stories Section
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStoriesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Stories of the Prophets',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navyDark,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${_storiesList.length} STORIES',
                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF2563EB)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ..._storiesList.map((story) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: story.color.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(story.icon, color: story.color, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
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
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${story.prophet} · ${story.readTime}',
                        style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _showStoryDialog(story),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: story.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Text('Read', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        }),
      ],
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
