import 'package:flutter/foundation.dart';
import '../../../payment/data/utils/order_response_utils.dart';
import '../../data/models/enrolled_course_model.dart';
import '../../data/services/enrollment_api_service.dart';

/// Zabira Academy — Enrollment Controller
class EnrollmentController extends ChangeNotifier {
  EnrollmentController({EnrollmentApiService? service})
    : _service = service ?? EnrollmentApiService();

  final EnrollmentApiService _service;

  List<EnrolledCourseModel> _enrolledCourses = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _lastOrderId;

  List<EnrolledCourseModel> get enrolledCourses =>
      List.unmodifiable(_enrolledCourses);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _enrolledCourses.isEmpty;
  int? get lastOrderId => _lastOrderId;

  bool isEnrolled(int courseId) {
    return _enrolledCourses.any(
      (c) => c.courseId == courseId || c.id == courseId,
    );
  }

  EnrolledCourseModel? getEnrolledCourse(int courseId) {
    try {
      return _enrolledCourses.firstWhere(
        (c) => c.courseId == courseId || c.id == courseId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> loadMyCourses(String? token, {bool forceRefresh = false}) async {
    if (token == null || token.isEmpty) {
      _enrolledCourses = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    if (_isLoading && !forceRefresh) return;

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

  void updateCourseProgressLocal({
    required int courseId,
    required double progressPercent,
    int? completedLessonsCount,
    int? lastLessonId,
    String? lastLessonTitle,
    int? lastPositionSeconds,
  }) {
    final index = _enrolledCourses.indexWhere(
      (c) => c.courseId == courseId || c.id == courseId,
    );
    if (index != -1) {
      final current = _enrolledCourses[index];
      _enrolledCourses[index] = EnrolledCourseModel(
        id: current.id,
        courseId: current.courseId,
        title: current.title,
        slug: current.slug,
        coverImage: current.coverImage,
        instructorName: current.instructorName,
        categoryName: current.categoryName,
        duration: current.duration,
        level: current.level,
        language: current.language,
        progressPercent: progressPercent,
        completed: progressPercent >= 100.0,
        lessonsCount: current.lessonsCount,
        completedLessonsCount:
            completedLessonsCount ?? current.completedLessonsCount,
        lastLessonId: lastLessonId ?? current.lastLessonId,
        lastLessonTitle: lastLessonTitle ?? current.lastLessonTitle,
        lastPositionSeconds: lastPositionSeconds ?? current.lastPositionSeconds,
        enrolledAt: current.enrolledAt,
        status: current.status,
      );
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> enrollInCourse({
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
      final res = await _service.enrollInCourse(
        courseId: courseId,
        paymentPlan: paymentPlan,
        planType: planType,
        email: email,
        token: token,
      );
      _lastOrderId = extractOrderId(res);
      _isLoading = false;
      notifyListeners();
      return res;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Enrollment failed. Please try again.';
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    }
  }

  void reset() {
    _enrolledCourses.clear();
    _errorMessage = null;
    _lastOrderId = null;
    notifyListeners();
  }
}
