import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// Premium flat-top bottom navigation bar for Zabira Academy.
///
/// 5 tabs: Home | My Learning | [Academy Logo] | Bookmarks | Profile
///
/// Design notes:
/// • The nav bar background is a flat dark-navy rectangle — NO notch/crescent
///   cut-out, so the area around the center logo stays the same navy colour.
/// • The center logo floats ~10px above the bar via a negative Positioned offset.
/// • academy_footer_logo.png has ~304px of transparent padding on each side.
///   We compensate with OverflowBox + ClipOval so the rendered circle shows
///   only the actual circular artwork at the correct visual size.
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    this.selectedIndex = 0,
    this.onItemTapped,
  });

  final int selectedIndex;
  final ValueChanged<int>? onItemTapped;

  // ── Layout constants ────────────────────────────────────────────────────────
  static const double _barHeight = 64.0;

  // Visual diameter we want the artwork to appear at (the circle of gold+navy).
  static const double _visibleDiameter = 60.0;

  // The PNG is 1268 px wide; the visible artwork spans 656 px.
  // Ratio = 1268 / 656 ≈ 1.934 — we need to scale the image up by this factor
  // so that the transparent edges are pushed outside the ClipOval boundary.
  static const double _imageScale = 1268.0 / 656.0; // ≈ 1.93

  // The ClipOval container size we give to Flutter equals the visible artwork
  // diameter; the image is rendered larger inside it and clipped.
  static const double _clipSize = _visibleDiameter;

  // How much the logo floats above the bar top edge.
  static const double _floatAbove = 10.0;

  // Center spacer width keeps the two flanking tabs from overlapping the logo.
  static const double _centerGap = _clipSize + 16.0;

  static const _items = [
    _NavItem(icon: Icons.home_rounded,           label: 'Home'),
    _NavItem(icon: Icons.menu_book_rounded,       label: 'My Learning'),
    _NavItem(icon: null,                          label: ''), // center spacer
    _NavItem(icon: Icons.bookmark_border_rounded, label: 'Bookmarks'),
    _NavItem(icon: Icons.person_outline_rounded,  label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // ── Flat Dark-Navy Bar (NO notch) ────────────────────────────────────
        // Using a plain Container means the area behind and around the logo
        // stays consistently navy — no white crescent, no cut-out.
        Container(
          width: double.infinity,
          height: _barHeight + bottomPad,
          decoration: const BoxDecoration(
            color: Color(0xFF07152B), // deep navy
            border: Border(
              top: BorderSide(
                color: Color(0x22C9A84C), // subtle gold top line
                width: 0.8,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: _barHeight,
              child: Row(
                children: [
                  Expanded(child: _buildTab(0)),
                  Expanded(child: _buildTab(1)),
                  SizedBox(width: _centerGap), // gap for center logo
                  Expanded(child: _buildTab(3)),
                  Expanded(child: _buildTab(4)),
                ],
              ),
            ),
          ),
        ),

        // ── Center Academy Logo — floats above the bar ───────────────────────
        Positioned(
          top: -_floatAbove,
          child: GestureDetector(
            onTap: () => onItemTapped?.call(2),
            behavior: HitTestBehavior.opaque,
            child: _AcademyLogo(
              clipSize: _clipSize,
              imageScale: _imageScale,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(int index) {
    final item     = _items[index];
    final isActive = index == selectedIndex;
    final color    = isActive ? AppColors.gold : const Color(0xFF8FA0BB);

    return GestureDetector(
      onTap: () => onItemTapped?.call(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, size: 22, color: color),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Renders the academy_footer_logo.png cropped to its visible circular
/// artwork by scaling the image up inside a ClipOval, discarding the
/// transparent padding that surrounds the actual art.
class _AcademyLogo extends StatelessWidget {
  const _AcademyLogo({
    required this.clipSize,
    required this.imageScale,
  });

  final double clipSize;
  final double imageScale;

  @override
  Widget build(BuildContext context) {
    final double scaledSize = clipSize * imageScale;

    return Container(
      width: clipSize,
      height: clipSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Single tight shadow — no blur halo, no glow spread
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(70),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: OverflowBox(
          // Allow the image to render larger than the clip container so the
          // transparent padding gets pushed outside the circular clip boundary.
          maxWidth: scaledSize,
          maxHeight: scaledSize,
          child: Image.asset(
            'assets/images/home/footer/academy_footer_logo.png',
            width: scaledSize,
            height: scaledSize,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stack) => Container(
              width: clipSize,
              height: clipSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF07152B),
              ),
              child: const Center(
                child: Icon(
                  Icons.auto_stories_rounded,
                  color: AppColors.gold,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData? icon;
  final String label;
}
