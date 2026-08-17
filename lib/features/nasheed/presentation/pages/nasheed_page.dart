import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
import '../../../../core/audio/global_audio_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/auth/auth_controller.dart';
import '../../../../features/store/presentation/controllers/cart_controller.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../features/home/presentation/widgets/home_header.dart';
import '../../../../shared/loaders/zabira_loader.dart';
import '../../../../shared/widgets/scholarship_promo_banner.dart';
import '../../../../shared/widgets/zabira_error_state.dart';
import '../controllers/nasheed_audio_player_controller.dart';
import '../controllers/nasheed_controller.dart';
import '../widgets/nasheed_category_chips.dart';
import '../widgets/nasheed_hero_card.dart';
import '../widgets/nasheed_now_playing_card.dart';
import '../widgets/nasheed_track_tile.dart';

class NasheedPage extends StatefulWidget {
  const NasheedPage({super.key});

  @override
  State<NasheedPage> createState() => _NasheedPageState();
}

class _NasheedPageState extends State<NasheedPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final NasheedController _controller;
  NasheedAudioPlayerController? _playerController;

  @override
  void initState() {
    super.initState();
    _controller = NasheedController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final globalAudio = context.read<GlobalAudioController>();
      setState(() {
        _playerController = NasheedAudioPlayerController(globalAudio);
      });
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await _controller.loadInitialData();
    // Do not auto-play on page load — let user choose
  }

  @override
  void dispose() {
    _controller.dispose();
    _playerController?.dispose();
    super.dispose();
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

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: AppColors.surfaceLight,
      body: Column(
        children: [
          // ── Fixed Top Header ──────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: HomeHeader(
              isAuthenticated: auth.isAuthenticated,
              notificationCount: 2,
              cartCount: cart.itemCount,
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
              onCartTap: () => context.push(AppRoutes.cart),
              onSignIn: () => context.push(AppRoutes.login),
              onProfileTap: () {
                if (auth.isAuthenticated) {
                  context.go(AppRoutes.studentDash);
                } else {
                  context.push(AppRoutes.login);
                }
              },
            ),
          ),

          // ── Scrollable Content ────────────────────────────────────────────────
          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge(
                [_controller, ?_playerController],
              ),
              builder: (context, _) {
                final player = _playerController;
                if (_controller.isLoading && _controller.nasheedList.isEmpty) {
                  return const Center(child: ZabiraLoader(size: 40));
                }

                if (_controller.errorMessage != null && _controller.nasheedList.isEmpty) {
                  return ZabiraErrorState(
                    title: 'Unable to Load Nasheeds',
                    message: _controller.errorMessage!,
                    onRetry: _loadData,
                  );
                }

                final nasheeds = _controller.filteredNasheeds;

                return RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppColors.gold,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),

                        // 1. Hero Card
                        NasheedHeroCard(
                          onListenTap: () {
                            if (nasheeds.isNotEmpty && player != null) {
                              player.playTrack(nasheeds.first);
                            }
                          },
                        ),

                        const SizedBox(height: 10),

                        // 2. Category Section Header & Chips
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Explore by Category',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
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
                        const SizedBox(height: 6),

                        NasheedCategoryChips(
                          categories: _controller.categories,
                          selectedCategoryId: _controller.selectedCategoryId,
                          onSelectCategory: _controller.selectCategory,
                        ),

                        const SizedBox(height: 8),

                        // 3. Now Playing Header & Card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF081D3A),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.music_note_rounded, color: AppColors.gold, size: 14),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Now Playing',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.navyDark,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'See All >',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navyDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),

                        if (player != null)
                          NasheedNowPlayingCard(playerController: player),

                        const SizedBox(height: 14),

                        // 4. All Nasheeds Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'All Nasheeds',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navyDark,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Sort',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.sort_rounded, size: 16, color: Color(0xFF64748B)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),

                        // List of Nasheeds
                        if (nasheeds.isEmpty)
                          Container(
                            height: 100,
                            margin: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text('No nasheeds found in this category.', style: TextStyle(color: Color(0xFF64748B))),
                            ),
                          )
                        else
                        if (player != null)
                          ...nasheeds.map((track) => NasheedTrackTile(
                                track: track,
                                playerController: player,
                              ))
                        else
                          ...nasheeds.map((track) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                child: Text(track.title, style: const TextStyle(color: Color(0xFF334155))),
                              )),

                        const SizedBox(height: 14),

                        // 5. Promotional Banner
                        const ScholarshipPromoBanner(
                          tag: 'GOOD NASHEEDS • BRIGHTER GENERATIONS',
                          titlePrefix: 'Let Their Hearts ',
                          titleHighlight: 'Be Filled with Goodness',
                          subtitle: 'Soulful nasheeds providing pure, positive values for youth.',
                          buttonText: 'Explore More',
                        ),

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
                Expanded(child: _buildNavTab(3, Icons.menu_book_outlined, 'Library', false, () => context.push(AppRoutes.library))),
                Expanded(child: _buildNavTab(4, Icons.music_note_rounded, 'Nasheed', true, () {})),
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
