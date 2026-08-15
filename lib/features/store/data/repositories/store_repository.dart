import '../models/store_category_model.dart';
import '../models/store_product_model.dart';
import '../services/store_service.dart';

/// Repository for Store operations, abstracting network calls and parsing.
class StoreRepository {
  StoreRepository({StoreService? service}) : _service = service ?? StoreService();

  final StoreService _service;

  /// Fetch public store categories
  Future<List<StoreCategoryModel>> getCategories() async {
    final response = await _service.getCategories();
    if (response['success'] == true && response['data'] != null) {
      final dynamic data = response['data'];
      final List? items = data is List
          ? data
          : (data is Map ? (data['items'] ?? data['categories'] ?? data['data']) as List? : null);
      if (items != null) {
        return items
            .whereType<Map<String, dynamic>>()
            .map(StoreCategoryModel.fromJson)
            .toList();
      }
    }
    return [];
  }

  /// Fetch public store products with optional filters
  Future<List<StoreProductModel>> getProducts({
    int page = 1,
    int limit = 20,
    String? search,
    int? categoryId,
    String? category,
    String? featured,
    String? bestseller,
    String? isNew,
    String? sort,
    String? dir,
  }) async {
    final response = await _service.getProducts(
      page: page,
      limit: limit,
      search: search,
      categoryId: categoryId,
      category: category,
      featured: featured,
      bestseller: bestseller,
      isNew: isNew,
      sort: sort,
      dir: dir,
    );

    if (response['success'] == true && response['data'] != null) {
      final dynamic data = response['data'];
      final List? items = data is List
          ? data
          : (data is Map ? (data['items'] ?? data['products'] ?? data['data']) as List? : null);
      if (items != null) {
        return items
            .whereType<Map<String, dynamic>>()
            .map(StoreProductModel.fromJson)
            .toList();
      }
    }
    return [];
  }

  /// Fetch detailed information for a single product by ID or slug
  Future<StoreProductModel> getProductDetails(int id) async {
    final response = await _service.getProductDetails(id: id);
    if (response['success'] == true && response['data'] != null) {
      final dynamic data = response['data'];
      final Map<String, dynamic>? item = data is Map
          ? (data['item'] ?? data['product'] ?? data) as Map<String, dynamic>?
          : null;
      if (item != null) {
        return StoreProductModel.fromJson(item);
      }
    }
    throw Exception('Product details not found');
  }

  /// Prepare purchase order
  Future<Map<String, dynamic>> purchase({
    required int storeProductId,
    int? storeVariantId,
    int quantity = 1,
    String? authToken,
  }) async {
    return _service.purchaseProduct(
      storeProductId: storeProductId,
      storeVariantId: storeVariantId,
      quantity: quantity,
      authToken: authToken,
    );
  }
}
