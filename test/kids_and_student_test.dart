import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zabira_academy/features/kids/data/models/kids_models.dart';
import 'package:zabira_academy/features/kids/data/services/kids_api_service.dart';
import 'package:zabira_academy/features/kids/presentation/controllers/kids_controller.dart';
import 'package:zabira_academy/features/courses/data/models/enrolled_course_model.dart';
import 'package:zabira_academy/features/student/data/models/student_dashboard_model.dart';
import 'package:zabira_academy/features/student/data/services/student_api_service.dart';
import 'package:zabira_academy/features/student/presentation/controllers/student_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Student Dashboard Models & Service Tests', () {
    test('StudentDashboardModel parses JSON correctly', () {
      final sampleJson = {
        'success': true,
        'data': {
          'name': 'Ahmed Ali',
          'email': 'ahmed@zabira.com',
          'stats': {
            'orders_count': 3,
            'courses_count': 2,
            'in_progress_count': 1,
            'progress_percent': 45.0,
            'certificates_count': 1,
            'wishlist_count': 4,
            'live_classes_count': 2,
          },
          'quote': 'Seek knowledge from the cradle to the grave.',
        }
      };

      final model = StudentDashboardModel.fromJson(sampleJson);
      expect(model.studentName, equals('Ahmed Ali'));
      expect(model.email, equals('ahmed@zabira.com'));
      expect(model.myOrdersCount, equals(3));
      expect(model.myCoursesCount, equals(2));
      expect(model.inProgressCount, equals(1));
      expect(model.progressPercent, equals(45.0));
      expect(model.certificatesCount, equals(1));
      expect(model.wishlistCount, equals(4));
      expect(model.liveClassesCount, equals(2));
      expect(model.quote, equals('Seek knowledge from the cradle to the grave.'));
    });

    test('StudentApiService and StudentController fetch and load dashboard correctly', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('dashboard.php')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'name': 'Fatima Zahra',
                'email': 'fatima@zabira.com',
                'stats': {
                  'orders_count': 2,
                  'courses_count': 1,
                  'in_progress_count': 1,
                  'progress_percent': 60.0,
                  'certificates_count': 1,
                  'wishlist_count': 2,
                  'live_classes_count': 1,
                }
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      final service = StudentApiService(client: mockClient);
      final controller = StudentController(service: service);

      await controller.loadDashboard('test_token', defaultName: 'Fatima Zahra', defaultEmail: 'fatima@zabira.com');

      expect(controller.state, equals(StudentDashboardState.loaded));
      expect(controller.dashboard?.studentName, equals('Fatima Zahra'));
      expect(controller.dashboard?.myOrdersCount, equals(2));
    });
  });

  group('Kids Portal Models & Service Tests', () {
    test('KidsCategoryItem and KidsQuizItem parse JSON correctly', () {
      final catJson = {
        'id': 1,
        'name': 'Quran Stories',
        'slug': 'quran-stories',
        'description': 'Inspiring stories',
      };
      final cat = KidsCategoryItem.fromJson(catJson);
      expect(cat.id, equals(1));
      expect(cat.name, equals('Quran Stories'));

      final quizJson = {
        'id': 10,
        'title': 'Who Am I? – Prophets',
        'slug': 'who-am-i',
        'difficulty': 'Easy',
        'questions_count': 5,
        'points_reward': 100,
      };
      final quiz = KidsQuizItem.fromJson(quizJson);
      expect(quiz.id, equals(10));
      expect(quiz.title, equals('Who Am I? – Prophets'));
      expect(quiz.pointsReward, equals(100));
    });

    test('KidsController reports error when kids APIs return empty payloads', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      final service = KidsApiService(client: mockClient);
      final controller = KidsController(service: service);

      await controller.loadKidsPortal();

      expect(controller.state, equals(KidsPortalState.error));
      expect(controller.games, isEmpty);
      expect(controller.quizzes, isEmpty);
      expect(controller.stories, isEmpty);
    });

    test('KidsStoryItem parses JSON and readTime correctly', () {
      final storyJson = {
        'id': 5,
        'title': 'The Story of Prophet Yusuf',
        'slug': 'story-prophet-yusuf',
        'prophet_name': 'Prophet Yusuf (AS)',
        'category_name': 'Prophets',
        'age_group': '7-9',
        'age_label': '7–9',
        'read_time_minutes': 4,
        'short_description': 'A story of patience and forgiveness.',
        'content': 'Prophet Yusuf went through many trials and became a great ruler.',
        'is_featured': 1,
      };

      final story = KidsStoryItem.fromJson(storyJson);
      expect(story.id, equals(5));
      expect(story.title, equals('The Story of Prophet Yusuf'));
      expect(story.prophetName, equals('Prophet Yusuf (AS)'));
      expect(story.readTimeLabel, equals('4 min read'));
      expect(story.ageLabel, equals('7–9'));
      expect(story.isFeatured, isTrue);
      expect(story.shortDescription, contains('patience'));
      expect(story.content, contains('trials'));
    });
  });

  group('Course Enrollment & Completion Tests', () {
    test('EnrolledCourseModel isCompleted handles percent >= 100 and lesson counts accurately', () {
      final inProgressCourse = EnrolledCourseModel(
        id: 1,
        courseId: 23,
        title: 'Language of Quran',
        slug: 'language-of-quran',
        progressPercent: 40.0,
        completed: false,
        lessonsCount: 10,
        completedLessonsCount: 4,
      );
      expect(inProgressCourse.isCompleted, isFalse);

      final completedCourseByPercent = EnrolledCourseModel(
        id: 2,
        courseId: 24,
        title: 'Modern Arabic',
        slug: 'modern-arabic',
        progressPercent: 100.0,
        completed: false,
        lessonsCount: 10,
        completedLessonsCount: 4,
      );
      expect(completedCourseByPercent.isCompleted, isTrue);

      final completedCourseByLessons = EnrolledCourseModel(
        id: 3,
        courseId: 25,
        title: 'Stories from the Quran',
        slug: 'stories-from-the-quran',
        progressPercent: 90.0,
        completed: false,
        lessonsCount: 5,
        completedLessonsCount: 5,
      );
      expect(completedCourseByLessons.isCompleted, isTrue);
    });
  });
}
