import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/latest_launch_model.dart';

/// Compact image-first card for the "Latest Launches" horizontal slider.
///
/// Matches the official reference design:
/// - Compact square tile (~88×88px)
/// - Clean 13px rounded corners with subtle shadow (no artificial glow)
/// - Image rendered with BoxFit.cover
/// - Smooth micro-scale tap interaction
class LatestLaunchCard extends StatefulWidget {
  const LatestLaunchCard({
    super.key,
    required this.launch,
    this.size = 88.0,
    this.onTap,
  });

  final LatestLaunchModel launch;
  final double size;
  final VoidCallback? onTap;

  @override
  State<LatestLaunchCard> createState() => _LatestLaunchCardState();
}

class _LatestLaunchCardState extends State<LatestLaunchCard> {
  bool _pressed = false;

  void _onTapDown(TapDownDetails _) {
    HapticFeedback.lightImpact();
    setState(() => _pressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _pressed = false);
    widget.onTap?.call();
    // TODO: Route to content details for id: ${widget.launch.id}
  }

  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open ${widget.launch.title}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: _pressed ? 0.85 : 1.0,
            duration: const Duration(milliseconds: 110),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: const Color(0xFF081D3A),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(16),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: widget.launch.imagePath != null
                    ? Image.asset(
                        widget.launch.imagePath!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (context, error, _) => _PlaceholderArt(
                          type: widget.launch.contentType,
                        ),
                      )
                    : _PlaceholderArt(type: widget.launch.contentType),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Minimal fallback if image asset is not found.
class _PlaceholderArt extends StatelessWidget {
  const _PlaceholderArt({required this.type});
  final LaunchContentType type;

  IconData get _icon => switch (type) {
        LaunchContentType.course    => Icons.school_outlined,
        LaunchContentType.nasheed   => Icons.headphones_outlined,
        LaunchContentType.qirat     => Icons.menu_book_outlined,
        LaunchContentType.audio     => Icons.graphic_eq_rounded,
        LaunchContentType.audiobook => Icons.auto_stories_outlined,
        LaunchContentType.event     => Icons.event_outlined,
        LaunchContentType.media     => Icons.play_circle_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF081D3A),
      child: Center(
        child: Icon(
          _icon,
          color: AppColors.gold.withAlpha(200),
          size: 28,
        ),
      ),
    );
  }
}
