import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/zabira_bottom_nav.dart';
import '../../data/models/kids_models.dart';
import '../controllers/kids_controller.dart';

class KidsGamesPage extends StatelessWidget {
  const KidsGamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final kidsCtrl = context.watch<KidsController>();
    final games = kidsCtrl.games;

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
          'Islamic Games & Puzzles',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Play, Learn & Win Stars',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Interactive puzzles and Islamic memory games designed for young minds.',
              style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),

            if (games.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.sports_esports_rounded, size: 42, color: Color(0xFF10B981)),
                      const SizedBox(height: 12),
                      Text(
                        'Games Loading',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navyDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Loading interactive games and puzzles...',
                        style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...games.map((game) {
                return GestureDetector(
                  onTap: () => context.push('/kids/game-detail/${game.id}', extra: game),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
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
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Center(
                            child: Icon(Icons.sports_esports_rounded, color: Color(0xFF059669), size: 32),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                 child: Text(
                                  game.gameType.toUpperCase(),
                                  style: GoogleFonts.outfit(fontSize: 9.5, fontWeight: FontWeight.w800, color: const Color(0xFF475569)),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                game.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navyDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                game.description ?? 'Play now and score XP points!',
                                style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
                                  const SizedBox(width: 3),
                                  Text(
                                    '+${game.pointsReward} XP',
                                    style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w800, color: const Color(0xFFB45309)),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'PLAY NOW',
                                      style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white),
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
              }),

            // Bottom clearance
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
