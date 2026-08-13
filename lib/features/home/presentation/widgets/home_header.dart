import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/zabira_logo.dart';

/// Top header bar.
///
/// Authenticated  → Logo | Search | Bell(badge)
/// Unauthenticated → Logo | Search | Sign In
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    this.isAuthenticated = false,
    this.notificationCount = 0,
    this.onSignIn,
  });

  final bool isAuthenticated;
  final int notificationCount;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceWhite,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo
          const ZabiraLogo(size: LogoSize.small, dark: true, showTagline: false),
          // Right action — notification (auth) or Sign In (public)
          if (isAuthenticated)
            _NotificationButton(count: notificationCount)
          else
            _SignInButton(onTap: onSignIn ?? () {}),
        ],
      ),
    );
  }
}

/// Gold pill "Sign In" button shown to unauthenticated visitors.
class _SignInButton extends StatelessWidget {
  const _SignInButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.navyDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.gold.withAlpha(120), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.login_rounded, color: AppColors.gold, size: 14),
            const SizedBox(width: 6),
            Text(
              'Sign In',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Icon(Icons.notifications_outlined, color: AppColors.navyDark, size: 20),
          ),
          if (count > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.surfaceWhite, width: 1.5),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: AppColors.navyDark,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
