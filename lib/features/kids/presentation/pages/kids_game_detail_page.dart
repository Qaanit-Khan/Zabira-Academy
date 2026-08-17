import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/kids_models.dart';
import '../../data/services/kids_api_service.dart';

/// Zabira Academy — Kids Game Detail Page
///
/// Shows game metadata, instructions, age/difficulty, XP reward, and
/// a "Play Now" CTA before launching the actual gameplay.
class KidsGameDetailPage extends StatefulWidget {
  const KidsGameDetailPage({
    super.key,
    required this.gameId,
    this.game,
  });

  final int gameId;
  final KidsGameItem? game;

  @override
  State<KidsGameDetailPage> createState() => _KidsGameDetailPageState();
}

class _KidsGameDetailPageState extends State<KidsGameDetailPage> {
  KidsGameItem? _gameDetail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  Future<void> _loadGame() async {
    // Use passed game first as instant data
    if (widget.game != null) {
      setState(() {
        _gameDetail = widget.game;
        _isLoading = false;
      });
      return;
    }

    try {
      final svc = KidsApiService();
      final detail = await svc.getGameDetails(gameId: widget.gameId);
      if (mounted) {
        setState(() {
          _gameDetail = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Unable to load game details.';
        });
      }
    }
  }

  IconData _gameTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'memory_match': return Icons.dashboard_rounded;
      case 'dua_match': return Icons.pan_tool_rounded;
      case 'trivia':
      case 'prophets_quiz': return Icons.help_outline_rounded;
      case 'word_puzzle': return Icons.text_fields_rounded;
      case 'sort_it_right': return Icons.sort_rounded;
      case 'prophet_timeline': return Icons.timeline_rounded;
      default: return Icons.sports_esports_rounded;
    }
  }

  Color _difficultyColor(String? d) {
    switch (d?.toLowerCase()) {
      case 'easy': return const Color(0xFF10B981);
      case 'medium': return const Color(0xFFF59E0B);
      case 'hard': return const Color(0xFFEF4444);
      default: return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _error != null && _gameDetail == null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.gold, size: 48),
          const SizedBox(height: 12),
          Text(_error ?? 'Something went wrong', style: GoogleFonts.outfit(fontSize: 15, color: const Color(0xFF334155))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadGame,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.navyDark),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final game = _gameDetail!;
    final icon = _gameTypeIcon(game.gameType);
    final diffColor = _difficultyColor(game.difficulty);

    return CustomScrollView(
      slivers: [
        // ── Hero App Bar ──────────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: AppColors.navyDark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: game.resolvedThumbnail != null && game.resolvedThumbnail!.isNotEmpty
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        game.resolvedThumbnail!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildGameBanner(game, icon),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, AppColors.navyDark.withAlpha(200)],
                          ),
                        ),
                      ),
                    ],
                  )
                : _buildGameBanner(game, icon),
          ),
        ),

        // ── Content ───────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + Category
                Text(
                  game.title,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyDark,
                    height: 1.2,
                  ),
                ),
                if (game.category != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    game.category!,
                    style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)),
                  ),
                ],
                const SizedBox(height: 14),

                // Badges row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _badge(Icons.child_care_rounded, game.ageGroup, const Color(0xFF3B82F6), const Color(0xFFEFF6FF)),
                    _badge(Icons.bar_chart_rounded, game.difficulty, diffColor, diffColor.withAlpha(25)),
                    _badge(Icons.star_rounded, '${game.pointsReward} XP', const Color(0xFFB45309), const Color(0xFFFEF3C7)),
                    _badge(icon, game.gameType.replaceAll('_', ' ').toUpperCase(), const Color(0xFF6D28D9), const Color(0xFFF5F3FF)),
                  ],
                ),

                const SizedBox(height: 20),

                // Description
                if (game.description != null && game.description!.isNotEmpty) ...[
                  Text(
                    'About This Game',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navyDark),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    game.description!,
                    style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF475569), height: 1.55),
                  ),
                  const SizedBox(height: 20),
                ] else if (game.shortDescription != null && game.shortDescription!.isNotEmpty) ...[
                  Text(
                    game.shortDescription!,
                    style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF475569), height: 1.55),
                  ),
                  const SizedBox(height: 20),
                ],

                // Instructions
                if (game.instructions != null && game.instructions!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppColors.gold, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'How to Play',
                              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navyDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          game.instructions!,
                          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF475569), height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // XP Reward Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded, color: Color(0xFFB45309), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Complete to Earn ${game.pointsReward} XP!',
                              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF92400E)),
                            ),
                            Text(
                              'XP is added to your profile after submission.',
                              style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFFB45309)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Play Now CTA
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/kids/game/${game.id}', extra: game);
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    label: Text(
                      'PLAY NOW',
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: Text(
                      'Back to Games',
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navyDark,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameBanner(KidsGameItem game, IconData icon) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F2D52), Color(0xFF10B981)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: game.icon != null && game.icon!.isNotEmpty
                    ? Text(game.icon!, style: const TextStyle(fontSize: 38))
                    : Icon(icon, color: Colors.white, size: 38),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              game.title,
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 13),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }
}
