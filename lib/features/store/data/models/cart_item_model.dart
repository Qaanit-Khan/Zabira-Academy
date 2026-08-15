import '../../../../core/constants/api_config.dart';

/// Zabira Academy — Cart Item Model
class CartItemModel {
  const CartItemModel({
    required this.id,
    required this.title,
    required this.price,
    this.salePrice,
    this.quantity = 1,
    this.imageUrl,
    this.productId,
    this.storeProductId,
    this.variantId,
    this.variantName,
    this.bookId,
    this.bookFormat,
    this.courseId,
    this.productType,
  });

  final int id;
  final String title;
  final double price;
  final double? salePrice;
  final int quantity;
  final String? imageUrl;
  final int? productId;
  final int? storeProductId;
  final int? variantId;
  final String? variantName;
  final int? bookId;
  final String? bookFormat;
  final int? courseId;
  final String? productType;

  double get effectivePrice => (salePrice != null && salePrice! > 0) ? salePrice! : price;
  double get totalPrice => effectivePrice * quantity;

  String? get resolvedImage => ApiConfig.resolveImageUrl(imageUrl);

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['cart_id'] ?? json['item_id'] ?? 0;
    final id = int.tryParse(rawId.toString()) ?? 0;

    final title = json['title']?.toString() ??
        json['name']?.toString() ??
        json['product_name']?.toString() ??
        json['book_title']?.toString() ??
        json['course_title']?.toString() ??
        'Item';

    final price = double.tryParse(json['price']?.toString() ?? '0') ?? 0.0;
    final salePrice = double.tryParse(json['sale_price']?.toString() ?? '0');

    final quantity = int.tryParse(json['quantity']?.toString() ?? '1') ?? 1;

    final image = json['image']?.toString() ??
        json['image_url']?.toString() ??
        json['cover_image']?.toString() ??
        json['thumbnail']?.toString() ??
        json['photo_path']?.toString();

    final productId = int.tryParse(json['product_id']?.toString() ?? '');
    final storeProductId = int.tryParse(json['store_product_id']?.toString() ?? '');
    final variantId = int.tryParse(json['variant_id']?.toString() ?? json['store_variant_id']?.toString() ?? '');
    final variantName = json['variant_name']?.toString() ?? json['variant']?.toString();
    final bookId = int.tryParse(json['book_id']?.toString() ?? '');
    final bookFormat = json['format']?.toString() ?? json['book_format']?.toString();
    final courseId = int.tryParse(json['course_id']?.toString() ?? '');
    final productType = json['product_type']?.toString() ?? json['type']?.toString();

    return CartItemModel(
      id: id,
      title: title,
      price: price,
      salePrice: salePrice,
      quantity: quantity > 0 ? quantity : 1,
      imageUrl: image,
      productId: productId,
      storeProductId: storeProductId,
      variantId: variantId,
      variantName: variantName,
      bookId: bookId,
      bookFormat: bookFormat,
      courseId: courseId,
      productType: productType,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'price': price,
    'sale_price': salePrice,
    'quantity': quantity,
    'image': imageUrl,
    'product_id': productId,
    'store_product_id': storeProductId,
    'variant_id': variantId,
    'variant_name': variantName,
    'book_id': bookId,
    'book_format': bookFormat,
    'course_id': courseId,
    'product_type': productType,
  };
}

/// Cart Summary Model
class CartSummaryModel {
  const CartSummaryModel({
    required this.items,
    this.subtotal = 0.0,
    this.discount = 0.0,
    this.tax = 0.0,
    this.total = 0.0,
    this.count = 0,
  });

  final List<CartItemModel> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final int count;

  factory CartSummaryModel.fromJson(Map<String, dynamic> json) {
    List<CartItemModel> itemsList = [];
    final rawItems = json['items'] ?? json['data'] ?? json['cart_items'] ?? [];
    if (rawItems is List) {
      itemsList = rawItems
          .whereType<Map<String, dynamic>>()
          .map((e) => CartItemModel.fromJson(e))
          .toList();
    }

    final rawSubtotal = double.tryParse(json['subtotal']?.toString() ?? '');
    final rawTotal = double.tryParse(json['total']?.toString() ?? '');
    final rawDiscount = double.tryParse(json['discount']?.toString() ?? '');
    final rawTax = double.tryParse(json['tax']?.toString() ?? '');

    final calculatedSubtotal = itemsList.fold<double>(0.0, (sum, item) => sum + item.totalPrice);
    final finalSubtotal = rawSubtotal ?? calculatedSubtotal;
    final finalTotal = rawTotal ?? (finalSubtotal - (rawDiscount ?? 0.0) + (rawTax ?? 0.0));
    final calculatedCount = itemsList.fold<int>(0, (sum, item) => sum + item.quantity);

    return CartSummaryModel(
      items: itemsList,
      subtotal: finalSubtotal,
      discount: rawDiscount ?? 0.0,
      tax: rawTax ?? 0.0,
      total: finalTotal,
      count: int.tryParse(json['count']?.toString() ?? json['items_count']?.toString() ?? '') ?? calculatedCount,
    );
  }
}
