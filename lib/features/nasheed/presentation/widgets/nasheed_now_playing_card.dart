import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/zabira_network_image.dart';
import '../controllers/nasheed_audio_player_controller.dart';

class NasheedNowPlayingCard extends StatelessWidget {
  const NasheedNowPlayingCard({
    super.key,
    required this.playerController,
  });

  final NasheedAudioPlayerController playerController;

  @override
  Widget build(BuildContext context) {
    final track = playerController.currentTrack;
    if (track == null) return const SizedBox.shrink();

    final isPlaying = playerController.isPlaying;
    final pos = playerController.position;
    final dur = playerController.duration;
    final isFav = playerController.isFavorite(track.id);

    final posStr = playerController.formatDuration(pos);
    final durStr = playerController.formatDuration(dur);
    final double maxSec = dur.inSeconds > 0 ? dur.inSeconds.toDouble() : 1.0;
    final double curSec = pos.inSeconds.toDouble().clamp(0.0, maxSec);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Artwork
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: ZabiraNetworkImage(
                    imageUrl: track.resolvedThumbnail,
                    fit: BoxFit.cover,
                    fallbackIcon: Icons.music_note_rounded,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Title & Artist
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      track.artist,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Favorite Heart
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFav ? AppColors.gold : const Color(0xFF94A3B8),
                  size: 20,
                ),
                onPressed: () => playerController.toggleFavorite(track.id),
              ),

              // Play / Pause Button
              GestureDetector(
                onTap: playerController.togglePlayPause,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold,
                  ),
                  child: Center(
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: const Color(0xFF081D3A),
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Scrubber slider & timestamps
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              activeTrackColor: AppColors.gold,
              inactiveTrackColor: const Color(0xFFE2E8F0),
              thumbColor: AppColors.gold,
            ),
            child: Slider(
              value: curSec,
              min: 0.0,
              max: maxSec,
              onChanged: (val) {
                playerController.seek(Duration(seconds: val.toInt()));
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  posStr,
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
                ),
                Text(
                  durStr,
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
