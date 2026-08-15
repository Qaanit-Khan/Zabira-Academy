import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/auth/auth_controller.dart';
import '../../../../features/courses/presentation/controllers/enrollment_controller.dart';
import '../../../../features/store/presentation/controllers/cart_controller.dart';
import '../../../../shared/widgets/zabira_network_image.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      if (auth.isAuthenticated) {
        auth.refreshProfile();
        context.read<EnrollmentController>().loadMyCourses(auth.currentToken);
        context.read<CartController>().loadCart(auth.currentToken);
      }
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sign Out',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.navyDark),
        ),
        content: Text(
          'Are you sure you want to sign out of Zabira Academy?',
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final auth = context.read<AuthController>();
              context.read<CartController>().reset();
              context.read<EnrollmentController>().reset();
              await auth.signOut();
              if (mounted) {
                context.go(AppRoutes.home);
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;
    final enrollment = context.watch<EnrollmentController>();
    final cart = context.watch<CartController>();

    if (!auth.isAuthenticated || user == null) {
      return Scaffold(
        backgroundColor: AppColors.surfaceLight,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navyDark, size: 20),
            onPressed: () => context.go(AppRoutes.home),
          ),
          title: Text(
            'Profile',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navyDark),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x2l),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_outline_rounded, size: 64, color: Color(0xFF94A3B8)),
                const SizedBox(height: 16),
                Text('You are not signed in', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Sign in to access your profile, enrolled courses, and cart.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyDark, foregroundColor: Colors.white),
                  onPressed: () => context.push(AppRoutes.login),
                  child: const Text('Sign In'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: const Color(0xFF071B36),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              GoRouter.of(context).pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: Text(
          'My Profile',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Sign Out',
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── Top Header Hero Banner ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF071B36),
                    Color(0xFF0F2C59),
                  ],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withAlpha(50),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: user.resolvedPhotoUrl != null
                          ? ZabiraNetworkImage(
                              imageUrl: user.resolvedPhotoUrl,
                              fit: BoxFit.cover,
                              fallbackIcon: Icons.person_rounded,
                            )
                          : Container(
                              color: const Color(0xFF071B36),
                              child: Center(
                                child: Text(
                                  user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                                  style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.gold),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Name & Role
                  Text(
                    user.displayName,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFFCBD5E1),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Role Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.role.value.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: const Color(0xFF071B36),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Summary Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatTile(
                          icon: Icons.auto_stories_outlined,
                          title: 'Enrolled Courses',
                          value: '${enrollment.enrolledCourses.length}',
                          onTap: () => context.push(AppRoutes.myCourses),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatTile(
                          icon: Icons.shopping_bag_outlined,
                          title: 'Cart Items',
                          value: '${cart.itemCount}',
                          onTap: () => context.push(AppRoutes.cart),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Account Information Card
                  Text(
                    'Account Information',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navyDark),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.email_outlined, 'Email', user.email),
                        if (user.formattedPhone.isNotEmpty) ...[
                          const Divider(height: 18),
                          _buildInfoRow(Icons.phone_outlined, 'Phone', user.formattedPhone),
                        ],
                        if (user.gender != null && user.gender!.isNotEmpty) ...[
                          const Divider(height: 18),
                          _buildInfoRow(Icons.person_pin_outlined, 'Gender', user.gender!),
                        ],
                        if (user.dateOfBirth != null && user.dateOfBirth!.isNotEmpty) ...[
                          const Divider(height: 18),
                          _buildInfoRow(Icons.cake_outlined, 'Date of Birth', user.dateOfBirth!),
                        ],
                        if (user.formattedLocation.isNotEmpty) ...[
                          const Divider(height: 18),
                          _buildInfoRow(Icons.location_on_outlined, 'Location', user.formattedLocation),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Quick Actions Card
                  Text(
                    'Learning & Activities',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navyDark),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildActionTile(
                          icon: Icons.school_outlined,
                          title: 'My Courses',
                          subtitle: 'View ongoing and completed courses',
                          onTap: () => context.push(AppRoutes.myCourses),
                        ),
                        const Divider(height: 1),
                        _buildActionTile(
                          icon: Icons.shopping_cart_outlined,
                          title: 'Shopping Cart',
                          subtitle: '${cart.itemCount} items ready for checkout',
                          onTap: () => context.push(AppRoutes.cart),
                        ),
                        const Divider(height: 1),
                        _buildActionTile(
                          icon: Icons.library_books_outlined,
                          title: 'Digital Library',
                          subtitle: 'Browse books, magazines, and workbooks',
                          onTap: () => context.push(AppRoutes.library),
                        ),
                        const Divider(height: 1),
                        _buildActionTile(
                          icon: Icons.lock_outline_rounded,
                          title: 'Change Password',
                          subtitle: 'Request a password reset email',
                          onTap: () => context.push(AppRoutes.forgotPassword),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showLogoutDialog,
                      icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                      label: Text(
                        'Sign Out',
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.gold.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.gold, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navyDark),
                  ),
                  Text(
                    title,
                    style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.gold),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.navyDark),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.navyDark, size: 20),
      ),
      title: Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navyDark)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }
}
