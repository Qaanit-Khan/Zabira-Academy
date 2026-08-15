import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/zabira_network_image.dart';
import '../../data/models/nasheed_item_model.dart';
import '../controllers/nasheed_audio_player_controller.dart';

class NasheedTrackTile extends StatelessWidget {
  const NasheedTrackTile({
    super.key,
    required this.track,
    required this.playerController,
    this.onTap,
  });

  final NasheedItemModel track;
  final NasheedAudioPlayerController playerController;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isCurrent = playerController.currentTrack?.id == track.id;
    final isPlaying = isCurrent && playerController.isPlaying;
    final isFav = playerController.isFavorite(track.id);

    final posStr = isCurrent ? playerController.formatDuration(playerController.position) : '00:00';
    final durStr = isCurrent && playerController.duration > Duration.zero
        ? playerController.formatDuration(playerController.duration)
        : track.formattedDuration;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent ? AppColors.gold.withAlpha(120) : const Color(0xFFF1F5F9),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Thumbnail with Play / Pause Icon overlay ─────────────────────
          GestureDetector(
            onTap: () {
              playerController.playTrack(track);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 50,
                height: 50,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ZabiraNetworkImage(
                      imageUrl: track.resolvedThumbnail,
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.music_note_rounded,
                    ),
                    Container(color: Colors.black.withAlpha(70)),
                    Center(
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isPlaying ? AppColors.gold : Colors.black.withAlpha(120),
                        ),
                        child: Center(
                          child: Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: isPlaying ? const Color(0xFF081D3A) : Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ── Info (Title, Artist, Duration / Progress) ────────────────────
          Expanded(
            child: GestureDetector(
              onTap: () {
                playerController.playTrack(track);
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isCurrent ? AppColors.navyDark : const Color(0xFF1E293B),
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
                  const SizedBox(height: 4),
                  // Progress line & Duration
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 3,
                        decoration: BoxDecoration(
                          color: isCurrent ? AppColors.gold : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$posStr  $durStr',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Right Side: Heart & 3 dots ───────────────────────────────────
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFav ? AppColors.gold : const Color(0xFF94A3B8),
              size: 20,
            ),
            onPressed: () => playerController.toggleFavorite(track.id),
          ),
          const Icon(Icons.more_vert, size: 18, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }
}
