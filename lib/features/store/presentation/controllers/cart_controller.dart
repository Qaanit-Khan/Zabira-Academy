import 'package:flutter/foundation.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/services/cart_api_service.dart';

/// Zabira Academy — Global Cart Controller
class CartController extends ChangeNotifier {
  CartController({CartApiService? service}) : _service = service ?? CartApiService();

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

  /// Load authenticated cart from backend
  Future<void> loadCart(String? token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final summary = await _service.getCartList(token: token);
      _items = summary.items;
      _subtotal = summary.subtotal;
      _discount = summary.discount;
      _tax = summary.tax;
      _total = summary.total;
      _itemCount = summary.count > 0 ? summary.count : _items.fold<int>(0, (sum, i) => sum + i.quantity);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Could not load cart items.';
      notifyListeners();
    }
  }

  /// Fetch only the badge count
  Future<void> refreshCount(String? token) async {
    try {
      final count = await _service.getCartCount(token: token);
      _itemCount = count;
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
    notifyListeners();

    try {
      await _service.addToCart(itemData: itemData, token: token);
      // Reload cart to get authoritative updated summary and items
      await loadCart(token);
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to add item to cart.';
      notifyListeners();
      return false;
    }
  }

  /// Remove item from cart
  Future<bool> removeItem(CartItemModel item, String? token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.removeFromCart(
        cartId: item.id,
        bookId: item.bookId,
        format: item.bookFormat,
        courseId: item.courseId,
        token: token,
      );
      await loadCart(token);
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to remove item.';
      notifyListeners();
      return false;
    }
  }

  /// Clear entire cart
  Future<void> clearCart(String? token) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.clearCart(token: token);
      _items.clear();
      _subtotal = 0.0;
      _discount = 0.0;
      _tax = 0.0;
      _total = 0.0;
      _itemCount = 0;
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset state on Logout
  void reset() {
    _items.clear();
    _subtotal = 0.0;
    _discount = 0.0;
    _tax = 0.0;
    _total = 0.0;
    _itemCount = 0;
    _errorMessage = null;
    notifyListeners();
  }
}
