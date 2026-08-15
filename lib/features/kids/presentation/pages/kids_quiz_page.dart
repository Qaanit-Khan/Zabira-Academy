import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/auth_controller.dart';
import '../controllers/kids_controller.dart';
import '../../data/models/kids_models.dart';

/// Zabira Academy — Interactive Kids Quiz Runner
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

class _KidsQuizPageState extends State<KidsQuizPage> {
  int _currentIndex = 0;
  final Map<int, int> _selectedAnswers = {};
  bool _isSubmitted = false;

  final List<KidsQuestionItem> _questions = const [
    KidsQuestionItem(
      id: 1,
      question: 'Which Prophet built the Ark by the command of Allah?',
      options: ['Prophet Musa (AS)', 'Prophet Nuh (AS)', 'Prophet Ibrahim (AS)', 'Prophet Isa (AS)'],
      correctAnswerIndex: 1,
      explanation: 'Prophet Nuh (AS) built the Ark with Allah\'s divine guidance.',
    ),
    KidsQuestionItem(
      id: 2,
      question: 'How many daily prayers (Salah) are obligatory in Islam?',
      options: ['3', '4', '5', '7'],
      correctAnswerIndex: 2,
      explanation: 'There are 5 daily obligatory prayers: Fajr, Dhuhr, Asr, Maghrib, and Isha.',
    ),
    KidsQuestionItem(
      id: 3,
      question: 'What is the Holy Book revealed to Prophet Muhammad (PBUH)?',
      options: ['Tawrat', 'Injil', 'Zabur', 'Holy Quran'],
      correctAnswerIndex: 3,
      explanation: 'The Holy Quran is the final revelation sent to Prophet Muhammad (PBUH).',
    ),
    KidsQuestionItem(
      id: 4,
      question: 'What is the first month in the Islamic Hijri calendar?',
      options: ['Ramadan', 'Muharram', 'Shawwal', 'Dhul Hijjah'],
      correctAnswerIndex: 1,
      explanation: 'Muharram marks the beginning of the Islamic lunar calendar year.',
    ),
    KidsQuestionItem(
      id: 5,
      question: 'What do we say before starting to eat or drink?',
      options: ['Alhamdulillah', 'Bismillah', 'SubhanAllah', 'Allahu Akbar'],
      correctAnswerIndex: 1,
      explanation: 'We begin with Bismillah ("In the name of Allah").',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthController>().currentToken;
      context.read<KidsController>().startQuiz(widget.quizId, token: token);
    });
  }

  void _submitQuiz() {
    final token = context.read<AuthController>().currentToken;
    context.read<KidsController>().submitQuiz(
      answers: _selectedAnswers.map((k, v) => MapEntry(k.toString(), v)),
      token: token,
    );

    setState(() => _isSubmitted = true);
  }

  @override
  Widget build(BuildContext context) {
    final quizTitle = widget.quiz?.title ?? 'Prophets & Islamic Knowledge';

    if (_isSubmitted) {
      int correct = 0;
      for (int i = 0; i < _questions.length; i++) {
        if (_selectedAnswers[i] == _questions[i].correctAnswerIndex) correct++;
      }
      final percent = (correct / _questions.length * 100).toInt();

      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.emoji_events_rounded, color: Color(0xFF10B981), size: 48),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  percent >= 60 ? 'Masha\'Allah! Well Done!' : 'Great Effort! Keep Learning!',
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navyDark),
                ),
                const SizedBox(height: 6),
                Text(
                  'You scored $percent% ($correct of ${_questions.length} correct)',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navyDark,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Back to Kids Portal', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final q = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.navyDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          quizTitle,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navyDark),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentIndex + 1} of ${_questions.length}',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gold),
                ),
                Text(
                  '${((_currentIndex + 1) / _questions.length * 100).toInt()}%',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / _questions.length,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 24),

            // Question Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                q.question,
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyDark,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Options List
            Expanded(
              child: ListView.builder(
                itemCount: q.options.length,
                itemBuilder: (context, optIdx) {
                  final isSelected = _selectedAnswers[_currentIndex] == optIdx;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAnswers[_currentIndex] = optIdx),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.navyDark : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppColors.navyDark : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
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
                              q.options[optIdx],
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Action Buttons
            Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentIndex--),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navyDark,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentIndex > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedAnswers[_currentIndex] == null
                        ? null
                        : () {
                            if (_currentIndex < _questions.length - 1) {
                              setState(() => _currentIndex++);
                            } else {
                              _submitQuiz();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.navyDark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentIndex < _questions.length - 1 ? 'Next Question' : 'Submit Quiz',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
