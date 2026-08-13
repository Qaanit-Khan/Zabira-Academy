import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/quick_access_model.dart';

/// Individual tappable item in the Quick Access 4×2 grid.
///
/// Category icons are rendered from SVG assets using [SvgPicture.asset]
/// in navy primary color on a soft-cream 54×54px container
/// (14px radius, subtle gold border, shadow).
///
/// Press feedback: AnimatedScale 1.0→0.95 over 120ms with subtle haptic.
class QuickAccessItem extends StatefulWidget {
  const QuickAccessItem({super.key, required this.item});

  final QuickAccessModel item;

  @override
  State<QuickAccessItem> createState() => _QuickAccessItemState();
}

class _QuickAccessItemState extends State<QuickAccessItem>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  void _onTapDown(TapDownDetails _) {
    HapticFeedback.lightImpact();
    setState(() => _pressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _pressed = false);
    // TODO: Navigate to ${widget.item.route} when page is ready.
  }

  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.item.semanticLabel,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: _pressed ? 0.82 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _IconContainer(item: widget.item, pressed: _pressed),
                const SizedBox(height: 7),
                Text(
                  widget.item.label,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Renders the 54×54px icon container:
/// soft cream background, 14px radius, thin gold border, subtle shadow.
class _IconContainer extends StatelessWidget {
  const _IconContainer({required this.item, required this.pressed});

  final QuickAccessModel item;
  final bool pressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.softCream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: pressed
              ? AppColors.gold.withAlpha(110)
              : AppColors.gold.withAlpha(55),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withAlpha(pressed ? 14 : 8),
            blurRadius: pressed ? 4 : 8,
            offset: Offset(0, pressed ? 1 : 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: item.iconPath != null
            ? SvgPicture.asset(
                item.iconPath!,
                colorFilter: const ColorFilter.mode(
                  AppColors.navyDark,
                  BlendMode.srcIn,
                ),
              )
            : _QaCustomIcon(type: item.iconType!),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Routes to the appropriate custom-painted icon by [QaIconType].
class _QaCustomIcon extends StatelessWidget {
  const _QaCustomIcon({required this.type});
  final QaIconType type;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _getIconPainter(type),
      child: const SizedBox.expand(),
    );
  }

  CustomPainter _getIconPainter(QaIconType type) {
    return switch (type) {
      QaIconType.courses     => _CoursesIconPainter(),
      QaIconType.kidsPortal  => _KidsPortalIconPainter(),
      QaIconType.library     => _LibraryIconPainter(),
      QaIconType.nasheed     => _NasheedIconPainter(),
      QaIconType.store       => _StoreIconPainter(),
      QaIconType.events      => _EventsIconPainter(),
      QaIconType.scholarship => _ScholarshipIconPainter(),
      QaIconType.media       => _MediaIconPainter(),
    };
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CUSTOM ICON PAINTERS — Unified Zabira Academy Visual Family
//
// Visual language:
//   • Primary geometry: AppColors.navyDark (solid filled)
//   • Gold accent details: AppColors.gold
//   • Soft cutout/counter areas: AppColors.softCream
//   • Canvas: 32×32 logical units (inside 11dp padding from 54×54 container)
//   • Stroke cap: round, stroke join: round for premium feel
//   • All shouldRepaint: false (static icons)
// ═════════════════════════════════════════════════════════════════════════════

/// Courses — graduation cap with gold tassel and a book base.
///
/// Solid navy mortarboard diamond, cylindrical cap top,
/// gold hanging tassel on the right, navy open book base.
class _CoursesIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final navy = Paint()
      ..color = AppColors.navyDark
      ..style = PaintingStyle.fill;
    final gold = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // ── Book base (bottom) ───────────────────────────────────────────────
    final bookPath = Path()
      ..moveTo(w * 0.10, h * 0.62)
      ..lineTo(w * 0.90, h * 0.62)
      ..lineTo(w * 0.90, h * 0.94)
      ..lineTo(w * 0.50, h * 0.94)
      ..lineTo(w * 0.50, h * 0.62);
    canvas.drawPath(bookPath, navy);

    final bookPath2 = Path()
      ..moveTo(w * 0.50, h * 0.62)
      ..lineTo(w * 0.50, h * 0.94)
      ..lineTo(w * 0.10, h * 0.94)
      ..lineTo(w * 0.10, h * 0.62);
    canvas.drawPath(bookPath2, Paint()..color = AppColors.navyDark.withAlpha(170)..style = PaintingStyle.fill);

    // Spine line
    canvas.drawRect(
      Rect.fromLTWH(w * 0.47, h * 0.62, w * 0.06, h * 0.32),
      gold,
    );

    // ── Graduation cap board (diamond) ───────────────────────────────────
    final capCx = w * 0.47;
    final capCy = h * 0.34;
    final cw = w * 0.58;
    final ch = h * 0.18;

    final boardPath = Path()
      ..moveTo(capCx, capCy - ch / 2)
      ..lineTo(capCx + cw / 2, capCy)
      ..lineTo(capCx, capCy + ch / 2)
      ..lineTo(capCx - cw / 2, capCy)
      ..close();
    canvas.drawPath(boardPath, navy);

    // ── Cap top cylinder (small rect) ───────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(capCx, capCy - ch / 2 - h * 0.05), width: w * 0.14, height: h * 0.09),
        const Radius.circular(2),
      ),
      navy,
    );

    // ── Gold tassel (right side) ─────────────────────────────────────────
    final tasselX = capCx + cw / 2;
    final tasselTopY = capCy;
    canvas.drawLine(
      Offset(tasselX, tasselTopY),
      Offset(tasselX, tasselTopY + h * 0.22),
      Paint()..color = AppColors.gold..style = PaintingStyle.stroke..strokeWidth = w * 0.07..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(tasselX, tasselTopY + h * 0.23), w * 0.06, gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────

/// Kids Portal — seated child reading an open Quran/book with a gold star above.
///
/// Navy head, torso, folded legs, and arms holding an open gold book,
/// with a 5-pointed gold star of knowledge floating top-right.
/// Much more aligned with the Islamic children's education theme.
class _KidsPortalIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final navy = Paint()
      ..color = AppColors.navyDark
      ..style = PaintingStyle.fill;
    final gold = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // ── Head ──────────────────────────────────────────────────────────────
    canvas.drawCircle(Offset(w * 0.42, h * 0.21), w * 0.14, navy);

    // ── Torso (seated — slightly wider at base) ────────────────────────────
    final torso = Path()
      ..moveTo(w * 0.28, h * 0.35)
      ..lineTo(w * 0.57, h * 0.35)
      ..lineTo(w * 0.60, h * 0.63)
      ..lineTo(w * 0.25, h * 0.63)
      ..close();
    canvas.drawPath(torso, navy);

    // ── Left arm (angled inward toward book) ──────────────────────────────
    canvas.drawLine(
      Offset(w * 0.30, h * 0.43),
      Offset(w * 0.22, h * 0.58),
      Paint()
        ..color = AppColors.navyDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.10
        ..strokeCap = StrokeCap.round,
    );

    // ── Right arm (angled inward toward book) ─────────────────────────────
    canvas.drawLine(
      Offset(w * 0.55, h * 0.43),
      Offset(w * 0.64, h * 0.58),
      Paint()
        ..color = AppColors.navyDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.10
        ..strokeCap = StrokeCap.round,
    );

    // ── Folded legs (two small horizontal rounded rects) ──────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.17, h * 0.76), width: w * 0.27, height: h * 0.10),
        const Radius.circular(5),
      ),
      navy,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.68, h * 0.76), width: w * 0.27, height: h * 0.10),
        const Radius.circular(5),
      ),
      navy,
    );

    // ── Open book / Quran (in reading position) ───────────────────────────
    // Left page (brighter gold)
    final leftPage = Path()
      ..moveTo(w * 0.42, h * 0.53)
      ..lineTo(w * 0.42, h * 0.70)
      ..lineTo(w * 0.16, h * 0.66)
      ..lineTo(w * 0.18, h * 0.50)
      ..close();
    canvas.drawPath(leftPage, gold);

    // Right page (slightly lower alpha for depth)
    final rightPage = Path()
      ..moveTo(w * 0.42, h * 0.53)
      ..lineTo(w * 0.42, h * 0.70)
      ..lineTo(w * 0.68, h * 0.66)
      ..lineTo(w * 0.66, h * 0.50)
      ..close();
    canvas.drawPath(rightPage,
        Paint()..color = AppColors.gold.withAlpha(165)..style = PaintingStyle.fill);

    // Book spine (navy line at center)
    canvas.drawLine(
      Offset(w * 0.42, h * 0.53),
      Offset(w * 0.42, h * 0.70),
      Paint()
        ..color = AppColors.navyDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.055
        ..strokeCap = StrokeCap.round,
    );

    // ── Gold 5-pointed star (top right — light of knowledge) ─────────────
    _drawStar5(canvas, Offset(w * 0.84, h * 0.18), w * 0.13, gold);
  }

  void _drawStar5(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    final innerR = r * 0.42;
    for (int i = 0; i < 10; i++) {
      final angle = (i * math.pi / 5) - math.pi / 2;
      final radius = i.isEven ? r : innerR;
      final pt = Offset(
          center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────

/// Library — open Islamic manuscript with a gold crescent bookmark.
///
/// Two splayed open pages (navy), a center spine, gold crescent
/// on the right page, and a subtle gold ribbon bookmark at the top.
class _LibraryIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final navy = Paint()
      ..color = AppColors.navyDark
      ..style = PaintingStyle.fill;
    final gold = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // ── Left page ────────────────────────────────────────────────────────
    final leftPage = Path()
      ..moveTo(w * 0.50, h * 0.10)
      ..lineTo(w * 0.50, h * 0.92)
      ..lineTo(w * 0.04, h * 0.84)
      ..lineTo(w * 0.08, h * 0.16)
      ..close();
    canvas.drawPath(leftPage, navy);

    // ── Right page ───────────────────────────────────────────────────────
    final rightPage = Path()
      ..moveTo(w * 0.50, h * 0.10)
      ..lineTo(w * 0.50, h * 0.92)
      ..lineTo(w * 0.96, h * 0.84)
      ..lineTo(w * 0.92, h * 0.16)
      ..close();
    canvas.drawPath(
      rightPage,
      Paint()..color = AppColors.navyDark.withAlpha(190)..style = PaintingStyle.fill,
    );

    // ── Spine highlight ───────────────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(w * 0.47, h * 0.10, w * 0.06, h * 0.82),
      gold,
    );

    // ── Gold crescent on right page ───────────────────────────────────────
    final cr = Offset(w * 0.73, h * 0.48);
    canvas.drawCircle(cr, w * 0.13, gold);
    canvas.drawCircle(
      Offset(cr.dx + w * 0.09, cr.dy - h * 0.02),
      w * 0.11,
      Paint()..color = AppColors.navyDark.withAlpha(190)..style = PaintingStyle.fill,
    );

    // ── Gold ribbon bookmark (top center) ────────────────────────────────
    final ribbonPath = Path()
      ..moveTo(w * 0.44, h * 0.02)
      ..lineTo(w * 0.56, h * 0.02)
      ..lineTo(w * 0.56, h * 0.30)
      ..lineTo(w * 0.50, h * 0.24)
      ..lineTo(w * 0.44, h * 0.30)
      ..close();
    canvas.drawPath(ribbonPath, gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────

/// Nasheed — elegant audio waveform bars with a gold vocal note accent.
///
/// 5 rounded waveform bars of varying heights, centered.
/// A small gold musical note (oval head + stem + flag) at the top right.
class _NasheedIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final navy = Paint()
      ..color = AppColors.navyDark
      ..style = PaintingStyle.fill;
    final gold = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // ── Waveform bars (5 centered bars) ──────────────────────────────────
    final barHeights = [0.38, 0.64, 1.0, 0.68, 0.42];
    final barW = size.width * 0.10;
    final spacing = size.width * 0.148;
    final maxBarH = size.height * 0.60;

    for (int i = 0; i < 5; i++) {
      final x = cx - (2 * spacing) + i * spacing;
      final bh = maxBarH * barHeights[i];
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, cy), width: barW, height: bh),
        const Radius.circular(2.5),
      );
      canvas.drawRRect(rect, navy);
    }

    // ── Gold musical note (top right) ─────────────────────────────────────
    canvas.save();
    canvas.translate(w * 0.76, h * 0.20);
    // Note head (oval)
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.18, height: h * 0.13),
      gold,
    );
    // Stem (vertical line up)
    canvas.drawRect(
      Rect.fromLTWH(w * 0.07, -h * 0.30, w * 0.045, h * 0.30),
      gold,
    );
    // Flag (curve approximated with filled triangle)
    final flagPath = Path()
      ..moveTo(w * 0.115, -h * 0.30)
      ..lineTo(w * 0.22, -h * 0.16)
      ..lineTo(w * 0.115, -h * 0.12)
      ..close();
    canvas.drawPath(flagPath, gold);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────

/// Store — solid navy shopping bag with gold handles and crescent emblem.
///
/// Filled navy trapezoid bag body, two arc gold handles at the top,
/// small gold crescent (filled circle with a softCream cut-circle) centered.
class _StoreIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final navy = Paint()
      ..color = AppColors.navyDark
      ..style = PaintingStyle.fill;
    final gold = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // ── Bag body (filled trapezoid) ───────────────────────────────────────
    final bagPath = Path()
      ..moveTo(w * 0.12, h * 0.38)
      ..lineTo(w * 0.05, h * 0.96)
      ..lineTo(w * 0.95, h * 0.96)
      ..lineTo(w * 0.88, h * 0.38)
      ..close();
    canvas.drawPath(bagPath, navy);

    // ── Gold handles (two arcs) ───────────────────────────────────────────
    final handlePaint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(w * 0.16, h * 0.06, w * 0.28, h * 0.36),
      math.pi, math.pi, false, handlePaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(w * 0.56, h * 0.06, w * 0.28, h * 0.36),
      math.pi, math.pi, false, handlePaint,
    );

    // ── Crescent emblem (centered in bag) ─────────────────────────────────
    final cx = w * 0.50;
    final cy = h * 0.66;
    canvas.drawCircle(Offset(cx, cy), w * 0.13, gold);
    canvas.drawCircle(
      Offset(cx + w * 0.09, cy - h * 0.015),
      w * 0.105,
      Paint()..color = AppColors.navyDark..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────

/// Events — solid navy calendar header with gold binding rings and date dots.
///
/// Navy filled calendar frame, solid navy header band, two gold
/// binding ring tabs at the top, three gold dot rows in the date grid area,
/// and a small gold crescent star in the header.
class _EventsIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final navy = Paint()
      ..color = AppColors.navyDark
      ..style = PaintingStyle.fill;
    final gold = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // ── Calendar body (outline-filled) ────────────────────────────────────
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.04, h * 0.18, w * 0.92, h * 0.78),
      const Radius.circular(4),
    );
    canvas.drawRRect(bodyRect, navy);

    // ── Date area fill (soft cream) ───────────────────────────────────────
    final dateArea = RRect.fromLTRBAndCorners(
      w * 0.04, h * 0.42, w * 0.96, h * 0.96,
      bottomLeft: const Radius.circular(4),
      bottomRight: const Radius.circular(4),
    );
    canvas.drawRRect(
      dateArea,
      Paint()..color = AppColors.softCream..style = PaintingStyle.fill,
    );

    // ── Date grid dots (3 × 2 = 6 navy dots) ─────────────────────────────
    final dotPaint = Paint()..color = AppColors.navyDark..style = PaintingStyle.fill;
    final dotR = w * 0.055;
    for (int row = 0; row < 2; row++) {
      for (int col = 0; col < 3; col++) {
        final dx = w * 0.22 + col * w * 0.28;
        final dy = h * 0.56 + row * h * 0.24;
        canvas.drawCircle(Offset(dx, dy), dotR, dotPaint);
      }
    }

    // ── Gold binding ring tabs ────────────────────────────────────────────
    final ringPaint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.30, h * 0.05), Offset(w * 0.30, h * 0.28), ringPaint);
    canvas.drawLine(Offset(w * 0.70, h * 0.05), Offset(w * 0.70, h * 0.28), ringPaint);

    // ── Small gold crescent in header ─────────────────────────────────────
    canvas.drawCircle(Offset(w * 0.78, h * 0.30), w * 0.10, gold);
    canvas.drawCircle(
      Offset(w * 0.84, h * 0.28),
      w * 0.08,
      Paint()..color = AppColors.navyDark..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────

/// Scholarship — open hand cradling a gold graduation cap above.
///
/// Solid navy flat graduation mortarboard cap (diamond) with gold
/// tassel, positioned above a solid navy open palm silhouette.
class _ScholarshipIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final navy = Paint()
      ..color = AppColors.navyDark
      ..style = PaintingStyle.fill;
    final gold = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // ── Open palm (bottom half) ───────────────────────────────────────────
    final palmPath = Path()
      ..moveTo(w * 0.16, h * 0.98)
      ..lineTo(w * 0.84, h * 0.98)
      ..lineTo(w * 0.84, h * 0.70)
      ..quadraticBezierTo(w * 0.84, h * 0.56, w * 0.68, h * 0.52)
      ..lineTo(w * 0.60, h * 0.50)
      ..quadraticBezierTo(w * 0.52, h * 0.45, w * 0.50, h * 0.50)
      ..lineTo(w * 0.50, h * 0.54)
      ..lineTo(w * 0.32, h * 0.54)
      ..quadraticBezierTo(w * 0.16, h * 0.56, w * 0.16, h * 0.70)
      ..close();
    canvas.drawPath(palmPath, navy);

    // ── Graduation cap board (diamond, top) ───────────────────────────────
    final capCx = w * 0.48;
    final capCy = h * 0.24;
    final cw = w * 0.52;
    final ch = h * 0.15;

    final boardPath = Path()
      ..moveTo(capCx, capCy - ch / 2)
      ..lineTo(capCx + cw / 2, capCy)
      ..lineTo(capCx, capCy + ch / 2)
      ..lineTo(capCx - cw / 2, capCy)
      ..close();
    canvas.drawPath(boardPath, navy);

    // Cap button on top
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(capCx, capCy - ch / 2 - h * 0.045), width: w * 0.12, height: h * 0.08),
        const Radius.circular(2),
      ),
      navy,
    );

    // ── Gold tassel ───────────────────────────────────────────────────────
    canvas.drawLine(
      Offset(capCx + cw / 2, capCy),
      Offset(capCx + cw / 2, capCy + h * 0.20),
      Paint()..color = AppColors.gold..style = PaintingStyle.stroke..strokeWidth = w * 0.07..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(capCx + cw / 2, capCy + h * 0.21), w * 0.06, gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────

/// Media — navy screen/TV frame with gold play button and Islamic star watermark.
///
/// Filled navy rounded rectangle frame, soft cream inner screen,
/// subtle 8-pointed Islamic star (low-alpha navy) as watermark,
/// solid gold play triangle centered, navy TV stand below.
class _MediaIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final navy = Paint()
      ..color = AppColors.navyDark
      ..style = PaintingStyle.fill;
    final gold = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // ── Screen frame (navy rounded rect) ─────────────────────────────────
    final screenRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.02, h * 0.08, w * 0.96, h * 0.72),
      const Radius.circular(5),
    );
    canvas.drawRRect(screenRect, navy);

    // ── Inner screen area (soft cream) ───────────────────────────────────
    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.09, h * 0.16, w * 0.82, h * 0.56),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      innerRect,
      Paint()..color = AppColors.softCream..style = PaintingStyle.fill,
    );

    // ── 8-pointed Islamic star watermark (low alpha) ──────────────────────
    _draw8Star(
      canvas,
      Offset(w * 0.50, h * 0.44),
      w * 0.20,
      Paint()..color = AppColors.navyDark.withAlpha(22)..style = PaintingStyle.fill,
    );

    // ── Gold play triangle ────────────────────────────────────────────────
    final playPath = Path()
      ..moveTo(w * 0.36, h * 0.28)
      ..lineTo(w * 0.36, h * 0.60)
      ..lineTo(w * 0.66, h * 0.44)
      ..close();
    canvas.drawPath(playPath, gold);

    // ── TV stand ──────────────────────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(w * 0.43, h * 0.80, w * 0.14, h * 0.12),
      navy,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.26, h * 0.90, w * 0.48, h * 0.08),
        const Radius.circular(2),
      ),
      navy,
    );
  }

  void _draw8Star(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final outerAngle = (i * math.pi / 4) - math.pi / 2;
      final innerAngle = outerAngle + math.pi / 8;
      final outerPt = Offset(center.dx + r * math.cos(outerAngle), center.dy + r * math.sin(outerAngle));
      final innerPt = Offset(center.dx + r * 0.45 * math.cos(innerAngle), center.dy + r * 0.45 * math.sin(innerAngle));
      i == 0 ? path.moveTo(outerPt.dx, outerPt.dy) : path.lineTo(outerPt.dx, outerPt.dy);
      path.lineTo(innerPt.dx, innerPt.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
