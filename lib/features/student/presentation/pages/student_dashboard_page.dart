import 'package:flutter/material.dart';
import '../../../../shared/widgets/dashboard_scaffold.dart';

/// Student Dashboard — Placeholder
/// Full implementation in Phase 2 (Learning module)
class StudentDashboardPage extends StatelessWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardScaffold(
      roleLabel: 'Student',
      roleIcon: Icons.school_outlined,
      color: Color(0xFF1565C0),
      description: 'Continue your learning journey through Quran, Arabic, and Islamic studies.',
      features: [
        (Icons.play_circle_outline_rounded, 'My Courses'),
        (Icons.quiz_outlined, 'Quizzes'),
        (Icons.emoji_events_outlined, 'Certificates'),
        (Icons.bar_chart_rounded, 'Progress'),
      ],
    );
  }
}
