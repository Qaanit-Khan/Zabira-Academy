import '../../../../core/constants/api_config.dart';

/// Model representing a Media video or short item from the Zabira Academy Media API.
class MediaItemModel {
  const MediaItemModel({
    required this.id,
    required this.title,
    required this.slug,
    this.description = '',
    this.url = '',
    this.youtubeUrl,
    this.duration,
    this.thumbnail,
    this.language = '',
    this.premium = false,
    this.featured = false,
    this.categoryId,
    this.categoryName,
    this.categorySlug,
    this.createdAt,
  });

  final int id;
  final String title;
  final String slug;
  final String description;
  final String url;
  final String? youtubeUrl;
  final String? duration;
  final String? thumbnail;
  final String language;
  final bool premium;
  final bool featured;
  final int? categoryId;
  final String? categoryName;
  final String? categorySlug;
  final String? createdAt;

  /// Check if this item is a YouTube short
  bool get isShort {
    final lowerTitle = title.toLowerCase();
    final lowerUrl = (url + (youtubeUrl ?? '')).toLowerCase();
    return lowerTitle.contains('#short') || lowerTitle.contains('short') || lowerUrl.contains('/shorts/');
  }

  /// Resolved thumbnail image URL
  String? get resolvedThumbnail => ApiConfig.resolveImageUrl(thumbnail);

  /// Helper to get playback URL (prefers youtube_url or url)
  String get playUrl => (youtubeUrl != null && youtubeUrl!.isNotEmpty) ? youtubeUrl! : url;

  factory MediaItemModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    }

    bool parseBool(dynamic val) {
      if (val == null) return false;
      if (val is bool) return val;
      if (val is num) return val == 1;
      return val.toString() == '1' || val.toString().toLowerCase() == 'true';
    }

    String? parseDuration(dynamic val) {
      if (val == null) return null;
      if (val is int) {
        final m = val ~/ 60;
        final s = val % 60;
        return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      }
      return val.toString();
    }

    return MediaItemModel(
      id: parseInt(json['id']),
      title: json['title']?.toString() ?? 'Untitled Video',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      youtubeUrl: json['youtube_url']?.toString(),
      duration: parseDuration(json['duration']),
      thumbnail: json['thumbnail']?.toString(),
      language: json['language']?.toString() ?? '',
      premium: parseBool(json['premium']),
      featured: parseBool(json['featured']),
      categoryId: json['category_id'] != null ? parseInt(json['category_id']) : null,
      categoryName: json['category_name']?.toString(),
      categorySlug: json['category_slug']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}
