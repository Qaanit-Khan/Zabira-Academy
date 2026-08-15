import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/nasheed_category_model.dart';
import '../../data/models/nasheed_item_model.dart';
import '../../data/services/nasheed_api_service.dart';

class NasheedController extends ChangeNotifier {
  NasheedController({NasheedApiService? service}) : _service = service ?? NasheedApiService();

  final NasheedApiService _service;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<NasheedCategoryModel> _categories = [];
  List<NasheedCategoryModel> get categories => _categories;

  List<NasheedItemModel> _nasheedList = [];
  List<NasheedItemModel> get nasheedList => _nasheedList;

  int? _selectedCategoryId;
  int? get selectedCategoryId => _selectedCategoryId;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  Timer? _debounceTimer;

  List<NasheedItemModel> get filteredNasheeds {
    if (_searchQuery.trim().isEmpty) return _nasheedList;
    final q = _searchQuery.trim().toLowerCase();
    return _nasheedList.where((item) =>
      item.title.toLowerCase().contains(q) ||
      item.artist.toLowerCase().contains(q) ||
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
          debugPrint('[NASHEED CONTROLLER] Categories error: $e');
          return <NasheedCategoryModel>[];
        }),
        _service.getNasheedList(categoryId: _selectedCategoryId, search: _searchQuery),
      ]);

      _categories = results[0] as List<NasheedCategoryModel>;
      _nasheedList = results[1] as List<NasheedItemModel>;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Unable to load nasheeds. Please check your connection.';
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
      _nasheedList = await _service.getNasheedList(
        categoryId: _selectedCategoryId,
        search: _searchQuery,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Unable to load nasheeds for selected category.';
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
        _nasheedList = await _service.getNasheedList(
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
