import '../../../../core/constants/api_config.dart';

/// Format option for a library book / resource (e.g. PDF, Paperback, Hardcover)
class LibraryBookFormat {
  const LibraryBookFormat({
    required this.format,
    required this.enabled,
    required this.price,
    this.salePrice,
    this.stock = 0,
  });

  final String format;
  final bool enabled;
  final double price;
  final double? salePrice;
  final int stock;

  factory LibraryBookFormat.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    bool parseBool(dynamic val) {
      if (val == null) return false;
      if (val is bool) return val;
      return val.toString() == '1' || val.toString().toLowerCase() == 'true';
    }

    return LibraryBookFormat(
      format: json['format']?.toString() ?? 'pdf',
      enabled: parseBool(json['enabled']),
      price: parseDouble(json['price']),
      salePrice: json['sale_price'] != null ? parseDouble(json['sale_price']) : null,
      stock: json['stock'] is int ? json['stock'] as int : int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
    );
  }
}

/// Book / learning resource item from Zabira Academy Library API
class LibraryItemModel {
  const LibraryItemModel({
    required this.id,
    required this.title,
    required this.slug,
    this.author = 'Zabira Academy',
    this.languages = const [],
    this.description = '',
    this.coverImage,
    this.fileUrl,
    this.previewUrl,
    this.premium = false,
    this.downloadAllowed = false,
    this.purchaseRequired = false,
    this.price = 0.0,
    this.salePrice,
    this.categoryId,
    this.categoryName,
    this.categorySlug,
    this.collectionId,
    this.collectionName,
    this.formats = const [],
    this.images = const [],
  });

  final int id;
  final String title;
  final String slug;
  final String author;
  final List<String> languages;
  final String description;
  final String? coverImage;
  final String? fileUrl;
  final String? previewUrl;
  final bool premium;
  final bool downloadAllowed;
  final bool purchaseRequired;
  final double price;
  final double? salePrice;
  final int? categoryId;
  final String? categoryName;
  final String? categorySlug;
  final int? collectionId;
  final String? collectionName;
  final List<LibraryBookFormat> formats;
  final List<String> images;

  /// Resolved cover image URL
  String? get resolvedCoverImage => ApiConfig.resolveImageUrl(coverImage);

  /// Resolved PDF / Download file URL
  String? get resolvedFileUrl => ApiConfig.resolveImageUrl(fileUrl);

  /// Resolved PDF Preview URL
  String? get resolvedPreviewUrl => ApiConfig.resolveImageUrl(previewUrl);

  /// Display price in INR (₹)
  String get formattedPrice {
    final effectivePrice = salePrice ?? price;
    return '₹${effectivePrice.toStringAsFixed(0)}';
  }

  /// Clean HTML-stripped description for snippets
  String get cleanDescription {
    return description.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').trim();
  }

  factory LibraryItemModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    }

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    bool parseBool(dynamic val) {
      if (val == null) return false;
      if (val is bool) return val;
      if (val is num) return val == 1;
      return val.toString() == '1' || val.toString().toLowerCase() == 'true';
    }

    final langs = <String>[];
    if (json['languages'] is List) {
      for (final l in json['languages'] as List) {
        if (l != null) langs.add(l.toString());
      }
    }

    final fmtList = <LibraryBookFormat>[];
    if (json['formats'] is List) {
      for (final f in json['formats'] as List) {
        if (f is Map<String, dynamic>) {
          fmtList.add(LibraryBookFormat.fromJson(f));
        }
      }
    }

    final imgList = <String>[];
    if (json['images'] is List) {
      for (final img in json['images'] as List) {
        if (img is Map<String, dynamic> && img['image_path'] != null) {
          imgList.add(img['image_path'].toString());
        }
      }
    }

    return LibraryItemModel(
      id: parseInt(json['id']),
      title: json['title']?.toString() ?? 'Untitled Resource',
      slug: json['slug']?.toString() ?? '',
      author: json['author']?.toString() ?? 'Zabira Academy',
      languages: langs,
      description: json['description']?.toString() ?? '',
      coverImage: json['cover_image']?.toString(),
      fileUrl: json['file_url']?.toString(),
      previewUrl: json['preview_url']?.toString(),
      premium: parseBool(json['premium']),
      downloadAllowed: parseBool(json['download_allowed']),
      purchaseRequired: parseBool(json['purchase_required']),
      price: parseDouble(json['price']),
      salePrice: json['sale_price'] != null ? parseDouble(json['sale_price']) : null,
      categoryId: json['category_id'] != null ? parseInt(json['category_id']) : null,
      categoryName: json['category_name']?.toString(),
      categorySlug: json['category_slug']?.toString(),
      collectionId: json['collection_id'] != null ? parseInt(json['collection_id']) : null,
      collectionName: json['collection_name']?.toString(),
      formats: fmtList,
      images: imgList,
    );
  }
}
