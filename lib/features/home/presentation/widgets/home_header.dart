import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Zabira Academy Home Screen Header.
///
/// LEFT  : Hamburger/menu icon  +  High-resolution Zabira horizontal logo
/// RIGHT : Cart icon  •  Bell notification icon (with badge)  •  Profile circle button
///
/// Features:
/// - Crisp, properly sized and vertically centered logo
/// - Perfectly balanced and uniformly spaced right-side action buttons (38×38 touch targets)
/// - Profile button: navigates to Login if unauthenticated, or Profile if logged in
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    this.notificationCount = 0,
    this.onMenuTap,
    this.onCartTap,
    this.onNotificationTap,
    this.onProfileTap,
    this.isAuthenticated = false,
    this.onSignIn,
  });

  final int notificationCount;
  final VoidCallback? onMenuTap;
  final VoidCallback? onCartTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final bool isAuthenticated;
  final VoidCallback? onSignIn;

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

          // ── Right: 3 Consistently Sized & Spaced Controls ────────────────
          // 1. Cart
          _HeaderIconButton(
            icon: Icons.shopping_cart_outlined,
            onTap: onCartTap ?? () {},
            semanticLabel: 'Open shopping cart',
          ),
          const SizedBox(width: 6),

          // 2. Notifications (Bell + Badge)
          Stack(
            clipBehavior: Clip.none,
            children: [
              _HeaderIconButton(
                icon: Icons.notifications_outlined,
                onTap: onNotificationTap ?? () {},
                semanticLabel: 'Notifications',
              ),
              if (notificationCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
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
          const SizedBox(width: 6),

          // 3. Profile Circular Button
          _ProfileButton(
            onTap: _handleProfileTap,
            isAuthenticated: isAuthenticated,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Standard 38×38 touch target icon button for header actions (Menu, Cart, Bell).
class _HeaderIconButton extends StatefulWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

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
            width: 38,
            height: 38,
            child: Center(
              child: Icon(
                widget.icon,
                color: const Color(0xFF081D3A),
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Circular dark navy Profile button with gold border, matching 38×38 size.
class _ProfileButton extends StatefulWidget {
  const _ProfileButton({
    required this.onTap,
    required this.isAuthenticated,
  });

  final VoidCallback onTap;
  final bool isAuthenticated;

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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF081D3A),
              border: Border.all(
                color: AppColors.gold.withAlpha(160),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF081D3A).withAlpha(30),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.person_outline_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
