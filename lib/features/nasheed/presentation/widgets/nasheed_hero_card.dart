import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class NasheedHeroCard extends StatelessWidget {
  const NasheedHeroCard({super.key, this.onListenTap});

  final VoidCallback? onListenTap;

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
                  'Nasheed',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pure Voices. Positive Vibes.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Soulful nasheeds to inspire, uplift\nand bring you closer to Allah.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFFCBD5E1),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: onListenTap ?? () {},
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
                          'Listen Now',
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
              height: 105,
              decoration: BoxDecoration(
                color: const Color(0xFF041021),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold.withAlpha(100), width: 1.2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Icon(Icons.nightlight_round, color: AppColors.gold.withAlpha(180), size: 16),
                  ),
                  Positioned(
                    top: 18,
                    left: 14,
                    child: Icon(Icons.music_note_rounded, color: Colors.white.withAlpha(120), size: 14),
                  ),
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.navyDark,
                        border: Border.all(color: AppColors.gold, width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.headphones_rounded,
                          color: AppColors.gold,
                          size: 28,
                        ),
                      ),
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
