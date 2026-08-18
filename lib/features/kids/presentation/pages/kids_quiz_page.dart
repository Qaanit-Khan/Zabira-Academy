import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/auth_controller.dart';
import '../controllers/kids_controller.dart';
import '../../data/models/kids_models.dart';
import '../../data/services/kids_api_service.dart';

/// Zabira Academy — Complete Interactive Kids Quiz Runner & Results Screen
///
/// Features:
/// - Real API Quiz Details, Start (`attempt_token`), and Submit (`quiz_submit.php`)
/// - Dynamic countdown timer with auto-submit
/// - Modular question renderers (MCQ, True/False, Multi-select, Matching, Ordering, Image)
/// - Confirmation modal before final submission
/// - Server-calculated results & question-by-question review with explanations
/// - Try Again (fresh attempt) & Back to Quizzes
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
  KidsQuizItem? _quiz;
  List<KidsQuestionItem> _questions = const [];
  int _currentIndex = 0;

  // Answers map: question.id -> List of selected option IDs (e.g. 30 -> ["b"], 35 -> ["a", "b"])
  final Map<int, List<String>> _answers = {};

  // Attempt session
  String? _attemptToken;
  String? _errorMessage;

  // Countdown timer
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  int _totalDurationSeconds = 0;

  // Final submission result from server
  QuizSubmitResult? _result;

  @override
  void initState() {
    super.initState();
    _quiz = widget.quiz;
    _initialize();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    _countdownTimer?.cancel();
    setState(() {
      _state = _QuizState.loading;
      _currentIndex = 0;
      _answers.clear();
      _errorMessage = null;
      _result = null;
    });

    try {
      final token = context.read<AuthController>().currentToken;

      // 1. Fetch full quiz details (if questions not loaded)
      KidsQuizItem? detailedQuiz = _quiz;
      if (detailedQuiz == null || detailedQuiz.questions.isEmpty) {
        detailedQuiz = await _api.getQuizDetails(
          quizId: widget.quizId > 0 ? widget.quizId : null,
          slug: widget.quiz?.slug,
        );
      }

      if (detailedQuiz == null) {
        throw Exception('Quiz not found. Please try another quiz.');
      }

      _quiz = detailedQuiz;
      _questions = detailedQuiz.questions;

      if (_questions.isEmpty) {
        throw Exception('No questions found for this quiz.');
      }

      // 2. Start quiz on backend to get real attempt_token
      final startData = await _api.startQuiz(quizId: detailedQuiz.id, token: token);
      final rawToken = startData['attempt_token']?.toString();

      if (rawToken == null || rawToken.isEmpty) {
        throw Exception('Unable to start quiz session. Missing attempt token.');
      }

      _attemptToken = rawToken;

      // 3. Initialize timer if quiz has time limit
      _totalDurationSeconds = detailedQuiz.timeLimitSeconds;
      _remainingSeconds = _totalDurationSeconds;
      if (_totalDurationSeconds > 0) {
        _startTimer();
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

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        _handleTimeExpired();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _handleTimeExpired() {
    if (_state != _QuizState.questions) return;
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.timer_off_rounded, color: Color(0xFFEF4444)),
            const SizedBox(width: 10),
            Text('Time is Up!', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'Your quiz time has expired. Submitting your answers now.',
          style: GoogleFonts.outfit(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performSubmit();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.navyDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('View Results'),
          ),
        ],
      ),
    ).then((_) => _performSubmit());
  }

  void _showSubmitConfirmationSheet() {
    HapticFeedback.mediumImpact();
    final answeredCount = _answers.values.where((v) => v.isNotEmpty).length;
    final totalCount = _questions.length;
    final unansweredCount = totalCount - answeredCount;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Submit Quiz?',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  unansweredCount > 0
                      ? 'You have $unansweredCount unanswered question${unansweredCount > 1 ? 's' : ''}. Are you sure you want to finish?'
                      : 'You have answered all $totalCount questions. Ready to see your score?',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$answeredCount',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF059669),
                              ),
                            ),
                            Text(
                              'Answered',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                        decoration: BoxDecoration(
                          color: unansweredCount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: unansweredCount > 0 ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$unansweredCount',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: unansweredCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              'Unanswered',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: unansweredCount > 0 ? const Color(0xFFB91C1C) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.navyDark,
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Continue Quiz',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _performSubmit();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.navyDark,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(
                          'Submit Quiz',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _performSubmit() async {
    if (_attemptToken == null) return;

    _countdownTimer?.cancel();
    setState(() => _state = _QuizState.submitting);
    HapticFeedback.lightImpact();

    try {
      final token = context.read<AuthController>().currentToken;

      // Build answers list
      final answerPayload = <QuizSubmitAnswer>[];
      for (final q in _questions) {
        final selectedOptions = _answers[q.id] ?? const [];
        if (selectedOptions.isNotEmpty) {
          answerPayload.add(QuizSubmitAnswer(questionId: q.id, selected: selectedOptions));
        }
      }

      final serverResult = await _api.submitQuiz(
        attemptToken: _attemptToken!,
        answers: answerPayload,
        token: token,
      );

      if (mounted) {
        setState(() {
          _result = serverResult;
          _state = _QuizState.results;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Quiz submission failed. Please try submitting again.';
          _state = _QuizState.error;
        });
      }
    }
  }

  String _formatTimerString(int totalSec) {
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _QuizState.loading => _buildLoading(),
      _QuizState.questions => _buildQuestionScreen(),
      _QuizState.submitting => _buildSubmitting(),
      _QuizState.results => _buildResultsScreen(),
      _QuizState.error => _buildErrorScreen(),
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
            const SizedBox(height: 18),
            Text(
              'Preparing your quiz...',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
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
            const SizedBox(height: 18),
            Text(
              'Submitting your answers...',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error Screen ────────────────────────────────────────────────────────────
  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.navyDark),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.gold, size: 52),
              const SizedBox(height: 14),
              Text(
                _errorMessage ?? 'Something went wrong',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navyDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: _initialize,
                icon: const Icon(Icons.refresh_rounded),
                label: Text('Try Again', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navyDark,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Main Question Screen ───────────────────────────────────────────────────
  Widget _buildQuestionScreen() {
    final quizTitle = _quiz?.title ?? 'Islamic Quiz';
    final q = _questions[_currentIndex];
    final selectedList = _answers[q.id] ?? const [];
    final isLastQuestion = _currentIndex == _questions.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navyDark),
          tooltip: 'Back to Overview',
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                title: Text('Quit Quiz?', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: AppColors.navyDark)),
                content: Text('Your progress in this quiz session will be lost.', style: GoogleFonts.outfit()),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Stay', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
                  ),
                  TextButton(
                    onPressed: () {
                      _countdownTimer?.cancel();
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    child: Text('Quit', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: Colors.red)),
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
          // Timer badge
          if (_totalDurationSeconds > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _remainingSeconds <= 30 ? const Color(0xFFFEF2F2) : AppColors.navyDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _remainingSeconds <= 30 ? const Color(0xFFEF4444) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: _remainingSeconds <= 30 ? const Color(0xFFEF4444) : AppColors.gold,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _formatTimerString(_remainingSeconds),
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _remainingSeconds <= 30 ? const Color(0xFFEF4444) : Colors.white,
                        ),
                      ),
                    ],
                  ),
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

                  // Header: Quiz category, Question X of Y, Points
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${_currentIndex + 1} of ${_questions.length}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${q.points} pt${q.points > 1 ? 's' : ''}',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Question Card
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
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image banner if question is image-based
                        if (q.isImageQuestion && q.resolvedMediaUrl != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              q.resolvedMediaUrl!,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        Text(
                          q.question,
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navyDark,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Render options based on question type
                  _buildQuestionContent(q, selectedList),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom navigation bar
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
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentIndex > 0) ...[
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() => _currentIndex--);
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Previous'),
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
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      if (!isLastQuestion) {
                        setState(() => _currentIndex++);
                      } else {
                        _showSubmitConfirmationSheet();
                      }
                    },
                    icon: Icon(
                      isLastQuestion ? Icons.check_rounded : Icons.arrow_forward_rounded,
                      size: 18,
                    ),
                    label: Text(
                      isLastQuestion ? 'Submit Quiz' : 'Next',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLastQuestion ? AppColors.gold : AppColors.navyDark,
                      foregroundColor: isLastQuestion ? AppColors.navyDark : Colors.white,
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

  Widget _buildQuestionContent(KidsQuestionItem q, List<String> selectedList) {
    switch (q.questionType) {
      case 'mcq':
        return _buildMCQRenderer(q, selectedList);
      case 'true_false':
        return _buildTrueFalseRenderer(q, selectedList);
      case 'multi':
        return _buildMultiSelectRenderer(q, selectedList);
      case 'matching':
        return _buildMatchingRenderer(q, selectedList);
      case 'ordering':
      case 'sort':
        return _buildOrderingRenderer(q, selectedList);
      default:
        // Graceful fallback for any unsupported question types
        if (q.options.isNotEmpty) {
          return _buildMCQRenderer(q, selectedList);
        }
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'This question type is not supported yet.',
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF92400E)),
          ),
        );
    }
  }

  // ── MCQ Renderer ────────────────────────────────────────────────────────────
  Widget _buildMCQRenderer(KidsQuestionItem q, List<String> selectedList) {
    final currentSelectedId = selectedList.isNotEmpty ? selectedList.first : null;

    return Column(
      children: q.options.asMap().entries.map((entry) {
        final optIdx = entry.key;
        final opt = entry.value;
        final isSelected = currentSelectedId == opt.id;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _answers[q.id] = [opt.id];
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFEF9C3) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.gold : const Color(0xFFE2E8F0),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.gold.withAlpha(40),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
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
                    opt.text,
                    style: GoogleFonts.outfit(
                      fontSize: 14.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? AppColors.navyDark : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── True/False Renderer ────────────────────────────────────────────────────
  Widget _buildTrueFalseRenderer(KidsQuestionItem q, List<String> selectedList) {
    final currentSelectedId = selectedList.isNotEmpty ? selectedList.first : null;

    return Column(
      children: q.options.map((opt) {
        final isSelected = currentSelectedId == opt.id;
        final isTrue = opt.text.toLowerCase().contains('true') || opt.id.toLowerCase() == 'a';

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _answers[q.id] = [opt.id];
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? (isTrue ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2)) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? (isTrue ? const Color(0xFF10B981) : const Color(0xFFEF4444)) : const Color(0xFFE2E8F0),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isTrue ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                  color: isTrue ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    opt.text,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: isTrue ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Multi-Select Renderer ──────────────────────────────────────────────────
  Widget _buildMultiSelectRenderer(KidsQuestionItem q, List<String> selectedList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Icon(Icons.checklist_rounded, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                'Select all that apply',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        ...q.options.asMap().entries.map((entry) {
          final opt = entry.value;
          final isSelected = selectedList.contains(opt.id);

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                final current = List<String>.from(_answers[q.id] ?? []);
                if (current.contains(opt.id)) {
                  current.remove(opt.id);
                } else {
                  current.add(opt.id);
                }
                _answers[q.id] = current;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFEF9C3) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.gold : const Color(0xFFE2E8F0),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.gold : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? AppColors.gold : const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded, color: AppColors.navyDark, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      opt.text,
                      style: GoogleFonts.outfit(
                        fontSize: 14.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? AppColors.navyDark : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Matching Renderer ──────────────────────────────────────────────────────
  Widget _buildMatchingRenderer(KidsQuestionItem q, List<String> selectedList) {
    return _buildMCQRenderer(q, selectedList);
  }

  // ── Ordering Renderer ──────────────────────────────────────────────────────
  Widget _buildOrderingRenderer(KidsQuestionItem q, List<String> selectedList) {
    return _buildMCQRenderer(q, selectedList);
  }

  // ── Results Screen ──────────────────────────────────────────────────────────
  Widget _buildResultsScreen() {
    final quizTitle = _quiz?.title ?? 'Islamic Quiz';
    final result = _result ??
        const QuizSubmitResult(
          score: 0,
          maxScore: 10,
          percentage: 0,
          correctCount: 0,
          incorrectCount: 0,
          passed: false,
          timeTakenSeconds: 0,
        );

    final passed = result.passed || result.percentage >= (_quiz?.passingScore ?? 60);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Trophy / Celebration Icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: passed ? const Color(0xFF10B981).withAlpha(25) : const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    passed ? Icons.emoji_events_rounded : Icons.auto_awesome_rounded,
                    color: passed ? const Color(0xFF10B981) : const Color(0xFFB45309),
                    size: 52,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Feedback headline
              Text(
                passed ? "Masha'Allah! Well Done!" : 'Great Effort! Keep Learning!',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
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

              // Score Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Score percentage
                    Text(
                      '${result.percentage}%',
                      style: GoogleFonts.outfit(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: passed ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Score',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const Divider(height: 28, color: Color(0xFFE2E8F0)),

                    // Stat Metrics: Points, Correct, Wrong, Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _resultStat(
                          label: 'Points',
                          value: '${result.score}/${result.maxScore}',
                          icon: Icons.star_rounded,
                          color: const Color(0xFFB45309),
                        ),
                        _resultStat(
                          label: 'Correct',
                          value: '${result.correctCount}',
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFF10B981),
                        ),
                        _resultStat(
                          label: 'To Improve',
                          value: '${result.incorrectCount}',
                          icon: Icons.refresh_rounded,
                          color: const Color(0xFFEF4444),
                        ),
                        _resultStat(
                          label: 'Time',
                          value: result.formattedTime,
                          icon: Icons.timer_outlined,
                          color: const Color(0xFF0284C7),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Question-by-Question Review Section
              if (result.review.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.rate_review_outlined, color: AppColors.gold, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Answer Review',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navyDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      ...result.review.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: item.isCorrect ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: item.isCorrect ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    item.isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                    color: item.isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    item.isCorrect ? 'Nice — correct' : "Let's review this one",
                                    style: GoogleFonts.outfit(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: item.isCorrect ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '+${item.earned} pt',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Q${idx + 1}: ${item.questionText}',
                                style: GoogleFonts.outfit(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navyDark,
                                  height: 1.3,
                                ),
                              ),
                              if (item.explanation != null && item.explanation!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(200),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.explanation!,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: const Color(0xFF475569),
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── Action Buttons ─────────────────────────────────────────────
              // 1. Try Again
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _initialize,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text('TRY AGAIN', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navyDark,
                    side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. Play a Game
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.go(AppRoutes.kids);
                  },
                  icon: const Icon(Icons.sports_esports_rounded),
                  label: Text('PLAY A GAME', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 3. Back to Quizzes
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<KidsController>().loadKidsPortal(forceRefresh: true);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navyDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text('BACK TO QUIZZES', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
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
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.navyDark)),
        Text(label, style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
      ],
    );
  }
}
