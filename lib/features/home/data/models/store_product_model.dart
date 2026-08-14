/// Data model for a single product shown in the "From Zabira Store" section.
class StoreProductModel {
  const StoreProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.imagePath,
  });

  final String id;
  final String name;
  final String category;
  final String price;

  /// Optional local asset path for a product thumbnail.
  /// If null, a code-designed placeholder is rendered.
  final String? imagePath;
}
