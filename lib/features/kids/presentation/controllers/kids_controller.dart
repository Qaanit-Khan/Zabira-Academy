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
  String? _selectedCategory;
  String? _errorMessage;

  // Active Quiz State
  String? _activeAttemptToken;
  bool _isSubmittingQuiz = false;
  Map<String, dynamic>? _lastQuizResult;

  KidsPortalState get state => _state;
  bool get isLoading => _state == KidsPortalState.loading;
  List<KidsCategoryItem> get categories => _categories;
  List<KidsGameItem> get games => _games;
  List<KidsQuizItem> get quizzes => _quizzes;
  String? get selectedCategory => _selectedCategory;
  String? get errorMessage => _errorMessage;
  String? get activeAttemptToken => _activeAttemptToken;
  bool get isSubmittingQuiz => _isSubmittingQuiz;
  Map<String, dynamic>? get lastQuizResult => _lastQuizResult;

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
      final catsFuture = _service.getCategories();
      final gamesFuture = _service.getGames();
      final quizzesFuture = _service.getQuizzes();

      final results = await Future.wait([catsFuture, gamesFuture, quizzesFuture]);

      _categories = results[0] as List<KidsCategoryItem>;
      _games = results[1] as List<KidsGameItem>;
      _quizzes = results[2] as List<KidsQuizItem>;

      _state = KidsPortalState.loaded;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _state = KidsPortalState.error;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
    }
  }

  Future<String?> startQuiz(int quizId, {String? token}) async {
    try {
      final res = await _service.startQuiz(quizId: quizId, token: token);
      _activeAttemptToken = res['attempt_token']?.toString();
      notifyListeners();
      return _activeAttemptToken;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> submitQuiz({
    required Map<String, dynamic> answers,
    String? token,
  }) async {
    if (_activeAttemptToken == null) return null;
    _isSubmittingQuiz = true;
    notifyListeners();

    try {
      final res = await _service.submitQuiz(
        attemptToken: _activeAttemptToken!,
        answers: answers,
        token: token,
      );
      _lastQuizResult = res;
      _isSubmittingQuiz = false;
      notifyListeners();
      return res;
    } catch (e) {
      _isSubmittingQuiz = false;
      notifyListeners();
      return null;
    }
  }

  Future<String?> startPlayGame(int gameId, {String? token}) async {
    try {
      final res = await _service.startPlayGame(gameId: gameId, token: token);
      return res['attempt_token']?.toString();
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
