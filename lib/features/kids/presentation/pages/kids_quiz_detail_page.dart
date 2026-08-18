import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/kids_models.dart';
import '../../data/services/kids_api_service.dart';

/// Zabira Academy — Mobile-Native Kids Quiz Detail Screen
/// Inspired by the official Zabira Kids Web & Mobile design references.
class KidsQuizDetailPage extends StatefulWidget {
  const KidsQuizDetailPage({
    super.key,
    required this.quizId,
    this.slug,
    this.initialQuiz,
  });

  final int quizId;
  final String? slug;
  final KidsQuizItem? initialQuiz;

  @override
  State<KidsQuizDetailPage> createState() => _KidsQuizDetailPageState();
}

class _KidsQuizDetailPageState extends State<KidsQuizDetailPage> {
  final KidsApiService _api = KidsApiService();
  KidsQuizItem? _quiz;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _quiz = widget.initialQuiz;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = _quiz == null;
      _errorMessage = null;
    });

    try {
      final detail = await _api.getQuizDetails(
        quizId: widget.quizId > 0 ? widget.quizId : null,
        slug: widget.slug ?? widget.initialQuiz?.slug,
      );

      if (mounted) {
        if (detail == null) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Quiz not found. Please try another quiz.';
          });
        } else {
          setState(() {
            _quiz = detail;
            _isLoading = false;
            _errorMessage = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    }
  }

  void _startQuiz() {
    if (_quiz == null) return;
    HapticFeedback.mediumImpact();
    context.push('/kids/quiz/${_quiz!.id}', extra: _quiz);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const BackButton(color: AppColors.navyDark),
          title: Text('Quiz Details', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.navyDark)),
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.gold),
              SizedBox(height: 16),
              Text('Loading quiz information...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _quiz == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const BackButton(color: AppColors.navyDark),
          title: Text('Quiz Details', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.navyDark)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.quiz_outlined, size: 56, color: Color(0xFF94A3B8)),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Quiz not found',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navyDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loadDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navyDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Retry', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final quiz = _quiz!;
    final coverUrl = quiz.resolvedCoverImage ?? quiz.resolvedThumbnail;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: const BackButton(color: AppColors.navyDark),
        title: Text(
          quiz.title,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navyDark),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.navyDark),
            tooltip: 'Refresh Quiz',
            onPressed: _loadDetails,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Top Cover / Hero Card ─────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.navyDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (coverUrl != null && coverUrl.isNotEmpty)
                      Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildFallbackCover(quiz),
                      )
                    else
                      _buildFallbackCover(quiz),
                    // Gradient overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withAlpha(160),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Badges on image
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Row(
                        children: [
                          if (quiz.featured) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'FEATURED',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.navyDark,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(140),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.help_outline_rounded, color: AppColors.gold, size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  '${quiz.questionsCount} Questions',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ── 2. Pill Badges Row ───────────────────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (quiz.categoryName != null && quiz.categoryName!.isNotEmpty)
                  _badge(
                    label: quiz.categoryName!.toUpperCase(),
                    color: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFEF3C7),
                    icon: Icons.category_rounded,
                  ),
                _badge(
                  label: 'AGES ${quiz.ageLabel}',
                  color: const Color(0xFF0284C7),
                  bgColor: const Color(0xFFE0F2FE),
                  icon: Icons.face_rounded,
                ),
                _badge(
                  label: quiz.difficulty.toUpperCase(),
                  color: quiz.difficulty.toLowerCase() == 'easy'
                      ? const Color(0xFF10B981)
                      : (quiz.difficulty.toLowerCase() == 'medium' ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                  bgColor: quiz.difficulty.toLowerCase() == 'easy'
                      ? const Color(0xFFECFDF5)
                      : (quiz.difficulty.toLowerCase() == 'medium' ? const Color(0xFFFFFBEB) : const Color(0xFFFEF2F2)),
                  icon: Icons.speed_rounded,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── 3. Quiz Title ────────────────────────────────────────────────
            Text(
              quiz.title,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.navyDark,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),

            // ── 4. Description ───────────────────────────────────────────────
            if (quiz.description != null && quiz.description!.isNotEmpty)
              Text(
                quiz.description!,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: const Color(0xFF475569),
                  height: 1.45,
                ),
              ),
            const SizedBox(height: 20),

            // ── 5. At a Glance Overview Grid ─────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(4),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AT A GLANCE',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gold,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Overview',
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = (constraints.maxWidth - 12) / 2;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _overviewCard(
                            width: itemWidth,
                            label: 'QUESTIONS',
                            value: '${quiz.questionsCount}',
                            icon: Icons.help_outline_rounded,
                            iconColor: const Color(0xFFD97706),
                          ),
                          _overviewCard(
                            width: itemWidth,
                            label: 'DIFFICULTY',
                            value: quiz.difficulty,
                            icon: Icons.speed_rounded,
                            iconColor: const Color(0xFF0284C7),
                          ),
                          _overviewCard(
                            width: itemWidth,
                            label: 'AGE GROUP',
                            value: quiz.ageLabel,
                            icon: Icons.people_outline_rounded,
                            iconColor: const Color(0xFF10B981),
                          ),
                          _overviewCard(
                            width: itemWidth,
                            label: 'DURATION',
                            value: quiz.durationLabel,
                            icon: Icons.timer_outlined,
                            iconColor: const Color(0xFF8B5CF6),
                          ),
                          _overviewCard(
                            width: itemWidth,
                            label: 'PASSING SCORE',
                            value: '${quiz.passingScore}%',
                            icon: Icons.emoji_events_outlined,
                            iconColor: const Color(0xFFF59E0B),
                          ),
                          _overviewCard(
                            width: itemWidth,
                            label: 'ATTEMPTS',
                            value: quiz.allowRetakes ? 'Unlimited' : '1',
                            icon: Icons.check_circle_outline_rounded,
                            iconColor: const Color(0xFF64748B),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── 6. Instructions Card ─────────────────────────────────────────
            if (quiz.instructions != null && quiz.instructions!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7).withAlpha(140),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFB45309), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How It Works',
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            quiz.instructions!,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              color: const Color(0xFF78350F),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── 7. Start Quiz Action Button ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _startQuiz,
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                label: Text(
                  'START QUIZ',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navyDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                  shadowColor: AppColors.gold.withAlpha(80),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackCover(KidsQuizItem quiz) {
    return Container(
      color: AppColors.navyDark,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_rounded, color: AppColors.gold, size: 48),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                quiz.title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge({
    required String label,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewCard({
    required double width,
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
