import 'package:flutter_test/flutter_test.dart';
import 'package:zabira_academy/features/courses/data/repositories/course_repository.dart';

void main() {
  test('CourseRepository returns all 14 courses without being filtered by sort=featured', () async {
    final repo = CourseRepository();
    final courses = await repo.getCourses(sort: 'featured');
    print('Fetched courses count: ${courses.length}');
    expect(courses.length, greaterThanOrEqualTo(14));
    for (final c in courses) {
      print('-> Course ID: ${c.id}, Title: "${c.title}", Cat: "${c.categoryName}"');
    }
  });
}
