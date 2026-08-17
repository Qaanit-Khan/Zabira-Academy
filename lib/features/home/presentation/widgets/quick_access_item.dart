import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/quick_access_model.dart';

/// Individual tappable item in the Quick Access 4×2 grid.
///
/// Category icons are rendered from individual transparent PNG assets directly
/// on the white background — with NO cream box, NO container border, and NO shadow.
/// Matches the official Zabira Academy white-card reference design.
///
/// Press feedback: AnimatedScale 1.0→0.94 over 120ms with subtle haptic.
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
    final route = widget.item.route;
    if (route.isNotEmpty) {
      context.push(route);
    }
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
          scale: _pressed ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: _pressed ? 0.75 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Direct Transparent Icon (No cream container, No border) ──
                SizedBox(
                  width: 42,
                  height: 42,
                  child: widget.item.imagePath != null
                      ? Image.asset(
                          widget.item.imagePath!,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (context, error, _) =>
                              _FallbackIcon(type: widget.item.iconType),
                        )
                      : _FallbackIcon(type: widget.item.iconType),
                ),
                const SizedBox(height: 8),

                // ── Label ──────────────────────────────────────────────────
                Text(
                  widget.item.label,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // ── Gold underline accent — matches reference design ───────
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: _pressed ? 18 : 14,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withAlpha(_pressed ? 220 : 160),
                    borderRadius: BorderRadius.circular(1),
                  ),
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

/// Minimal fallback icon shown only if the PNG asset fails to load.
class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon({this.type});
  final QaIconType? type;

  IconData get _icon => switch (type) {
        QaIconType.courses => Icons.school_outlined,
        QaIconType.kidsPortal => Icons.child_care_outlined,
        QaIconType.library => Icons.menu_book_outlined,
        QaIconType.nasheed => Icons.headphones_outlined,
        QaIconType.store => Icons.shopping_bag_outlined,
        QaIconType.events => Icons.calendar_month_outlined,
        QaIconType.scholarship => Icons.volunteer_activism_outlined,
        QaIconType.media => Icons.play_circle_outlined,
        null => Icons.apps_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(_icon, color: AppColors.navyDark, size: 28),
    );
  }
}
