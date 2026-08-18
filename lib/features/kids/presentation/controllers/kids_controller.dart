import 'package:flutter/foundation.dart';
import '../../data/models/kids_models.dart';
import '../../data/services/kids_api_service.dart';

enum KidsPortalState { initial, loading, loaded, error }

/// Zabira Academy — Kids Portal Controller
class KidsController extends ChangeNotifier {
  KidsController({KidsApiService? service}) : _service = service ?? KidsApiService();

  final KidsApiService _service;

  KidsPortalState _state = KidsPortalState.initial;
  List<KidsCategoryItem> _categories = const [];
  List<KidsGameItem> _games = const [];
  List<KidsQuizItem> _quizzes = const [];
  List<KidsStoryItem> _stories = const [];
  String? _selectedCategory;
  String? _errorMessage;

  // Active Quiz State
  String? _activeAttemptToken;
  int? _activeAttemptId;
  KidsQuizItem? _activeQuiz;
  bool _isSubmittingQuiz = false;
  QuizSubmitResult? _lastQuizResult;

  KidsPortalState get state => _state;
  bool get isLoading => _state == KidsPortalState.loading;
  List<KidsCategoryItem> get categories => _categories;
  List<KidsGameItem> get games => _games;
  List<KidsQuizItem> get quizzes => _quizzes;
  List<KidsStoryItem> get stories => _stories;
  String? get selectedCategory => _selectedCategory;
  String? get errorMessage => _errorMessage;
  String? get activeAttemptToken => _activeAttemptToken;
  int? get activeAttemptId => _activeAttemptId;
  KidsQuizItem? get activeQuiz => _activeQuiz;
  bool get isSubmittingQuiz => _isSubmittingQuiz;
  QuizSubmitResult? get lastQuizResult => _lastQuizResult;

  void selectCategory(String? cat) {
    _selectedCategory = cat;
    notifyListeners();
  }

  Future<void> loadKidsPortal({bool forceRefresh = false}) async {
    if (_state == KidsPortalState.loading && !forceRefresh) return;

    _state = KidsPortalState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getCategories(),
        _service.getGames(),
        _service.getQuizzes(limit: 50),
        _service.getStories(limit: 50),
      ]);

      _categories = results[0] as List<KidsCategoryItem>;
      _games = results[1] as List<KidsGameItem>;
      _quizzes = results[2] as List<KidsQuizItem>;
      _stories = results[3] as List<KidsStoryItem>;

      if (_games.isEmpty && _quizzes.isEmpty && _stories.isEmpty) {
        _state = KidsPortalState.error;
        _errorMessage = 'Kids API returned no content. Please retry.';
      } else {
        _state = KidsPortalState.loaded;
        _errorMessage = null;
      }
      notifyListeners();
    } catch (e) {
      _state = KidsPortalState.error;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
    }
  }

  /// Reload live quizzes catalogue
  Future<List<KidsQuizItem>> fetchQuizzes({
    int page = 1,
    int limit = 50,
    String? search,
    String? category,
    String? ageGroup,
    String? difficulty,
  }) async {
    try {
      final list = await _service.getQuizzes(
        page: page,
        limit: limit,
        search: search,
        category: category,
        ageGroup: ageGroup,
        difficulty: difficulty,
      );
      if (page == 1) {
        _quizzes = list;
        notifyListeners();
      }
      return list;
    } catch (_) {
      return const [];
    }
  }

  /// Fetch full quiz details including questions & options
  Future<KidsQuizItem?> loadQuizDetails(int quizId, {String? slug}) async {
    try {
      final details = await _service.getQuizDetails(quizId: quizId, slug: slug);
      if (details != null) {
        _activeQuiz = details;
        notifyListeners();
      }
      return details;
    } catch (_) {
      return null;
    }
  }

  /// Starts a real quiz attempt and stores attempt_token from backend
  Future<String?> startQuiz(int quizId, {String? token}) async {
    try {
      final res = await _service.startQuiz(quizId: quizId, token: token);
      _activeAttemptToken = res['attempt_token']?.toString();
      _activeAttemptId = int.tryParse(res['attempt_id']?.toString() ?? '');
      if (_activeAttemptToken == null || _activeAttemptToken!.isEmpty) {
        throw Exception('Quiz start did not return attempt_token');
      }
      notifyListeners();
      return _activeAttemptToken;
    } catch (_) {
      return null;
    }
  }

  /// Submits answers to `quiz_submit.php` with validated `List<QuizSubmitAnswer>` payload
  Future<QuizSubmitResult?> submitQuizAnswers({
    required List<QuizSubmitAnswer> answers,
    String? token,
  }) async {
    if (_activeAttemptToken == null) return null;
    _isSubmittingQuiz = true;
    notifyListeners();

    try {
      final result = await _service.submitQuiz(
        attemptToken: _activeAttemptToken!,
        answers: answers,
        token: token,
      );
      _lastQuizResult = result;
      _isSubmittingQuiz = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isSubmittingQuiz = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Reset active quiz session
  void resetQuizSession() {
    _activeAttemptToken = null;
    _activeAttemptId = null;
    _isSubmittingQuiz = false;
    _lastQuizResult = null;
    notifyListeners();
  }

  Future<String?> startPlayGame(int gameId, {String? token}) async {
    try {
      final res = await _service.startPlayGame(gameId: gameId, token: token);
      final tokenValue = res['attempt_token']?.toString();
      if (tokenValue == null || tokenValue.isEmpty) {
        throw Exception('Game start did not return attempt_token');
      }
      return tokenValue;
    } catch (_) {
      return null;
    }
  }

  Future<void> submitGameScore(String attemptToken, int score, {int? timeTakenSeconds, String? token}) async {
    try {
      await _service.submitGameResult(
        attemptToken: attemptToken,
        score: score,
        timeTakenSeconds: timeTakenSeconds,
        token: token,
      );
    } catch (_) {}
  }
}
