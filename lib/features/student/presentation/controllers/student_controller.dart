import 'package:flutter/foundation.dart';
import '../../data/models/student_dashboard_model.dart';
import '../../data/services/student_api_service.dart';

enum StudentDashboardState { initial, loading, loaded, error }

/// Controller managing Student Dashboard state
class StudentController extends ChangeNotifier {
  StudentController({StudentApiService? service})
      : _service = service ?? StudentApiService();

  final StudentApiService _service;

  StudentDashboardState _state = StudentDashboardState.initial;
  StudentDashboardModel? _dashboard;
  String? _errorMessage;
  int _selectedFilterIndex = 0;

  StudentDashboardState get state => _state;
  StudentDashboardModel? get dashboard => _dashboard;
  String? get errorMessage => _errorMessage;
  int get selectedFilterIndex => _selectedFilterIndex;
  bool get isLoading => _state == StudentDashboardState.loading;

  void setFilterIndex(int index) {
    _selectedFilterIndex = index;
    notifyListeners();
  }

  Future<void> loadDashboard(
    String? token, {
    String? defaultName,
    String? defaultEmail,
    String? defaultPhoto,
    bool forceRefresh = false,
  }) async {
    if (token == null || token.isEmpty) {
      _state = StudentDashboardState.error;
      _errorMessage = 'Session required. Please sign in.';
      notifyListeners();
      return;
    }

    if (_state == StudentDashboardState.loading && !forceRefresh) return;

    _state = StudentDashboardState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _service.getDashboard(
        token: token,
        defaultName: defaultName,
        defaultEmail: defaultEmail,
        defaultPhoto: defaultPhoto,
      );
      _dashboard = data;
      _state = StudentDashboardState.loaded;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _state = StudentDashboardState.error;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
    }
  }

  Future<void> markNotificationsRead(String? token) async {
    if (token == null || token.isEmpty) return;
    try {
      await _service.markNotificationsRead(token: token);
      if (_dashboard != null) {
        final updatedNotifs = _dashboard!.notifications
            .map((n) => StudentNotificationItem(
                  id: n.id,
                  title: n.title,
                  message: n.message,
                  type: n.type,
                  createdAt: n.createdAt,
                  isRead: true,
                ))
            .toList();
        _dashboard = _dashboard!.copyWith(notifications: updatedNotifs);
        notifyListeners();
      }
    } catch (_) {}
  }
}
