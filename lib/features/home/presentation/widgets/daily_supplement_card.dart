import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/daily_supplement_model.dart';

/// Daily Supplement compact audio player card.
///
/// Replaces the old Continue Learning card. Shows the current day's
/// supplemental Islamic content (nasheed, qirat, dua, reminder, etc.).
///
/// Layout:
///   [Islamic Art Panel] | [Content Info + Progress] | [Play/Pause Button]
///
/// State: local [_playing] bool toggles play/pause icon.
/// No audio backend — architecture is ready for future media integration.
class DailySupplementCard extends StatefulWidget {
  const DailySupplementCard({super.key, required this.supplement});

  final DailySupplementModel supplement;

  @override
  State<DailySupplementCard> createState() => _DailySupplementCardState();
}

class _DailySupplementCardState extends State<DailySupplementCard> {
  bool _playing = false;

  void _togglePlay() {
    HapticFeedback.lightImpact();
    setState(() => _playing = !_playing);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        height: 104,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Art Panel (left) ─────────────────────────────────────────
            _ArtPanel(artType: widget.supplement.artType),

            // ── Content Info (center) ─────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Section label (gold, small)
                    Text(
                      widget.supplement.sectionLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gold,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // Content title (navy, Poppins semibold)
                    Text(
                      widget.supplement.contentTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyDark,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // Duration
                    Text(
                      widget.supplement.duration,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Progress bar + percentage
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: LinearProgressIndicator(
                              value: widget.supplement.progress,
                              backgroundColor: AppColors.borderMedium,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          widget.supplement.progressLabel,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
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

            // ── Play / Pause Button (right) ───────────────────────────────
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: _togglePlay,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _playing ? AppColors.navyDark : AppColors.gold,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withAlpha(_playing ? 35 : 85),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      child: Icon(
                        _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        key: ValueKey(_playing),
                        color: _playing ? AppColors.gold : AppColors.navyDark,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Left-side 110px illustration panel rendering the Daily Supplement banner image asset.
class _ArtPanel extends StatelessWidget {
  const _ArtPanel({required this.artType});
  final DailySupplementArtType artType;

  static const String _bannerPath =
      'assets/images/home/daily_supplement/daily_supplement_banner.png';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadius.xl)),
      child: SizedBox(
        width: 110,
        child: Image.asset(
          _bannerPath,
          fit: BoxFit.cover,
          alignment: Alignment.centerLeft,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF060F20), Color(0xFF0B1C38)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CustomPaint(
                painter: _SupplementArtPainter(artType),
                child: const SizedBox.expand(),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Paints a premium Islamic geometric motif inside the Daily Supplement art panel.
///
/// All art variants use gold geometry on the deep navy gradient background.
class _SupplementArtPainter extends CustomPainter {
  const _SupplementArtPainter(this.artType);
  final DailySupplementArtType artType;

  @override
  void paint(Canvas canvas, Size size) {
    switch (artType) {
      case DailySupplementArtType.nasheed:
        _paintNasheed(canvas, size);
      case DailySupplementArtType.qirat:
        _paintQirat(canvas, size);
      case DailySupplementArtType.quranRecitation:
        _paintQirat(canvas, size);
      case DailySupplementArtType.islamicReminder:
        _paintNasheed(canvas, size);
    }
  }

  // ── Nasheed: Layered 8-pointed Islamic star with crescent ────────────────
  void _paintNasheed(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.44;
    final cy = h * 0.51;
    final r = w * 0.29;

    // Outer halo glow
    canvas.drawCircle(Offset(cx, cy), r * 1.72,
        Paint()..color = AppColors.gold.withAlpha(13)..style = PaintingStyle.fill);

    // Outer star (very faint, large)
    _draw8Star(canvas, Offset(cx, cy), r * 1.18,
        Paint()..color = AppColors.gold.withAlpha(22)..style = PaintingStyle.fill);

    // Main star (filled, moderate alpha)
    _draw8Star(canvas, Offset(cx, cy), r,
        Paint()..color = AppColors.gold.withAlpha(158)..style = PaintingStyle.fill);

    // Main star stroke outline
    _draw8Star(
        canvas,
        Offset(cx, cy),
        r,
        Paint()
          ..color = AppColors.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.020
          ..strokeJoin = StrokeJoin.round);

    // Inner dark cutout (creates depth / window-through-star effect)
    _draw8Star(canvas, Offset(cx, cy), r * 0.42,
        Paint()..color = const Color(0xFF060F20)..style = PaintingStyle.fill);

    // Inner tiny star (gold gem)
    _draw8Star(canvas, Offset(cx, cy), r * 0.17,
        Paint()..color = AppColors.gold.withAlpha(210)..style = PaintingStyle.fill);

    // Ring of 8 small dot accents
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) - math.pi / 8;
      final dx = cx + r * 1.46 * math.cos(angle);
      final dy = cy + r * 1.46 * math.sin(angle);
      canvas.drawCircle(Offset(dx, dy), w * 0.022,
          Paint()..color = AppColors.gold.withAlpha(108)..style = PaintingStyle.fill);
    }

    // Crescent (top right corner)
    canvas.drawCircle(Offset(w * 0.82, h * 0.21), w * 0.095,
        Paint()..color = AppColors.gold..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(w * 0.88, h * 0.18), w * 0.076,
        Paint()..color = const Color(0xFF060F20)..style = PaintingStyle.fill);
  }

  // ── Qirat: Open Quran pages with spine and crescent ─────────────────────
  void _paintQirat(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.50;

    final goldStroke = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.022
      ..strokeCap = StrokeCap.round;

    // Left page
    final leftPage = Path()
      ..moveTo(cx, cy - h * 0.26)
      ..lineTo(cx, cy + h * 0.20)
      ..lineTo(cx - w * 0.38, cy + h * 0.14)
      ..lineTo(cx - w * 0.36, cy - h * 0.28)
      ..close();
    canvas.drawPath(leftPage, Paint()..color = AppColors.gold.withAlpha(46)..style = PaintingStyle.fill);
    canvas.drawPath(leftPage, goldStroke);

    // Right page
    final rightPage = Path()
      ..moveTo(cx, cy - h * 0.26)
      ..lineTo(cx, cy + h * 0.20)
      ..lineTo(cx + w * 0.38, cy + h * 0.14)
      ..lineTo(cx + w * 0.36, cy - h * 0.28)
      ..close();
    canvas.drawPath(rightPage, Paint()..color = AppColors.gold.withAlpha(28)..style = PaintingStyle.fill);
    canvas.drawPath(rightPage, goldStroke);

    // Spine
    canvas.drawLine(
        Offset(cx, cy - h * 0.26),
        Offset(cx, cy + h * 0.20),
        Paint()..color = AppColors.gold..style = PaintingStyle.stroke..strokeWidth = w * 0.028..strokeCap = StrokeCap.round);

    // Text lines on left page
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(cx - w * 0.28, cy - h * 0.10 + i * h * 0.10),
        Offset(cx - w * 0.08, cy - h * 0.10 + i * h * 0.10),
        Paint()..color = AppColors.gold.withAlpha(90)..style = PaintingStyle.stroke..strokeWidth = 1.2,
      );
    }

    // Crescent (top left)
    canvas.drawCircle(Offset(w * 0.18, h * 0.19), w * 0.085,
        Paint()..color = AppColors.gold..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(w * 0.24, h * 0.17), w * 0.068,
        Paint()..color = const Color(0xFF060F20)..style = PaintingStyle.fill);
  }

  // ─────────────────────────────────────────────────────────────────────────

  void _draw8Star(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final outer = (i * math.pi / 4) - math.pi / 2;
      final inner = outer + math.pi / 8;
      final op = Offset(center.dx + r * math.cos(outer), center.dy + r * math.sin(outer));
      final ip = Offset(center.dx + r * 0.42 * math.cos(inner), center.dy + r * 0.42 * math.sin(inner));
      i == 0 ? path.moveTo(op.dx, op.dy) : path.lineTo(op.dx, op.dy);
      path.lineTo(ip.dx, ip.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SupplementArtPainter old) => old.artType != artType;
}
