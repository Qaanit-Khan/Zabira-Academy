import 'package:http/http.dart' as http;
import '../../../../core/constants/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../models/kids_models.dart';

/// Zabira Academy — Kids Portal API Network Service
class KidsApiService {
  KidsApiService({http.Client? client, ApiClient? apiClient})
      : _client = apiClient ?? ApiClient(client: client);

  final ApiClient _client;

  List<dynamic> _extractList(dynamic response, [String? preferredKey]) {
    if (response is List) return response;
    if (response is Map) {
      final data = response['data'];
      if (data is List) return data;
      if (data is Map) {
        if (preferredKey != null && data[preferredKey] is List) {
          return data[preferredKey] as List;
        }
        final inner = data['items'] ?? data['games'] ?? data['categories'] ?? data['quizzes'] ?? data['questions'];
        if (inner is List) return inner;
      }
      if (preferredKey != null && response[preferredKey] is List) {
        return response[preferredKey] as List;
      }
      final outer = response['items'] ?? response['games'] ?? response['categories'] ?? response['quizzes'] ?? response['questions'];
      if (outer is List) return outer;
    }
    return const [];
  }

  /// `GET /kids/public_categories.php`
  Future<List<KidsCategoryItem>> getCategories() async {
    final response = await _client.get(ApiConfig.kidsCategories);
    final rawList = _extractList(response, 'categories');
    return rawList
        .whereType<Map<String, dynamic>>()
        .map((c) => KidsCategoryItem.fromJson(c))
        .toList();
  }

  /// `GET /kids/public_games.php`
  Future<List<KidsGameItem>> getGames({String? category, String? ageGroup, String? difficulty}) async {
    final query = <String, dynamic>{'page': 1, 'limit': 50};
    if (category != null && category.isNotEmpty && category != 'All') {
      query['category'] = category;
    }
    if (ageGroup != null && ageGroup.isNotEmpty) {
      query['age_group'] = ageGroup;
    }
    if (difficulty != null && difficulty.isNotEmpty) {
      query['difficulty'] = difficulty;
    }

    final response = await _client.get(ApiConfig.kidsGames, queryParameters: query);
    final rawList = _extractList(response, 'items');
    return rawList
        .whereType<Map<String, dynamic>>()
        .map((g) => KidsGameItem.fromJson(g))
        .toList();
  }

  /// `GET /kids/public_game.php`
  Future<KidsGameItem?> getGameDetails({required int gameId, String? slug}) async {
    final query = <String, dynamic>{'id': gameId};
    if (slug != null && slug.isNotEmpty) query['slug'] = slug;

    try {
      final response = await _client.get(ApiConfig.kidsGameDetails, queryParameters: query);
      final data = response['data'] is Map<String, dynamic> ? response['data'] as Map<String, dynamic> : response;
      final gameMap = data['game'] is Map<String, dynamic> ? data['game'] as Map<String, dynamic> : data;
      return KidsGameItem.fromJson(gameMap);
    } catch (_) {
      return null;
    }
  }

  /// `GET /kids/public_quizzes.php`
  Future<List<KidsQuizItem>> getQuizzes({String? category, String? ageGroup}) async {
    final query = <String, dynamic>{'page': 1, 'limit': 50};
    if (category != null && category.isNotEmpty && category != 'All') {
      query['category'] = category;
    }
    if (ageGroup != null && ageGroup.isNotEmpty) {
      query['age_group'] = ageGroup;
    }

    final response = await _client.get(ApiConfig.kidsQuizzes, queryParameters: query);
    final rawList = _extractList(response, 'items');
    return rawList
        .whereType<Map<String, dynamic>>()
        .map((q) => KidsQuizItem.fromJson(q))
        .toList();
  }

  /// `GET /kids/public_quiz.php`
  Future<KidsQuizItem?> getQuizDetails({required int quizId, String? slug}) async {
    final query = <String, dynamic>{'id': quizId};
    if (slug != null && slug.isNotEmpty) query['slug'] = slug;

    try {
      final response = await _client.get(ApiConfig.kidsQuizDetails, queryParameters: query);
      final data = response['data'] is Map<String, dynamic> ? response['data'] as Map<String, dynamic> : response;
      final quizMap = data['quiz'] is Map<String, dynamic> ? data['quiz'] as Map<String, dynamic> : data;
      return KidsQuizItem.fromJson(quizMap);
    } catch (_) {
      return null;
    }
  }

  /// `POST /kids/quiz_start.php`
  Future<Map<String, dynamic>> startQuiz({required int quizId, String? token}) async {
    return _client.post(ApiConfig.kidsQuizStart, body: {'quiz_id': quizId}, token: token);
  }

  /// `POST /kids/quiz_submit.php`
  Future<Map<String, dynamic>> submitQuiz({
    required String attemptToken,
    required Map<String, dynamic> answers,
    String? token,
  }) async {
    return _client.post(
      ApiConfig.kidsQuizSubmit,
      body: {
        'attempt_token': attemptToken,
        'answers': answers,
      },
      token: token,
    );
  }

  /// `POST /kids/game_play.php`
  Future<Map<String, dynamic>> startPlayGame({required int gameId, String? token}) async {
    final res = await _client.post(ApiConfig.kidsGamePlay, body: {'game_id': gameId}, token: token);
    final data = res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : res;
    return {
      'attempt_token': data['attempt_token']?.toString(),
      'attempt_id': data['attempt_id'],
    };
  }

  /// `POST /kids/game_result.php`
  Future<Map<String, dynamic>> submitGameResult({
    required String attemptToken,
    required int score,
    int? maxScore,
    int? timeTakenSeconds,
    String result = 'win',
    String? token,
  }) async {
    final body = <String, dynamic>{
      'attempt_token': attemptToken,
      'score': score.toString(),
      'max_score': (maxScore ?? score).toString(),
      'time_taken_seconds': (timeTakenSeconds ?? 30).toString(),
      'result': result,
    };
    return _client.post(
      ApiConfig.kidsGameResult,
      body: body,
      token: token,
    );
  }

  Future<List<KidsQuestionItem>> getQuizQuestions({required int quizId, String? slug}) async {
    final query = <String, dynamic>{'id': quizId};
    if (slug != null && slug.isNotEmpty) {
      query['slug'] = slug;
    }
    final response = await _client.get(ApiConfig.kidsQuizDetails, queryParameters: query);
    final data = response['data'] is Map<String, dynamic> ? response['data'] as Map<String, dynamic> : response;
    final raw = data['questions'] ?? data['quiz']?['questions'] ?? response['questions'] ?? const [];
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(KidsQuestionItem.fromJson)
          .toList();
    }
    return const [];
  }
}
