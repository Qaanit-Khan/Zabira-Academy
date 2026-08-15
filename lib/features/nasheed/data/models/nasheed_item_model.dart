import '../../../../core/constants/api_config.dart';

/// Nasheed track item from Zabira Academy API
class NasheedItemModel {
  const NasheedItemModel({
    required this.id,
    required this.title,
    required this.slug,
    this.type = 'audio',
    this.description = '',
    this.fileUrl = '',
    this.duration = 0,
    this.language = '',
    this.thumbnail,
    this.premium = false,
    this.downloadAllowed = false,
    this.featured = false,
    this.categoryId,
    this.categoryName,
    this.categorySlug,
    this.artist = 'Zabira Academy',
  });

  final int id;
  final String title;
  final String slug;
  final String type;
  final String description;
  final String fileUrl;
  final int duration; // in seconds
  final String language;
  final String? thumbnail;
  final bool premium;
  final bool downloadAllowed;
  final bool featured;
  final int? categoryId;
  final String? categoryName;
  final String? categorySlug;
  final String artist;

  /// Resolved audio file URL for streaming
  String get resolvedAudioUrl {
    if (fileUrl.isEmpty) return '';
    final trimmed = fileUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      return '${ApiConfig.assetBaseUrl}$trimmed';
    }
    return '${ApiConfig.assetBaseUrl}/$trimmed';
  }

  /// Resolved thumbnail image URL
  String? get resolvedThumbnail => ApiConfig.resolveImageUrl(thumbnail);

  /// Format duration into mm:ss
  String get formattedDuration {
    if (duration <= 0) return '03:45';
    final m = duration ~/ 60;
    final s = duration % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  factory NasheedItemModel.fromJson(Map<String, dynamic> json) {
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

    return NasheedItemModel(
      id: parseInt(json['id']),
      title: json['title']?.toString() ?? 'Nasheed',
      slug: json['slug']?.toString() ?? '',
      type: json['type']?.toString() ?? 'audio',
      description: json['description']?.toString() ?? '',
      fileUrl: json['file_url']?.toString() ?? json['audio_url']?.toString() ?? '',
      duration: parseInt(json['duration']),
      language: json['language']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString() ?? json['image_url']?.toString(),
      premium: parseBool(json['premium']),
      downloadAllowed: parseBool(json['download_allowed']),
      featured: parseBool(json['featured']),
      categoryId: json['category_id'] != null ? parseInt(json['category_id']) : null,
      categoryName: json['category_name']?.toString(),
      categorySlug: json['category_slug']?.toString(),
      artist: json['artist']?.toString() ?? 'Zabira Academy',
    );
  }
}
