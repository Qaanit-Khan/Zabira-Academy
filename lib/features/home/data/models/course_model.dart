/// Identifies the course-specific visual icon to render in the CourseCard header.
/// Used to paint a unique, Islamic-educational illustration per course type.
enum CourseType {
  quranTajweed,
  understandQuran,
  namazDua,
  muslimLife,
}

/// Data model for a Top Course card.
class CourseModel {
  const CourseModel({
    required this.id,
    required this.title,
    required this.studentCount,
    required this.imagePath,
    required this.courseType,
  });

  final String id;
  final String title;

  /// Display string e.g. "1.2K Students"
  final String studentCount;

  /// Local asset path for the course thumbnail image.
  final String imagePath;

  /// Determines which course-specific custom illustration to render
  /// as a fallback / header visual in the CourseCard.
  final CourseType courseType;
}
