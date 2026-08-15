import '../models/course_api_model.dart';
import '../models/course_category_api_model.dart';
import '../services/course_service.dart';

/// Repository for Course operations, abstracting network calls and parsing.
class CourseRepository {
  CourseRepository({CourseService? service}) : _service = service ?? CourseService();

  final CourseService _service;

  /// Fetch public course categories
  Future<List<CourseCategoryApiModel>> getCategories() async {
    final response = await _service.getCategories();
    if (response['success'] == true && response['data'] != null) {
      final dynamic data = response['data'];
      final List? categories = data is List
          ? data
          : (data is Map ? (data['categories'] ?? data['items'] ?? data['data']) as List? : null);
      if (categories != null) {
        return categories
            .whereType<Map<String, dynamic>>()
            .map(CourseCategoryApiModel.fromJson)
            .toList();
      }
    }
    return [];
  }

  /// Fetch published courses with optional filters
  Future<List<CourseApiModel>> getCourses({
    int page = 1,
    int limit = 20,
    String? search,
    int? categoryId,
    String? level,
    String? language,
    double? price,
    String? sort,
  }) async {
    final response = await _service.getCourses(
      page: page,
      limit: limit,
      search: search,
      categoryId: categoryId,
      level: level,
      language: language,
      price: price,
      sort: sort,
    );

    if (response['success'] == true && response['data'] != null) {
      final dynamic data = response['data'];
      final List? courses = data is List
          ? data
          : (data is Map ? (data['courses'] ?? data['items'] ?? data['data']) as List? : null);
      if (courses != null) {
        return courses
            .whereType<Map<String, dynamic>>()
            .map(CourseApiModel.fromJson)
            .toList();
      }
    }
    return [];
  }

  /// Fetch complete details for a single course
  Future<CourseApiModel> getCourseDetails(int id) async {
    final response = await _service.getCourseDetails(id: id);
    if (response['success'] == true && response['data'] != null) {
      final dynamic data = response['data'];
      final Map<String, dynamic>? courseMap = data is Map
          ? (data['course'] ?? data['item'] ?? data) as Map<String, dynamic>?
          : null;
      if (courseMap != null) {
        // Merge payment plans from root data if present
        if (data is Map && data['payment_plans'] != null) {
          courseMap['payment_plans'] = data['payment_plans'];
        }
        return CourseApiModel.fromJson(courseMap);
      }
    }
    throw Exception('Course details not found');
  }
}
