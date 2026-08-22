import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Zabira Academy — Universal Scholarship Promotional Banner
/// Matches the reference screenshot with dark navy background,
/// Islamic illustration, gold typography accents, and direct navigation.
class ScholarshipPromoBanner extends StatelessWidget {
  const ScholarshipPromoBanner({
    super.key,
    this.tag = 'SCHOLARSHIP PROGRAM',
    this.titlePrefix = "Support a Child's ",
    this.titleHighlight = 'Future',
    this.subtitle = 'Your contribution can help a child receive quality Islamic education.',
    this.buttonText = 'Donate Now',
    this.onTap,
  });

  final String tag;
  final String titlePrefix;
  final String titleHighlight;
  final String subtitle;
  final String buttonText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Scholarship Program Banner - Donate Now',
      child: GestureDetector(
        onTap: onTap ?? () => context.push(AppRoutes.scholarship),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF07192F),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.25),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF07192F).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Left: Decorative Islamic Art / Icon Graphic ─────────────
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/home/categories/scholarship.png',
                    width: 34,
                    height: 34,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.volunteer_activism_rounded,
                      color: AppColors.gold,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // ── Center: Title, Subtitle, & Tag ────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tag,
                      style: GoogleFonts.outfit(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        text: titlePrefix,
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        children: [
                          TextSpan(
                            text: titleHighlight,
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        color: const Color(0xFF94A3B8),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // ── Right: Donate Now CTA Button ──────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      buttonText,
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF071B36),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: Color(0xFF071B36),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

