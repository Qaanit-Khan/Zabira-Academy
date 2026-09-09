import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/hero_banner_model.dart';

/// Hero promotional carousel — 4 full-width banners with auto-slide and
/// a subtle pagination dot indicator.
///
/// • Auto-rotates every 5 seconds, 500 ms easeInOut transition
/// • Swipeable manually — resets the timer on each swipe
/// • Gold/grey pagination dots below the banner
class HeroCarousel extends StatefulWidget {
  const HeroCarousel({super.key, required this.banners});

  final List<HeroBannerModel> banners;

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentIndex = 0;

  static const _autoPlayInterval  = Duration(seconds: 5);
  static const _animationDuration = Duration(milliseconds: 500);
  static const _animationCurve    = Curves.easeInOut;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (widget.banners.isEmpty) return;
    _autoPlayTimer = Timer.periodic(_autoPlayInterval, (_) {
      if (!mounted || widget.banners.isEmpty) return;
      final next = (_currentIndex + 1) % widget.banners.length;
      _pageController.animateToPage(
        next,
        duration: _animationDuration,
        curve: _animationCurve,
      );
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    final screenWidth  = MediaQuery.of(context).size.width;
    // ~50% width ratio gives a pleasant 2:1-ish aspect on any phone
    final bannerHeight = (screenWidth * 0.50).clamp(170.0, 210.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Slide area ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SizedBox(
            height: bannerHeight,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.banners.length,
              onPageChanged: (i) {
                setState(() => _currentIndex = i);
                _startAutoPlay(); // reset timer on manual swipe
              },
              itemBuilder: (context, index) {
                return _HeroSlide(banner: widget.banners[index]);
              },
            ),
          ),
        ),

        // ── Pagination dots ────────────────────────────────────────────────
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.banners.length, (i) {
            final isActive = i == _currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width:  isActive ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.gold
                    : AppColors.gold.withAlpha(70),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Single full-width tappable hero slide.
class _HeroSlide extends StatelessWidget {
  const _HeroSlide({required this.banner});
  final HeroBannerModel banner;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Hero Banner ${banner.id}',
      child: GestureDetector(
        onTap: banner.onTap,
        child: Container(
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
            child: banner.imageUrl != null && banner.imageUrl!.isNotEmpty
                ? Image.network(
                    banner.imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: const Color(0xFF081D3A),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.gold,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, _) => _buildAssetFallback(),
                  )
                : _buildAssetFallback(),
          ),
        ),
      ),
    );
  }

  Widget _buildAssetFallback() {
    return Image.asset(
      banner.imagePath,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, _) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF081D3A),
        ),
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.gold.withAlpha(150),
            size: 40,
          ),
        ),
      ),
    );
  }
}
