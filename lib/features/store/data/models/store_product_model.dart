import '../../../../core/constants/api_config.dart';

/// Store Product Model mapped directly from Zabira Academy Store API
/// (`GET /store/public_list.php` and `GET /store/public_details.php`).
class StoreProductModel {
  const StoreProductModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.price,
    this.salePrice,
    this.stock = 0,
    this.lowStockThreshold = 5,
    this.sku,
    this.thumbnail,
    this.type = 'physical',
    this.fulfillmentType,
    this.publishStatus = 'published',
    this.isFeatured = false,
    this.isBestseller = false,
    this.isNew = false,
    this.categoryId,
    this.categoryName,
    this.categorySlug,
    this.galleryUrls = const [],
    this.localAssetFallback,
  });

  final int id;
  final String name;
  final String slug;
  final String? description;
  final double price;
  final double? salePrice;
  final int stock;
  final int lowStockThreshold;
  final String? sku;
  final String? thumbnail;
  final String type;
  final String? fulfillmentType;
  final String publishStatus;
  final bool isFeatured;
  final bool isBestseller;
  final bool isNew;
  final int? categoryId;
  final String? categoryName;
  final String? categorySlug;
  final List<String> galleryUrls;
  final String? localAssetFallback;

  /// Compatibility getters for home screen & existing widgets
  String get category => categoryName ?? 'Zabira Store';
  String? get imagePath => localAssetFallback;

  /// Resolved full thumbnail URL from API
  String? get fullThumbnailUrl => ApiConfig.resolveImageUrl(thumbnail);

  /// Resolved list of full gallery URLs
  List<String> get allImageUrls {
    final list = <String>[];
    final main = fullThumbnailUrl;
    if (main != null && main.isNotEmpty) {
      list.add(main);
    }
    for (final g in galleryUrls) {
      final resolved = ApiConfig.resolveImageUrl(g);
      if (resolved != null && resolved.isNotEmpty && !list.contains(resolved)) {
        list.add(resolved);
      }
    }
    return list;
  }

  /// Effective price considering sale discount
  double get effectivePrice => (salePrice != null && salePrice! > 0) ? salePrice! : price;

  /// Formatted current price for UI display (e.g. "₹69" or "₹1.50")
  String get formattedPrice {
    return _formatCurrency(effectivePrice);
  }

  /// Formatted original price (if on sale)
  String? get formattedOriginalPrice {
    if (salePrice != null && salePrice! > 0 && salePrice! < price) {
      return _formatCurrency(price);
    }
    return null;
  }

  /// Whether the item is on discount
  bool get hasDiscount => salePrice != null && salePrice! > 0 && salePrice! < price;

  /// Discount percentage
  int get discountPercent {
    if (!hasDiscount || price <= 0) return 0;
    return (((price - salePrice!) / price) * 100).round();
  }

  /// Stock status label
  bool get inStock => stock > 0;
  bool get isLowStock => stock > 0 && stock <= lowStockThreshold;

  static String _formatCurrency(double val) {
    if (val == val.roundToDouble()) {
      return '₹${val.toInt()}';
    }
    return '₹${val.toStringAsFixed(2)}';
  }

  factory StoreProductModel.fromJson(Map<String, dynamic> json) {
    // Parse price safely
    double parsePrice(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString().replaceAll('₹', '').replaceAll(',', '').trim()) ?? 0.0;
    }

    double? parseSalePrice(dynamic val) {
      if (val == null) return null;
      final parsed = parsePrice(val);
      return parsed > 0 ? parsed : null;
    }

    // Parse gallery URLs
    final gallery = <String>[];
    if (json['gallery_urls'] is List) {
      for (final item in json['gallery_urls'] as List) {
        if (item != null) gallery.add(item.toString());
      }
    } else if (json['gallery'] is List) {
      for (final item in json['gallery'] as List) {
        if (item is Map && item['image_url'] != null) {
          gallery.add(item['image_url'].toString());
        }
      }
    }

    return StoreProductModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      price: parsePrice(json['price']),
      salePrice: parseSalePrice(json['sale_price']),
      stock: json['stock'] is int ? json['stock'] as int : int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
      lowStockThreshold: json['low_stock_threshold'] is int
          ? json['low_stock_threshold'] as int
          : int.tryParse(json['low_stock_threshold']?.toString() ?? '5') ?? 5,
      sku: json['sku']?.toString(),
      thumbnail: json['thumbnail']?.toString(),
      type: json['type']?.toString() ?? 'physical',
      fulfillmentType: json['fulfillment_type']?.toString(),
      publishStatus: json['publish_status']?.toString() ?? 'published',
      isFeatured: json['is_featured'] == 1 || json['is_featured'] == true || json['is_featured'] == '1',
      isBestseller: json['is_bestseller'] == 1 || json['is_bestseller'] == true || json['is_bestseller'] == '1',
      isNew: json['is_new'] == 1 || json['is_new'] == true || json['is_new'] == '1',
      categoryId: json['category_id'] is int
          ? json['category_id'] as int
          : int.tryParse(json['category_id']?.toString() ?? ''),
      categoryName: json['category_name']?.toString(),
      categorySlug: json['category_slug']?.toString(),
      galleryUrls: gallery,
    );
  }
}
