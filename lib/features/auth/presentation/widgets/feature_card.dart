import 'package:flutter/material.dart';
import 'package:zabira_academy/core/theme/app_colors.dart';
import 'package:zabira_academy/core/theme/app_typography.dart';
import 'package:zabira_academy/core/theme/app_spacing.dart';

/// Stats row: 10k+ Learners | 200+ Courses | 50+ Educators
class StatsRow extends StatelessWidget {
  const StatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatItem(value: '10k+', label: 'Learners'),
        _Divider(),
        _StatItem(value: '200+', label: 'Courses'),
        _Divider(),
        _StatItem(value: '50+', label: 'Educators'),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(value, style: AppTypography.statNumber),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.statLabel),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 28, color: AppColors.textWhite.withAlpha(50));
  }
}

/// Feature highlight cards: Learn Anytime, Live Classes, etc.
class FeatureCard extends StatelessWidget {
  const FeatureCard({super.key, required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBgOnDark,
        border: Border.all(color: AppColors.cardBorderOnDark),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.gold.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: AppColors.gold, size: 18),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: AppTypography.titleSmall.copyWith(color: AppColors.textWhite)),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textWhite.withAlpha(153),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
