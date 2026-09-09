import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app/router.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/auth/presentation/widgets/auth_bottom_sheet.dart';
import '../../features/store/presentation/controllers/cart_controller.dart';
import 'menu_info_sheets.dart';

/// Zabira Academy — Universal Production Navigation Drawer
///
/// Features:
/// - Smooth animated background blur (6.0 sigma) + semi-transparent navy overlay
/// - Sharp, crisp white drawer from left edge
/// - Top shortcuts (Wishlist with gold accent + Shopping Cart with live badge count)
/// - Logged-in profile card (dynamic with fallback) / Guest welcome card
/// - EXPLORE & SUPPORT menu sections
/// - Fixed red Logout button with modern Android gesture bar safe-area padding
/// - Reusable across every page in the application
class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key, this.currentRoute});

  final String? currentRoute;

  /// Universal method to open the drawer from ANY page or header with full background blur
  static Future<void> open(BuildContext context, [String? currentRoute]) {
    HapticFeedback.lightImpact();
    final resolvedLocation = currentRoute ?? resolveLocation(context);
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Navigation Menu',
      barrierColor: const Color(0xFF0A1628).withValues(alpha: 0.42),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, anim1, anim2) => AppDrawer(currentRoute: resolvedLocation),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return Stack(
          children: [
            // Smooth background blur that covers the ENTIRE underlying screen
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: curved.value * 6.0,
                  sigmaY: curved.value * 6.0,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            // Sharp, crisp sliding drawer sitting above the blur
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1.0, 0.0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          ],
        );
      },
    );
  }

  static String resolveLocation(BuildContext context) {
    try {
      final state = GoRouterState.of(context);
      if (state.matchedLocation.isNotEmpty) return state.matchedLocation;
      if (state.uri.path.isNotEmpty) return state.uri.path;
    } catch (_) {}

    try {
      final router = GoRouter.of(context);
      final uriPath = router.routerDelegate.currentConfiguration.uri.path;
      if (uriPath.isNotEmpty) return uriPath;
    } catch (_) {}

    try {
      return GoRouter.of(context).routeInformationProvider.value.uri.path;
    } catch (_) {
      return '';
    }
  }

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final ScrollController _scrollController = ScrollController();
  bool _isSupportExpanded = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _closeAndNavigate(VoidCallback navigationAction) {
    HapticFeedback.lightImpact();
    // Close the drawer dialog/route
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    // Execute target navigation
    navigationAction();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final cart = context.watch<CartController>();
    final user = auth.user;
    final isAuthenticated = auth.isAuthenticated && user != null;

    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = (screenWidth * 0.64).clamp(260.0, 320.0);

    // Current route location for active gold highlighting
    final rawLocation = widget.currentRoute?.isNotEmpty == true
        ? widget.currentRoute!
        : AppDrawer.resolveLocation(context);
    final currentLocation = rawLocation.trim();

    final isCourses = currentLocation == AppRoutes.courses || currentLocation.startsWith('/courses');
    final isMedia = currentLocation == AppRoutes.media || currentLocation.startsWith('/media');
    final isEvents = currentLocation == AppRoutes.events || currentLocation.startsWith('/events');
    final isLibrary = currentLocation == AppRoutes.library || currentLocation.startsWith('/library');
    final isNasheed = currentLocation == AppRoutes.nasheed || currentLocation.startsWith('/nasheed');
    final isKids = currentLocation == AppRoutes.kids || currentLocation.startsWith('/kids');
    final isScholarship = currentLocation == AppRoutes.scholarship || currentLocation.startsWith('/scholarship');
    final isStore = currentLocation == AppRoutes.store || currentLocation.startsWith('/store');
    final isProfile = currentLocation == AppRoutes.profile || currentLocation == AppRoutes.studentDash || currentLocation.startsWith('/student');
    final isCart = currentLocation == AppRoutes.cart || currentLocation.startsWith('/cart');
    final isWishlist = currentLocation == AppRoutes.studentWishlist;

    // Home is only active if on home/root and no other section is active
    final isHome = !isCourses && !isMedia && !isEvents && !isLibrary && !isNasheed && !isKids && !isScholarship && !isProfile && !isStore && !isCart && !isWishlist && (currentLocation == AppRoutes.home || currentLocation == '/' || currentLocation.isEmpty);

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.white,
        elevation: 16,
        shadowColor: const Color(0xFF0A1628).withValues(alpha: 0.35),
        child: SizedBox(
          width: drawerWidth,
          height: double.infinity,
          child: SafeArea(
            bottom: true,
            top: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Scrollable Menu Content ────────────────────────────────────
                Expanded(
                  child: RawScrollbar(
                    controller: _scrollController,
                    thumbVisibility: false,
                    trackVisibility: false,
                    thickness: 3.5,
                    radius: const Radius.circular(4),
                    thumbColor: const Color(0xFFCBD5E1),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── 1. Top Shortcuts (Wishlist & Cart) ───────────────
                          _buildTopShortcuts(context, cart.itemCount),
                          const SizedBox(height: 14),

                          // ── 2. User Profile Card (Only for Authenticated Users)
                          if (isAuthenticated) ...[
                            _buildUserProfileCard(context, user, isProfile: isProfile),
                            const SizedBox(height: 14),
                          ],

                          // ── 3. EXPLORE Section ──────────────────────────────
                          _buildSectionHeader('EXPLORE'),
                          const SizedBox(height: 6),
                          _buildMenuItem(
                            icon: Icons.home_outlined,
                            title: 'Home',
                            isActive: isHome,
                            onTap: () => _closeAndNavigate(() => context.go(AppRoutes.home)),
                          ),
                          _buildMenuItem(
                            icon: Icons.play_circle_outlined,
                            title: 'Media',
                            isActive: isMedia,
                            onTap: () => _closeAndNavigate(() => context.push(AppRoutes.media)),
                          ),
                          _buildMenuItem(
                            icon: Icons.event_outlined,
                            title: 'Events',
                            isActive: isEvents,
                            onTap: () => _closeAndNavigate(() => context.push(AppRoutes.events)),
                          ),
                          _buildMenuItem(
                            icon: Icons.photo_library_outlined,
                            title: 'Gallery',
                            isActive: false,
                            onTap: () => _closeAndNavigate(() => ZabiraMenuModals.showGallery(context)),
                          ),
                          _buildMenuItem(
                            icon: Icons.library_books_outlined,
                            title: 'Library',
                            isActive: isLibrary,
                            onTap: () => _closeAndNavigate(() => context.push(AppRoutes.library)),
                          ),
                          _buildMenuItem(
                            icon: Icons.school_outlined,
                            title: 'Courses',
                            isActive: isCourses,
                            onTap: () => _closeAndNavigate(() => context.go(AppRoutes.courses)),
                          ),
                          _buildMenuItem(
                            icon: Icons.headphones_outlined,
                            title: 'Nasheed',
                            isActive: isNasheed,
                            onTap: () => _closeAndNavigate(() => context.push(AppRoutes.nasheed)),
                          ),
                          _buildMenuItem(
                            icon: Icons.child_care_rounded,
                            title: 'Kids Portal',
                            badgeText: 'NEW',
                            isActive: isKids,
                            onTap: () => _closeAndNavigate(() => context.push(AppRoutes.kids)),
                          ),
                          _buildMenuItem(
                            icon: Icons.card_giftcard_rounded,
                            title: 'Scholarship',
                            isActive: isScholarship,
                            onTap: () => _closeAndNavigate(() => context.push(AppRoutes.scholarship)),
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 10),

                          // ── 4. SUPPORT Section (Expandable / Collapsible) ──
                          _buildExpandableSupportSection(context),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Fixed Bottom Bar (Logout or Sign In) ────────────────────────
                _buildBottomFixedBar(context, isAuthenticated, auth),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 1. Top Shortcuts (Wishlist & Cart) ───────────────────────────────────────
  Widget _buildTopShortcuts(BuildContext context, int cartCount) {
    return Row(
      children: [
        // Wishlist Button
        Expanded(
          child: InkWell(
            onTap: () => _closeAndNavigate(() => ZabiraMenuModals.showWishlist(context)),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite_border_rounded, size: 17, color: Color(0xFFC9A84C)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Wishlist',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Cart Button
        Expanded(
          child: InkWell(
            onTap: () => _closeAndNavigate(() => context.push(AppRoutes.cart)),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.shopping_cart_outlined, size: 17, color: AppColors.navyDark),
                      if (cartCount > 0)
                        Positioned(
                          top: -4,
                          right: -6,
                          child: Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: const BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 13, minHeight: 13),
                            child: Text(
                              cartCount > 99 ? '99+' : '$cartCount',
                              style: GoogleFonts.outfit(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF071B36),
                                height: 1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Cart',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── 2. User Profile Card (Authenticated) ───────────────────────────────────
  Widget _buildUserProfileCard(BuildContext context, dynamic user, {bool isProfile = false}) {
    final displayName = (user?.displayName?.isNotEmpty == true) ? user!.displayName : 'Qaanit Khan';
    final email = (user?.email?.isNotEmpty == true) ? user!.email : 'qaanitumar77@gmail.com';
    final initials = displayName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();

    return InkWell(
      onTap: () => _closeAndNavigate(() => context.push(AppRoutes.profile)),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isProfile ? const Color(0xFFC9A84C).withValues(alpha: 0.10) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isProfile ? const Color(0xFFC9A84C) : const Color(0xFFE2E8F0),
            width: isProfile ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Circular Avatar / Initials
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF092540),
                border: Border.all(color: AppColors.gold, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF092540).withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initials.isNotEmpty ? initials : 'QK',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: GoogleFonts.outfit(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navyDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'STUDENT',
                          style: GoogleFonts.outfit(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF092540),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  // ── Expandable SUPPORT Section ─────────────────────────────────────────────
  Widget _buildExpandableSupportSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _isSupportExpanded = !_isSupportExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SUPPORT',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFDC8C1A),
                    letterSpacing: 1.0,
                  ),
                ),
                AnimatedRotation(
                  turns: _isSupportExpanded ? 0.25 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFFDC8C1A),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              _buildMenuItem(
                icon: Icons.quiz_outlined,
                title: 'FAQs',
                isActive: false,
                onTap: () => _closeAndNavigate(() => ZabiraMenuModals.showFAQs(context)),
              ),
              _buildMenuItem(
                icon: Icons.article_outlined,
                title: 'Blogs',
                isActive: false,
                onTap: () => _closeAndNavigate(() => ZabiraMenuModals.showBlog(context)),
              ),
              _buildMenuItem(
                icon: Icons.work_outline_rounded,
                title: 'Careers',
                isActive: false,
                onTap: () => _closeAndNavigate(() => ZabiraMenuModals.showJoinAcademy(context)),
              ),
              _buildMenuItem(
                icon: Icons.info_outline_rounded,
                title: 'About Us',
                isActive: false,
                onTap: () => _closeAndNavigate(() => ZabiraMenuModals.showAboutAcademy(context)),
              ),
              _buildMenuItem(
                icon: Icons.mail_outline_rounded,
                title: 'Contact Us',
                isActive: false,
                onTap: () => _closeAndNavigate(() => ZabiraMenuModals.showContactUs(context)),
              ),
              _buildMenuItem(
                icon: Icons.support_agent_rounded,
                title: 'Help Center',
                isActive: false,
                onTap: () => _closeAndNavigate(() => ZabiraMenuModals.showHelpCenter(context)),
              ),
            ],
          ),
          crossFadeState: _isSupportExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
        ),
      ],
    );
  }

  // ── Section Heading ────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: const Color(0xFFC9A84C),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  // ── Menu Item Row ──────────────────────────────────────────────────────────
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
    String? badgeText,
    Color? iconColor,
  }) {
    const activeGold = Color(0xFFC9A84C);
    const inactiveNavy = Color(0xFF112039);
    const inactiveIcon = Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isActive ? activeGold.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: -2, vertical: -2.5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: Icon(
            icon,
            color: isActive ? activeGold : (iconColor ?? inactiveIcon),
            size: 21,
          ),
          title: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              color: isActive ? activeGold : inactiveNavy,
            ),
          ),
          trailing: badgeText != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF071B36),
                    ),
                  ),
                )
              : null,
          onTap: onTap,
        ),
      ),
    );
  }

  // ── Fixed Bottom Bar (Logout or Sign In) ─────────────────────────────────────
  Widget _buildBottomFixedBar(BuildContext context, bool isAuthenticated, AuthController auth) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding > 0 ? bottomPadding + 8 : 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2)),
      ),
      child: isAuthenticated
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                  await auth.signOut();
                  if (context.mounted) {
                    context.go(AppRoutes.home);
                  }
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                label: Text(
                  'Logout',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  shadowColor: const Color(0xFFEF4444).withValues(alpha: 0.3),
                ),
              ),
            )
          : SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                  showAuthBottomSheet(context);
                },
                icon: const Icon(Icons.login_rounded, color: Color(0xFF071B36), size: 18),
                label: Text(
                  'Sign In / Register',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF071B36),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
    );
  }
}
