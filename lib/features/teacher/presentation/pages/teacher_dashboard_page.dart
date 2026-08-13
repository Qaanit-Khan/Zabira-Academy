import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

/// Teacher Dashboard — Placeholder
/// Full implementation in Phase 2 (Teacher module)
class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardScaffold(
      roleLabel: 'Teacher',
      roleIcon: Icons.cast_for_education_rounded,
      color: AppColors.navyDark,
      description:
          'Manage your classes, track student progress, and deliver exceptional Islamic education.',
      features: [
        (Icons.video_camera_front_outlined, 'Live Classes'),
        (Icons.people_outline_rounded, 'My Students'),
        (Icons.assignment_outlined, 'Assignments'),
        (Icons.bar_chart_rounded, 'Reports'),
      ],
    );
  }
}
