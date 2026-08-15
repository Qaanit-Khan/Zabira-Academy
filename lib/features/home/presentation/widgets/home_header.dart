import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Zabira Academy Home Screen Header.
///
/// LEFT  : Hamburger/menu icon  +  High-resolution Zabira horizontal logo
/// RIGHT : Cart icon (with badge)  •  Bell notification icon (with badge)  •  Profile circle button
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    this.notificationCount = 0,
    this.cartCount = 0,
    this.onMenuTap,
    this.onCartTap,
    this.onNotificationTap,
    this.onProfileTap,
    this.isAuthenticated = false,
    this.onSignIn,
    this.userInitial,
  });

  final int notificationCount;
  final int cartCount;
  final VoidCallback? onMenuTap;
  final VoidCallback? onCartTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final bool isAuthenticated;
  final VoidCallback? onSignIn;
  final String? userInitial;

  void _handleProfileTap() {
    HapticFeedback.lightImpact();
    if (onProfileTap != null) {
      onProfileTap!();
    } else if (!isAuthenticated && onSignIn != null) {
      onSignIn!();
    }
  }

  @override
  Widget build(BuildContext context) {
    const double controlSize = 36.0;
    const double gapBetweenControls = 10.0;

    return Container(
      color: AppColors.surfaceWhite,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Left: Hamburger Menu ─────────────────────────────────────────
          _HeaderIconButton(
            size: controlSize,
            icon: Icons.menu_rounded,
            onTap: onMenuTap ?? () {},
            semanticLabel: 'Open menu',
          ),
          const SizedBox(width: 8),

          // ── Left: Sharp High-Res Horizontal Logo ─────────────────────────
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(
                'assets/images/branding/zabira_logo_horizontal.png',
                height: 38,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, _) => const SizedBox.shrink(),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ── Right: 3 Mathematically Equidistant & Symmetrical Controls ───
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Cart (with real item count badge)
              SizedBox(
                width: controlSize,
                height: controlSize,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    _HeaderIconButton(
                      size: controlSize,
                      icon: Icons.shopping_cart_outlined,
                      onTap: onCartTap ?? () {},
                      semanticLabel: 'Open shopping cart',
                    ),
                    if (cartCount > 0)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                          child: Center(
                            child: Text(
                              cartCount > 99 ? '99+' : '$cartCount',
                              style: GoogleFonts.outfit(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF071B36),
                                height: 1.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: gapBetweenControls),

              // 2. Notifications (Bell + Badge)
              SizedBox(
                width: controlSize,
                height: controlSize,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    _HeaderIconButton(
                      size: controlSize,
                      icon: Icons.notifications_outlined,
                      onTap: onNotificationTap ?? () {},
                      semanticLabel: 'Notifications',
                    ),
                    if (notificationCount > 0)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surfaceWhite,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: gapBetweenControls),

              // 3. Profile Circular Button
              _ProfileButton(
                size: controlSize,
                onTap: _handleProfileTap,
                isAuthenticated: isAuthenticated,
                userInitial: userInitial,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Standard touch target icon button for header actions (Menu, Cart, Bell).
class _HeaderIconButton extends StatefulWidget {
  const _HeaderIconButton({
    required this.size,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  final double size;
  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.90 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Center(
              child: Icon(
                widget.icon,
                color: const Color(0xFF081D3A),
                size: 21,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Circular dark navy Profile button with gold border.
class _ProfileButton extends StatefulWidget {
  const _ProfileButton({
    required this.size,
    required this.onTap,
    required this.isAuthenticated,
    this.userInitial,
  });

  final double size;
  final VoidCallback onTap;
  final bool isAuthenticated;
  final String? userInitial;

  @override
  State<_ProfileButton> createState() => _ProfileButtonState();
}

class _ProfileButtonState extends State<_ProfileButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.isAuthenticated ? 'Open profile' : 'Sign in',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.90 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF081D3A),
              border: Border.all(
                color: AppColors.gold.withAlpha(160),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF081D3A).withAlpha(30),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: widget.isAuthenticated && widget.userInitial != null
                  ? Text(
                      widget.userInitial!.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.gold,
                      ),
                    )
                  : const Icon(
                      Icons.person_outline_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
