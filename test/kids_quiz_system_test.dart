import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zabira_academy/features/kids/data/models/kids_models.dart';
import 'package:zabira_academy/features/kids/data/services/kids_api_service.dart';
import 'package:zabira_academy/features/kids/presentation/controllers/kids_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Kids Quiz System Unit & API Tests', () {
    test('KidsQuizItem, KidsQuestionItem, and QuizSubmitResult parse JSON accurately', () {
      final quizJson = {
        'id': 8,
        'title': 'Who Am I? – Prophets',
        'slug': 'who-am-i-prophets',
        'category_name': 'Prophets',
        'category_slug': 'prophets',
        'age_group': '7-9',
        'age_label': '7-9',
        'difficulty': 'Easy',
        'question_count': 10,
        'time_limit_seconds': 180,
        'passing_score': 60,
        'points': 100,
        'featured': true,
        'allow_retakes': true,
        'cover_image': '/uploads/kids/prophets.png',
        'thumbnail': '/uploads/kids/prophets_thumb.png',
        'instructions': 'Read clues carefully and guess the Prophet.',
        'questions': [
          {
            'id': 30,
            'question_text': 'Who am I? I built the Ark.',
            'question_type': 'mcq',
            'points': 1,
            'media_type': null,
            'media_url': null,
            'options': [
              {'id': 'a', 'text': 'Prophet Ibrahim'},
              {'id': 'b', 'text': 'Prophet Nuh'},
            ]
          },
          {
            'id': 35,
            'question_text': 'Which of these are connected with Prophet Yusuf?',
            'question_type': 'multi',
            'points': 1,
            'options': [
              {'id': 'a', 'text': 'Saw a special dream'},
              {'id': 'b', 'text': 'Brothers left him in a well'},
              {'id': 'c', 'text': 'Built the Ark'},
            ]
          }
        ]
      };

      final quiz = KidsQuizItem.fromJson(quizJson);
      expect(quiz.id, equals(8));
      expect(quiz.title, equals('Who Am I? – Prophets'));
      expect(quiz.slug, equals('who-am-i-prophets'));
      expect(quiz.categoryName, equals('Prophets'));
      expect(quiz.ageLabel, equals('7-9'));
      expect(quiz.difficulty, equals('Easy'));
      expect(quiz.timeLimitSeconds, equals(180));
      expect(quiz.durationLabel, equals('3 Min'));
      expect(quiz.passingScore, equals(60));
      expect(quiz.featured, isTrue);
      expect(quiz.allowRetakes, isTrue);
      expect(quiz.questions.length, equals(2));

      final q1 = quiz.questions[0];
      expect(q1.id, equals(30));
      expect(q1.questionType, equals('mcq'));
      expect(q1.options.length, equals(2));
      expect(q1.options[0].id, equals('a'));
      expect(q1.options[0].text, equals('Prophet Ibrahim'));
      expect(q1.options[1].id, equals('b'));
      expect(q1.options[1].text, equals('Prophet Nuh'));

      final q2 = quiz.questions[1];
      expect(q2.id, equals(35));
      expect(q2.questionType, equals('multi'));
      expect(q2.options.length, equals(3));
    });

    test('QuizSubmitAnswer serializes correctly into API validated format', () {
      final answer1 = const QuizSubmitAnswer(questionId: 30, selected: ['b']);
      final answer2 = const QuizSubmitAnswer(questionId: 35, selected: ['a', 'b']);

      expect(answer1.toJson(), equals({'question_id': 30, 'selected': ['b']}));
      expect(answer2.toJson(), equals({'question_id': 35, 'selected': ['a', 'b']}));
    });

    test('QuizSubmitResult parses server response with full review data', () {
      final submitResponseJson = {
        'score': 10,
        'max_score': 10,
        'percentage': 100,
        'correct_count': 10,
        'incorrect_count': 0,
        'passed': true,
        'time_taken_seconds': 45,
        'show_correct_after': true,
        'review': [
          {
            'question_id': 30,
            'question_text': 'Who am I? I built the Ark.',
            'question_type': 'mcq',
            'selected': ['b'],
            'is_correct': true,
            'points': 1,
            'earned': 1,
            'correct': ['b'],
            'explanation': 'Prophet Nuh built the Ark by Allah\'s command.',
            'options': [
              {'id': 'a', 'text': 'Prophet Ibrahim', 'correct': false},
              {'id': 'b', 'text': 'Prophet Nuh', 'correct': true}
            ]
          }
        ]
      };

      final result = QuizSubmitResult.fromJson(submitResponseJson);
      expect(result.score, equals(10));
      expect(result.maxScore, equals(10));
      expect(result.percentage, equals(100));
      expect(result.correctCount, equals(10));
      expect(result.incorrectCount, equals(0));
      expect(result.passed, isTrue);
      expect(result.timeTakenSeconds, equals(45));
      expect(result.formattedTime, equals('00:45'));
      expect(result.review.length, equals(1));

      final rev = result.review.first;
      expect(rev.questionId, equals(30));
      expect(rev.isCorrect, isTrue);
      expect(rev.selected, equals(['b']));
      expect(rev.correct, equals(['b']));
      expect(rev.explanation, contains('Prophet Nuh'));
      expect(rev.options.length, equals(2));
      expect(rev.options[1].correct, isTrue);
    });

    test('KidsApiService sends clean query parameters for public_quizzes.php without placeholders', () async {
      String? requestedQuery;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('public_quizzes.php')) {
          requestedQuery = request.url.query;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'items': [
                  {
                    'id': 8,
                    'title': 'Who Am I? – Prophets',
                    'slug': 'who-am-i-prophets',
                    'question_count': 10,
                    'difficulty': 'Easy'
                  }
                ],
                'pagination': {'total': 1, 'page': 1, 'limit': 24, 'pages': 1}
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{"success": false}', 404);
      });

      final service = KidsApiService(client: mockClient);
      final quizzes = await service.getQuizzes(page: 1, limit: 24, search: 'prophets');

      expect(quizzes.length, equals(1));
      expect(quizzes.first.title, equals('Who Am I? – Prophets'));
      expect(requestedQuery, contains('page=1'));
      expect(requestedQuery, contains('limit=24'));
      expect(requestedQuery, contains('search=prophets'));
      // Verify no dummy placeholders sent
      expect(requestedQuery, isNot(contains('category=')));
      expect(requestedQuery, isNot(contains('age_group=')));
    });

    test('KidsApiService startQuiz and submitQuiz work end-to-end with mock backend', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('quiz_start.php')) {
          final body = jsonDecode(request.body);
          expect(body['quiz_id'], equals(8));
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Quiz started.',
              'data': {
                'attempt_token': 'mock_token_abc_123',
                'attempt_id': 99,
              }
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.contains('quiz_submit.php')) {
          final body = jsonDecode(request.body);
          expect(body['attempt_token'], equals('mock_token_abc_123'));
          expect(body['answers'], isA<List>());
          final answersList = body['answers'] as List;
          expect(answersList.first['question_id'], equals(30));
          expect(answersList.first['selected'], equals(['b']));

          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Quiz submitted.',
              'data': {
                'score': 1,
                'max_score': 1,
                'percentage': 100,
                'correct_count': 1,
                'incorrect_count': 0,
                'passed': true,
                'time_taken_seconds': 10,
                'show_correct_after': true,
                'review': [
                  {
                    'question_id': 30,
                    'question_text': 'Who am I? I built the Ark.',
                    'question_type': 'mcq',
                    'selected': ['b'],
                    'is_correct': true,
                    'points': 1,
                    'earned': 1,
                    'correct': ['b'],
                    'explanation': 'Prophet Nuh built the Ark.'
                  }
                ]
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('{"success": false}', 404);
      });

      final service = KidsApiService(client: mockClient);
      final controller = KidsController(service: service);

      // Start quiz
      final token = await controller.startQuiz(8);
      expect(token, equals('mock_token_abc_123'));
      expect(controller.activeAttemptToken, equals('mock_token_abc_123'));

      // Submit quiz
      final result = await controller.submitQuizAnswers(
        answers: [const QuizSubmitAnswer(questionId: 30, selected: ['b'])],
      );

      expect(result, isNotNull);
      expect(result!.score, equals(1));
      expect(result.passed, isTrue);
      expect(result.percentage, equals(100));
      expect(result.review.first.isCorrect, isTrue);
    });
  });
}
