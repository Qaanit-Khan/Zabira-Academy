import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/daily_supplement_model.dart';

/// Slim and compact Daily Nasheed / Daily Audio Player Card.
///
/// Matches the slim horizontal audio bar in the reference:
/// - Sleek card height with minimal vertical padding
/// - Compact 42×42px cover thumbnail
/// - Compact typography (DAILY NASHEED • Allah Knows • 03:42)
/// - Thin, responsive gold audio waveform
/// - Compact 36×36px dark navy play button with gold border
class DailySupplementCard extends StatefulWidget {
  const DailySupplementCard({super.key, required this.supplement});

  final DailySupplementModel supplement;

  @override
  State<DailySupplementCard> createState() => _DailySupplementCardState();
}

class _DailySupplementCardState extends State<DailySupplementCard>
    with SingleTickerProviderStateMixin {
  bool _playing = false;
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    HapticFeedback.lightImpact();
    setState(() {
      _playing = !_playing;
      if (_playing) {
        _waveController.repeat(reverse: true);
      } else {
        _waveController.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderLight.withAlpha(200),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDark.withAlpha(7),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── 1. Compact Cover Image ─────────────────────────────────────
            _CoverThumbnail(
              imageUrl: widget.supplement.imageUrl,
              imagePath: 'assets/images/home/daily_supplement/daily_supplement_cover.png',
            ),

            const SizedBox(width: 10),

            // ── 2. Text Column ─────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // "DAILY NASHEED"
                  Text(
                    widget.supplement.sectionLabel.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),

                  // "Allah Knows"
                  Text(
                    widget.supplement.contentTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark,
                      height: 1.15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),

                  // "03:42"
                  Text(
                    widget.supplement.duration,
                    style: GoogleFonts.outfit(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF8FA0BB),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),

            // ── 3. Gold Audio Waveform ─────────────────────────────────────
            AnimatedBuilder(
              animation: _waveController,
              builder: (context, _) {
                return _WaveformWidget(
                  playing: _playing,
                  animationValue: _waveController.value,
                );
              },
            ),

            const SizedBox(width: 10),

            // ── 4. Compact Play / Pause Button ─────────────────────────────
            _PlayButton(
              playing: _playing,
              onTap: _togglePlay,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Square rounded cover thumbnail image (compact 42×42px).
class _CoverThumbnail extends StatelessWidget {
  const _CoverThumbnail({this.imageUrl, required this.imagePath});
  final String? imageUrl;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(16),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.navyDark,
                    child: const Center(
                      child: Icon(Icons.music_note_rounded, color: AppColors.gold, size: 20),
                    ),
                  ),
                ),
              )
            : Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, _) {
                  return Container(
                    color: AppColors.navyDark,
                    child: const Center(
                      child: Icon(
                        Icons.music_note_rounded,
                        color: AppColors.gold,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Slim gold audio waveform visualization.
class _WaveformWidget extends StatelessWidget {
  const _WaveformWidget({
    required this.playing,
    required this.animationValue,
  });

  final bool playing;
  final double animationValue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 22,
      child: CustomPaint(
        painter: _WaveformPainter(
          playing: playing,
          anim: animationValue,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.playing,
    required this.anim,
  });

  final bool playing;
  final double anim;

  static const List<double> _baseHeights = [
    0.15, 0.25, 0.20, 0.40, 0.30, 0.65, 0.50, 0.90,
    0.70, 1.00, 0.80, 0.95, 0.60, 0.85, 0.45, 0.70,
    0.35, 0.50, 0.25, 0.35, 0.15,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4;

    final barCount = _baseHeights.length;
    final spacing = size.width / (barCount - 1);
    final centerY = size.height / 2;
    final maxHalfHeight = size.height * 0.46;

    for (int i = 0; i < barCount; i++) {
      final x = i * spacing;
      double hFactor = _baseHeights[i];

      if (playing) {
        final phase = (i * 0.4) + (anim * 2 * math.pi);
        final osc = 0.25 * math.sin(phase);
        hFactor = (hFactor + osc).clamp(0.15, 1.0);
      }

      final halfH = maxHalfHeight * hFactor;
      canvas.drawLine(
        Offset(x, centerY - halfH),
        Offset(x, centerY + halfH),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.playing != playing || oldDelegate.anim != anim;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Circular dark navy play/pause button (compact 36×36px) with gold border.
class _PlayButton extends StatefulWidget {
  const _PlayButton({
    required this.playing,
    required this.onTap,
  });

  final bool playing;
  final VoidCallback onTap;

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.playing ? 'Pause Nasheed' : 'Play Nasheed',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.90 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF081D3A),
              border: Border.all(
                color: AppColors.gold,
                width: 1.3,
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 140),
                child: Icon(
                  widget.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey(widget.playing),
                  color: AppColors.gold,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
