import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// Apple-Style Floating Dock Bottom Navigation.
///
/// Layout:
///   [Home] | [Learn] | [CENTER LOGO] | [Library] | [Profile]
///
/// Design Features:
/// - Floating white rounded-pill dock with soft ambient shadow
/// - Slim and compact (~54px height) floating above bottom edge
/// - Center item: Dark Navy circular button, NO gold outer ring, slightly elevated
/// - 5 evenly distributed positions with mathematically centered logo
/// - Active Home: dark navy/gold accent with active gold indicator dot underneath
/// - Inactive items: muted slate/navy (#8FA0BB)
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    this.selectedIndex = 0,
    this.onItemTapped,
  });

  final int selectedIndex;
  final ValueChanged<int>? onItemTapped;

  // ── Layout Constants ──────────────────────────────────────────────────────
  static const double _dockHeight     = 54.0;
  static const double _centerBtnSize  = 52.0;
  static const double _floatAbove     = 10.0;
  static const double _centerGap      = 56.0;

  static const _items = [
    _NavItem(icon: Icons.home_rounded,           label: 'Home'),
    _NavItem(icon: Icons.auto_stories_outlined,  label: 'Learn'),
    _NavItem(icon: null,                         label: ''), // Center spacer
    _NavItem(icon: Icons.menu_book_outlined,     label: 'Library'),
    _NavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        bottomPad > 0 ? bottomPad + 4 : 14,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // ── 1. Floating Apple-Style White Dock Pill ───────────────────────
          Container(
            width: double.infinity,
            height: _dockHeight,
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.borderLight.withAlpha(220),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyDark.withAlpha(14),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(child: _buildTab(0)),
                Expanded(child: _buildTab(1)),
                const SizedBox(width: _centerGap), // Center spacer
                Expanded(child: _buildTab(3)),
                Expanded(child: _buildTab(4)),
              ],
            ),
          ),

          // ── 2. Floating Center Elevated Button (No Gold Ring) ────────────
          Positioned(
            top: -_floatAbove,
            child: _CenterLogoButton(
              size: _centerBtnSize,
              onTap: () {
                HapticFeedback.lightImpact();
                onItemTapped?.call(2);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index) {
    final item     = _items[index];
    final isActive = index == selectedIndex;
    final color    = isActive ? AppColors.navyDark : const Color(0xFF8FA0BB);
    final dotColor = isActive ? AppColors.gold : Colors.transparent;

    return Semantics(
      button: true,
      label: item.label,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onItemTapped?.call(index);
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: 20,
              color: isActive ? AppColors.navyDark : const Color(0xFF8FA0BB),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: GoogleFonts.outfit(
                fontSize: 9.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            // Active Gold Indicator Dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 4 : 0,
              height: isActive ? 4 : 0,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Circular floating Center Button with NO gold outer ring.
class _CenterLogoButton extends StatefulWidget {
  const _CenterLogoButton({
    required this.size,
    required this.onTap,
  });

  final double size;
  final VoidCallback onTap;

  @override
  State<_CenterLogoButton> createState() => _CenterLogoButtonState();
}

class _CenterLogoButtonState extends State<_CenterLogoButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Kids Portal',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF081D3A),
              // NO gold outer ring / border as requested
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF081D3A).withAlpha(40),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/home/footer/academy_footer_logo.png',
                width: widget.size,
                height: widget.size,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, _) => const Center(
                  child: Icon(
                    Icons.auto_stories_rounded,
                    color: AppColors.gold,
                    size: 24,
                  ),
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
