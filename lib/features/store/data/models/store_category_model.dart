import '../../../../core/constants/api_config.dart';

/// Category model mapped directly from `GET /store/public_categories.php`.
class StoreCategoryModel {
  const StoreCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.image,
    this.productCount = 0,
    this.status = 'active',
  });

  final int id;
  final String name;
  final String slug;
  final String? image;
  final int productCount;
  final String status;

  String? get fullImageUrl => ApiConfig.resolveImageUrl(image);

  factory StoreCategoryModel.fromJson(Map<String, dynamic> json) {
    return StoreCategoryModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      image: json['image']?.toString(),
      productCount: json['product_count'] is int
          ? json['product_count'] as int
          : int.tryParse(json['product_count']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'active',
    );
  }
}
