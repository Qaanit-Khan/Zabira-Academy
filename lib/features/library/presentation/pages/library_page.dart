import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/auth/auth_controller.dart';
import '../../../../features/store/presentation/controllers/cart_controller.dart';
import '../../../courses/presentation/controllers/wishlist_controller.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../features/home/presentation/widgets/home_header.dart';
import '../../../../shared/loaders/zabira_loader.dart';
import '../../../../shared/widgets/scholarship_promo_banner.dart';
import '../../../../shared/widgets/zabira_bottom_nav.dart';
import '../../../../shared/widgets/zabira_error_state.dart';
import '../../../auth/presentation/widgets/auth_bottom_sheet.dart';
import '../../data/models/library_item_model.dart';
import '../controllers/library_controller.dart';
import '../widgets/library_book_card.dart';
import 'library_item_details_page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final LibraryController _controller;

  // Exact Brand Colors
  static const Color brandGold = Color(0xFFC9A84C);
  static const Color brandNavy = Color(0xFF112039);

  @override
  void initState() {
    super.initState();
    _controller = LibraryController();
    _controller.loadInitialData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openDetails(LibraryItemModel item) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LibraryItemDetailsPage(
          itemId: item.id,
          initialItem: item,
        ),
      ),
    );
  }

  Future<void> _addLibraryItemToCart(LibraryItemModel item) async {
    final auth = context.read<AuthController>();
    final cart = context.read<CartController>();

    if (!auth.isAuthenticated) {
      auth.setPendingReturnTo('/library/${item.id}');
      if (!mounted) return;
      showAuthBottomSheet(context);
      return;
    }

    final format = item.formats.isNotEmpty ? item.formats.first.format : 'pdf';
    final success = await cart.addItem(
      itemData: {
        'book_id': item.id,
        'format': format,
        'book_format': format,
        'product_type': 'library',
        'quantity': '1',
      },
      token: auth.currentToken,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: brandGold, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                success ? 'Added "${item.title}" to cart.' : (cart.errorMessage ?? 'Could not add to cart.'),
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: brandNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: success
            ? SnackBarAction(
                label: 'View Cart',
                textColor: brandGold,
                onPressed: () => context.push(AppRoutes.cart),
              )
            : null,
      ),
    );
  }

  Future<void> _buyNow(LibraryItemModel item) async {
    _openDetails(item);
  }

  void _openFilterSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final categories = _controller.categories;
          final currentCatId = _controller.selectedCategoryId;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.tune_rounded, color: brandNavy, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Filter Library',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: brandNavy,
                      ),
                    ),
                    const Spacer(),
                    if (currentCatId != null)
                      TextButton(
                        onPressed: () {
                          _controller.selectCategory(null);
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          'Reset',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: brandGold,
                          ),
                        ),
                      ),
                  ],
                ),
                const Divider(height: 20),
                Text(
                  'Categories',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: brandNavy,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All Books'),
                      selected: currentCatId == null,
                      onSelected: (_) {
                        _controller.selectCategory(null);
                        Navigator.pop(ctx);
                      },
                      selectedColor: brandNavy,
                      backgroundColor: const Color(0xFFF1F5F9),
                      labelStyle: GoogleFonts.outfit(
                        color: currentCatId == null ? brandGold : brandNavy,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                    ...categories.map((c) {
                      final isSel = currentCatId == c.id;
                      return ChoiceChip(
                        label: Text(c.name),
                        selected: isSel,
                        onSelected: (_) {
                          _controller.selectCategory(c.id);
                          Navigator.pop(ctx);
                        },
                        selectedColor: brandNavy,
                        backgroundColor: const Color(0xFFF1F5F9),
                        labelStyle: GoogleFonts.outfit(
                          color: isSel ? brandGold : brandNavy,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final auth = context.watch<AuthController>();
    final cart = context.watch<CartController>();
    final isAuth = auth.isAuthenticated && auth.user != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          _scaffoldKey.currentState?.closeDrawer();
          return;
        }
        context.go(AppRoutes.home);
      },
      child: Scaffold(
        extendBody: true,
        key: _scaffoldKey,
        drawer: const AppDrawer(),
        backgroundColor: const Color(0xFFF8FAFC),
        bottomNavigationBar: const ZabiraBottomNav(selectedIndex: 4),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: _buildFloatingFilterButton(),
        body: Column(
          children: [
            // ── Fixed Top Header ──────────────────────────────────────────────
            SafeArea(
              bottom: false,
              child: HomeHeader(
                isAuthenticated: isAuth,
                notificationCount: isAuth ? 2 : 0,
                cartCount: cart.itemCount,
                userInitial: isAuth && auth.user!.displayName.isNotEmpty ? auth.user!.displayName[0] : null,
                onMenuTap: () => AppDrawer.open(context),
                onCartTap: () => context.push(AppRoutes.cart),
                onSignIn: () => showAuthBottomSheet(context),
                onProfileTap: () {
                  if (isAuth) {
                    context.push(AppRoutes.studentDash);
                  } else {
                    showAuthBottomSheet(context);
                  }
                },
              ),
            ),

            // ── Scrollable Body ───────────────────────────────────────────────
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  if (_controller.isLoading && _controller.items.isEmpty) {
                    return const Center(child: ZabiraLoader(size: 40));
                  }

                  if (_controller.errorMessage != null && _controller.items.isEmpty) {
                    return ZabiraErrorState(
                      title: 'Unable to Load Library',
                      message: _controller.errorMessage!,
                      onRetry: _controller.loadInitialData,
                    );
                  }

                  final books = _controller.items;

                  return RefreshIndicator(
                    onRefresh: _controller.loadInitialData,
                    color: brandGold,
                    backgroundColor: Colors.white,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.sm),

                          // ── 1. Static Hero Banner (Single Banner) ───────────
                          _buildStaticHeroBanner(),

                          const SizedBox(height: AppSpacing.lg),

                          // ── 2. Four Stat Summary Boxes (2x2 Grid) ───────────
                          _buildStatBoxes(_controller.stats),

                          const SizedBox(height: 24),

                          // ── 3. "JUST PUBLISHED" / "New Releases" Header ─────
                          _buildSectionHeading(books.length),

                          const SizedBox(height: 14),

                          // ── 4. 2-Column Book Cards Grid ──────────────────────
                          _buildBooksGrid(books),

                          const SizedBox(height: 24),

                          // ── 5. Universal Scholarship Promo ──────────────────
                          const ScholarshipPromoBanner(),

                          // Bottom navigation dock padding
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Static Hero Banner (Same size as Home Hero Banner, Single Banner) ──────
  Widget _buildStaticHeroBanner() {
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = (screenWidth * 0.50).clamp(170.0, 210.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        height: bannerHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/home/hero/hero_4.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, _) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF071B36), Color(0xFF0F2C59)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_stories_rounded,
                      color: brandGold,
                      size: 38,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Zabira Academy Library',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Four Stat Summary Boxes (2x2 Grid) matching exact screenshot ────────────
  Widget _buildStatBoxes(LibraryStatsModel stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.menu_book_rounded,
                  iconBg: const Color(0xFFEFF6FF),
                  iconColor: const Color(0xFF3B82F6),
                  title: 'BOOKS',
                  value: stats.totalBooks.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.layers_outlined,
                  iconBg: const Color(0xFFF0FDF4),
                  iconColor: const Color(0xFF10B981),
                  title: 'COLLECTIONS',
                  value: stats.totalCollections.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.description_outlined,
                  iconBg: const Color(0xFFEFF6FF),
                  iconColor: const Color(0xFF3B82F6),
                  title: 'PRINTABLE',
                  value: stats.printableResources.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.auto_awesome_rounded,
                  iconBg: const Color(0xFFFAF5FF),
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'AUDIO BOOKS',
                  value: stats.audiobooks.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: brandNavy.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: brandNavy,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Section Heading ("JUST PUBLISHED / New Releases") ──────────────────────
  Widget _buildSectionHeading(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'JUST PUBLISHED',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: brandGold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'New Releases',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: brandNavy,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Fresh titles from Zabira Press — crafted for classrooms and homes.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── 2-Column Book Grid ─────────────────────────────────────────────────────
  Widget _buildBooksGrid(List<LibraryItemModel> books) {
    if (books.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.menu_book_rounded, size: 40, color: Color(0xFF94A3B8)),
              const SizedBox(height: 10),
              Text(
                'No books available right now.',
                style: GoogleFonts.outfit(fontSize: 14, color: brandNavy, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    final wishlist = context.watch<WishlistController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 0.46,
        ),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final item = books[index];
          final isFav = wishlist.isLibraryFavorite(item.id);

          return LibraryBookCard(
            item: item,
            isFavorite: isFav,
            onTap: () => _openDetails(item),
            onAddToCart: () => _addLibraryItemToCart(item),
            onBuyNow: () => _buyNow(item),
            onFavoriteToggle: () => wishlist.toggleLibraryItem(item),
          );
        },
      ),
    );
  }

  // ── Floating Action Button for Filter ──────────────────────────────────────
  Widget _buildFloatingFilterButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 76, right: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: brandGold.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _openFilterSheet,
        backgroundColor: brandGold,
        elevation: 0,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        icon: const Icon(Icons.tune_rounded, color: brandNavy, size: 18),
        label: Text(
          'FILTER',
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            color: brandNavy,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
