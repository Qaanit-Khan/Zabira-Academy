/// Nasheed category model
class NasheedCategoryModel {
  const NasheedCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
  });

  final int id;
  final String name;
  final String slug;

  factory NasheedCategoryModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    }

    return NasheedCategoryModel(
      id: parseInt(json['id']),
      name: json['name']?.toString() ?? 'Category',
      slug: json['slug']?.toString() ?? '',
    );
  }
}
