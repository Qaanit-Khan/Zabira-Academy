import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/auth_controller.dart';
import '../controllers/kids_controller.dart';
import '../../data/models/kids_models.dart';
import '../../data/services/kids_api_service.dart';

/// Zabira Academy — Interactive Kids Quiz Runner
///
/// Full flow: Load questions from API → Answer one at a time → Submit → Results
class KidsQuizPage extends StatefulWidget {
  const KidsQuizPage({
    super.key,
    required this.quizId,
    this.quiz,
  });

  final int quizId;
  final KidsQuizItem? quiz;

  @override
  State<KidsQuizPage> createState() => _KidsQuizPageState();
}

enum _QuizState { loading, questions, submitting, results, error }

class _KidsQuizPageState extends State<KidsQuizPage> {
  final KidsApiService _api = KidsApiService();
  _QuizState _state = _QuizState.loading;
  List<KidsQuestionItem> _questions = [];
  int _currentIndex = 0;
  final Map<int, int> _selectedAnswers = {}; // question.id → selected option index
  String? _errorMessage;

  // Results
  int _scorePercent = 0;
  int _pointsEarned = 0;
  bool _passed = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _state = _QuizState.loading);

    try {
      final token = context.read<AuthController>().currentToken;
      final kidsCtrl = context.read<KidsController>();

      // 1. Start quiz — get attempt_token in controller
      await kidsCtrl.startQuiz(widget.quizId, token: token);

      // 2. Load questions
      _questions = await _api.getQuizQuestions(
        quizId: widget.quizId,
        slug: widget.quiz?.slug,
      );
      if (_questions.isEmpty) {
        throw Exception('Quiz questions are not available for this quiz.');
      }

      if (mounted) {
        setState(() => _state = _QuizState.questions);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
          _state = _QuizState.error;
        });
      }
    }
  }

  Future<void> _submitQuiz() async {
    setState(() => _state = _QuizState.submitting);
    HapticFeedback.lightImpact();

    try {
      final token = context.read<AuthController>().currentToken;
      final kidsCtrl = context.read<KidsController>();

      // Build answers map: question_id → selected_option_index (as string)
      final answers = _selectedAnswers.map(
        (qId, optIdx) => MapEntry(qId.toString(), optIdx),
      );

      final result = await kidsCtrl.submitQuiz(answers: answers, token: token);

      // Calculate local score as a fallback
      int correct = 0;
      for (int i = 0; i < _questions.length; i++) {
        final q = _questions[i];
        if (_selectedAnswers[q.id] == q.correctAnswerIndex) correct++;
      }
      final localPercent = _questions.isNotEmpty
          ? (correct / _questions.length * 100).toInt()
          : 0;

      if (mounted) {
        setState(() {
          _scorePercent = result != null
              ? (int.tryParse(result['score']?.toString() ?? '') ?? localPercent)
              : localPercent;
          _pointsEarned = result != null
              ? (int.tryParse(result['points_earned']?.toString() ?? '') ?? widget.quiz?.pointsReward ?? 100)
              : (widget.quiz?.pointsReward ?? 100);
          _passed = result != null
              ? (result['passed'] == true || result['passed']?.toString() == '1')
              : _scorePercent >= 60;
          _state = _QuizState.results;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Submission failed. Please try again.';
          _state = _QuizState.error;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _QuizState.loading => _buildLoading(),
      _QuizState.questions => _buildQuestion(),
      _QuizState.submitting => _buildSubmitting(),
      _QuizState.results => _buildResults(),
      _QuizState.error => _buildError(),
    };
  }

  // ── Loading Screen ──────────────────────────────────────────────────────────
  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.gold),
            const SizedBox(height: 16),
            Text(
              'Preparing your quiz...',
              style: GoogleFonts.outfit(fontSize: 15, color: const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Submitting Screen ───────────────────────────────────────────────────────
  Widget _buildSubmitting() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.gold),
            const SizedBox(height: 16),
            Text(
              'Submitting your answers...',
              style: GoogleFonts.outfit(fontSize: 15, color: const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error Screen ────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.gold, size: 48),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'Something went wrong',
                style: GoogleFonts.outfit(fontSize: 15, color: const Color(0xFF334155)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _initialize,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navyDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Try Again', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Back', style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Results Screen ──────────────────────────────────────────────────────────
  Widget _buildResults() {
    final quizTitle = widget.quiz?.title ?? 'Quiz';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Trophy / fail icon
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: _passed
                      ? const Color(0xFF10B981).withAlpha(22)
                      : const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    _passed ? Icons.emoji_events_rounded : Icons.auto_awesome_rounded,
                    color: _passed ? const Color(0xFF10B981) : const Color(0xFFB45309),
                    size: 50,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Text(
                _passed ? "Masha'Allah! Well Done!" : 'Great Effort! Keep Learning!',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                quizTitle,
                style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Score card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    // Score percentage
                    Text(
                      '$_scorePercent%',
                      style: GoogleFonts.outfit(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: _passed ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Score',
                      style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)),
                    ),
                    const Divider(height: 24, color: Color(0xFFE2E8F0)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _resultStat(
                          label: 'XP Earned',
                          value: '+$_pointsEarned',
                          icon: Icons.star_rounded,
                          color: const Color(0xFFB45309),
                        ),
                        _resultStat(
                          label: 'Result',
                          value: _passed ? 'PASSED' : 'KEEP GOING',
                          icon: _passed ? Icons.check_circle_rounded : Icons.refresh_rounded,
                          color: _passed ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Review answers
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
                    Text(
                      'Answer Review',
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navyDark),
                    ),
                    const SizedBox(height: 10),
                    ..._questions.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final q = entry.value;
                      final selected = _selectedAnswers[q.id];
                      final isCorrect = selected == q.correctAnswerIndex;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Q${idx + 1}: ${q.question}',
                                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (q.explanation != null)
                                    Text(
                                      q.explanation!,
                                      style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B), height: 1.35),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Retry
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentIndex = 0;
                      _selectedAnswers.clear();
                    });
                    _initialize();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text('Try Again', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navyDark,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navyDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Back to Kids Portal', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Question Screen ─────────────────────────────────────────────────────────
  Widget _buildQuestion() {
    final quizTitle = widget.quiz?.title ?? 'Islamic Quiz';
    final q = _questions[_currentIndex];
    final hasSelected = _selectedAnswers.containsKey(q.id);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.navyDark),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text('Quit Quiz?', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
                content: Text('Your progress will be lost.', style: GoogleFonts.outfit()),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Stay')),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('Quit', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
        ),
        title: Text(
          quizTitle,
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navyDark),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_currentIndex + 1}/${_questions.length}',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions.length,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
            minHeight: 4,
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // Question card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Question ${_currentIndex + 1}',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.gold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          q.question,
                          style: GoogleFonts.outfit(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navyDark,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Options
                  ...q.options.asMap().entries.map((entry) {
                    final optIdx = entry.key;
                    final optText = entry.value;
                    final isSelected = _selectedAnswers[q.id] == optIdx;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedAnswers[q.id] = optIdx);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.navyDark : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppColors.navyDark : const Color(0xFFE2E8F0),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.navyDark.withAlpha(30),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.gold : const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + optIdx),
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected ? AppColors.navyDark : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                optText,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 20),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Navigation buttons
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              12,
              AppSpacing.screenHorizontal,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, -3)),
              ],
            ),
            child: Row(
              children: [
                if (_currentIndex > 0) ...[
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _currentIndex--),
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Prev'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navyDark,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: hasSelected
                        ? () {
                            if (_currentIndex < _questions.length - 1) {
                              setState(() => _currentIndex++);
                            } else {
                              _submitQuiz();
                            }
                          }
                        : null,
                    icon: Icon(
                      _currentIndex < _questions.length - 1 ? Icons.arrow_forward_rounded : Icons.check_rounded,
                      size: 18,
                    ),
                    label: Text(
                      _currentIndex < _questions.length - 1 ? 'Next' : 'Submit Quiz',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.navyDark,
                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B))),
      ],
    );
  }
}
