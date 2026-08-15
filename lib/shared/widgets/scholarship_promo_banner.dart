import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Promotional banner widget matching the mobile reference screenshots
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF061426),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF061426).withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tag,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              text: titlePrefix,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              children: [
                TextSpan(
                  text: titleHighlight,
                  style: const TextStyle(color: AppColors.gold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onTap ?? () {},
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      buttonText,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF081D3A),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: Color(0xFF081D3A),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
