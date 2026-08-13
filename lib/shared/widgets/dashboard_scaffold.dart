import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/auth/auth_controller.dart';
import '../widgets/zabira_logo.dart';
import '../buttons/primary_button.dart';

/// Shared placeholder dashboard scaffold used by all three role dashboards.
/// Provides a consistent branded placeholder UI with logout.
class DashboardScaffold extends StatelessWidget {
  const DashboardScaffold({
    super.key,
    required this.roleLabel,
    required this.roleIcon,
    required this.color,
    required this.description,
    required this.features,
  });

  final String roleLabel;
  final IconData roleIcon;
  final Color color;
  final String description;
  final List<(IconData, String)> features;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.navyDark,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.lg,
                    AppSpacing.screenHorizontal,
                    AppSpacing.x3l,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo row
                      Row(
                        children: [
                          const ZabiraLogo(size: LogoSize.small),
                          const Spacer(),
                          // Role badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withAlpha(30),
                              border: Border.all(color: AppColors.gold.withAlpha(100)),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(roleIcon, color: AppColors.gold, size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  roleLabel,
                                  style: AppTypography.labelSmall.copyWith(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x2l),
                      // Greeting
                      Text(
                        user != null ? 'Welcome back,' : 'Welcome,',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textWhite.withAlpha(180),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.displayName ?? roleLabel,
                        style: AppTypography.headlineLarge.copyWith(color: AppColors.textWhite),
                      ),
                      if (user?.email != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          user!.email,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textWhite.withAlpha(130),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Content Card ─────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Coming Soon Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.x2l),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navyDark.withAlpha(10),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(roleIcon, color: AppColors.gold, size: 40),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        '$roleLabel Dashboard',
                        style: AppTypography.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        description,
                        style: AppTypography.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.x2l),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withAlpha(20),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.gold.withAlpha(80)),
                        ),
                        child: Text(
                          '🚧  Full dashboard coming in Phase 2',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.navyText,
                            fontSize: 12,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Feature Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.4,
                  children: features.map((f) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(f.$1, color: AppColors.textSecondary, size: 26),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            f.$2,
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Coming soon',
                            style: AppTypography.bodySmall.copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.x2l),

                // Logout Button
                NavyButton(
                  label: 'Logout',
                  icon: Icons.logout_rounded,
                  onPressed: () async {
                    await context.read<AuthController>().signOut();
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
