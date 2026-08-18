import 'package:flutter/foundation.dart';
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
  Future<List<KidsQuizItem>> getQuizzes({
    int page = 1,
    int limit = 24,
    String? search,
    String? category,
    String? age,
    String? ageGroup,
    String? difficulty,
    bool? featured,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (category != null && category.trim().isNotEmpty && category != 'All') {
      query['category'] = category.trim();
    }
    if (age != null && age.trim().isNotEmpty) {
      query['age'] = age.trim();
    }
    if (ageGroup != null && ageGroup.trim().isNotEmpty) {
      query['age_group'] = ageGroup.trim();
    }
    if (difficulty != null && difficulty.trim().isNotEmpty) {
      query['difficulty'] = difficulty.trim();
    }
    if (featured == true) {
      query['featured'] = '1';
    }

    final response = await _client.get(ApiConfig.kidsQuizzes, queryParameters: query);
    final rawList = _extractList(response, 'items');
    final quizzes = rawList
        .whereType<Map<String, dynamic>>()
        .map((q) => KidsQuizItem.fromJson(q))
        .toList();

    return quizzes;
  }

  /// `GET /kids/public_quiz.php`
  Future<KidsQuizItem?> getQuizDetails({int? quizId, String? slug}) async {
    final query = <String, dynamic>{};
    if (slug != null && slug.trim().isNotEmpty) {
      query['slug'] = slug.trim();
    } else if (quizId != null && quizId > 0) {
      query['id'] = quizId;
    } else {
      throw const ApiException(message: 'Quiz identifier (id or slug) is required.');
    }

    try {
      final response = await _client.get(ApiConfig.kidsQuizDetails, queryParameters: query);
      final data = response['data'] is Map<String, dynamic> ? response['data'] as Map<String, dynamic> : response;
      final quizMap = data['quiz'] is Map<String, dynamic> ? Map<String, dynamic>.from(data['quiz'] as Map) : Map<String, dynamic>.from(data);

      // Embed questions if returned at top data level
      final rawQuestions = data['questions'] ?? quizMap['questions'] ?? response['questions'];
      if (rawQuestions is List) {
        quizMap['questions'] = rawQuestions;
      }

      return KidsQuizItem.fromJson(quizMap);
    } catch (_) {
      rethrow;
    }
  }

  /// `POST /kids/quiz_start.php`
  Future<Map<String, dynamic>> startQuiz({required int quizId, String? token}) async {
    final response = await _client.post(
      ApiConfig.kidsQuizStart,
      body: {'quiz_id': quizId},
      token: token,
    );

    final data = response['data'] is Map<String, dynamic> ? response['data'] as Map<String, dynamic> : response;
    return data;
  }

  /// `POST /kids/quiz_submit.php`
  Future<QuizSubmitResult> submitQuiz({
    required String attemptToken,
    required List<QuizSubmitAnswer> answers,
    String? token,
  }) async {
    final response = await _client.post(
      ApiConfig.kidsQuizSubmit,
      body: {
        'attempt_token': attemptToken,
        'answers': answers.map((a) => a.toJson()).toList(),
      },
      token: token,
    );

    final data = response['data'] is Map<String, dynamic> ? response['data'] as Map<String, dynamic> : response;
    return QuizSubmitResult.fromJson(data);
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

  Future<List<KidsQuestionItem>> getQuizQuestions({int? quizId, String? slug}) async {
    final quiz = await getQuizDetails(quizId: quizId, slug: slug);
    return quiz?.questions ?? const [];
  }

  /// `GET /kids/public_stories.php` or media stories fallback
  Future<List<KidsStoryItem>> getStories({
    int page = 1,
    int limit = 20,
    String? search,
    String? token,
  }) async {
    try {
      final query = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (search != null && search.trim().isNotEmpty) {
        query['search'] = search.trim();
      }

      // Try dedicated kids stories endpoint first
      try {
        final response = await _client.get('/kids/public_stories.php', queryParameters: query, token: token);
        if (response['success'] == true && response['data'] != null) {
          final data = response['data'];
          final List? items = data is List
              ? data
              : (data is Map ? (data['items'] ?? data['stories'] ?? data['data']) as List? : null);
          if (items != null && items.isNotEmpty) {
            return items.whereType<Map<String, dynamic>>().map(KidsStoryItem.fromJson).toList();
          }
        }
      } catch (_) {
        // Fall back to media stories if /kids/public_stories.php is not yet routed
      }

      // Secondary fallback: /media/public_list.php?category_slug=stories
      final mediaQuery = <String, String>{
        'category_slug': 'stories',
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (search != null && search.trim().isNotEmpty) {
        mediaQuery['search'] = search.trim();
      }

      final mediaRes = await _client.get('/media/public_list.php', queryParameters: mediaQuery, token: token);
      if (mediaRes['success'] == true && mediaRes['data'] != null) {
        final data = mediaRes['data'];
        final List? items = data is List
            ? data
            : (data is Map ? (data['items'] ?? data['data']) as List? : null);
        if (items != null && items.isNotEmpty) {
          return items.whereType<Map<String, dynamic>>().map(KidsStoryItem.fromJson).toList();
        }
      }

      return [];
    } catch (e) {
      debugPrint('[KIDS STORIES API EXCEPTION] $e');
      return [];
    }
  }

  /// `GET /kids/public_story.php` or story details
  Future<KidsStoryItem?> getStoryDetails({int? id, String? slug, String? token}) async {
    try {
      final query = <String, String>{};
      if (id != null && id > 0) query['id'] = id.toString();
      if (slug != null && slug.isNotEmpty) query['slug'] = slug;

      final res = await _client.get('/kids/public_story.php', queryParameters: query, token: token);
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        final Map<String, dynamic>? storyMap = data is Map<String, dynamic>
            ? (data['story'] ?? data['item'] ?? data) as Map<String, dynamic>?
            : null;
        if (storyMap != null) {
          return KidsStoryItem.fromJson(storyMap);
        }
      }
    } catch (_) {}
    return null;
  }
}
