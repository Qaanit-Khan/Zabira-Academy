import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/router.dart';
import '../../../../features/auth/models/user_model.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/zabira_network_image.dart';
import '../../data/models/student_dashboard_model.dart';

/// Exact Hero Banner from Reference Designs
/// Colors: Dark Navy #112039, Golden #C9A84C
class StudentHeroHeader extends StatelessWidget {
  const StudentHeroHeader({
    super.key,
    required this.user,
    this.dashboard,
  });

  final UserModel? user;
  final StudentDashboardModel? dashboard;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final name = (dashboard?.studentName.isNotEmpty == true
            ? dashboard!.studentName
            : user?.displayName ?? 'Student')
        .trim();

    final photoUrl = dashboard?.photoUrl ?? user?.photoUrl;
    final initials = name.isNotEmpty
        ? name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join().toUpperCase()
        : 'ST';

    return Container(
      width: double.infinity,
      color: const Color(0xFF112039), // Exact Dark Navy Blue
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Bar with Left Menu Button Only ─────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        AppDrawer.open(context);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withAlpha(40),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.menu,
                          color: Color(0xFFC9A84C),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Row with Avatar Card and Top Details (Clickable -> Opens /student/profile)
          GestureDetector(
            onTap: () => context.go('/student/profile'),
            behavior: HitTestBehavior.opaque,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Card
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFF1E293B),
                    border: Border.all(color: const Color(0xFFC9A84C).withAlpha(120), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC9A84C).withAlpha(30),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: photoUrl != null && photoUrl.isNotEmpty
                        ? ZabiraNetworkImage(
                            imageUrl: photoUrl,
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Text(
                              initials,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFC9A84C),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),

                // Title and Badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge: ZABIRA ACADEMY · STUDENT
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withAlpha(35), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.sparkles, size: 12, color: Color(0xFFC9A84C)),
                            const SizedBox(width: 5),
                            Text(
                              'ZABIRA ACADEMY · STUDENT',
                              style: GoogleFonts.outfit(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withAlpha(230),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Greeting
                      Text(
                        '${_getGreeting()} · Assalamu Alaikum',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Name with golden dot
                      RichText(
                        text: TextSpan(
                          text: name,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                          children: const [
                            TextSpan(
                              text: '.',
                              style: TextStyle(
                                color: Color(0xFFC9A84C),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Subtitle
          Text(
            'Your personal learning workspace — continue courses, track progress, and grow in knowledge with intention.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withAlpha(200),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),

          // Quote in italics
          Text(
            '“Knowledge is light — keep your heart open to receive it.”',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
              color: const Color(0xFFC9A84C),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              // Continue Learning button (Golden)
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/student/continue'),
                    icon: const Icon(LucideIcons.playCircle, size: 16, color: Color(0xFF112039)),
                    label: Text(
                      'Continue Learning',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF112039),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC9A84C),
                      foregroundColor: const Color(0xFF112039),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Browse Courses button (Navy Outlined)
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.courses),
                    icon: const Icon(LucideIcons.bookOpen, size: 16, color: Colors.white),
                    label: Text(
                      'Browse Courses',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white.withAlpha(12),
                      side: BorderSide(color: Colors.white.withAlpha(45), width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
