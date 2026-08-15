import 'package:flutter/foundation.dart';
import '../../data/models/enrolled_course_model.dart';
import '../../data/services/enrollment_api_service.dart';

/// Zabira Academy — Enrollment Controller
class EnrollmentController extends ChangeNotifier {
  EnrollmentController({EnrollmentApiService? service}) : _service = service ?? EnrollmentApiService();

  final EnrollmentApiService _service;

  List<EnrolledCourseModel> _enrolledCourses = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<EnrolledCourseModel> get enrolledCourses => List.unmodifiable(_enrolledCourses);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _enrolledCourses.isEmpty;

  bool isEnrolled(int courseId) {
    return _enrolledCourses.any((c) => c.courseId == courseId || c.id == courseId);
  }

  EnrolledCourseModel? getEnrolledCourse(int courseId) {
    try {
      return _enrolledCourses.firstWhere((c) => c.courseId == courseId || c.id == courseId);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadMyCourses(String? token) async {
    if (token == null || token.isEmpty) {
      _enrolledCourses = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _service.getMyCourses(token: token);
      _enrolledCourses = list;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Could not load enrolled courses.';
      notifyListeners();
    }
  }

  Future<bool> enrollInCourse({
    required int courseId,
    String? paymentPlan,
    String? planType,
    String? email,
    String? token,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.enrollInCourse(
        courseId: courseId,
        paymentPlan: paymentPlan,
        planType: planType,
        email: email,
        token: token,
      );
      // Refresh list to confirm enrollment
      await loadMyCourses(token);
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Enrollment failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _enrolledCourses.clear();
    _errorMessage = null;
    notifyListeners();
  }
}
