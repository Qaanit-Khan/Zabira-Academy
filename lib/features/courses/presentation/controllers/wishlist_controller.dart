import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_config.dart';
import '../../data/models/course_api_model.dart';

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

  final Map<int, WishlistItem> _items = {};

  List<WishlistItem> get items => _items.values.toList();
  int get count => _items.length;
  bool get isEmpty => _items.isEmpty;

  bool isWishlisted(int id) => _items.containsKey(id);

  static const String _storageKey = 'zabira_wishlist_items';

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _items.clear();
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              final w = WishlistItem.fromJson(item);
              _items[w.id] = w;
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
    if (_items.containsKey(course.id)) {
      _items.remove(course.id);
      _saveToPrefs();
      notifyListeners();
      return false;
    } else {
      _items[course.id] = WishlistItem.fromCourse(course);
      _saveToPrefs();
      notifyListeners();
      return true;
    }
  }

  bool toggleItem(WishlistItem item) {
    if (_items.containsKey(item.id)) {
      _items.remove(item.id);
      _saveToPrefs();
      notifyListeners();
      return false;
    } else {
      _items[item.id] = item;
      _saveToPrefs();
      notifyListeners();
      return true;
    }
  }

  void removeItem(int id) {
    if (_items.containsKey(id)) {
      _items.remove(id);
      _saveToPrefs();
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    _saveToPrefs();
    notifyListeners();
  }
}
