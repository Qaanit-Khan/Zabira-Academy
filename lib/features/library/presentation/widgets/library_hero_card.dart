import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class LibraryHeroCard extends StatelessWidget {
  const LibraryHeroCard({super.key, this.onExploreTap});

  final VoidCallback? onExploreTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF071B36),
            Color(0xFF0F2C59),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF071B36).withAlpha(40),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Left side text & CTA ─────────────────────────────────────────
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Library',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Knowledge in Every Page',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Discover authentic books and\nlearning resources that inspire,\neducate and transform.',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: const Color(0xFFCBD5E1),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: onExploreTap ?? () {},
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withAlpha(120), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Explore Collection',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 9,
                              color: Color(0xFF071B36),
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

          // ── Right side illustration graphic ──────────────────────────────
          Expanded(
            flex: 5,
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFF051329),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.gold.withAlpha(100), width: 1.2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Icon(Icons.auto_stories_rounded, color: AppColors.gold.withAlpha(140), size: 20),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 58,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A2246),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.gold, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withAlpha(60),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'THE\nQURAN\nCODE',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 6.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
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
}
