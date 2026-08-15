import '../../../../core/constants/api_config.dart';

/// Zabira Academy — Enrolled Course Model
class EnrolledCourseModel {
  const EnrolledCourseModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.slug,
    this.coverImage,
    this.progressPercent = 0.0,
    this.completed = false,
    this.lessonsCount = 0,
    this.completedLessonsCount = 0,
    this.lastLessonId,
    this.lastLessonTitle,
    this.lastPositionSeconds = 0,
    this.enrolledAt,
    this.status = 'active',
  });

  final int id;
  final int courseId;
  final String title;
  final String slug;
  final String? coverImage;
  final double progressPercent;
  final bool completed;
  final int lessonsCount;
  final int completedLessonsCount;
  final int? lastLessonId;
  final String? lastLessonTitle;
  final int lastPositionSeconds;
  final DateTime? enrolledAt;
  final String status;

  String? get resolvedImage => ApiConfig.resolveImageUrl(coverImage);

  int get progressPercentInt => progressPercent.round().clamp(0, 100);

  factory EnrolledCourseModel.fromJson(Map<String, dynamic> json) {
    final rawCourseId = json['course_id'] ?? json['id'] ?? 0;
    final courseId = int.tryParse(rawCourseId.toString()) ?? 0;
    final id = int.tryParse((json['enrollment_id'] ?? json['id'] ?? courseId).toString()) ?? courseId;

    final title = json['title']?.toString() ??
        json['course_title']?.toString() ??
        json['name']?.toString() ??
        'Course';

    final slug = json['slug']?.toString() ?? json['course_slug']?.toString() ?? '';

    final image = json['cover_image']?.toString() ??
        json['thumbnail']?.toString() ??
        json['image']?.toString() ??
        json['banner_image']?.toString();

    final progress = double.tryParse(json['progress_percent']?.toString() ?? json['progress']?.toString() ?? '0') ?? 0.0;
    final completed = json['completed'] == true || json['completed'] == 1 || json['status'] == 'completed';

    final lessonsCount = int.tryParse(json['lessons_count']?.toString() ?? json['total_lessons']?.toString() ?? '0') ?? 0;
    final completedLessons = int.tryParse(json['completed_lessons_count']?.toString() ?? json['completed_lessons']?.toString() ?? '0') ?? 0;

    final lastLessonId = int.tryParse(json['last_lesson_id']?.toString() ?? json['lesson_id']?.toString() ?? '');
    final lastLessonTitle = json['last_lesson_title']?.toString() ?? json['lesson_title']?.toString();
    final lastPos = int.tryParse(json['last_position_seconds']?.toString() ?? json['last_position']?.toString() ?? '0') ?? 0;

    return EnrolledCourseModel(
      id: id,
      courseId: courseId,
      title: title,
      slug: slug,
      coverImage: image,
      progressPercent: progress,
      completed: completed,
      lessonsCount: lessonsCount,
      completedLessonsCount: completedLessons,
      lastLessonId: lastLessonId,
      lastLessonTitle: lastLessonTitle,
      lastPositionSeconds: lastPos,
      enrolledAt: DateTime.tryParse(json['enrolled_at']?.toString() ?? json['created_at']?.toString() ?? ''),
      status: json['status']?.toString() ?? 'active',
    );
  }
}
