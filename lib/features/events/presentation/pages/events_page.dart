import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/auth/auth_controller.dart';
import '../../../../features/home/presentation/widgets/home_header.dart';
import '../../../../shared/loaders/zabira_loader.dart';
import '../../../../shared/widgets/scholarship_promo_banner.dart';
import '../../../../shared/widgets/zabira_error_state.dart';
import '../../data/models/event_item_model.dart';
import '../controllers/events_controller.dart';
import '../widgets/event_past_card.dart';
import '../widgets/event_upcoming_card.dart';
import '../widgets/events_category_chips.dart';
import '../widgets/events_coming_soon_grid.dart';
import '../widgets/events_hero_card.dart';
import 'event_details_page.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late final EventsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EventsController();
    _controller.loadInitialData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openDetails(EventItemModel event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailsPage(
          eventId: event.id,
          initialEvent: event,
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

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: Column(
        children: [
          // ── Fixed Top Header ──────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: HomeHeader(
              isAuthenticated: auth.isAuthenticated,
              notificationCount: 2,
              onSignIn: () => context.push(AppRoutes.login),
              onProfileTap: () {
                if (auth.isAuthenticated) {
                  // Profile
                } else {
                  context.push(AppRoutes.login);
                }
              },
            ),
          ),

          // ── Scrollable Content ────────────────────────────────────────────
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (_controller.isLoading && _controller.events.isEmpty) {
                  return const Center(child: ZabiraLoader(size: 40));
                }

                if (_controller.errorMessage != null && _controller.events.isEmpty) {
                  return ZabiraErrorState(
                    title: 'Unable to Load Events',
                    message: _controller.errorMessage!,
                    onRetry: _controller.loadInitialData,
                  );
                }

                return RefreshIndicator(
                  onRefresh: _controller.loadInitialData,
                  color: AppColors.gold,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),

                        // 1. Hero Card
                        EventsHeroCard(
                          onExploreTap: () {},
                        ),

                        const SizedBox(height: 10),

                        // 2. Category Chips
                        EventsCategoryChips(
                          selectedCategory: _controller.selectedCategory,
                          onSelectCategory: _controller.selectCategory,
                        ),

                        const SizedBox(height: 12),

                        // 3. Upcoming Events Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Upcoming Events',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navyDark,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {},
                                child: Row(
                                  children: [
                                    Text(
                                      'View All',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.navyDark,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.navyDark),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Upcoming Events Horizontal List
                        _buildUpcomingEventsList(),

                        const SizedBox(height: 20),

                        // 4. Past / Highlighted Events Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Past / Highlighted Events',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navyDark,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {},
                                child: Row(
                                  children: [
                                    Text(
                                      'View All',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.navyDark,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.navyDark),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Past Events List
                        _buildPastEventsList(),

                        const SizedBox(height: 18),

                        // 5. Coming Soon Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: Text(
                            'Coming Soon',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        const EventsComingSoonGrid(),

                        const SizedBox(height: 14),

                        // 6. Promotional Banner
                        const ScholarshipPromoBanner(),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Fixed Bottom Navigation ───────────────────────────────────────
          _buildBottomNav(context),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventsList() {
    final upcoming = _controller.upcomingEvents;
    if (upcoming.isEmpty) {
      return Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('No upcoming events found.', style: TextStyle(color: Color(0xFF64748B))),
        ),
      );
    }

    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: upcoming.length,
        itemBuilder: (context, index) {
          final event = upcoming[index];
          return EventUpcomingCard(
            event: event,
            onTap: () => _openDetails(event),
          );
        },
      ),
    );
  }

  Widget _buildPastEventsList() {
    final past = _controller.pastEvents;
    if (past.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 175,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: past.length,
        itemBuilder: (context, index) {
          final event = past[index];
          return EventPastCard(
            event: event,
            onTap: () => _openDetails(event),
          );
        },
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad > 0 ? bottomPad + 4 : 14),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.borderLight.withAlpha(220), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyDark.withAlpha(14),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(child: _buildNavTab(0, Icons.home_rounded, 'Home', false, () => context.go(AppRoutes.home))),
                Expanded(child: _buildNavTab(1, Icons.auto_stories_outlined, 'Learn', false, () => context.push(AppRoutes.courses))),
                const SizedBox(width: 56),
                Expanded(child: _buildNavTab(3, Icons.calendar_month_rounded, 'Events', true, () {})),
                Expanded(child: _buildNavTab(4, Icons.person_outline_rounded, 'Profile', false, () => context.push(AppRoutes.login))),
              ],
            ),
          ),
          Positioned(
            top: -10,
            child: GestureDetector(
              onTap: () => context.go(AppRoutes.home),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF081D3A),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF081D3A).withAlpha(40),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/home/footer/academy_footer_logo.png',
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.auto_stories_rounded, color: AppColors.gold, size: 24),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTab(int index, IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: isActive ? AppColors.navyDark : const Color(0xFF8FA0BB)),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 9.5,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? AppColors.navyDark : const Color(0xFF8FA0BB),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 4 : 0,
            height: isActive ? 4 : 0,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
