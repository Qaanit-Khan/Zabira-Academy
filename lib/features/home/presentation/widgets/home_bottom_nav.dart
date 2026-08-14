import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// Bottom navigation bar — 5 tabs: Home | Library | [Kids Center] | Store | Dashboard.
///
/// The center Kids button uses the academy_footer_logo.png asset and
/// floats slightly above the bar surface.
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    this.selectedIndex = 0,
    this.onItemTapped,
  });

  final int selectedIndex;
  final ValueChanged<int>? onItemTapped;

  // ── Layout constants ──────────────────────────────────────────────────────
  static const double _barHeight       = 64.0;
  static const double _visibleDiameter = 58.0;
  static const double _imageScale      = 1268.0 / 656.0; // ≈ 1.93
  static const double _clipSize        = _visibleDiameter;
  static const double _floatAbove      = 12.0;
  static const double _centerGap       = _clipSize + 20.0;

  // Tabs — index 2 is the invisible center spacer
  static const _items = [
    _NavItem(icon: Icons.home_rounded,          label: 'Home'),
    _NavItem(icon: Icons.menu_book_outlined,    label: 'Library'),
    _NavItem(icon: null,                        label: ''), // center spacer
    _NavItem(icon: Icons.shopping_bag_outlined, label: 'Store'),
    _NavItem(icon: Icons.person_outline_rounded,label: 'Dashboard'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // ── Dark navy bar ─────────────────────────────────────────────────
        Container(
          width: double.infinity,
          height: _barHeight + bottomPad,
          decoration: const BoxDecoration(
            color: Color(0xFF081D3A),
            border: Border(
              top: BorderSide(color: Color(0x30C9A84C), width: 0.8),
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

        // ── Floating center Kids button ────────────────────────────────────
        Positioned(
          top: -_floatAbove,
          child: GestureDetector(
            onTap: () => onItemTapped?.call(2),
            behavior: HitTestBehavior.opaque,
            child: _CenterLogo(
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
          // Active indicator dot
          const SizedBox(height: 3),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 4 : 0,
            height: isActive ? 4 : 0,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Circular floating Kids center button with the academy logo asset.
class _CenterLogo extends StatelessWidget {
  const _CenterLogo({required this.clipSize, required this.imageScale});

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
        color: const Color(0xFF081D3A),
        border: Border.all(color: AppColors.gold.withAlpha(180), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: OverflowBox(
          maxWidth: scaledSize,
          maxHeight: scaledSize,
          child: Image.asset(
            'assets/images/home/footer/academy_footer_logo.png',
            width: scaledSize,
            height: scaledSize,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, _) => const Icon(
              Icons.auto_stories_rounded,
              color: AppColors.gold,
              size: 26,
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
