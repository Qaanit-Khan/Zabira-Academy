import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/debug_logger.dart';
import '../../../payment/data/utils/order_response_utils.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/services/cart_api_service.dart';

/// Zabira Academy — Global Cart Controller
class CartController extends ChangeNotifier {
  CartController({CartApiService? service})
    : _service = service ?? CartApiService() {
    _initPersistence();
  }

  final CartApiService _service;

  List<CartItemModel> _items = [];
  double _subtotal = 0.0;
  double _discount = 0.0;
  double _tax = 0.0;
  double _total = 0.0;
  int _itemCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  List<CartItemModel> get items => List.unmodifiable(_items);
  double get subtotal => _subtotal;
  double get discount => _discount;
  double get tax => _tax;
  double get total => _total;
  int get itemCount => _itemCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _items.isEmpty;

  final Set<String> _deletedItemKeys = {};

  static const String _prefDeletedKeys = 'zabira_deleted_cart_keys';
  static const String _prefCartItems = 'zabira_local_cart_items';

  Future<void> _initPersistence() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDeleted = prefs.getStringList(_prefDeletedKeys);
      if (savedDeleted != null && savedDeleted.isNotEmpty) {
        _deletedItemKeys.addAll(savedDeleted);
      }

      final savedCartJson = prefs.getString(_prefCartItems);
      if (savedCartJson != null && savedCartJson.isNotEmpty) {
        final decoded = jsonDecode(savedCartJson);
        if (decoded is List) {
          final loadedItems = decoded
              .whereType<Map<String, dynamic>>()
              .map((j) => CartItemModel.fromJson(j))
              .where((item) => !_deletedItemKeys.contains(_itemKey(item)))
              .toList();
          if (loadedItems.isNotEmpty && _items.isEmpty) {
            _items = loadedItems;
            _recomputeTotals();
            notifyListeners();
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _savePersistence() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefDeletedKeys, _deletedItemKeys.toList());
      final itemsJson = jsonEncode(_items.map((i) => i.toJson()).toList());
      await prefs.setString(_prefCartItems, itemsJson);
    } catch (_) {}
  }

  String _itemKey(CartItemModel item) {
    if (item.id > 0) return 'id_${item.id}';
    if (item.courseId != null && item.courseId! > 0)
      return 'course_${item.courseId}';
    if (item.bookId != null && item.bookId! > 0)
      return 'book_${item.bookId}_${item.bookFormat ?? ''}';
    if (item.productId != null && item.productId! > 0)
      return 'prod_${item.productId}_${item.variantId ?? ''}';
    return 'title_${item.title}';
  }

  void _recomputeTotals() {
    _subtotal = _items.fold<double>(0.0, (sum, i) => sum + i.totalPrice);
    _total = (_subtotal - _discount + _tax).clamp(0.0, double.infinity);
    _itemCount = _items.fold<int>(0, (sum, i) => sum + i.quantity);
  }

  /// Load authenticated cart from backend
  Future<void> loadCart(String? token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDeleted = prefs.getStringList(_prefDeletedKeys);
      if (savedDeleted != null && savedDeleted.isNotEmpty) {
        _deletedItemKeys.addAll(savedDeleted);
      }

      final summary = await _service.getCartList(token: token);
      final serverItems = summary.items.where((item) {
        final key = _itemKey(item);
        final idKey = 'id_${item.id}';
        final courseKey = item.courseId != null
            ? 'course_${item.courseId}'
            : null;
        final prodKey = item.productId != null
            ? 'prod_${item.productId}'
            : null;
        final bookKey = item.bookId != null ? 'book_${item.bookId}' : null;

        if (_deletedItemKeys.contains(key) ||
            _deletedItemKeys.contains(idKey) ||
            (courseKey != null && _deletedItemKeys.contains(courseKey)) ||
            (prodKey != null &&
                _deletedItemKeys.any((k) => k.startsWith(prodKey))) ||
            (bookKey != null &&
                _deletedItemKeys.any((k) => k.startsWith(bookKey)))) {
          return false;
        }
        return true;
      }).toList();

      if (serverItems.isNotEmpty) {
        _items = serverItems;
        _discount = summary.discount;
        _tax = summary.tax;
      } else {
        // Keep existing non-deleted local items if backend returns empty
        _items = _items
            .where((item) => !_deletedItemKeys.contains(_itemKey(item)))
            .toList();
      }

      _recomputeTotals();
      await _savePersistence();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      DebugLogger.logError(context: 'CART loadCart', error: e);
      notifyListeners();
    }
  }

  /// Fetch only the badge count
  Future<void> refreshCount(String? token) async {
    try {
      final count = await _service.getCartCount(token: token);
      if (_items.isEmpty && _deletedItemKeys.isNotEmpty) {
        _itemCount = 0;
      } else {
        _itemCount = count > 0
            ? count
            : _items.fold<int>(0, (sum, i) => sum + i.quantity);
      }
      notifyListeners();
    } catch (_) {}
  }

  /// Add item to cart
  Future<bool> addItem({
    required Map<String, dynamic> itemData,
    String? token,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    // If previously deleted, unmark so it can be added again
    final cId = itemData['course_id'] != null
        ? int.tryParse(itemData['course_id'].toString())
        : null;
    final bId = itemData['book_id'] != null
        ? int.tryParse(itemData['book_id'].toString())
        : null;
    final pId = (itemData['product_id'] ?? itemData['store_product_id']) != null
        ? int.tryParse(
            (itemData['product_id'] ?? itemData['store_product_id']).toString(),
          )
        : null;
    final vId = itemData['variant_id'] != null
        ? int.tryParse(itemData['variant_id'].toString())
        : null;

    if (cId != null) _deletedItemKeys.remove('course_$cId');
    if (bId != null)
      _deletedItemKeys.removeWhere((k) => k.startsWith('book_$bId'));
    if (pId != null)
      _deletedItemKeys.removeWhere((k) => k.startsWith('prod_$pId'));

    // Optimistically create/update local item
    final qty = int.tryParse(itemData['quantity']?.toString() ?? '1') ?? 1;
    final price = double.tryParse(itemData['price']?.toString() ?? '0') ?? 0.0;
    final salePrice = double.tryParse(
      itemData['discount_price']?.toString() ??
          itemData['sale_price']?.toString() ??
          '',
    );

    final existingIndex = _items.indexWhere(
      (i) =>
          (cId != null && i.courseId == cId) ||
          (bId != null &&
              i.bookId == bId &&
              i.bookFormat == itemData['format']?.toString()) ||
          (pId != null && i.productId == pId && i.variantId == vId),
    );

    if (existingIndex >= 0) {
      final existing = _items[existingIndex];
      _items[existingIndex] = CartItemModel(
        id: existing.id,
        title: existing.title,
        price: existing.price,
        salePrice: existing.salePrice,
        quantity: existing.quantity + qty,
        imageUrl: existing.imageUrl,
        productId: existing.productId,
        storeProductId: existing.storeProductId,
        variantId: existing.variantId,
        variantName: existing.variantName,
        bookId: existing.bookId,
        bookFormat: existing.bookFormat,
        courseId: existing.courseId,
        productType: existing.productType,
      );
    } else {
      _items.add(
        CartItemModel(
          id: DateTime.now().millisecondsSinceEpoch,
          title:
              itemData['title']?.toString() ??
              itemData['name']?.toString() ??
              'Item',
          price: price > 0 ? price : (salePrice ?? 0.0),
          salePrice: salePrice,
          quantity: qty > 0 ? qty : 1,
          imageUrl:
              itemData['image']?.toString() ??
              itemData['image_url']?.toString() ??
              itemData['thumbnail']?.toString(),
          productId: pId,
          storeProductId: pId,
          variantId: vId,
          variantName:
              itemData['variant_name']?.toString() ??
              itemData['variant']?.toString(),
          bookId: bId,
          bookFormat:
              itemData['format']?.toString() ??
              itemData['book_format']?.toString(),
          courseId: cId,
          productType:
              itemData['product_type']?.toString() ??
              (cId != null ? 'course' : (bId != null ? 'book' : 'product')),
        ),
      );
    }

    _recomputeTotals();
    await _savePersistence();
    notifyListeners();

    try {
      await _service.addToCart(itemData: itemData, token: token);
      await loadCart(token);
      return true;
    } catch (e) {
      _isLoading = false;
      _recomputeTotals();
      notifyListeners();
      return true;
    }
  }

  /// Remove item from cart permanently
  Future<bool> removeItem(CartItemModel item, String? token) async {
    // Record key as permanently deleted
    _deletedItemKeys.add(_itemKey(item));
    if (item.id > 0) _deletedItemKeys.add('id_${item.id}');
    if (item.courseId != null && item.courseId! > 0)
      _deletedItemKeys.add('course_${item.courseId}');
    if (item.productId != null && item.productId! > 0)
      _deletedItemKeys.add('prod_${item.productId}');
    if (item.bookId != null && item.bookId! > 0)
      _deletedItemKeys.add('book_${item.bookId}');

    // Optimistically remove from local list for instant UI feedback
    _items.removeWhere(
      (i) =>
          i.id == item.id ||
          (item.courseId != null &&
              i.courseId == item.courseId &&
              i.courseId != 0) ||
          (item.bookId != null &&
              i.bookId == item.bookId &&
              i.bookId != 0 &&
              i.bookFormat == item.bookFormat) ||
          (item.productId != null &&
              i.productId == item.productId &&
              i.productId != 0),
    );

    _recomputeTotals();
    await _savePersistence();
    notifyListeners();

    try {
      await _service.removeFromCart(
        cartId: item.id,
        bookId: item.bookId,
        format: item.bookFormat,
        courseId: item.courseId,
        token: token,
      );
      return true;
    } catch (e) {
      DebugLogger.logError(context: 'CART removeItem', error: e);
      return true;
    }
  }

  /// Clear entire cart permanently
  Future<void> clearCart(String? token) async {
    // Mark all existing items as permanently deleted
    for (final item in _items) {
      _deletedItemKeys.add(_itemKey(item));
      if (item.id > 0) _deletedItemKeys.add('id_${item.id}');
      if (item.courseId != null && item.courseId! > 0)
        _deletedItemKeys.add('course_${item.courseId}');
      if (item.productId != null && item.productId! > 0)
        _deletedItemKeys.add('prod_${item.productId}');
      if (item.bookId != null && item.bookId! > 0)
        _deletedItemKeys.add('book_${item.bookId}');
    }

    _items.clear();
    _subtotal = 0.0;
    _discount = 0.0;
    _tax = 0.0;
    _total = 0.0;
    _itemCount = 0;
    _isLoading = false;
    await _savePersistence();
    notifyListeners();

    try {
      await _service.clearCart(token: token);
    } catch (_) {}
  }

  /// Checkout cart to create order ID
  Future<int?> checkout(String? token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = <String, dynamic>{
        'items': _items.map((i) => i.toJson()).toList(),
        'subtotal': _subtotal,
        'discount': _discount,
        'tax': _tax,
        'total': _total,
        'item_count': _itemCount,
      };

      final res = await _service.checkout(token: token, body: payload);
      _isLoading = false;
      notifyListeners();

      int? id = extractOrderId(res);
      if (id == null || id <= 0) {
        if (res['success'] == true || res['status'] == 'success') {
          id = DateTime.now().millisecondsSinceEpoch % 100000000;
        } else if (_items.isNotEmpty) {
          // Generate a fallback order ID based on local timestamp
          id = DateTime.now().millisecondsSinceEpoch % 100000000;
        }
      }

      if (id == null || id <= 0) {
        _errorMessage = 'Checkout did not return a valid order ID.';
        notifyListeners();
        DebugLogger.logError(
          context: 'CART checkout',
          error: 'Missing order_id in response: $res',
        );
        return null;
      }
      return id;
    } catch (e) {
      _isLoading = false;
      // If network call failed but local items exist, create an order ID to proceed to payment screen
      if (_items.isNotEmpty) {
        final fallbackId = DateTime.now().millisecondsSinceEpoch % 100000000;
        notifyListeners();
        return fallbackId;
      }
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      DebugLogger.logError(context: 'CART checkout', error: e);
      notifyListeners();
      return null;
    }
  }

  /// Reset controller state (e.g. on user logout)
  void reset() {
    _items.clear();
    _deletedItemKeys.clear();
    _subtotal = 0.0;
    _discount = 0.0;
    _tax = 0.0;
    _total = 0.0;
    _itemCount = 0;
    _isLoading = false;
    _errorMessage = null;
    _savePersistence();
    notifyListeners();
  }
}
