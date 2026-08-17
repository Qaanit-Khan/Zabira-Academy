import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app/router.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/auth_controller.dart';
import 'zabira_logo.dart';

/// Zabira Academy — Unified App Navigation Drawer
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;
    final isAuthenticated = auth.isAuthenticated && user != null;

    final initials = (user?.displayName.isNotEmpty ?? false)
        ? user!.displayName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'ST';

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // ── 1. Drawer Header ───────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.navyDark,
              ),
              child: isAuthenticated
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.gold.withAlpha(35),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.gold, width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  initials,
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.gold,
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'STUDENT',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.gold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.displayName,
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          user.email,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ZabiraLogo(size: LogoSize.small),
                        const SizedBox(height: 12),
                        Text(
                          'Welcome to Zabira Academy',
                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Empowering Muslims with authentic Islamic education.',
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              context.push(AppRoutes.login);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: AppColors.navyDark,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: Text('Sign In / Register', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
            ),

            // ── 2. Scrollable Navigation List ──────────────────────────────
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _drawerItem(
                    context,
                    'Home',
                    Icons.home_outlined,
                    () => context.go(AppRoutes.home),
                  ),
                  if (isAuthenticated)
                    _drawerItem(
                      context,
                      'Student Dashboard',
                      Icons.dashboard_outlined,
                      () => context.go(AppRoutes.studentDash),
                      highlight: true,
                    ),
                  _drawerItem(
                    context,
                    'All Courses',
                    Icons.menu_book_outlined,
                    () => context.push(AppRoutes.courses),
                  ),
                  if (isAuthenticated)
                    _drawerItem(
                      context,
                      'My Enrolled Courses',
                      Icons.play_circle_outline_rounded,
                      () => context.push(AppRoutes.myCourses),
                    ),
                  _drawerItem(
                    context,
                    'Islamic Library',
                    Icons.library_books_outlined,
                    () => context.push(AppRoutes.library),
                  ),
                  _drawerItem(
                    context,
                    'Zabira Store',
                    Icons.storefront_outlined,
                    () => context.push(AppRoutes.store),
                  ),
                  _drawerItem(
                    context,
                    'Kids Learning Portal',
                    Icons.child_care_rounded,
                    () => context.push('/kids'),
                    badge: 'NEW',
                  ),
                  _drawerItem(
                    context,
                    'Live Events',
                    Icons.event_outlined,
                    () => context.push(AppRoutes.events),
                  ),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),

                  if (isAuthenticated) ...[
                    _drawerItem(
                      context,
                      'My Orders & Invoices',
                      Icons.receipt_long_outlined,
                      () => context.push('/my-orders'),
                    ),
                    _drawerItem(
                      context,
                      'Shopping Cart',
                      Icons.shopping_cart_outlined,
                      () => context.push(AppRoutes.cart),
                    ),
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  ],

                  _drawerItem(
                    context,
                    'Daily Nasheed',
                    Icons.headphones_outlined,
                    () => context.push(AppRoutes.nasheed),
                  ),
                  _drawerItem(
                    context,
                    'Media & Lectures',
                    Icons.play_circle_outlined,
                    () => context.push(AppRoutes.media),
                  ),
                  _drawerItem(
                    context,
                    'Free Trial Classes',
                    Icons.videocam_outlined,
                    () => context.push(AppRoutes.courses),
                  ),
                  _drawerItem(
                    context,
                    'Scholarship Program',
                    Icons.volunteer_activism_outlined,
                    () => context.push(AppRoutes.scholarship),
                  ),

                  if (isAuthenticated) ...[
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _drawerItem(
                      context,
                      'Sign Out',
                      Icons.logout_rounded,
                      () async {
                        Navigator.of(context).pop();
                        await auth.signOut();
                        if (context.mounted) {
                          context.go(AppRoutes.home);
                        }
                      },
                      textColor: AppColors.error,
                      iconColor: AppColors.error,
                    ),
                  ],
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Zabira Academy © 2026',
                style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    String? badge,
    bool highlight = false,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      leading: Icon(
        icon,
        color: iconColor ?? (highlight ? AppColors.gold : const Color(0xFF64748B)),
        size: 22,
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
          color: textColor ?? (highlight ? AppColors.navyDark : const Color(0xFF334155)),
        ),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: GoogleFonts.outfit(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.navyDark),
              ),
            )
          : null,
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
    );
  }
}
