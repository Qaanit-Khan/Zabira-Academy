import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Greeting section — adapts to auth state.
///
/// Authenticated  → "Assalamu Alaikum," / "[Real Name]" / subtitle
/// Unauthenticated → Generic public welcome message
class GreetingSection extends StatelessWidget {
  const GreetingSection({
    super.key,
    // Null = unauthenticated. Real name supplied after login.
    this.userName,
    this.subtitle,
  });

  /// The authenticated user's display name.
  /// Pass `null` to show the public unauthenticated welcome state.
  final String? userName;

  /// Optional subtitle override. Defaults per auth state if null.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = userName != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: isAuthenticated
          ? _AuthenticatedGreeting(name: userName!, subtitle: subtitle)
          : const _PublicGreeting(),
    );
  }
}

/// Personalized greeting shown to authenticated users.
class _AuthenticatedGreeting extends StatelessWidget {
  const _AuthenticatedGreeting({required this.name, this.subtitle});
  final String name;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assalamu Alaikum,',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          name,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.navyDark,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle ?? 'Keep learning, keep growing.',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Neutral public greeting shown to unauthenticated visitors.
class _PublicGreeting extends StatelessWidget {
  const _PublicGreeting();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assalamu Alaikum',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.navyDark,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Discover, learn and grow.',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
