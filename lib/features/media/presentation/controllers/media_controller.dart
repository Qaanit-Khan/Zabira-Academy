import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/media_category_model.dart';
import '../../data/models/media_item_model.dart';
import '../../data/services/media_api_service.dart';

class MediaController extends ChangeNotifier {
  MediaController({MediaApiService? service}) : _service = service ?? MediaApiService();

  final MediaApiService _service;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<MediaCategoryModel> _categories = [];
  List<MediaCategoryModel> get categories => _categories;

  List<MediaItemModel> _mediaList = [];
  List<MediaItemModel> get mediaList => _mediaList;

  int? _selectedCategoryId;
  int? get selectedCategoryId => _selectedCategoryId;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  Timer? _debounceTimer;

  // Filtered lists
  List<MediaItemModel> get latestVideos {
    final filtered = _filterByQuery(_mediaList);
    return filtered.where((m) => !m.isShort).toList();
  }

  List<MediaItemModel> get shorts {
    final filtered = _filterByQuery(_mediaList);
    final shortsList = filtered.where((m) => m.isShort).toList();
    if (shortsList.isEmpty && filtered.isNotEmpty) {
      return filtered.take(5).toList();
    }
    return shortsList;
  }

  List<MediaItemModel> _filterByQuery(List<MediaItemModel> list) {
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.trim().toLowerCase();
    return list.where((item) =>
      item.title.toLowerCase().contains(q) ||
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
          debugPrint('[MEDIA CONTROLLER] Categories error: $e');
          return <MediaCategoryModel>[];
        }),
        _service.getMediaList(categoryId: _selectedCategoryId, search: _searchQuery),
      ]);

      _categories = results[0] as List<MediaCategoryModel>;
      _mediaList = results[1] as List<MediaItemModel>;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Unable to load media content. Please check your connection.';
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
      _mediaList = await _service.getMediaList(
        categoryId: _selectedCategoryId,
        search: _searchQuery,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Unable to load videos for selected category.';
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
        _mediaList = await _service.getMediaList(
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
