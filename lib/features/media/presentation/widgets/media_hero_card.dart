import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class MediaHeroCard extends StatelessWidget {
  const MediaHeroCard({super.key, this.onExploreTap});

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
                  'Media',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Watch & Learn',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Inspiring lectures and\nbite-sized shorts.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
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
                          'Explore Videos',
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: const Color(0xFF030D1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold.withAlpha(120), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(80),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withAlpha(120),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.gold.withAlpha(220),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withAlpha(100),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Color(0xFF071B36),
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
