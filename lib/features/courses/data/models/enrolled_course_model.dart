import '../../../../core/constants/api_config.dart';

/// Zabira Academy — Enrolled Course Model
class EnrolledCourseModel {
  const EnrolledCourseModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.slug,
    this.coverImage,
    this.instructorName,
    this.categoryName,
    this.duration = 'Self-Paced',
    this.level = 'All Levels',
    this.language = 'English',
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
  final String? instructorName;
  final String? categoryName;
  final String duration;
  final String level;
  final String language;
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

  bool get isActive => status.toLowerCase() == 'active' || status.toLowerCase() == 'enrolled' || status.toLowerCase() == 'paid';

  factory EnrolledCourseModel.fromJson(Map<String, dynamic> json) {
    final dynamic courseObj = json['course'] is Map<String, dynamic> ? json['course'] as Map<String, dynamic> : null;

    final rawCourseId = json['course_id'] ??
        courseObj?['id'] ??
        courseObj?['course_id'] ??
        json['id'] ??
        0;
    final courseId = int.tryParse(rawCourseId.toString()) ?? 0;
    final id = int.tryParse((json['enrollment_id'] ?? json['id'] ?? courseId).toString()) ?? courseId;

    final title = json['title']?.toString() ??
        json['course_title']?.toString() ??
        courseObj?['title']?.toString() ??
        json['name']?.toString() ??
        'Course';

    final slug = json['slug']?.toString() ??
        json['course_slug']?.toString() ??
        courseObj?['slug']?.toString() ??
        '';

    final image = json['cover_image']?.toString() ??
        json['thumbnail']?.toString() ??
        json['image']?.toString() ??
        json['banner_image']?.toString() ??
        courseObj?['cover_image']?.toString() ??
        courseObj?['thumbnail']?.toString();

    final instructor = json['instructor_name']?.toString() ??
        json['instructor']?.toString() ??
        json['teacher']?.toString() ??
        courseObj?['instructor_name']?.toString();

    final category = json['category_name']?.toString() ??
        json['category']?.toString() ??
        courseObj?['category_name']?.toString();

    final duration = json['duration']?.toString() ??
        courseObj?['duration']?.toString() ??
        'Self-Paced';

    final level = json['level']?.toString() ??
        courseObj?['level']?.toString() ??
        'All Levels';

    final language = json['language']?.toString() ??
        courseObj?['language']?.toString() ??
        'English';

    final progress = double.tryParse((json['progress_percent'] ?? json['progress'] ?? courseObj?['progress'] ?? '0').toString()) ?? 0.0;
    final completed = json['completed'] == true ||
        json['completed'] == 1 ||
        json['status'] == 'completed' ||
        progress >= 100.0;

    final lessonsCount = int.tryParse((json['lessons_count'] ?? json['total_lessons'] ?? courseObj?['total_lessons'] ?? '0').toString()) ?? 0;
    final completedLessons = int.tryParse((json['completed_lessons_count'] ?? json['completed_lessons'] ?? '0').toString()) ?? 0;

    final lastLessonId = int.tryParse((json['last_lesson_id'] ?? json['lesson_id'] ?? '').toString());
    final lastLessonTitle = json['last_lesson_title']?.toString() ?? json['lesson_title']?.toString();
    final lastPos = int.tryParse((json['last_position_seconds'] ?? json['last_position'] ?? '0').toString()) ?? 0;

    return EnrolledCourseModel(
      id: id,
      courseId: courseId,
      title: title,
      slug: slug,
      coverImage: image,
      instructorName: instructor,
      categoryName: category,
      duration: duration,
      level: level,
      language: language,
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
