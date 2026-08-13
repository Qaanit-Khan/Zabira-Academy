/// Art direction type for the Daily Supplement illustration panel.
/// Drives the custom-painted Islamic artwork rendered in [DailySupplementCard].
enum DailySupplementArtType {
  nasheed,
  qirat,
  quranRecitation,
  islamicReminder,
}

/// Data model for the Daily Supplement card.
///
/// API-ready: replace [HomeMockRepository.getDailySupplementInfo()] with a
/// real repository to fetch the current day's supplemental content.
class DailySupplementModel {
  const DailySupplementModel({
    required this.sectionLabel,
    required this.contentTitle,
    required this.contentType,
    required this.duration,
    required this.progress,
    required this.artType,
  });

  /// Section label shown at the top of the card e.g. "Daily Nasheed"
  final String sectionLabel;

  /// Title of the specific content piece e.g. "Allah Knows"
  final String contentTitle;

  /// Human-readable content type for the meta area e.g. "Nasheed"
  final String contentType;

  /// Playback duration string e.g. "03:42"
  final String duration;

  /// Playback progress 0.0 – 1.0
  final double progress;

  /// Drives the custom Islamic illustration rendered in the left art panel.
  final DailySupplementArtType artType;

  /// Formatted percentage string e.g. "42%"
  String get progressLabel => '${(progress * 100).round()}%';
}
