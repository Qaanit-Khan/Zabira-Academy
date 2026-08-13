import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/hero_banner_model.dart';

/// Hero promotional carousel displaying full Zabira Academy hero banners.
///
/// Features:
///   • 3 exact uploaded banners (Kids Portal, Zabira Store, Quality Courses)
///   • Auto-rotates every 4.5 seconds with a smooth 600ms easeInOut transition
///   • Horizontally swipeable with manual swipe support
///   • Entire banner is tappable with specific callback per banner
///   • Clean rounded-corner container (16px radius) with soft shadow
///   • NO pagination dots / NO arrows
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

  static const _autoPlayInterval = Duration(seconds: 4, milliseconds: 500);
  static const _animationDuration = Duration(milliseconds: 600);
  static const _animationCurve = Curves.easeInOut;

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
      final nextIndex = (_currentIndex + 1) % widget.banners.length;
      _pageController.animateToPage(
        nextIndex,
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

    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive height tuned to preserve banner artwork aspect ratio (~2.1:1 ratio)
    final bannerHeight = (screenWidth * 0.46).clamp(170.0, 205.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: SizedBox(
        height: bannerHeight,
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.banners.length,
          onPageChanged: (i) {
            setState(() => _currentIndex = i);
            _startAutoPlay();
          },
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: _HeroSlide(banner: widget.banners[index]),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Full-width tappable hero banner slide.
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
                color: AppColors.navyDark.withAlpha(50),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              banner.imagePath,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.navyDark,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      color: AppColors.gold,
                      size: 36,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
