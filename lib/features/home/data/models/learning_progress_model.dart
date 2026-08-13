/// Data model for the Continue Learning progress card.
class LearningProgressModel {
  const LearningProgressModel({
    required this.courseId,
    required this.courseTitle,
    required this.stepLabel,
    required this.progress,
  });

  final String courseId;
  final String courseTitle;

  /// Display string e.g. "Step 3 • Lesson 12"
  final String stepLabel;

  /// Progress value between 0.0 and 1.0
  final double progress;

  /// Formatted percentage string e.g. "60%"
  String get progressLabel => '${(progress * 100).round()}%';
}
