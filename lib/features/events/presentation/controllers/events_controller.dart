import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/event_item_model.dart';
import '../../data/services/events_api_service.dart';

class EventsController extends ChangeNotifier {
  EventsController({EventsApiService? service}) : _service = service ?? EventsApiService();

  final EventsApiService _service;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  EventItemModel? _featuredEvent;
  EventItemModel? get featuredEvent => _featuredEvent;

  List<EventItemModel> _events = [];
  List<EventItemModel> get events => _events;

  String? _selectedCategory;
  String? get selectedCategory => _selectedCategory;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  Timer? _debounceTimer;

  // Upcoming vs Past events
  List<EventItemModel> get upcomingEvents {
    final filtered = _filterByQuery(_events);
    final upcoming = filtered.where((e) => !e.isPast).toList();
    if (upcoming.isEmpty && filtered.isNotEmpty) {
      return filtered;
    }
    return upcoming;
  }

  List<EventItemModel> get pastEvents {
    final filtered = _filterByQuery(_events);
    final past = filtered.where((e) => e.isPast).toList();
    if (past.isEmpty && filtered.length > 2) {
      return filtered.skip(2).toList();
    }
    return past;
  }

  List<EventItemModel> _filterByQuery(List<EventItemModel> list) {
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.trim().toLowerCase();
    return list.where((item) =>
      item.title.toLowerCase().contains(q) ||
      item.shortDescription.toLowerCase().contains(q) ||
      item.category.toLowerCase().contains(q) ||
      item.venue.toLowerCase().contains(q)
    ).toList();
  }

  Future<void> loadInitialData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getFeaturedEvent(),
        _service.getEventsList(category: _selectedCategory, search: _searchQuery),
      ]);

      _featuredEvent = results[0] as EventItemModel?;
      _events = results[1] as List<EventItemModel>;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Unable to load events. Please check your connection.';
      notifyListeners();
    }
  }

  Future<void> selectCategory(String? category) async {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _events = await _service.getEventsList(
        category: _selectedCategory,
        search: _searchQuery,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Unable to load events for selected category.';
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
        _events = await _service.getEventsList(
          category: _selectedCategory,
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
