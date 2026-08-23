import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/auth/auth_controller.dart';
import '../../../../features/store/presentation/controllers/cart_controller.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../features/home/presentation/widgets/home_header.dart';
import '../../../../features/home/presentation/widgets/hero_carousel.dart';
import '../../../../features/home/data/repositories/hero_banner_repository.dart';
import '../../../../features/home/data/models/hero_banner_model.dart';
import '../../../../shared/loaders/zabira_loader.dart';
import '../../../../shared/widgets/scholarship_promo_banner.dart';
import '../../../../shared/widgets/zabira_bottom_nav.dart';
import '../../../../shared/widgets/zabira_error_state.dart';
import '../../../../shared/widgets/zabira_network_image.dart';
import '../../../auth/presentation/widgets/auth_bottom_sheet.dart';
import '../../data/models/event_item_model.dart';
import '../../data/services/events_api_service.dart';
import 'event_details_page.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final EventsApiService _service = EventsApiService();
  final TextEditingController _searchController = TextEditingController();

  List<EventItemModel> _events = [];
  List<EventItemModel> _filteredEvents = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  late final List<HeroBannerModel> _banners;

  // Exact Brand Colors
  static const Color brandGold = Color(0xFFC9A84C);
  static const Color brandNavy = Color(0xFF112039);

  final List<String> _categories = const [
    'All',
    'Competition',
    'Webinar',
    'Workshop',
    'School',
    'Kids',
    'Cultural',
  ];

  @override
  void initState() {
    super.initState();
    _banners = HeroBannerRepository.getBannersForSection(
      section: HeroBannerSection.events,
      onCoursesTap: () => context.push(AppRoutes.courses),
      onKidsPortalTap: () => context.push(AppRoutes.kids),
      onStoreTap: () => context.push(AppRoutes.store),
      onLibraryTap: () => context.push(AppRoutes.library),
      onEventsTap: () {},
    );
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _service.getEventsList(limit: 50);
      if (mounted) {
        setState(() {
          _events = list;
          _isLoading = false;
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to load events. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    List<EventItemModel> result = List.from(_events);

    if (_selectedCategory != 'All') {
      result = result.where((e) {
        final cat = e.category.toLowerCase();
        final sel = _selectedCategory.toLowerCase();
        return cat.contains(sel) || e.categories.any((c) => c.toLowerCase().contains(sel));
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((e) {
        return e.title.toLowerCase().contains(q) ||
            e.shortDescription.toLowerCase().contains(q) ||
            e.venue.toLowerCase().contains(q) ||
            e.instructor.toLowerCase().contains(q);
      }).toList();
    }

    setState(() {
      _filteredEvents = result;
    });
  }

  void _openDetails(EventItemModel event, {bool scrollToRegister = false}) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailsPage(
          eventId: event.id,
          initialEvent: event,
          scrollToRegister: scrollToRegister,
        ),
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
        bottomNavigationBar: const ZabiraBottomNav(selectedIndex: -1),
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

            // ── Scrollable Content ────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: brandGold,
                backgroundColor: Colors.white,
                onRefresh: _loadEvents,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.sm),

                      // 1. Hero Carousel (5 banners)
                      HeroCarousel(banners: _banners),

                      const SizedBox(height: AppSpacing.md),

                      // 2. Search & Category Filter Section
                      _buildSearchAndFilters(),

                      const SizedBox(height: AppSpacing.md),

                      // 3. "10 Events Found" / Events Count Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Row(
                          children: [
                            Text(
                              '${_filteredEvents.length} Events Found',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: brandNavy,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: brandGold.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: brandGold.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified_rounded, size: 13, color: brandGold),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Live Events',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: brandNavy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // 4. Events Cards List
                      _buildEventsList(),

                      const SizedBox(height: AppSpacing.lg),

                      // 5. Promotional Scholarship Banner
                      const ScholarshipPromoBanner(),

                      // Bottom navigation breathing space
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search & Horizontal Category Filter Pills ──────────────────────────────
  Widget _buildSearchAndFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: brandNavy.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                _searchQuery = val.trim();
                _applyFilters();
              },
              style: GoogleFonts.outfit(fontSize: 13.5, color: brandNavy),
              decoration: InputDecoration(
                hintText: 'Search events, topics, or venues...',
                hintStyle: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, color: brandNavy, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF64748B)),
                        onPressed: () {
                          _searchController.clear();
                          _searchQuery = '';
                          _applyFilters();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Category Pills
        SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _selectedCategory == cat;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedCategory = cat;
                  });
                  _applyFilters();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? brandNavy : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? brandNavy : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected ? brandNavy.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      cat,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? brandGold : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Events List ────────────────────────────────────────────────────────────
  Widget _buildEventsList() {
    if (_isLoading && _events.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: ZabiraLoader(size: 36),
        ),
      );
    }

    if (_errorMessage != null && _events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ZabiraErrorState(
          title: 'Unable to Load Events',
          message: _errorMessage!,
          onRetry: _loadEvents,
        ),
      );
    }

    if (_filteredEvents.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 20),
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(Icons.event_busy_rounded, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              'No events found',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: brandNavy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try changing your category filter or search keywords.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _selectedCategory = 'All';
                  _searchQuery = '';
                });
                _applyFilters();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: brandNavy,
                foregroundColor: brandGold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('View All Events'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: _filteredEvents.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final event = _filteredEvents[index];
        return _EventListingCard(
          event: event,
          onLearnMore: () => _openDetails(event, scrollToRegister: false),
          onRegisterNow: () => _openDetails(event, scrollToRegister: true),
        );
      },
    );
  }
}

// ── Event Listing Card matching exact reference screenshot ──────────────────
class _EventListingCard extends StatelessWidget {
  const _EventListingCard({
    required this.event,
    required this.onLearnMore,
    required this.onRegisterNow,
  });

  final EventItemModel event;
  final VoidCallback onLearnMore;
  final VoidCallback onRegisterNow;

  static const Color brandGold = Color(0xFFC9A84C);
  static const Color brandNavy = Color(0xFF112039);

  @override
  Widget build(BuildContext context) {
    final bannerUrl = event.resolvedBannerImage ?? event.resolvedFeaturedImage;
    final isFree = event.registrationFee <= 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: brandNavy.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Image Container with Tags ─────────────────────────────────
          GestureDetector(
            onTap: onLearnMore,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: bannerUrl != null && bannerUrl.isNotEmpty
                        ? ZabiraNetworkImage(
                            imageUrl: bannerUrl,
                            fit: BoxFit.cover,
                            fallbackIcon: Icons.event_rounded,
                          )
                        : Container(
                            color: brandNavy,
                            child: const Center(
                              child: Icon(Icons.event_rounded, color: brandGold, size: 40),
                            ),
                          ),
                  ),
                ),

                // Gradient Overlay for readability
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                ),

                // Category Tag (Top Left)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: brandGold,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      event.category.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: brandNavy,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                // Free / Fee Tag (Top Right)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isFree ? const Color(0xFF00A884) : brandNavy,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isFree ? Colors.transparent : brandGold,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      isFree ? '100% FREE' : '₹${event.registrationFee.toInt()}',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Event Details Content ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                GestureDetector(
                  onTap: onLearnMore,
                  child: Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: brandNavy,
                      height: 1.25,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Date & Time Row
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: brandGold),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${event.formattedDate} • ${event.formattedTime}',
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Location / Mode Row
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 15, color: brandGold),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event.formattedLocation,
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                if (event.instructor.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person_rounded, size: 15, color: brandGold),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.instructor,
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),

                // ── Two Action Buttons: Learn More & Register Now ─────────
                Row(
                  children: [
                    // Learn More Button (Dark Navy #112039)
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 42,
                        child: OutlinedButton(
                          onPressed: onLearnMore,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: brandNavy, width: 1.5),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Learn More',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: brandNavy,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Register Now Button (Golden #C9A84C)
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 42,
                        child: ElevatedButton(
                          onPressed: onRegisterNow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandGold,
                            foregroundColor: brandNavy,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Register Now',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: brandNavy,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
