import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_config.dart';
import '../../data/models/course_api_model.dart';
import '../../../store/data/models/store_product_model.dart';
import '../../../library/data/models/library_item_model.dart';

/// Wishlist Item Model
class WishlistItem {
  const WishlistItem({
    required this.id,
    required this.title,
    required this.type,
    required this.price,
    this.originalPrice,
    this.imageUrl,
    this.subtitle,
  });

  final int id;
  final String title;
  final String type; // 'course', 'store', 'book'
  final double price;
  final double? originalPrice;
  final String? imageUrl;
  final String? subtitle;

  String? get resolvedImage => ApiConfig.resolveImageUrl(imageUrl);

  factory WishlistItem.fromCourse(CourseApiModel course) {
    return WishlistItem(
      id: course.id,
      title: course.title,
      type: 'course',
      price: course.effectivePrice,
      originalPrice: course.formattedOriginalPrice != null ? course.price : null,
      imageUrl: course.fullThumbnailUrl ?? course.fullHeroBannerUrl,
      subtitle: course.instructorName ?? course.categoryName ?? 'Zabira Course',
    );
  }

  factory WishlistItem.fromStoreProduct(StoreProductModel product) {
    return WishlistItem(
      id: product.id,
      title: product.name,
      type: 'store',
      price: product.effectivePrice,
      originalPrice: product.hasDiscount ? product.price : null,
      imageUrl: product.fullThumbnailUrl,
      subtitle: product.categoryName ?? 'Zabira Store',
    );
  }

  factory WishlistItem.fromBook(LibraryItemModel book) {
    final effectivePrice = (book.salePrice != null && book.salePrice! > 0) ? book.salePrice! : book.price;
    final hasDiscount = book.salePrice != null && book.salePrice! > 0 && book.salePrice! < book.price;
    return WishlistItem(
      id: book.id,
      title: book.title,
      type: 'book',
      price: effectivePrice,
      originalPrice: hasDiscount ? book.price : null,
      imageUrl: book.coverImage,
      subtitle: book.author.isNotEmpty ? book.author : 'Zabira Library',
    );
  }

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? 'Item',
      type: json['type']?.toString() ?? 'course',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      originalPrice: double.tryParse(json['original_price']?.toString() ?? ''),
      imageUrl: json['image_url']?.toString(),
      subtitle: json['subtitle']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'price': price,
        'original_price': originalPrice,
        'image_url': imageUrl,
        'subtitle': subtitle,
      };
}

/// Global Wishlist Controller
class WishlistController extends ChangeNotifier {
  WishlistController() {
    _loadFromPrefs();
  }

  final Map<String, WishlistItem> _items = {};

  List<WishlistItem> get items => _items.values.toList();
  int get count => _items.length;
  bool get isEmpty => _items.isEmpty;

  String _genKey(int id, String type) => '${type}_$id';

  bool isWishlisted(int id, {String type = 'course'}) {
    return _items.containsKey(_genKey(id, type)) || _items.containsKey(id.toString());
  }

  static const String _storageKey = 'zabira_wishlist_items_v2';

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey) ?? prefs.getString('zabira_wishlist_items');
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _items.clear();
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              final w = WishlistItem.fromJson(item);
              _items[_genKey(w.id, w.type)] = w;
            }
          }
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _items.values.map((e) => e.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(list));
    } catch (_) {}
  }

  bool toggleCourse(CourseApiModel course) {
    final key = _genKey(course.id, 'course');
    if (_items.containsKey(key)) {
      _items.remove(key);
      _saveToPrefs();
      notifyListeners();
      return false;
    } else {
      _items[key] = WishlistItem.fromCourse(course);
      _saveToPrefs();
      notifyListeners();
      return true;
    }
  }

  bool toggleStoreProduct(StoreProductModel product) {
    final key = _genKey(product.id, 'store');
    if (_items.containsKey(key)) {
      _items.remove(key);
      _saveToPrefs();
      notifyListeners();
      return false;
    } else {
      _items[key] = WishlistItem.fromStoreProduct(product);
      _saveToPrefs();
      notifyListeners();
      return true;
    }
  }

  bool isLibraryFavorite(int id) => isWishlisted(id, type: 'book');

  bool toggleLibraryItem(LibraryItemModel book) => toggleBook(book);

  bool toggleBook(LibraryItemModel book) {
    final key = _genKey(book.id, 'book');
    if (_items.containsKey(key)) {
      _items.remove(key);
      _saveToPrefs();
      notifyListeners();
      return false;
    } else {
      _items[key] = WishlistItem.fromBook(book);
      _saveToPrefs();
      notifyListeners();
      return true;
    }
  }

  bool toggleItem(WishlistItem item) {
    final key = _genKey(item.id, item.type);
    if (_items.containsKey(key)) {
      _items.remove(key);
      _saveToPrefs();
      notifyListeners();
      return false;
    } else {
      _items[key] = item;
      _saveToPrefs();
      notifyListeners();
      return true;
    }
  }

  void removeItem(int id, {String type = 'course'}) {
    final key = _genKey(id, type);
    _items.remove(key);
    _items.remove(id.toString());
    _saveToPrefs();
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _saveToPrefs();
    notifyListeners();
  }
}
