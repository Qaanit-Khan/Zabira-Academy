import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/latest_launch_model.dart';

/// Reusable Latest Launch card — renders any [LaunchContentType].
///
/// Features:
///   • 4:3 content-type-specific custom illustration header (or real image asset)
///   • Gold category badge pill (e.g. "QIRAT", "AUDIOBOOK")
///   • Poppins SemiBold title + Outfit supporting info
///   • Zabira Gold accent bar (animates on press)
///   • AnimatedScale (0.97) + AnimatedOpacity press feedback
///   • Semantics label for accessibility
class LatestLaunchCard extends StatefulWidget {
  const LatestLaunchCard({super.key, required this.launch});

  final LatestLaunchModel launch;

  @override
  State<LatestLaunchCard> createState() => _LatestLaunchCardState();
}

class _LatestLaunchCardState extends State<LatestLaunchCard> {
  bool _pressed = false;

  void _onTapDown(TapDownDetails _) {
    HapticFeedback.lightImpact();
    setState(() => _pressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _pressed = false);
    // TODO: Navigate to content detail for id: ${widget.launch.id}
  }

  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Open ${widget.launch.title.replaceAll('\n', ' ')}',
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: _pressed ? 0.84 : 1.0,
            duration: const Duration(milliseconds: 130),
            child: _CardBody(launch: widget.launch, pressed: _pressed),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _CardBody extends StatelessWidget {
  const _CardBody({required this.launch, required this.pressed});

  final LatestLaunchModel launch;
  final bool pressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 130),
      width: 148,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: pressed ? AppColors.gold.withAlpha(90) : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withAlpha(pressed ? 18 : 10),
            blurRadius: pressed ? 6 : 12,
            offset: Offset(0, pressed ? 2 : 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Content Illustration Header ──────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: _LaunchThumbnail(launch: launch),
            ),
          ),

          // ── Card Body ────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Badge + Title group
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ContentTypeBadge(contentType: launch.contentType),
                      const SizedBox(height: 5),
                      SizedBox(
                        height: 30,
                        child: Text(
                          launch.title,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navyDark,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Supporting info + Gold bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        launch.supportingInfo,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 130),
                        height: 2,
                        width: pressed ? 32 : 24,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────

/// Small gold outlined category badge pill.
class _ContentTypeBadge extends StatelessWidget {
  const _ContentTypeBadge({required this.contentType});
  final LaunchContentType contentType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.gold.withAlpha(22),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.gold.withAlpha(72), width: 0.5),
      ),
      child: Text(
        contentType.label,
        style: GoogleFonts.outfit(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: AppColors.gold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Attempts to load the real image asset; falls back to a custom illustration.
class _LaunchThumbnail extends StatelessWidget {
  const _LaunchThumbnail({required this.launch});
  final LatestLaunchModel launch;

  @override
  Widget build(BuildContext context) {
    if (launch.imagePath != null) {
      return Image.asset(
        launch.imagePath!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _LaunchIllustration(contentType: launch.contentType),
      );
    }
    return _LaunchIllustration(contentType: launch.contentType);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Navy-gradient background with a content-type-specific custom illustration.
class _LaunchIllustration extends StatelessWidget {
  const _LaunchIllustration({required this.contentType});
  final LaunchContentType contentType;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF071326), Color(0xFF0D1F3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CustomPaint(
        painter: _launchPainter(contentType),
        child: const SizedBox.expand(),
      ),
    );
  }

  CustomPainter _launchPainter(LaunchContentType type) => switch (type) {
        LaunchContentType.course    => _CourseLaunchPainter(),
        LaunchContentType.nasheed   => _NasheedLaunchPainter(),
        LaunchContentType.qirat     => _QiratLaunchPainter(),
        LaunchContentType.audio     => _AudioLaunchPainter(),
        LaunchContentType.audiobook => _AudiobookLaunchPainter(),
        LaunchContentType.event     => _EventLaunchPainter(),
        LaunchContentType.media     => _MediaLaunchPainter(),
      };
}

// ═════════════════════════════════════════════════════════════════════════════
// LATEST LAUNCH ILLUSTRATION PAINTERS
//
// Each painter renders a unique Islamic-educational illustration on the
// navy gradient background. Gold is the primary accent color.
// Canvas fills the entire 4:3 header area (148 × 111 logical pixels).
// ═════════════════════════════════════════════════════════════════════════════

/// Course — Open Quran with radiating light rays and gold crescent.
class _CourseLaunchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.56;

    final goldStroke = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.014
      ..strokeCap = StrokeCap.round;

    final goldFaint = Paint()
      ..color = AppColors.gold.withAlpha(38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.010;

    // Radiant rays from top of book
    final rayOrigin = Offset(cx, h * 0.20);
    for (int i = 0; i < 11; i++) {
      final angle = -math.pi / 2 + (i - 5) * (math.pi * 0.65 / 10);
      final len = (i % 3 == 0) ? w * 0.40 : w * 0.25;
      canvas.drawLine(
        rayOrigin,
        Offset(rayOrigin.dx + len * math.cos(angle), rayOrigin.dy + len * math.sin(angle)),
        goldFaint,
      );
    }

    // Left page
    final leftPage = Path()
      ..moveTo(cx, cy - h * 0.28)
      ..lineTo(cx, cy + h * 0.20)
      ..lineTo(cx - w * 0.40, cy + h * 0.15)
      ..lineTo(cx - w * 0.38, cy - h * 0.30)
      ..close();
    canvas.drawPath(leftPage, Paint()..color = AppColors.gold.withAlpha(44)..style = PaintingStyle.fill);
    canvas.drawPath(leftPage, goldStroke);

    // Right page
    final rightPage = Path()
      ..moveTo(cx, cy - h * 0.28)
      ..lineTo(cx, cy + h * 0.20)
      ..lineTo(cx + w * 0.40, cy + h * 0.15)
      ..lineTo(cx + w * 0.38, cy - h * 0.30)
      ..close();
    canvas.drawPath(rightPage, Paint()..color = AppColors.gold.withAlpha(26)..style = PaintingStyle.fill);
    canvas.drawPath(rightPage, goldStroke);

    // Spine
    canvas.drawLine(
      Offset(cx, cy - h * 0.28),
      Offset(cx, cy + h * 0.20),
      Paint()..color = AppColors.gold..style = PaintingStyle.stroke..strokeWidth = size.width * 0.020..strokeCap = StrokeCap.round,
    );

    // Text lines on left page
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(cx - w * 0.30, cy - h * 0.10 + i * h * 0.09),
        Offset(cx - w * 0.10, cy - h * 0.10 + i * h * 0.09),
        Paint()..color = AppColors.gold.withAlpha(90)..style = PaintingStyle.stroke..strokeWidth = 1.2,
      );
    }

    // Crescent (top right)
    canvas.drawCircle(Offset(w * 0.84, h * 0.18), w * 0.075,
        Paint()..color = AppColors.gold..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(w * 0.90, h * 0.16), w * 0.060,
        Paint()..color = const Color(0xFF071326)..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────

/// Nasheed — elegant waveform bars with a floating gold musical note.
class _NasheedLaunchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.54;

    final gold = Paint()..color = AppColors.gold..style = PaintingStyle.fill;

    // Waveform bars (5 centered)
    final barHeights = [0.36, 0.62, 1.0, 0.66, 0.40];
    final barW = w * 0.09;
    final spacing = w * 0.138;
    final maxBarH = h * 0.58;

    for (int i = 0; i < 5; i++) {
      final x = cx - (2 * spacing) + i * spacing;
      final bh = maxBarH * barHeights[i];
      final opacity = 80 + (i == 2 ? 90 : (i == 1 || i == 3 ? 50 : 20));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, cy), width: barW, height: bh),
          const Radius.circular(3),
        ),
        Paint()..color = AppColors.gold.withAlpha(opacity)..style = PaintingStyle.fill,
      );
    }

    // Musical note (top right)
    canvas.save();
    canvas.translate(w * 0.76, h * 0.22);
    // Head
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.14, height: h * 0.11),
      gold,
    );
    // Stem
    canvas.drawRect(
      Rect.fromLTWH(w * 0.06, -h * 0.28, w * 0.038, h * 0.28),
      gold,
    );
    // Flag
    final flagPath = Path()
      ..moveTo(w * 0.098, -h * 0.28)
      ..lineTo(w * 0.20, -h * 0.14)
      ..lineTo(w * 0.098, -h * 0.10)
      ..close();
    canvas.drawPath(flagPath, gold);
    canvas.restore();

    // Crescent (top left)
    canvas.drawCircle(Offset(w * 0.16, h * 0.18), w * 0.068,
        Paint()..color = AppColors.gold..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(w * 0.21, h * 0.16), w * 0.055,
        Paint()..color = const Color(0xFF071326)..style = PaintingStyle.fill);

  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────

/// Qirat — open Quran pages resting on an A-frame rehal (book stand).
class _QiratLaunchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final rehalPaint = Paint()
      ..color = AppColors.gold.withAlpha(160)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.040
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final goldStroke = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.014
      ..strokeCap = StrokeCap.round;

    // ── Rehal (A-frame book stand) ────────────────────────────────────────
    // Left leg
    canvas.drawLine(Offset(w * 0.18, h * 0.94), Offset(cx, h * 0.58), rehalPaint);
    // Right leg
    canvas.drawLine(Offset(w * 0.82, h * 0.94), Offset(cx, h * 0.58), rehalPaint);
    // Horizontal cross-bar
    canvas.drawLine(
      Offset(w * 0.30, h * 0.78),
      Offset(w * 0.70, h * 0.78),
      Paint()..color = AppColors.gold.withAlpha(100)..style = PaintingStyle.stroke..strokeWidth = w * 0.025..strokeCap = StrokeCap.round,
    );

    // ── Open Quran pages on the rehal ─────────────────────────────────────
    // Left page
    final leftPage = Path()
      ..moveTo(cx, h * 0.20)
      ..lineTo(cx, h * 0.58)
      ..lineTo(cx - w * 0.38, h * 0.52)
      ..lineTo(cx - w * 0.36, h * 0.16)
      ..close();
    canvas.drawPath(leftPage, Paint()..color = AppColors.gold.withAlpha(44)..style = PaintingStyle.fill);
    canvas.drawPath(leftPage, goldStroke);

    // Right page
    final rightPage = Path()
      ..moveTo(cx, h * 0.20)
      ..lineTo(cx, h * 0.58)
      ..lineTo(cx + w * 0.38, h * 0.52)
      ..lineTo(cx + w * 0.36, h * 0.16)
      ..close();
    canvas.drawPath(rightPage, Paint()..color = AppColors.gold.withAlpha(26)..style = PaintingStyle.fill);
    canvas.drawPath(rightPage, goldStroke);

    // Spine
    canvas.drawLine(
      Offset(cx, h * 0.20),
      Offset(cx, h * 0.58),
      Paint()..color = AppColors.gold..style = PaintingStyle.stroke..strokeWidth = w * 0.020..strokeCap = StrokeCap.round,
    );

    // Crescent (top right)
    canvas.drawCircle(Offset(w * 0.84, h * 0.16), w * 0.072,
        Paint()..color = AppColors.gold..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(w * 0.90, h * 0.14), w * 0.058,
        Paint()..color = const Color(0xFF071326)..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────

/// Audio (Morning Adhkar) — large gold crescent moon with scattered stars.
///
/// The crescent represents the blessed morning and dawn of dhikr.
class _AudioLaunchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final gold = Paint()..color = AppColors.gold..style = PaintingStyle.fill;

    // Subtle glow behind crescent
    canvas.drawCircle(Offset(w * 0.44, h * 0.48), w * 0.34,
        Paint()..color = AppColors.gold.withAlpha(14)..style = PaintingStyle.fill);

    // ── Large crescent moon (main) ────────────────────────────────────────
    // Outer circle
    canvas.drawCircle(Offset(w * 0.44, h * 0.48), w * 0.30,
        Paint()..color = AppColors.gold.withAlpha(180)..style = PaintingStyle.fill);
    // Inner cutout circle (offset right-up) creates the crescent
    canvas.drawCircle(Offset(w * 0.58, h * 0.43), w * 0.24,
        Paint()..color = const Color(0xFF071326)..style = PaintingStyle.fill);

    // Crescent gold outline
    canvas.drawCircle(Offset(w * 0.44, h * 0.48), w * 0.30,
        Paint()..color = AppColors.gold..style = PaintingStyle.stroke..strokeWidth = w * 0.012);

    // ── Scattered stars ───────────────────────────────────────────────────
    _drawStar5(canvas, Offset(w * 0.78, h * 0.20), w * 0.060, gold);
    _drawStar5(canvas, Offset(w * 0.86, h * 0.56), w * 0.040,
        Paint()..color = AppColors.gold.withAlpha(160)..style = PaintingStyle.fill);
    _drawStar5(canvas, Offset(w * 0.18, h * 0.28), w * 0.042,
        Paint()..color = AppColors.gold.withAlpha(140)..style = PaintingStyle.fill);
    _drawStar5(canvas, Offset(w * 0.72, h * 0.84), w * 0.034,
        Paint()..color = AppColors.gold.withAlpha(100)..style = PaintingStyle.fill);
    _drawStar5(canvas, Offset(w * 0.22, h * 0.76), w * 0.028,
        Paint()..color = AppColors.gold.withAlpha(90)..style = PaintingStyle.fill);

    // Subtle dot ring
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 + math.pi / 6;
      final dx = w * 0.44 + w * 0.42 * math.cos(angle);
      final dy = h * 0.48 + h * 0.42 * math.sin(angle);
      canvas.drawCircle(Offset(dx, dy), w * 0.016,
          Paint()..color = AppColors.gold.withAlpha(55)..style = PaintingStyle.fill);
    }
  }

  void _drawStar5(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    final innerR = r * 0.42;
    for (int i = 0; i < 10; i++) {
      final angle = (i * math.pi / 5) - math.pi / 2;
      final radius = i.isEven ? r : innerR;
      final pt = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────

/// Audiobook (Stories of the Prophets) — stacked books with sound wave arcs.
class _AudiobookLaunchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Three stacked books (bottom to top) ───────────────────────────────
    _drawBook(canvas, w, h, w * 0.10, h * 0.60, w * 0.50, h * 0.20, 160); // bottom
    _drawBook(canvas, w, h, w * 0.15, h * 0.46, w * 0.50, h * 0.20, 200); // middle
    _drawBook(canvas, w, h, w * 0.20, h * 0.32, w * 0.50, h * 0.20, 240); // top

    // ── Sound wave arcs (right side) ──────────────────────────────────────
    final wavePaint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final waveCx = w * 0.82;
    final waveCy = h * 0.50;
    final radii = [w * 0.06, w * 0.11, w * 0.17];

    for (int i = 0; i < 3; i++) {
      wavePaint
        ..strokeWidth = w * 0.022
        ..color = AppColors.gold.withAlpha(60 + i * 50);
      canvas.drawArc(
        Rect.fromCenter(center: Offset(waveCx, waveCy), width: radii[i] * 2, height: radii[i] * 2),
        -math.pi / 2.6,
        math.pi / 1.3,
        false,
        wavePaint,
      );
    }

    // ── Center dot of wave ────────────────────────────────────────────────
    canvas.drawCircle(Offset(waveCx, waveCy), w * 0.030,
        Paint()..color = AppColors.gold..style = PaintingStyle.fill);
  }

  void _drawBook(Canvas canvas, double w, double h, double left, double top, double bw, double bh, int alpha) {
    final bookRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, bw, bh),
      const Radius.circular(3),
    );
    // Book body
    canvas.drawRRect(bookRect,
        Paint()..color = AppColors.navyDark.withAlpha(alpha)..style = PaintingStyle.fill);
    // Gold spine (left edge)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(left, top, w * 0.040, bh), const Radius.circular(2)),
      Paint()..color = AppColors.gold..style = PaintingStyle.fill,
    );
    // Book outline
    canvas.drawRRect(bookRect,
        Paint()..color = AppColors.gold.withAlpha(55)..style = PaintingStyle.stroke..strokeWidth = 0.8);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────

/// Event — Islamic calendar with gold binding rings and a crescent header.
class _EventLaunchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final gold = Paint()..color = AppColors.gold..style = PaintingStyle.fill;

    // Calendar body (navy fill)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.10, h * 0.18, w * 0.80, h * 0.68), const Radius.circular(6)),
      Paint()..color = AppColors.navyDark.withAlpha(200)..style = PaintingStyle.fill,
    );

    // Header fill (solid navy band)
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(w * 0.10, h * 0.18, w * 0.90, h * 0.40,
          topLeft: const Radius.circular(6), topRight: const Radius.circular(6)),
      Paint()..color = AppColors.navyDark..style = PaintingStyle.fill,
    );

    // Date area (soft cream fill)
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(w * 0.10, h * 0.40, w * 0.90, h * 0.86,
          bottomLeft: const Radius.circular(6), bottomRight: const Radius.circular(6)),
      Paint()..color = AppColors.softCream.withAlpha(22)..style = PaintingStyle.fill,
    );

    // Gold binding rings
    final ringPaint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.052
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.32, h * 0.08), Offset(w * 0.32, h * 0.28), ringPaint);
    canvas.drawLine(Offset(w * 0.68, h * 0.08), Offset(w * 0.68, h * 0.28), ringPaint);

    // Date grid dots (3 × 2)
    final dotPaint = Paint()..color = AppColors.gold.withAlpha(160)..style = PaintingStyle.fill;
    for (int row = 0; row < 2; row++) {
      for (int col = 0; col < 3; col++) {
        canvas.drawCircle(
          Offset(w * 0.28 + col * w * 0.22, h * 0.54 + row * h * 0.18),
          w * 0.038,
          dotPaint,
        );
      }
    }

    // Crescent in header (top right)
    canvas.drawCircle(Offset(w * 0.78, h * 0.29), w * 0.068, gold);
    canvas.drawCircle(Offset(w * 0.84, h * 0.27), w * 0.054,
        Paint()..color = AppColors.navyDark..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────

/// Media — screen frame with Islamic star watermark and gold play triangle.
class _MediaLaunchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final gold = Paint()..color = AppColors.gold..style = PaintingStyle.fill;

    // Screen frame (navy rounded rect)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.06, h * 0.10, w * 0.88, h * 0.68), const Radius.circular(6)),
      Paint()..color = AppColors.navyDark.withAlpha(210)..style = PaintingStyle.fill,
    );

    // Inner screen (soft cream)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.12, h * 0.17, w * 0.76, h * 0.54), const Radius.circular(4)),
      Paint()..color = AppColors.softCream.withAlpha(20)..style = PaintingStyle.fill,
    );

    // 8-pointed Islamic star watermark
    _draw8Star(canvas, Offset(w * 0.50, h * 0.44), w * 0.18,
        Paint()..color = AppColors.gold.withAlpha(22)..style = PaintingStyle.fill);

    // Gold play triangle (centered)
    final playPath = Path()
      ..moveTo(w * 0.36, h * 0.26)
      ..lineTo(w * 0.36, h * 0.62)
      ..lineTo(w * 0.68, h * 0.44)
      ..close();
    canvas.drawPath(playPath, gold);

    // Stand
    canvas.drawRect(Rect.fromLTWH(w * 0.44, h * 0.78, w * 0.12, h * 0.10), 
        Paint()..color = AppColors.navyDark.withAlpha(200)..style = PaintingStyle.fill);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.28, h * 0.87, w * 0.44, h * 0.08), const Radius.circular(2)),
      Paint()..color = AppColors.navyDark.withAlpha(200)..style = PaintingStyle.fill,
    );
  }

  void _draw8Star(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final outer = (i * math.pi / 4) - math.pi / 2;
      final inner = outer + math.pi / 8;
      final op = Offset(center.dx + r * math.cos(outer), center.dy + r * math.sin(outer));
      final ip = Offset(center.dx + r * 0.45 * math.cos(inner), center.dy + r * 0.45 * math.sin(inner));
      i == 0 ? path.moveTo(op.dx, op.dy) : path.lineTo(op.dx, op.dy);
      path.lineTo(ip.dx, ip.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
