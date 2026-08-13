import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/learning_progress_model.dart';

/// Continue Learning card — thumbnail left, progress info right, play button.
class ContinueLearningCard extends StatelessWidget {
  const ContinueLearningCard({super.key, required this.progress});

  final LearningProgressModel progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDark.withAlpha(10),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Course Thumbnail ─────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadius.xl)),
              child: Container(
                width: 110,
                height: 100,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF071326), Color(0xFF0D1F3C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Gold decorative circle
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold.withAlpha(15),
                        border: Border.all(color: AppColors.gold.withAlpha(40), width: 1),
                      ),
                    ),
                    // Quran icon
                    const Icon(Icons.auto_stories_rounded, color: AppColors.gold, size: 28),
                    // Title text overlay
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          Text(
                            'QURAN',
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: AppColors.gold,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            '─ WITH ─',
                            style: GoogleFonts.outfit(
                              fontSize: 6,
                              color: Colors.white.withAlpha(160),
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'TAJWEED',
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: AppColors.gold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Progress Info ────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      progress.courseTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      progress.stepLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Progress bar + percentage
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: LinearProgressIndicator(
                              value: progress.progress,
                              backgroundColor: AppColors.borderMedium,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                              minHeight: 5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          progress.progressLabel,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Play Button ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withAlpha(80),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: AppColors.navyDark, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
