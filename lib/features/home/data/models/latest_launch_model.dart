/// Content type for a Latest Launch item.
///
/// The Home Page [LatestLaunchCard] uses this to select the correct
/// illustration painter and category badge label. Future API responses
/// can return any of these types and the UI will render them correctly.
enum LaunchContentType {
  course,
  nasheed,
  qirat,
  audio,
  audiobook,
  event,
  media,
}

/// Display label for each content type — used in the badge pill overlay.
extension LaunchContentTypeX on LaunchContentType {
  String get label => switch (this) {
        LaunchContentType.course    => 'COURSE',
        LaunchContentType.nasheed   => 'NASHEED',
        LaunchContentType.qirat     => 'QIRAT',
        LaunchContentType.audio     => 'AUDIO',
        LaunchContentType.audiobook => 'AUDIOBOOK',
        LaunchContentType.event     => 'EVENT',
        LaunchContentType.media     => 'MEDIA',
      };
}

/// Data model for a single Latest Launch card.
///
/// Flexible enough to represent any newly published academy content.
/// API-ready: replace [HomeMockRepository.getLatestLaunches()] with a real repo.
class LatestLaunchModel {
  const LatestLaunchModel({
    required this.id,
    required this.title,
    required this.contentType,
    required this.supportingInfo,
    this.imagePath,
  });

  final String id;
  final String title;

  /// Drives card illustration painter, category badge, and future navigation.
  final LaunchContentType contentType;

  /// Secondary info line e.g. "1.2K Students" or "28 min · New"
  final String supportingInfo;

  /// Optional local asset path for a real thumbnail image.
  /// If null, a custom-painted Islamic illustration is rendered instead.
  final String? imagePath;
}
