import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/kids_models.dart';
import '../../data/services/kids_api_service.dart';

/// Zabira Academy — Mobile Native Kids Story Reading Screen
class KidsStoryDetailPage extends StatefulWidget {
  const KidsStoryDetailPage({
    super.key,
    required this.storyId,
    this.slug,
    this.initialStory,
  });

  final int storyId;
  final String? slug;
  final KidsStoryItem? initialStory;

  @override
  State<KidsStoryDetailPage> createState() => _KidsStoryDetailPageState();
}

class _KidsStoryDetailPageState extends State<KidsStoryDetailPage> {
  final KidsApiService _api = KidsApiService();
  KidsStoryItem? _story;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _story = widget.initialStory;
    if (_story == null || _story!.content == null || _story!.content!.isEmpty) {
      _loadStoryDetails();
    }
  }

  Future<void> _loadStoryDetails() async {
    setState(() {
      _isLoading = _story == null;
      _errorMessage = null;
    });

    try {
      final fetched = await _api.getStoryDetails(id: widget.storyId, slug: widget.slug);
      if (mounted) {
        setState(() {
          if (fetched != null) {
            _story = fetched;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to load story details.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = _story;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navyDark, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/kids');
            }
          },
        ),
        title: Text(
          story?.title ?? 'Kids Story',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.navyDark,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.navyDark, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing coming soon!'), duration: Duration(seconds: 1)),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : (story == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_stories_outlined, size: 48, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage ?? 'Story not found.',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navyDark),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => context.pop(),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.navyDark),
                          child: const Text('Back to Kids Portal'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildStoryContent(story)),
    );
  }

  Widget _buildStoryContent(KidsStoryItem story) {
    final coverUrl = story.resolvedCoverImage ?? story.resolvedThumbnail;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cover Banner ──────────────────────────────────────────────────
          if (coverUrl != null && coverUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                coverUrl,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildFallbackHeader(story),
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            _buildFallbackHeader(story),
            const SizedBox(height: 16),
          ],

          // ── Badges Row ────────────────────────────────────────────────────
          Row(
            children: [
              if (story.prophetName != null && story.prophetName!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    story.prophetName!,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1D4ED8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFFB45309)),
                    const SizedBox(width: 4),
                    Text(
                      story.readTimeLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Ages ${story.ageLabel}',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Story Title ───────────────────────────────────────────────────
          Text(
            story.title,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.navyDark,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),

          // ── Short Description / Summary Callout ───────────────────────────
          if (story.shortDescription != null && story.shortDescription!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF16A34A), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      story.shortDescription!,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF166534),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 18),

          // ── Story Body / Text ─────────────────────────────────────────────
          Text(
            story.content ?? story.description ?? 'Story content will be available shortly.',
            style: GoogleFonts.outfit(
              fontSize: 15.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF1E293B),
              height: 1.7,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 32),

          // ── Bottom Action ─────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Great job completing this story! ⭐ +20 XP'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
                context.pop();
              },
              icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
              label: Text(
                'Finished Reading',
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFallbackHeader(KidsStoryItem story) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_stories_rounded, color: AppColors.gold, size: 48),
            const SizedBox(height: 8),
            Text(
              story.title,
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
