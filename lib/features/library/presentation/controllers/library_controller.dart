import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/library_category_model.dart';
import '../../data/models/library_item_model.dart';
import '../../data/services/library_api_service.dart';

class LibraryController extends ChangeNotifier {
  LibraryController({LibraryApiService? service}) : _service = service ?? LibraryApiService();

  final LibraryApiService _service;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  LibraryStatsModel _stats = const LibraryStatsModel();
  LibraryStatsModel get stats => _stats;

  List<LibraryCategoryModel> _categories = [];
  List<LibraryCategoryModel> get categories => _categories;

  List<LibraryItemModel> _items = [];
  List<LibraryItemModel> get items => _items;

  int? _selectedCategoryId;
  int? get selectedCategoryId => _selectedCategoryId;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  Timer? _debounceTimer;

  // Filtered lists
  List<LibraryItemModel> get allBooks => _filterByQuery(_items);

  List<LibraryItemModel> get featuredBooks {
    final filtered = _filterByQuery(_items);
    return filtered;
  }

  List<LibraryItemModel> get otherResources {
    final filtered = _filterByQuery(_items);
    if (filtered.length > 4) {
      return filtered.skip(4).toList();
    }
    return filtered;
  }

  List<LibraryItemModel> _filterByQuery(List<LibraryItemModel> list) {
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.trim().toLowerCase();
    return list.where((item) =>
      item.title.toLowerCase().contains(q) ||
      item.author.toLowerCase().contains(q) ||
      item.description.toLowerCase().contains(q) ||
      (item.categoryName?.toLowerCase().contains(q) ?? false)
    ).toList();
  }

  Future<void> loadInitialData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getCategories().catchError((e) {
          debugPrint('[LIBRARY CONTROLLER] Categories error: $e');
          return <LibraryCategoryModel>[];
        }),
        _service.getLibraryList(limit: 50, categoryId: _selectedCategoryId, search: _searchQuery),
        _service.getStats().catchError((e) {
          debugPrint('[LIBRARY CONTROLLER] Stats error: $e');
          return const LibraryStatsModel();
        }),
      ]);

      _categories = results[0] as List<LibraryCategoryModel>;
      _items = results[1] as List<LibraryItemModel>;
      _stats = results[2] as LibraryStatsModel;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Unable to load library books. Please check your connection.';
      notifyListeners();
    }
  }

  Future<void> selectCategory(int? categoryId) async {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _service.getLibraryList(
        categoryId: _selectedCategoryId,
        search: _searchQuery,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Unable to load resources for selected category.';
      notifyListeners();
    }
  }

  void onSearchChanged(String query) {
    _searchQuery = query;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      _isLoading = true;
      notifyListeners();
      try {
        _items = await _service.getLibraryList(
          categoryId: _selectedCategoryId,
          search: _searchQuery,
        );
        _isLoading = false;
        notifyListeners();
      } catch (e) {
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
