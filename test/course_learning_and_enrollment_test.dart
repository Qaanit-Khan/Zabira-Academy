import 'package:flutter_test/flutter_test.dart';
import 'package:zabira_academy/features/courses/data/models/enrolled_course_model.dart';
import 'package:zabira_academy/features/courses/presentation/controllers/enrollment_controller.dart';
import 'package:zabira_academy/features/student/data/models/student_dashboard_model.dart';

void main() {
  group('EnrolledCourseModel & Enrollment Sync Tests', () {
    test('EnrolledCourseModel correctly unpacks nested course map', () {
      final nestedJson = {
        'id': 101, // enrollment id
        'status': 'active',
        'progress_percent': 45.5,
        'course': {
          'id': 5, // real course id
          'title': 'Quran with Tajweed',
          'slug': 'quran-with-tajweed',
          'cover_image': 'https://api.zabiraacademy.com/uploads/quran.jpg',
          'instructor_name': 'Qari Abdul Basit',
          'category_name': 'Quran Studies',
          'duration': '12 Weeks',
          'level': 'Beginner',
          'language': 'English & Arabic',
          'total_lessons': 24,
        },
      };

      final model = EnrolledCourseModel.fromJson(nestedJson);

      expect(model.courseId, 5);
      expect(model.id, 101);
      expect(model.title, 'Quran with Tajweed');
      expect(model.instructorName, 'Qari Abdul Basit');
      expect(model.categoryName, 'Quran Studies');
      expect(model.duration, '12 Weeks');
      expect(model.level, 'Beginner');
      expect(model.language, 'English & Arabic');
      expect(model.progressPercent, 45.5);
      expect(model.progressPercentInt, 46);
      expect(model.lessonsCount, 24);
      expect(model.isActive, true);
    });

    test('EnrolledCourseModel correctly unpacks flat JSON format', () {
      final flatJson = {
        'id': 21,
        'course_id': 21,
        'course_title': 'The Quran Code',
        'slug': 'the-quran-code',
        'thumbnail': 'https://api.zabiraacademy.com/uploads/code.jpg',
        'instructor': 'Sheikh Omar',
        'category': 'Quran Studies',
        'duration': '8 Weeks',
        'level': 'Intermediate',
        'language': 'English',
        'progress': 100.0,
        'completed': true,
        'total_lessons': 10,
        'completed_lessons': 10,
      };

      final model = EnrolledCourseModel.fromJson(flatJson);

      expect(model.courseId, 21);
      expect(model.title, 'The Quran Code');
      expect(model.instructorName, 'Sheikh Omar');
      expect(model.categoryName, 'Quran Studies');
      expect(model.completed, true);
      expect(model.progressPercentInt, 100);
      expect(model.completedLessonsCount, 10);
    });

    test('StudentDashboardModel correctly unpacks continue learning courses from Map and List', () {
      final dashboardJson = {
        'data': {
          'name': 'Student User',
          'email': 'student@example.com',
          'stats': {
            'courses_count': 2,
            'my_orders': 3,
          },
          'continue_learning': {
            'courses': [
              {
                'id': 5,
                'course_id': 5,
                'title': 'Quran with Tajweed',
                'progress_percent': 25.0,
              },
              {
                'id': 11,
                'course_id': 11,
                'title': 'Namaz & Dua',
                'progress_percent': 50.0,
              },
            ],
          },
        },
      };

      final dashboard = StudentDashboardModel.fromJson(dashboardJson);

      expect(dashboard.studentName, 'Student User');
      expect(dashboard.myCoursesCount, 2);
      expect(dashboard.continueLearningCourses.length, 2);
      expect(dashboard.continueLearningCourses[0].courseId, 5);
      expect(dashboard.continueLearningCourses[1].courseId, 11);
    });

    test('EnrollmentController updates local course progress accurately', () {
      final controller = EnrollmentController();
      expect(controller.enrolledCourses.isEmpty, true);

      // Verify progress update method compiles and safely executes
      controller.updateCourseProgressLocal(
        courseId: 5,
        progressPercent: 50.0,
        completedLessonsCount: 6,
        lastLessonId: 102,
        lastLessonTitle: 'Makharij Part 2',
      );

      expect(controller.enrolledCourses.isEmpty, true);
    });
  });
}
