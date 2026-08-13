import 'package:flutter/material.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

/// Parent Dashboard — Placeholder
/// Full implementation in Phase 2 (Parent Zone module)
class ParentDashboardPage extends StatelessWidget {
  const ParentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardScaffold(
      roleLabel: 'Parent / Guardian',
      roleIcon: Icons.family_restroom_rounded,
      color: Color(0xFF2E7D32),
      description:
          "Manage your children's learning, view progress reports, and track their educational journey.",
      features: [
        (Icons.people_outline_rounded, 'My Children'),
        (Icons.bar_chart_rounded, 'Progress'),
        (Icons.schedule_rounded, 'Schedule'),
        (Icons.school_outlined, 'Courses'),
      ],
    );
  }
}
