
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/router.dart';
import '../../features/islamic_ai/presentation/widgets/islamic_ai_modal.dart';

/// Zabira Academy — Global Bottom Navigation Footer
///
/// Exact 5-position layout:
///   1. Courses  |  2. Kids  |  3. CENTER HOME  |  4. Store  |  5. Library
///
/// Visual matches the attached reference image:
/// - Full-width white rounded-rectangle pill footer
/// - Large circular center notch (true semi-circular cutout) exposing #092540 bg
/// - Navy (#092540) circular center Home button rising above the bar
/// - Gold (#DC8C1A) home icon and active state
/// - Outline icon family assets
class ZabiraBottomNav extends StatelessWidget {
  const ZabiraBottomNav({
    super.key,
    this.selectedIndex = 2,
    this.onItemTapped,
  });

  /// Active tab index:
  /// 0 = Courses  1 = Kids  2 = Home  3 = Store  4 = Library  -1 = none
  final int selectedIndex;
  final ValueChanged<int>? onItemTapped;

  // ── Footer dimensions ───────────────────────────────────────────────────────
  static const double _btnDiameter  = 48.0;   // circle diameter
  static const double _notchGap     = 8.0;    // distinct clean gap between floating button and footer notch
  static const double _barHeight    = 54.0;   // bar thickness
  static const double _buttonRise   = 32.0;   // elevated button height above the footer
  static const double _totalHeight  = _barHeight + _buttonRise;
  static const double _cornerRadius = 0.0;    // flat full-width bar

  static const Color _activeGold    = Color(0xFFDC8C1A);
  static const Color _inactiveColor = Color(0xFF1A2332); // rich dark readable
  static const Color _navyBtn       = Color(0xFF092540);

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final extraPad = bottomPad > 0 ? bottomPad : 0.0;

    return Semantics(
      container: true,
      label: 'Bottom Navigation Bar',
      child: SizedBox(
        width: double.infinity,
        height: _totalHeight + extraPad,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // ── 1. White pill bar extending seamlessly all the way to bottom ─
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _barHeight + extraPad,
              child: CustomPaint(
                painter: _NotchedBarPainter(
                  // notchR = button_radius + gap
                  notchR: _btnDiameter / 2 + _notchGap,
                  // btnCenterY in bar coords: negative = above bar top
                  btnCenterY: (_btnDiameter + 14) / 2 - _buttonRise,
                  cornerRadius: _cornerRadius,
                ),
              ),
            ),

            // ── 2. Four side nav slots ──────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: extraPad,
              height: _barHeight,
              child: Row(
                // Horizontal padding keeps icons away from the screen edge
                // and groups them into balanced, parallel positions.
                children: [
                  const SizedBox(width: 14),
                  Expanded(
                    child: _NavTab(
                      index: 0,
                      selectedIndex: selectedIndex,
                      label: 'Courses',
                      assetPath: 'assets/images/home/categories/courses.png',
                      fallbackIcon: Icons.school_outlined,
                      activeColor: _activeGold,
                      inactiveColor: _inactiveColor,
                      onTap: () => _handleTap(context, 0),
                    ),
                  ),
                  Expanded(
                    child: _NavTab(
                      index: 1,
                      selectedIndex: selectedIndex,
                      label: 'Kids',
                      assetPath: 'assets/images/home/categories/kids_portal.png',
                      fallbackIcon: Icons.child_care_outlined,
                      activeColor: _activeGold,
                      inactiveColor: _inactiveColor,
                      onTap: () => _handleTap(context, 1),
                    ),
                  ),
                  // Center spacer — tighter, pulls tabs toward home button
                  SizedBox(width: _btnDiameter + _notchGap * 2),
                  Expanded(
                    child: _NavTab(
                      index: 3,
                      selectedIndex: selectedIndex,
                      label: 'Store',
                      assetPath: 'assets/images/home/categories/store.png',
                      fallbackIcon: Icons.shopping_bag_outlined,
                      activeColor: _activeGold,
                      inactiveColor: _inactiveColor,
                      onTap: () => _handleTap(context, 3),
                    ),
                  ),
                  Expanded(
                    child: _NavTab(
                      index: 4,
                      selectedIndex: selectedIndex,
                      label: 'Library',
                      assetPath: 'assets/images/home/categories/library.png',
                      fallbackIcon: Icons.menu_book_outlined,
                      activeColor: _activeGold,
                      inactiveColor: _inactiveColor,
                      onTap: () => _handleTap(context, 4),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
              ),
            ),

            // ── 3. Center Home button ────────────────────────────────────────
            Positioned(
              top: 0,
              child: _CenterHomeButton(
                diameter: _btnDiameter,
                isActive: selectedIndex == 2,
                navyColor: _navyBtn,
                goldColor: _activeGold,
                onTap: () => _handleTap(context, 2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, int index) {
    HapticFeedback.lightImpact();
    if (onItemTapped != null) {
      onItemTapped!(index);
      return;
    }
    switch (index) {
      case 0:
        if (GoRouterState.of(context).matchedLocation != AppRoutes.courses) {
          context.go(AppRoutes.courses);
        }
        break;
      case 1:
        if (GoRouterState.of(context).matchedLocation != AppRoutes.kids) {
          context.push(AppRoutes.kids);
        }
        break;
      case 2:
        if (GoRouterState.of(context).matchedLocation != AppRoutes.home) {
          context.go(AppRoutes.home);
        }
        break;
      case 3:
        if (GoRouterState.of(context).matchedLocation != AppRoutes.store) {
          context.push(AppRoutes.store);
        }
        break;
      case 4:
        if (GoRouterState.of(context).matchedLocation != AppRoutes.library) {
          context.push(AppRoutes.library);
        }
        break;
    }
  }
}

// =============================================================================
// WHITE PILL BAR PAINTER — smooth bezier-wing concave notch at top-centre
//
// The notch uses cubic Bezier "wings" on each shoulder so the transition from
// the flat bar top into the concave arc is smooth and organic — matching the
// reference PDF design.  Geometry:
//
//   btnCenterY  = button_radius − buttonRise  (negative = above bar top)
//   notchR      = button_radius + gap
//   arcEntry    = point where the concave arc meets y=entryDepth
//   shoulder    = flat bar extent beyond the arc entry x-position
//
//        flat bar      [bezier wing]  [concave arc]  [bezier wing]    flat bar
//   ━━━━━━━━━━━━━━━━━╮               ╰──────────────╯              ╭━━━━━━━━━━━━━━━━━
// =============================================================================
class _NotchedBarPainter extends CustomPainter {
  const _NotchedBarPainter({
    required this.notchR,
    required this.btnCenterY,
    required this.cornerRadius,
  });

  /// Actual notch radius (button_radius + gap).
  final double notchR;

  /// Button centre Y in bar-local coordinates.  Negative = above bar top.
  final double btnCenterY;

  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final w  = size.width;
    final h  = size.height;
    final cx = w / 2;
    final cr = cornerRadius;

    // ── Arc entry depth ──────────────────────────────────────────────────────
    // The concave arc starts/ends at this depth below the bar top (y > 0).
    // Dropping slightly below y=0 lets the bezier wing create a smooth curve.
    const double entryDepth = 5.0;

    // X-coordinate where the notch circle meets y = entryDepth:
    //   (x-cx)² + (entryDepth - btnCenterY)² = notchR²
    final double dy   = entryDepth - btnCenterY; // always positive (btn above bar)
    final double dxArc = math.sqrt(math.max(0.0, notchR * notchR - dy * dy));

    final double arcRightX  = cx + dxArc;   // right arc entry x
    final double arcLeftX   = cx - dxArc;   // left  arc entry x

    // Shoulder: flat bar extends this many px beyond the arc entry.
    const double shoulderW = 6.0;
    final double shoulderRightX = arcRightX + shoulderW;
    final double shoulderLeftX  = arcLeftX  - shoulderW;

    // ── Build path ───────────────────────────────────────────────────────────
    final path = Path();

    // Top-left rounded corner
    path.moveTo(cr, 0);
    path.arcToPoint(Offset(0, cr),
        radius: Radius.circular(cr), clockwise: false);

    // Left side
    path.lineTo(0, h - cr);

    // Bottom-left corner
    path.arcToPoint(Offset(cr, h), radius: Radius.circular(cr));

    // Bottom edge
    path.lineTo(w - cr, h);

    // Bottom-right corner
    path.arcToPoint(Offset(w, h - cr), radius: Radius.circular(cr));

    // Right side
    path.lineTo(w, cr);

    // Top-right corner
    path.arcToPoint(Offset(w - cr, 0),
        radius: Radius.circular(cr), clockwise: false);

    // ── Right shoulder: flat → smooth bezier → arc entry ─────────────────────
    path.lineTo(shoulderRightX, 0);
    path.cubicTo(
      shoulderRightX - shoulderW * 0.55, 0,       // CP1 – horizontal tangent
      arcRightX + 4,               entryDepth * 0.5, // CP2 – angling in
      arcRightX,                   entryDepth,    // endpoint = arc entry
    );

    // ── Concave arc: clockwise from right entry to left entry ─────────────────
    path.arcToPoint(
      Offset(arcLeftX, entryDepth),
      radius: Radius.circular(notchR),
      clockwise: true, // curves downward into bar (concave from above)
    );

    // ── Left shoulder: arc exit → smooth bezier → flat ───────────────────────
    path.cubicTo(
      arcLeftX - 4,               entryDepth * 0.5, // CP1 – matching arc exit
      shoulderLeftX + shoulderW * 0.55, 0,       // CP2 – returning horizontal
      shoulderLeftX,              0,              // endpoint = flat bar
    );

    // Continue flat to top-left corner
    path.lineTo(cr, 0);
    path.close();

    // ── 1. Distinct Top Upward Shadow (Layered ambient blur above the footer) ──
    final shadowPaint1 = Paint()
      ..color = const Color(0xFF07192F).withValues(alpha: 0.11)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final shadowPaint2 = Paint()
      ..color = const Color(0xFF07192F).withValues(alpha: 0.07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.save();
    canvas.translate(0, -4);
    canvas.drawPath(path, shadowPaint1);
    canvas.drawPath(path, shadowPaint2);
    canvas.restore();

    // ── 2. Structural Elevation Shadow ──
    canvas.drawShadow(
      path,
      const Color(0x35000000),
      8.0,
      false,
    );

    // ── 3. White bar fill (smooth concave Apple dock cutout) ──
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _NotchedBarPainter old) =>
      old.notchR != notchR ||
      old.btnCenterY != btnCenterY ||
      old.cornerRadius != cornerRadius;
}

// =============================================================================
// SIDE NAV TAB
// =============================================================================
class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.index,
    required this.selectedIndex,
    required this.label,
    required this.assetPath,
    required this.fallbackIcon,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final int index;
  final int selectedIndex;
  final String label;
  final String assetPath;
  final IconData fallbackIcon;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = selectedIndex == index;

    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon — gold when active, dark when inactive
            SizedBox(
              width: 24,
              height: 24,
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                color: isActive ? activeColor : inactiveColor,
                colorBlendMode: BlendMode.srcIn,
                errorBuilder: (context, error, stackTrace) => Icon(
                  fallbackIcon,
                  size: 22,
                  color: isActive ? activeColor : inactiveColor,
                ),
              ),
            ),
            const SizedBox(height: 3),
            // Text — always dark, never changes
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 11.0,
                fontWeight: FontWeight.w500,
                color: inactiveColor,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            // Active dot — only visible with color when tab is active
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 5.0,
              height: 5.0,
              decoration: BoxDecoration(
                color: isActive ? activeColor : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// CENTER HOME BUTTON
// =============================================================================
class _CenterHomeButton extends StatefulWidget {
  const _CenterHomeButton({
    required this.diameter,
    required this.isActive,
    required this.navyColor,
    required this.goldColor,
    required this.onTap,
  });

  final double diameter;
  final bool isActive;
  final Color navyColor;
  final Color goldColor;
  final VoidCallback onTap;

  @override
  State<_CenterHomeButton> createState() => _CenterHomeButtonState();
}

class _CenterHomeButtonState extends State<_CenterHomeButton>
    with TickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _holdAnimController;
  late final AnimationController _discoveryAnimController;
  late final Animation<double> _discoveryOpacity;
  bool _aiTriggered = false;

  @override
  void initState() {
    super.initState();
    // Exactly 3-second hold for AI activation
    _holdAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _holdAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _pressed) {
        _aiTriggered = true;
        HapticFeedback.heavyImpact();
        _holdAnimController.reset();
        setState(() => _pressed = false);
        IslamicAiModal.show(context);
      }
    });

    // Periodic subtle AI discovery rainbow glow: fades in & out every 5.5s
    _discoveryAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    )..repeat();

    _discoveryOpacity = TweenSequence<double>([
      // 0% -> 25%: fade in from 0 to 0.45
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.45).chain(CurveTween(curve: Curves.easeOut)), weight: 25),
      // 25% -> 45%: gentle shimmer
      TweenSequenceItem(tween: Tween<double>(begin: 0.45, end: 0.35).chain(CurveTween(curve: Curves.easeInOut)), weight: 20),
      // 45% -> 70%: fade out to 0
      TweenSequenceItem(tween: Tween<double>(begin: 0.35, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 25),
      // 70% -> 100%: stay invisible (pause)
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 30),
    ]).animate(_discoveryAnimController);
  }

  @override
  void dispose() {
    _holdAnimController.dispose();
    _discoveryAnimController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _pressed = true;
      _aiTriggered = false;
    });
    _holdAnimController.forward(from: 0.0);
  }

  void _onTapUp(TapUpDetails details) {
    if (!_aiTriggered) {
      _holdAnimController.reset();
      setState(() => _pressed = false);
      widget.onTap();
    }
  }

  void _onTapCancel() {
    _holdAnimController.reset();
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    // Rigid outer bounding box ensures the button position NEVER shifts vertically or horizontally
    return Semantics(
      button: true,
      selected: widget.isActive,
      label: 'Home and Islamic AI Assistant',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: SizedBox(
          width: widget.diameter + 14,
          height: widget.diameter + 14,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // ── 1. Periodic AI Discovery Rainbow / Iridescent Halo (Non-shifting overlay) ──
              if (!_pressed)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _discoveryAnimController,
                    builder: (context, child) {
                      final opacity = _discoveryOpacity.value;
                      if (opacity <= 0.01) return const SizedBox.shrink();

                      return Center(
                        child: Transform.rotate(
                          angle: _discoveryAnimController.value * 2 * math.pi,
                          child: Container(
                            width: widget.diameter + 8,
                            height: widget.diameter + 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  const Color(0xFFDC8C1A).withValues(alpha: opacity),
                                  const Color(0xFF38BDF8).withValues(alpha: opacity * 0.8),
                                  const Color(0xFFA855F7).withValues(alpha: opacity * 0.9),
                                  const Color(0xFF10B981).withValues(alpha: opacity * 0.8),
                                  const Color(0xFFDC8C1A).withValues(alpha: opacity),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFDC8C1A).withValues(alpha: opacity * 0.45),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // ── 2. 3-Second Hold Golden Progress Ring (Non-shifting overlay) ──
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _holdAnimController,
                  builder: (context, child) {
                    if (_holdAnimController.value <= 0.01) {
                      return const SizedBox.shrink();
                    }
                    return Center(
                      child: SizedBox(
                        width: widget.diameter + 8,
                        height: widget.diameter + 8,
                        child: CircularProgressIndicator(
                          value: _holdAnimController.value,
                          strokeWidth: 2.8,
                          valueColor: AlwaysStoppedAnimation<Color>(widget.goldColor),
                          backgroundColor: widget.goldColor.withValues(alpha: 0.2),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── 3. Fixed Center Home / AI Button (Rigid anchor) ──
              AnimatedScale(
                scale: _pressed ? 0.94 : 1.0,
                duration: const Duration(milliseconds: 100),
                child: Container(
                  width: widget.diameter,
                  height: widget.diameter,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.navyColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                        spreadRadius: -1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: CustomPaint(
                      size: const Size(27, 27),
                      painter: _HomeIconPainter(
                        color: widget.isActive ? widget.goldColor : Colors.white,
                        strokeWidth: 2.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// HOME ICON PAINTER — Exact Lucide House SVG Vector Path
// =============================================================================
class _HomeIconPainter extends CustomPainter {
  const _HomeIconPainter({required this.color, this.strokeWidth = 2.0});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final sx = size.width / 24.0;
    final sy = size.height / 24.0;

    canvas.save();
    canvas.scale(sx, sy);

    // ── 1. Door path: M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8 ────────────
    final door = Path()
      ..moveTo(15, 21)
      ..lineTo(15, 13)
      ..arcToPoint(
        const Offset(14, 12),
        radius: const Radius.circular(1),
        clockwise: false,
      )
      ..lineTo(10, 12)
      ..arcToPoint(
        const Offset(9, 13),
        radius: const Radius.circular(1),
        clockwise: false,
      )
      ..lineTo(9, 21);

    // ── 2. House body: M3 10a2 2 0 0 1 .709-1.528l7-6a2 2 0 0 1 2.582 0l7 6A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z
    final house = Path()
      ..moveTo(3, 10)
      ..arcToPoint(
        const Offset(3.709, 8.472),
        radius: const Radius.circular(2),
        clockwise: true,
      )
      ..lineTo(10.709, 2.472)
      ..arcToPoint(
        const Offset(13.291, 2.472),
        radius: const Radius.circular(2),
        clockwise: true,
      )
      ..lineTo(20.291, 8.472)
      ..arcToPoint(
        const Offset(21, 10),
        radius: const Radius.circular(2),
        clockwise: true,
      )
      ..lineTo(21, 19)
      ..arcToPoint(
        const Offset(19, 21),
        radius: const Radius.circular(2),
        clockwise: true,
      )
      ..lineTo(5, 21)
      ..arcToPoint(
        const Offset(3, 19),
        radius: const Radius.circular(2),
        clockwise: true,
      )
      ..close();

    canvas.drawPath(door, p);
    canvas.drawPath(house, p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HomeIconPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

// Alias for backward compatibility
typedef StreamlineHomeIconPainter = _HomeIconPainter;
