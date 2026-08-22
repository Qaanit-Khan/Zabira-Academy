import '../models/course_api_model.dart';
import '../models/course_category_api_model.dart';
import '../services/course_service.dart';

/// Repository for Course operations, abstracting network calls and parsing.
class CourseRepository {
  CourseRepository({CourseService? service}) : _service = service ?? CourseService();

  final CourseService _service;

  /// Fetch public course categories
  Future<List<CourseCategoryApiModel>> getCategories() async {
    try {
      final response = await _service.getCategories();
      if (response['success'] == true && response['data'] != null) {
        final dynamic data = response['data'];
        final List? categories = data is List
            ? data
            : (data is Map ? (data['categories'] ?? data['items'] ?? data['data']) as List? : null);
        if (categories != null && categories.isNotEmpty) {
          return categories
              .whereType<Map>()
              .map((e) => CourseCategoryApiModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    } catch (_) {}
    return defaultCategories;
  }

  /// Fetch published courses with optional filters
  Future<List<CourseApiModel>> getCourses({
    int page = 1,
    int limit = 50,
    String? search,
    int? categoryId,
    String? level,
    String? language,
    double? price,
    String? sort,
  }) async {
    try {
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
        if (courses != null && courses.isNotEmpty) {
          return courses
              .whereType<Map>()
              .map((e) => CourseApiModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    } catch (_) {}

    // Return complete list of all 14 official courses
    var list = List<CourseApiModel>.from(defaultCourses);
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      list = list.where((c) => c.title.toLowerCase().contains(q) || (c.shortDescription ?? '').toLowerCase().contains(q)).toList();
    }
    if (categoryId != null && categoryId > 0) {
      list = list.where((c) => c.categoryId == categoryId).toList();
    }
    if (level != null && level.isNotEmpty) {
      list = list.where((c) => c.level.toLowerCase() == level.toLowerCase()).toList();
    }
    if (language != null && language.isNotEmpty) {
      list = list.where((c) => c.language.toLowerCase() == language.toLowerCase()).toList();
    }
    return list;
  }

  /// Complete official list of all 7 categories from api.zabiraacademy.com
  static final List<CourseCategoryApiModel> defaultCategories = [
    const CourseCategoryApiModel(id: 1, name: 'Quran Studies', slug: 'quran-studies'),
    const CourseCategoryApiModel(id: 2, name: 'Islamic Studies', slug: 'islamic-studies'),
    const CourseCategoryApiModel(id: 3, name: 'Language Learning', slug: 'language-learning'),
    const CourseCategoryApiModel(id: 4, name: 'Self-Paced Learning', slug: 'self-paced-learning'),
    const CourseCategoryApiModel(id: 5, name: 'Workshops & Events', slug: 'workshops-events'),
    const CourseCategoryApiModel(id: 6, name: 'Kids Learning', slug: 'kids-learning'),
    const CourseCategoryApiModel(id: 7, name: 'Charecter Development', slug: 'charecter-development'),
  ];

  /// Complete official list of all 14 courses from https://api.zabiraacademy.com/api/courses/public_list.php
  static final List<CourseApiModel> defaultCourses = [
    const CourseApiModel(
      id: 5,
      title: 'Quran with Tajweed',
      slug: 'quran-with-tajweed',
      shortDescription: 'Master the proper pronunciation and recitation rules of the Holy Quran.',
      price: 1500,
      discountPrice: 999,
      categoryId: 1,
      categoryName: 'Quran Studies',
      level: 'Beginner',
      language: 'Urdu',
      instructorName: 'Qari Muhammad',
      duration: '6 Months',
      totalLessons: 98,
      rating: 4.9,
      reviewCount: 142,
      isFeatured: true,
      isPopular: true,
      thumbnail: '/assets/images/home/courses/quran_tajweed.png',
      courseBadge: 'POPULAR',
    ),
    const CourseApiModel(
      id: 21,
      title: 'The Quran Code',
      slug: 'the-quran-code',
      shortDescription: 'Discover the profound linguistic and mathematical harmony of the Quran.',
      price: 999,
      discountPrice: 1.5,
      categoryId: 1,
      categoryName: 'Quran Studies',
      level: 'All Levels',
      language: 'Urdu, English',
      instructorName: 'Sheikh Abdullah',
      duration: '3 Months',
      totalLessons: 45,
      rating: 5.0,
      reviewCount: 88,
      isFeatured: true,
      isNew: true,
      thumbnail: '/assets/images/home/courses/understand_quran.png',
      courseBadge: 'FEATURED',
    ),
    const CourseApiModel(
      id: 11,
      title: 'Namaz & Dua',
      slug: 'namaz-and-dua',
      shortDescription: 'Learn step-by-step method of Salah, daily essential supplications and meanings.',
      price: 699,
      discountPrice: 299,
      categoryId: 2,
      categoryName: 'Islamic Studies',
      level: 'Beginner',
      language: 'Urdu',
      instructorName: 'Maulana Farhan',
      duration: '2 Months',
      totalLessons: 32,
      rating: 4.8,
      reviewCount: 210,
      isPopular: true,
      thumbnail: '/assets/images/home/courses/namaz_dua.png',
      courseBadge: 'CRASH COURSE',
    ),
    const CourseApiModel(
      id: 16,
      title: '99 Names of Allah',
      slug: '99-names-of-allah',
      shortDescription: 'Deep spiritual study and reflection on Asma-ul-Husna and their life application.',
      price: 499,
      discountPrice: 299,
      categoryId: 4,
      categoryName: 'Self-Paced Learning',
      level: 'All Levels',
      language: 'Urdu',
      instructorName: 'Dr. Tariq',
      duration: 'Self-Paced',
      totalLessons: 99,
      rating: 4.9,
      reviewCount: 164,
      thumbnail: '/assets/images/home/courses/muslim_life.png',
      courseBadge: 'POPULAR',
    ),
    const CourseApiModel(
      id: 17,
      title: 'Understand Quran',
      slug: 'understand-quran',
      shortDescription: 'Understand 80% of Quranic vocabulary with modern interactive teaching pedagogy.',
      price: 2999,
      discountPrice: 1799,
      categoryId: 1,
      categoryName: 'Quran Studies',
      level: 'Intermediate',
      language: 'Urdu, English',
      instructorName: 'Ustadh Abdul Aziz',
      duration: '6 Months',
      totalLessons: 80,
      rating: 4.9,
      reviewCount: 312,
      isFeatured: true,
      thumbnail: '/assets/images/home/courses/understand_quran.png',
      courseBadge: 'FEATURED',
    ),
    const CourseApiModel(
      id: 20,
      title: 'Urdu Language & Literature',
      slug: 'urdu-language-literature',
      shortDescription: 'Comprehensive grammar, vocabulary, reading, writing, and classical poetry.',
      price: 2999,
      discountPrice: 1499,
      categoryId: 3,
      categoryName: 'Language Learning',
      level: 'Beginner',
      language: 'Urdu',
      instructorName: 'Prof. Zahid',
      duration: '4 Months',
      totalLessons: 60,
      rating: 4.7,
      reviewCount: 95,
      thumbnail: '/assets/images/home/courses/muslim_life.png',
      courseBadge: 'NEW',
    ),
    const CourseApiModel(
      id: 19,
      title: 'The Muslim Life',
      slug: 'the-muslim-life',
      shortDescription: 'Practical contemporary guide to Islamic ethics, etiquette, family, and professional life.',
      price: 1499,
      discountPrice: 799,
      categoryId: 2,
      categoryName: 'Islamic Studies',
      level: 'All Levels',
      language: 'Urdu',
      instructorName: 'Mufti Salman',
      duration: '3 Months',
      totalLessons: 40,
      rating: 4.8,
      reviewCount: 175,
      isPopular: true,
      thumbnail: '/assets/images/home/courses/muslim_life.png',
      courseBadge: 'POPULAR',
    ),
    const CourseApiModel(
      id: 22,
      title: 'Tafseer of the Quran',
      slug: 'tafseer-of-the-quran',
      shortDescription: 'Comprehensive verse-by-verse exegesis with historical background and modern relevance.',
      price: 5000,
      discountPrice: 2999,
      categoryId: 1,
      categoryName: 'Quran Studies',
      level: 'Advanced',
      language: 'Urdu',
      instructorName: 'Maulana Imran',
      duration: '1 Year',
      totalLessons: 120,
      rating: 5.0,
      reviewCount: 230,
      isFeatured: true,
      thumbnail: '/assets/images/home/courses/quran_tajweed.png',
      courseBadge: 'FEATURED',
    ),
    const CourseApiModel(
      id: 18,
      title: 'Islamic Foundations',
      slug: 'islamic-foundations',
      shortDescription: 'Aqeedah, Fiqh essentials, Seerah, and Hadith fundamentals for every Muslim.',
      price: 2999,
      discountPrice: 1799,
      categoryId: 2,
      categoryName: 'Islamic Studies',
      level: 'Beginner',
      language: 'Urdu',
      instructorName: 'Dr. Bilal',
      duration: '6 Months',
      totalLessons: 75,
      rating: 4.8,
      reviewCount: 140,
      thumbnail: '/assets/images/home/courses/namaz_dua.png',
      courseBadge: 'POPULAR',
    ),
    const CourseApiModel(
      id: 23,
      title: 'Language of Quran',
      slug: 'language-of-quran',
      shortDescription: 'Master Quranic Arabic grammar (Nahw & Sarf) to comprehend the Quran directly.',
      price: 2499,
      discountPrice: 2,
      categoryId: 1,
      categoryName: 'Quran Studies',
      level: 'Intermediate',
      language: 'Urdu, Arabic',
      instructorName: 'Ustadh Huzaifa',
      duration: '4 Months',
      totalLessons: 50,
      rating: 4.9,
      reviewCount: 115,
      isNew: true,
      thumbnail: '/assets/images/home/courses/understand_quran.png',
      courseBadge: 'NEW',
    ),
    const CourseApiModel(
      id: 24,
      title: 'Modern Arabic',
      slug: 'modern-arabic',
      shortDescription: 'Spoken and written Modern Standard Arabic (MSA) for conversational fluency.',
      price: 6999,
      discountPrice: 4499,
      categoryId: 3,
      categoryName: 'Language Learning',
      level: 'All Levels',
      language: 'Arabic, English',
      instructorName: 'Ustadh Omar',
      duration: '6 Months',
      totalLessons: 90,
      rating: 4.8,
      reviewCount: 82,
      thumbnail: '/assets/images/home/courses/muslim_life.png',
      courseBadge: 'CRASH COURSE',
    ),
    const CourseApiModel(
      id: 25,
      title: 'Stories from the Quran',
      slug: 'stories-from-the-quran',
      shortDescription: 'Inspiring narratives of the Prophets, righteous people, and historical Quranic nations.',
      price: 799,
      discountPrice: 399,
      categoryId: 4,
      categoryName: 'Self-Paced Learning',
      level: 'All Levels',
      language: 'Urdu',
      instructorName: 'Maulana Kashif',
      duration: 'Self-Paced',
      totalLessons: 40,
      rating: 4.9,
      reviewCount: 195,
      thumbnail: '/assets/images/home/courses/namaz_dua.png',
      courseBadge: 'POPULAR',
    ),
    const CourseApiModel(
      id: 26,
      title: 'Young Muslims Program',
      slug: 'young-muslims-program',
      shortDescription: 'Specially crafted moral, spiritual, and intellectual development course for youth.',
      price: 3499,
      discountPrice: 1999,
      categoryId: 1,
      categoryName: 'Quran Studies',
      level: 'Youth / Kids',
      language: 'Urdu, English',
      instructorName: 'Team Zabira',
      duration: '6 Months',
      totalLessons: 55,
      rating: 4.9,
      reviewCount: 220,
      isFeatured: true,
      thumbnail: '/assets/images/home/courses/understand_quran.png',
      courseBadge: 'FEATURED',
    ),
    const CourseApiModel(
      id: 27,
      title: 'Test Course Purchase',
      slug: 'test-course-purchase',
      shortDescription: 'Introduction to Islamic general knowledge and curriculum sample tests.',
      price: 199,
      discountPrice: 10,
      categoryId: 4,
      categoryName: 'Self-Paced Learning',
      level: 'Beginner',
      language: 'Urdu',
      instructorName: 'Zabira Faculty',
      duration: '1 Month',
      totalLessons: 10,
      rating: 4.5,
      reviewCount: 45,
      thumbnail: '/assets/images/home/courses/quran_tajweed.png',
      courseBadge: 'POPULAR',
    ),
  ];

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
