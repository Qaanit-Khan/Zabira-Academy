/// Media Category Model
class MediaCategoryModel {
  const MediaCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.parentId,
    this.displayOrder = 0,
  });

  final int id;
  final String name;
  final String slug;
  final int? parentId;
  final int displayOrder;

  factory MediaCategoryModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    }

    return MediaCategoryModel(
      id: parseInt(json['id']),
      name: json['name']?.toString() ?? 'Category',
      slug: json['slug']?.toString() ?? '',
      parentId: json['parent_id'] != null ? parseInt(json['parent_id']) : null,
      displayOrder: parseInt(json['display_order']),
    );
  }
}
