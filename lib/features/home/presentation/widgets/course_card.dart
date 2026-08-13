import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/course_model.dart';

/// Premium Top Course card.
///
/// Features:
///   • Course-specific custom-painted illustration in the header
///     (unique per CourseType — Quran Tajweed, Understand Quran,
///      Namaz & Dua, The Muslim Life)
///   • Poppins bold title + Outfit student count
///   • Zabira Gold 24px accent bar
///   • AnimatedScale (0.97) + AnimatedOpacity press feedback
///   • Full-card GestureDetector tap area
///   • Semantics label for accessibility
class CourseCard extends StatefulWidget {
  const CourseCard({super.key, required this.course});

  final CourseModel course;

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  bool _pressed = false;

  void _onTapDown(TapDownDetails _) {
    HapticFeedback.lightImpact();
    setState(() => _pressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _pressed = false);
    // TODO: Navigate to course detail page for course id: ${widget.course.id}
  }

  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Open ${widget.course.title.replaceAll('\n', ' ')} course',
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
            child: _CardBody(course: widget.course, pressed: _pressed),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _CardBody extends StatelessWidget {
  const _CardBody({required this.course, required this.pressed});

  final CourseModel course;
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
          // ── Course Illustration Header ─────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: _CourseIllustrationHeader(
                courseType: course.courseType,
                imagePath: course.imagePath,
              ),
            ),
          ),

          // ── Card Body ──────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Course Title (Poppins SemiBold)
                  Text(
                    course.title,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navyDark,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Student Count + Gold Accent Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.studentCount,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
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

/// Attempts to load the course image asset; falls back to a course-specific
/// custom-painted illustration header if the image cannot be loaded.
class _CourseIllustrationHeader extends StatelessWidget {
  const _CourseIllustrationHeader({
    required this.courseType,
    required this.imagePath,
  });

  final CourseType courseType;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (ctx, err, _) => _CourseIllustrationFallback(courseType: courseType),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Navy-background custom illustration — unique per course type.
class _CourseIllustrationFallback extends StatelessWidget {
  const _CourseIllustrationFallback({required this.courseType});

  final CourseType courseType;

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
      child: Stack(
        children: [
          // Course-specific illustration
          Positioned.fill(
            child: CustomPaint(
              painter: _getCourseIllustrationPainter(courseType),
            ),
          ),
          // Course label overlay at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _CourseLabelBanner(courseType: courseType),
          ),
        ],
      ),
    );
  }

  CustomPainter _getCourseIllustrationPainter(CourseType type) {
    return switch (type) {
      CourseType.quranTajweed    => _QuranTajweedPainter(),
      CourseType.understandQuran => _UnderstandQuranPainter(),
      CourseType.namazDua        => _NamazDuaPainter(),
      CourseType.muslimLife      => _MuslimLifePainter(),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _CourseLabelBanner extends StatelessWidget {
  const _CourseLabelBanner({required this.courseType});

  final CourseType courseType;

  static const _labels = {
    CourseType.quranTajweed:    ('QURAN', 'TAJWEED'),
    CourseType.understandQuran: ('UNDERSTAND', 'QURAN'),
    CourseType.namazDua:        ('NAMAZ', '& DUA'),
    CourseType.muslimLife:      ('MUSLIM', 'LIFE'),
  };

  @override
  Widget build(BuildContext context) {
    final (line1, line2) = _labels[courseType]!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, AppColors.navyDark.withAlpha(200)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            line1,
            style: GoogleFonts.poppins(
              fontSize: 7,
              fontWeight: FontWeight.w800,
              color: AppColors.gold,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            line2,
            style: GoogleFonts.poppins(
              fontSize: 7,
              fontWeight: FontWeight.w800,
              color: AppColors.gold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// COURSE ILLUSTRATION PAINTERS
//
// Each painter renders a unique Islamic-educational illustration using
// AppColors.gold as the primary bright color on the navy gradient background.
// Canvas fills the entire 4:3 header area.
// ═════════════════════════════════════════════════════════════════════════════

/// Quran with Tajweed — open Quran with radiating light rays and a crescent.
///
/// Two open pages in gold, a spine, radiating straight lines from the top
/// center suggesting the light of Tajweed knowledge, a small crescent top-right.
class _QuranTajweedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;
    final goldStroke = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.012
      ..strokeCap = StrokeCap.round;
    final goldFaint = Paint()
      ..color = AppColors.gold.withAlpha(38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.010;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.58;

    // ── Radiant rays (from top center of the book) ────────────────────────
    final rayOrigin = Offset(cx, h * 0.20);
    for (int i = 0; i < 12; i++) {
      final angle = -math.pi / 2 + (i - 5.5) * (math.pi * 0.7 / 11);
      final len = (i % 3 == 0) ? w * 0.44 : w * 0.28;
      canvas.drawLine(
        rayOrigin,
        Offset(rayOrigin.dx + len * math.cos(angle), rayOrigin.dy + len * math.sin(angle)),
        goldFaint,
      );
    }

    // ── Left page ────────────────────────────────────────────────────────
    final leftPage = Path()
      ..moveTo(cx, cy - h * 0.28)
      ..lineTo(cx, cy + h * 0.18)
      ..lineTo(cx - w * 0.38, cy + h * 0.14)
      ..lineTo(cx - w * 0.36, cy - h * 0.30)
      ..close();
    canvas.drawPath(leftPage, Paint()..color = AppColors.gold.withAlpha(45)..style = PaintingStyle.fill);
    canvas.drawPath(leftPage, goldStroke);

    // ── Right page ───────────────────────────────────────────────────────
    final rightPage = Path()
      ..moveTo(cx, cy - h * 0.28)
      ..lineTo(cx, cy + h * 0.18)
      ..lineTo(cx + w * 0.38, cy + h * 0.14)
      ..lineTo(cx + w * 0.36, cy - h * 0.30)
      ..close();
    canvas.drawPath(rightPage, Paint()..color = AppColors.gold.withAlpha(30)..style = PaintingStyle.fill);
    canvas.drawPath(rightPage, goldStroke);

    // ── Spine ─────────────────────────────────────────────────────────────
    canvas.drawLine(
      Offset(cx, cy - h * 0.28),
      Offset(cx, cy + h * 0.18),
      Paint()..color = AppColors.gold..style = PaintingStyle.stroke..strokeWidth = size.width * 0.018..strokeCap = StrokeCap.round,
    );

    // ── Small text lines on left page ────────────────────────────────────
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(cx - w * 0.30, cy - h * 0.14 + i * h * 0.08),
        Offset(cx - w * 0.10, cy - h * 0.14 + i * h * 0.08),
        Paint()..color = AppColors.gold.withAlpha(100)..style = PaintingStyle.stroke..strokeWidth = 1.0,
      );
    }

    // ── Crescent (top right) ─────────────────────────────────────────────
    canvas.drawCircle(Offset(w * 0.82, h * 0.18), w * 0.09, gold);
    canvas.drawCircle(
      Offset(w * 0.88, h * 0.16),
      w * 0.075,
      Paint()..color = const Color(0xFF071326)..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────

/// Understand Quran — open book with a gold magnifying glass and crescent bookmark.
///
/// Open manuscript pages (gold strokes), a magnifying glass overlay
/// suggesting deep reading and understanding, text lines in the lens.
class _UnderstandQuranPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final goldStroke = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.014
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.54;

    // ── Open book pages ───────────────────────────────────────────────────
    final leftPage = Path()
      ..moveTo(cx, cy - h * 0.26)
      ..lineTo(cx, cy + h * 0.22)
      ..lineTo(cx - w * 0.40, cy + h * 0.18)
      ..lineTo(cx - w * 0.38, cy - h * 0.28)
      ..close();
    canvas.drawPath(leftPage, Paint()..color = AppColors.gold.withAlpha(40)..style = PaintingStyle.fill);
    canvas.drawPath(leftPage, goldStroke);

    final rightPage = Path()
      ..moveTo(cx, cy - h * 0.26)
      ..lineTo(cx, cy + h * 0.22)
      ..lineTo(cx + w * 0.40, cy + h * 0.18)
      ..lineTo(cx + w * 0.38, cy - h * 0.28)
      ..close();
    canvas.drawPath(rightPage, Paint()..color = AppColors.gold.withAlpha(28)..style = PaintingStyle.fill);
    canvas.drawPath(rightPage, goldStroke);

    // Spine
    canvas.drawLine(
      Offset(cx, cy - h * 0.26),
      Offset(cx, cy + h * 0.22),
      Paint()..color = AppColors.gold..style = PaintingStyle.stroke..strokeWidth = size.width * 0.016..strokeCap = StrokeCap.round,
    );

    // ── Magnifying glass (centered, top half of book) ─────────────────────
    final glassCx = cx - w * 0.08;
    final glassCy = cy - h * 0.10;
    final glassR = w * 0.18;
    canvas.drawCircle(
      Offset(glassCx, glassCy),
      glassR,
      Paint()..color = AppColors.gold.withAlpha(22)..style = PaintingStyle.fill,
    );
    canvas.drawCircle(Offset(glassCx, glassCy), glassR, goldStroke);
    // Handle
    final handleAngle = math.pi / 4;
    canvas.drawLine(
      Offset(glassCx + glassR * math.cos(handleAngle), glassCy + glassR * math.sin(handleAngle)),
      Offset(glassCx + (glassR + w * 0.18) * math.cos(handleAngle), glassCy + (glassR + w * 0.18) * math.sin(handleAngle)),
      Paint()..color = AppColors.gold..style = PaintingStyle.stroke..strokeWidth = size.width * 0.022..strokeCap = StrokeCap.round,
    );
    // Inner text lines (inside lens)
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(glassCx - glassR * 0.55, glassCy - h * 0.04 + i * h * 0.05),
        Offset(glassCx + glassR * 0.55, glassCy - h * 0.04 + i * h * 0.05),
        Paint()..color = AppColors.gold.withAlpha(80)..style = PaintingStyle.stroke..strokeWidth = 1.0,
      );
    }

    // ── Gold crescent bookmark (top center) ───────────────────────────────
    canvas.drawCircle(Offset(cx, h * 0.12), w * 0.07, Paint()..color = AppColors.gold..style = PaintingStyle.fill);
    canvas.drawCircle(
      Offset(cx + w * 0.05, h * 0.11),
      w * 0.058,
      Paint()..color = const Color(0xFF0D1F3C)..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────

/// Namaz & Dua — mosque dome and minarets silhouette with prayer beads arc.
///
/// Central dome (semi-circle) flanked by two tall minarets (thin rectangles
/// with pointed finials), a gold crescent on the dome, and an arc of
/// tasbih (prayer bead) circles at the bottom.
class _NamazDuaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;
    final goldFaint = Paint()
      ..color = AppColors.gold.withAlpha(55)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // ── Main mosque dome (semi-circle) ────────────────────────────────────
    final domePath = Path()
      ..moveTo(cx - w * 0.30, h * 0.56)
      ..arcToPoint(
        Offset(cx + w * 0.30, h * 0.56),
        radius: Radius.circular(w * 0.30),
        clockwise: false,
      )
      ..close();
    canvas.drawPath(domePath, goldFaint);
    canvas.drawPath(domePath, Paint()..color = AppColors.gold..style = PaintingStyle.stroke..strokeWidth = size.width * 0.025..strokeCap = StrokeCap.round);

    // Dome body (filled rectangle below arc)
    canvas.drawRect(Rect.fromLTWH(cx - w * 0.30, h * 0.56, w * 0.60, h * 0.26), goldFaint);

    // ── Central entrance arch ─────────────────────────────────────────────
    final archPath = Path()
      ..moveTo(cx - w * 0.10, h * 0.82)
      ..lineTo(cx - w * 0.10, h * 0.66)
      ..arcToPoint(
        Offset(cx + w * 0.10, h * 0.66),
        radius: Radius.circular(w * 0.10),
        clockwise: false,
      )
      ..lineTo(cx + w * 0.10, h * 0.82)
      ..close();
    canvas.drawPath(
      archPath,
      Paint()..color = const Color(0xFF0D1F3C)..style = PaintingStyle.fill,
    );

    // ── Left minaret ──────────────────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cx - w * 0.44, h * 0.36, w * 0.10, h * 0.46), const Radius.circular(2)),
      goldFaint,
    );
    // Minaret tip
    final leftTip = Path()
      ..moveTo(cx - w * 0.44, h * 0.36)
      ..lineTo(cx - w * 0.39, h * 0.20)
      ..lineTo(cx - w * 0.34, h * 0.36)
      ..close();
    canvas.drawPath(leftTip, gold);

    // ── Right minaret ─────────────────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cx + w * 0.34, h * 0.36, w * 0.10, h * 0.46), const Radius.circular(2)),
      goldFaint,
    );
    final rightTip = Path()
      ..moveTo(cx + w * 0.34, h * 0.36)
      ..lineTo(cx + w * 0.39, h * 0.20)
      ..lineTo(cx + w * 0.44, h * 0.36)
      ..close();
    canvas.drawPath(rightTip, gold);

    // ── Gold crescent on dome top ─────────────────────────────────────────
    canvas.drawCircle(Offset(cx, h * 0.22), w * 0.07, gold);
    canvas.drawCircle(
      Offset(cx + w * 0.05, h * 0.20),
      w * 0.058,
      Paint()..color = const Color(0xFF071326)..style = PaintingStyle.fill,
    );

    // ── Prayer beads arc (bottom) ─────────────────────────────────────────
    const beads = 9;
    for (int i = 0; i < beads; i++) {
      final angle = math.pi + i * (math.pi / (beads - 1));
      final bx = cx + w * 0.46 * math.cos(angle);
      final by = h * 0.96 + h * 0.10 * math.sin(angle);
      canvas.drawCircle(Offset(bx, by), w * 0.033, i.isEven ? gold : goldFaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────

/// The Muslim Life — Islamic geometric archway with a hanging golden lantern.
///
/// Pointed horseshoe arch (gold outline), an ornamental geometric pattern
/// inside the arch (8-pointed star), and a hanging gold fanous (lantern)
/// suspended from the keystone of the arch.
class _MuslimLifePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final goldStroke = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.022
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final gold = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;
    final goldFaint = Paint()
      ..color = AppColors.gold.withAlpha(40)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // ── Horseshoe arch outline ────────────────────────────────────────────
    final archPath = Path()
      ..moveTo(cx - w * 0.36, h * 0.92)
      ..lineTo(cx - w * 0.36, h * 0.52)
      // left shoulder
      ..arcToPoint(
        Offset(cx, h * 0.14),
        radius: Radius.circular(w * 0.40),
        clockwise: false,
      )
      ..arcToPoint(
        Offset(cx + w * 0.36, h * 0.52),
        radius: Radius.circular(w * 0.40),
        clockwise: false,
      )
      ..lineTo(cx + w * 0.36, h * 0.92);
    canvas.drawPath(archPath, Paint()..color = AppColors.gold.withAlpha(30)..style = PaintingStyle.fill);
    canvas.drawPath(archPath, goldStroke);

    // ── 8-pointed star inside arch (decorative pattern) ───────────────────
    _draw8Star(canvas, Offset(cx, h * 0.50), w * 0.18, goldFaint);
    _draw8Star(canvas, Offset(cx, h * 0.50), w * 0.18,
        Paint()..color = AppColors.gold.withAlpha(80)..style = PaintingStyle.stroke..strokeWidth = 1.0);

    // ── Hanging chain ─────────────────────────────────────────────────────
    canvas.drawLine(
      Offset(cx, h * 0.14),
      Offset(cx, h * 0.30),
      Paint()..color = AppColors.gold..style = PaintingStyle.stroke..strokeWidth = size.width * 0.015..strokeCap = StrokeCap.round,
    );

    // ── Lantern body (fanous) ─────────────────────────────────────────────
    // Top cap
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - w * 0.10, h * 0.30, w * 0.20, h * 0.05),
        const Radius.circular(2),
      ),
      gold,
    );
    // Body (hexagonal — approximated with a rounded rect + triangles)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - w * 0.12, h * 0.35, w * 0.24, h * 0.22),
        const Radius.circular(4),
      ),
      goldFaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - w * 0.12, h * 0.35, w * 0.24, h * 0.22),
        const Radius.circular(4),
      ),
      Paint()..color = AppColors.gold..style = PaintingStyle.stroke..strokeWidth = size.width * 0.018,
    );
    // Bottom drip
    final dripPath = Path()
      ..moveTo(cx - w * 0.08, h * 0.57)
      ..lineTo(cx, h * 0.66)
      ..lineTo(cx + w * 0.08, h * 0.57)
      ..close();
    canvas.drawPath(dripPath, goldFaint);
    canvas.drawPath(dripPath, Paint()..color = AppColors.gold..style = PaintingStyle.stroke..strokeWidth = size.width * 0.018);

    // Inner glow dot
    canvas.drawCircle(Offset(cx, h * 0.46), w * 0.055, gold);
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
