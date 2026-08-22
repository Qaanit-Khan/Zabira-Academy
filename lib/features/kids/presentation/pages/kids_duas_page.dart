import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/zabira_bottom_nav.dart';
import '../../../../core/audio/global_audio_controller.dart';
import '../controllers/kids_controller.dart';

class _DuaItemData {
  const _DuaItemData({
    required this.id,
    required this.title,
    required this.category,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.icon,
    required this.color,
    this.audioUrl,
  });

  final String id;
  final String title;
  final String category;
  final String arabic;
  final String transliteration;
  final String translation;
  final IconData icon;
  final Color color;
  final String? audioUrl;
}

class KidsDuasPage extends StatefulWidget {
  const KidsDuasPage({super.key});

  @override
  State<KidsDuasPage> createState() => _KidsDuasPageState();
}

class _KidsDuasPageState extends State<KidsDuasPage> {
  String? _selectedCategory;
  final Set<String> _learnedDuaIds = {'dua_1', 'dua_3'};

  final List<_DuaItemData> _duasList = const [
    _DuaItemData(
      id: 'dua_1',
      title: 'Before Sleeping',
      category: 'Sleeping',
      arabic: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
      transliteration: "Bismika Allahumma amootu wa-ahya",
      translation: "In Your name, O Allah, I live and die.",
      icon: Icons.nightlight_round,
      color: Color(0xFF6366F1),
      audioUrl: 'https://api.zabiraacademy.com/assets/audio/dua_sleep.mp3',
    ),
    _DuaItemData(
      id: 'dua_2',
      title: 'Waking Up',
      category: 'Morning',
      arabic: 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
      transliteration: "Alhamdu lillahil-lathee ahyana ba'da ma amatana wa-ilayhin-nushoor",
      translation: "Praise is to Allah Who gave us life after taking it from us, and unto Him is the resurrection.",
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFFF59E0B),
      audioUrl: 'https://api.zabiraacademy.com/assets/audio/dua_wake.mp3',
    ),
    _DuaItemData(
      id: 'dua_3',
      title: 'Before Eating',
      category: 'Food',
      arabic: 'بِسْمِ اللَّهِ وَعَلَى بَرَكَةِ اللَّهِ',
      transliteration: "Bismillahi wa 'ala barakatillah",
      translation: "In the name of Allah and upon the blessings of Allah.",
      icon: Icons.restaurant_rounded,
      color: Color(0xFF10B981),
      audioUrl: 'https://api.zabiraacademy.com/assets/audio/dua_eat.mp3',
    ),
    _DuaItemData(
      id: 'dua_4',
      title: 'After Eating',
      category: 'Food',
      arabic: 'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا وَجَعَلَنَا مُسْلِمِينَ',
      transliteration: "Alhamdu lillahil-lathee at'amana wa saqana waja'alana muslimeen",
      translation: "Praise belongs to Allah Who gave us food and drink, and made us Muslims.",
      icon: Icons.done_all_rounded,
      color: Color(0xFF059669),
      audioUrl: 'https://api.zabiraacademy.com/assets/audio/dua_after_eat.mp3',
    ),
    _DuaItemData(
      id: 'dua_5',
      title: 'Traveling / Boarding Vehicle',
      category: 'Travel',
      arabic: 'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَٰذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ',
      transliteration: "Subhanal-lathee sakh-khara lana hatha wama kunna lahoo muqrineen",
      translation: "Glory unto Him who has subjected this to us, for we could never have accomplished this by ourselves.",
      icon: Icons.directions_car_rounded,
      color: Color(0xFF3B82F6),
      audioUrl: 'https://api.zabiraacademy.com/assets/audio/dua_travel.mp3',
    ),
    _DuaItemData(
      id: 'dua_6',
      title: 'For Parents',
      category: 'Parents',
      arabic: 'رَّبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا',
      transliteration: "Rabbir-hamhuma kama rabbayani sagheera",
      translation: "My Lord, have mercy upon them as they brought me up when I was small.",
      icon: Icons.favorite_rounded,
      color: Color(0xFFEC4899),
      audioUrl: 'https://api.zabiraacademy.com/assets/audio/dua_parents.mp3',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final audioCtrl = context.read<GlobalAudioController>();
    final categories = ['All', 'Morning', 'Evening', 'Food', 'Travel', 'Sleeping', 'Parents'];
    final displayedDuas = _selectedCategory == null || _selectedCategory == 'All'
        ? _duasList
        : _duasList.where((d) => d.category.toLowerCase() == _selectedCategory!.toLowerCase()).toList();

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      extendBody: true,
      bottomNavigationBar: const ZabiraBottomNav(selectedIndex: 1),
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Daily Duas & Adhkar',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${_learnedDuaIds.length}/${_duasList.length} Learned',
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.gold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Filter Chips
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSel = (_selectedCategory == null && cat == 'All') || _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat == 'All' ? null : cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.navyDark : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSel ? AppColors.navyDark : const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        cat,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                          color: isSel ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Duas Cards
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
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isLearned ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isLearned ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                  size: 14,
                                  color: isLearned ? Colors.white : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isLearned ? 'Learned' : 'Learn',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
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

                    // Arabic Text
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

                    // Audio Listen CTA
                    Row(
                      children: [
                        SizedBox(
                          height: 36,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              if (dua.audioUrl != null) {
                                audioCtrl.playUrl(
                                  dua.audioUrl!,
                                  title: '${dua.title} (Dua)',
                                  artist: 'Zabira Kids Academy',
                                );
                              }
                            },
                            icon: const Icon(Icons.volume_up_rounded, size: 16),
                            label: Text('Listen Audio', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: dua.color,
                              side: BorderSide(color: dua.color.withAlpha(120)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '+10 XP',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
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

            // Bottom clearance for floating nav
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
