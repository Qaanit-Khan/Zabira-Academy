import '../../../../core/constants/api_config.dart';

/// Category model mapped directly from `GET /categories/list.php`.
class CourseCategoryApiModel {
  const CourseCategoryApiModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.bannerImage,
    this.description,
    this.sortOrder = 0,
    this.status = 'active',
  });

  final int id;
  final String name;
  final String slug;
  final String? icon;
  final String? bannerImage;
  final String? description;
  final int sortOrder;
  final String status;

  String? get fullIconUrl => ApiConfig.resolveImageUrl(icon);
  String? get fullBannerUrl => ApiConfig.resolveImageUrl(bannerImage);

  factory CourseCategoryApiModel.fromJson(Map<String, dynamic> json) {
    return CourseCategoryApiModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      icon: json['icon']?.toString(),
      bannerImage: json['banner_image']?.toString(),
      description: json['description']?.toString(),
      sortOrder: json['sort_order'] is int
          ? json['sort_order'] as int
          : int.tryParse(json['sort_order']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'active',
    );
  }
}
