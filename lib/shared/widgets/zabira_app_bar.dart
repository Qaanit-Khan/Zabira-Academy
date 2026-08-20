import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app/router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/auth/presentation/widgets/auth_bottom_sheet.dart';
import '../../features/store/presentation/controllers/cart_controller.dart';
import 'app_drawer.dart';
import 'zabira_logo.dart';

/// Zabira Academy — Unified Global Navigation App Bar
///
/// Provides consistent header actions across EVERY page in the application:
/// - Hamburger / Menu button (reliably opens AppDrawer from anywhere)
/// - Zabira Logo (returns to Home)
/// - Cart Icon with live badge count from [CartController]
/// - Notifications Icon
/// - Profile Avatar or Sign In button
class ZabiraAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ZabiraAppBar({
    super.key,
    this.title,
    this.showBackButton = false,
    this.onBackPressed,
    this.onMenuPressed,
    this.backgroundColor,
    this.elevation = 0,
    this.actions,
  });

  final String? title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final VoidCallback? onMenuPressed;
  final Color? backgroundColor;
  final double elevation;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final cart = context.watch<CartController>();
    final canPop = GoRouter.of(context).canPop();

    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.surfaceWhite,
      elevation: elevation,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      leading: (showBackButton && canPop)
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navyDark, size: 20),
              tooltip: 'Back',
              onPressed: onBackPressed ?? () => context.pop(),
            )
          : Builder(
              builder: (innerContext) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: AppColors.navyDark, size: 26),
                tooltip: 'Open Menu',
                onPressed: onMenuPressed ?? () => AppDrawer.open(innerContext),
              ),
            ),
      title: title != null
          ? Text(
              title!,
              style: GoogleFonts.outfit(
                color: AppColors.navyDark,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            )
          : GestureDetector(
              onTap: () => context.go(AppRoutes.home),
              child: Image.asset(
                'assets/images/branding/zabira_logo_horizontal.png',
                height: 36,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, _) => const ZabiraLogo(size: LogoSize.small),
              ),
            ),
      actions: actions ??
          [
            // Cart Button with badge
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF081D3A), size: 21),
                  tooltip: 'Shopping Cart',
                  onPressed: () => context.push(AppRoutes.cart),
                ),
                if (cart.itemCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        cart.itemCount > 99 ? '99+' : '${cart.itemCount}',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF071B36),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 4),

            // Profile Button (matching HomeHeader styling)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: GestureDetector(
                onTap: () {
                  if (auth.isAuthenticated) {
                    context.go(AppRoutes.studentDash);
                  } else {
                    showAuthBottomSheet(context);
                  }
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF081D3A),
                    border: Border.all(
                      color: AppColors.gold.withAlpha(160),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF081D3A).withAlpha(30),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: auth.isAuthenticated && (auth.user?.displayName.isNotEmpty == true)
                        ? Text(
                            auth.user!.displayName[0].toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.gold,
                            ),
                          )
                        : const Icon(
                            Icons.person_outline_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                  ),
                ),
              ),
            ),
          ],
    );
  }
}
