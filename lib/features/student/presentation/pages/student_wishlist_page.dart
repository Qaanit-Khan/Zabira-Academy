import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/zabira_bottom_nav.dart';
import '../../../../shared/widgets/zabira_network_image.dart';
import '../../../auth/auth_controller.dart';
import '../../../courses/presentation/controllers/wishlist_controller.dart';
import '../../../store/presentation/controllers/cart_controller.dart';
import '../controllers/student_controller.dart';
import '../../data/services/student_api_service.dart';
import '../widgets/student_breadcrumb.dart';
import '../widgets/student_hero_header.dart';
import '../widgets/student_nav_tabs_bar.dart';

/// Screen 8: Student Wishlist (1:1 with `8 - profile whishlist 8.pdf`)
class StudentWishlistPage extends StatefulWidget {
  const StudentWishlistPage({super.key});

  @override
  State<StudentWishlistPage> createState() => _StudentWishlistPageState();
}

class _StudentWishlistPageState extends State<StudentWishlistPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final StudentApiService _apiService = StudentApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWishlist());
  }

  Future<void> _loadWishlist() async {
    final auth = context.read<AuthController>();
    final wishlistCtrl = context.read<WishlistController>();
    if (auth.isAuthenticated && auth.user != null) {
      context.read<StudentController>().loadDashboard(
            auth.currentToken,
            defaultName: auth.user!.displayName,
            defaultEmail: auth.user!.email,
            defaultPhoto: auth.user!.photoUrl,
          );

      try {
        final apiItems = await _apiService.getWishlist(token: auth.currentToken ?? '');
        for (final item in apiItems) {
          if (wishlistCtrl.isExplicitlyDeleted(item.courseId, 'course')) continue;
          final wItem = WishlistItem(
            id: item.courseId,
            title: item.title,
            type: 'course',
            price: item.discountPrice > 0 ? item.discountPrice : item.price,
            originalPrice: item.discountPrice > 0 ? item.price : null,
            imageUrl: item.thumbnailUrl,
            subtitle: item.category.isNotEmpty ? item.category : 'Course',
          );
          if (!wishlistCtrl.isWishlisted(item.courseId, type: 'course')) {
            wishlistCtrl.toggleItem(wItem);
          }
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final studentCtrl = context.watch<StudentController>();
    final wishlistCtrl = context.watch<WishlistController>();
    final user = auth.user;
    final dashboard = studentCtrl.dashboard;
    final items = wishlistCtrl.items;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppDrawer(),
      bottomNavigationBar: const ZabiraBottomNav(selectedIndex: -1),
      body: RefreshIndicator(
        color: const Color(0xFFC9A84C),
        onRefresh: () async {
          await _loadWishlist();
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Dark Navy Top Hero Header
                StudentHeroHeader(user: user, dashboard: dashboard),

                // 2. Horizontal Nav Bar (Index 7: Wishlist)
                const StudentNavTabsBar(selectedIndex: 7),

                // 3. Breadcrumb & Section Title
                StudentBreadcrumbHeader(
                  currentPage: 'Wishlist',
                  title: 'My Wishlist',
                  subtitle: "Courses you've saved for later. Add them to your cart when you're ready to enroll.",
                  actionWidget: ElevatedButton.icon(
                    onPressed: () => context.go(AppRoutes.courses),
                    icon: const Icon(LucideIcons.compass, size: 14, color: Color(0xFF112039)),
                    label: Text(
                      'Browse Courses',
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),

                // 4. Main Content Area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: items.isEmpty
                      ? _buildEmptyState(context)
                      : _buildWishlistList(context, items, wishlistCtrl),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFEF3C7)),
            ),
            child: const Icon(LucideIcons.heart, size: 28, color: Color(0xFFC9A84C)),
          ),
          const SizedBox(height: 20),
          Text(
            'Your wishlist is empty',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse our courses, library books, and store products.\nTap the heart icon to save items you love.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => context.go(AppRoutes.courses),
                icon: const Icon(LucideIcons.bookOpen, size: 14, color: Colors.white),
                label: Text(
                  'Courses',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF112039),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.store),
                icon: const Icon(LucideIcons.shoppingBag, size: 14, color: Color(0xFF112039)),
                label: Text(
                  'Store',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF112039),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistList(
    BuildContext context,
    List<WishlistItem> items,
    WishlistController wishlistCtrl,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = items[index];
        final typeBadge = item.type.toUpperCase();
        final isStore = item.type == 'store';
        final isBook = item.type == 'book';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? ZabiraNetworkImage(imageUrl: item.imageUrl!, fit: BoxFit.cover)
                      : Container(
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(LucideIcons.image, size: 28, color: Color(0xFF94A3B8)),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Info & Actions
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type Badge & Title
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            typeBadge,
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Subtitle / Category
                    if (item.subtitle != null && item.subtitle!.isNotEmpty)
                      Text(
                        item.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    const SizedBox(height: 8),

                    // Price & Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              item.price <= 0 ? 'FREE' : '₹${item.price.toInt()}',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            if (item.originalPrice != null && item.originalPrice! > item.price) ...[
                              const SizedBox(width: 6),
                              Text(
                                '₹${item.originalPrice!.toInt()}',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: const Color(0xFF94A3B8),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Action Buttons: Add to Cart + Remove
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Add to cart button
                            InkWell(
                              onTap: () {
                                final auth = context.read<AuthController>();
                                final cart = context.read<CartController>();
                                final itemMap = {
                                  if (isStore) 'store_product_id': item.id,
                                  if (isStore) 'product_id': item.id,
                                  if (!isStore && !isBook) 'course_id': item.id,
                                  if (isBook) 'book_id': item.id,
                                  'title': item.title,
                                  'name': item.title,
                                  'price': item.price,
                                  'product_type': item.type,
                                  'image': item.imageUrl ?? '',
                                };
                                cart.addItem(itemData: itemMap, token: auth.currentToken);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF112039),
                                    content: Text(
                                      '${item.title} added to Cart!',
                                      style: GoogleFonts.outfit(color: Colors.white),
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF112039),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(LucideIcons.shoppingCart, size: 13, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Add to Cart',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Remove button
                            InkWell(
                              onTap: () async {
                                wishlistCtrl.removeItem(item.id, type: item.type);
                                final auth = context.read<AuthController>();
                                if (auth.currentToken != null && item.type == 'course') {
                                  _apiService.toggleWishlist(
                                    token: auth.currentToken!,
                                    courseId: item.id,
                                  );
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF475569),
                                    content: Text(
                                      'Removed from Wishlist',
                                      style: GoogleFonts.outfit(color: Colors.white),
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  LucideIcons.trash2,
                                  size: 15,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
