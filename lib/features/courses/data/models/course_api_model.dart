import '../../../../core/constants/api_config.dart';

/// Course Payment Option Model
class CoursePaymentOption {
  const CoursePaymentOption({
    required this.planType,
    required this.label,
    required this.finalPrice,
    this.originalPrice,
    this.amountDueToday,
    this.installmentCount,
    this.installmentAmount,
    this.durationMonths,
    this.benefits = const [],
  });

  final String planType;
  final String label;
  final double finalPrice;
  final double? originalPrice;
  final double? amountDueToday;
  final int? installmentCount;
  final double? installmentAmount;
  final int? durationMonths;
  final List<String> benefits;

  factory CoursePaymentOption.fromJson(Map<String, dynamic> json) {
    double parse(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    final bList = <String>[];
    if (json['benefits'] is List) {
      for (final b in json['benefits'] as List) {
        if (b != null) bList.add(b.toString());
      }
    }

    return CoursePaymentOption(
      planType: json['plan_type']?.toString() ?? 'full',
      label: json['label']?.toString() ?? 'Pay',
      finalPrice: parse(json['final']),
      originalPrice: json['original'] != null ? parse(json['original']) : null,
      amountDueToday: json['amount_due_today'] != null ? parse(json['amount_due_today']) : null,
      installmentCount: json['installment_count'] is int
          ? json['installment_count'] as int
          : int.tryParse(json['installment_count']?.toString() ?? ''),
      installmentAmount: json['installment_amount'] != null ? parse(json['installment_amount']) : null,
      durationMonths: json['duration_months'] is int
          ? json['duration_months'] as int
          : int.tryParse(json['duration_months']?.toString() ?? ''),
      benefits: bList,
    );
  }
}

/// Course Curriculum Item Model (Section / Lesson)
class CourseCurriculumSection {
  const CourseCurriculumSection({
    required this.id,
    required this.title,
    this.description,
    this.lessonCount = 0,
    this.duration,
    this.lessons = const [],
  });

  final int id;
  final String title;
  final String? description;
  final int lessonCount;
  final String? duration;
  final List<CourseLessonItem> lessons;

  factory CourseCurriculumSection.fromJson(Map<String, dynamic> json) {
    final lessonItems = <CourseLessonItem>[];
    if (json['lessons'] is List) {
      for (final l in json['lessons'] as List) {
        if (l is Map<String, dynamic>) {
          lessonItems.add(CourseLessonItem.fromJson(l));
        }
      }
    }

    return CourseCurriculumSection(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? json['section_title']?.toString() ?? 'Section',
      description: json['description']?.toString(),
      lessonCount: json['lesson_count'] is int
          ? json['lesson_count'] as int
          : (lessonItems.isNotEmpty ? lessonItems.length : 0),
      duration: json['duration']?.toString(),
      lessons: lessonItems,
    );
  }
}

/// Course Lesson Item Model
class CourseLessonItem {
  const CourseLessonItem({
    required this.id,
    required this.title,
    this.duration,
    this.isPreview = false,
    this.videoUrl,
  });

  final int id;
  final String title;
  final String? duration;
  final bool isPreview;
  final String? videoUrl;

  factory CourseLessonItem.fromJson(Map<String, dynamic> json) {
    return CourseLessonItem(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? json['lesson_title']?.toString() ?? 'Lesson',
      duration: json['duration']?.toString(),
      isPreview: json['is_preview'] == 1 || json['is_preview'] == true || json['is_free'] == 1,
      videoUrl: json['video_url']?.toString(),
    );
  }
}

/// Full Course Model mapped directly from Zabira Academy Courses API
/// (`GET /courses/public_list.php` and `GET /courses/public_details.php`).
class CourseApiModel {
  const CourseApiModel({
    required this.id,
    required this.title,
    this.titleRe,
    this.titleUr,
    required this.slug,
    this.shortDescription,
    this.shortDescriptionRe,
    this.shortDescriptionUr,
    this.description,
    this.descriptionRe,
    this.descriptionUr,
    this.thumbnail,
    this.heroBanner,
    this.previewVideoUrl,
    this.courseBadge,
    this.level = 'All Levels',
    this.duration = 'Self-Paced',
    this.courseType = 'Online Course',
    this.language = 'English',
    this.languages = const [],
    required this.price,
    this.discountPrice,
    this.offerLabel,
    this.currency = 'INR',
    this.totalLessons = 0,
    this.hasCertificate = false,
    this.hasStudyMaterial = false,
    this.isFeatured = false,
    this.isPopular = false,
    this.isBestseller = false,
    this.isNew = false,
    this.isCrashCourse = false,
    this.categoryName,
    this.categoryId,
    this.instructorName,
    this.rating = 5.0,
    this.reviewCount = 0,
    this.curriculum = const [],
    this.paymentOptions = const [],
    this.outcomes = const [],
    this.requirements = const [],
    this.faqs = const [],
  });

  final int id;
  final String title;
  final String? titleRe;
  final String? titleUr;
  final String slug;
  final String? shortDescription;
  final String? shortDescriptionRe;
  final String? shortDescriptionUr;
  final String? description;
  final String? descriptionRe;
  final String? descriptionUr;
  final String? thumbnail;
  final String? heroBanner;
  final String? previewVideoUrl;
  final String? courseBadge;
  final String level;
  final String duration;
  final String courseType;
  final String language;
  final List<String> languages;
  final double price;
  final double? discountPrice;
  final String? offerLabel;
  final String currency;
  final int totalLessons;
  final bool hasCertificate;
  final bool hasStudyMaterial;
  final bool isFeatured;
  final bool isPopular;
  final bool isBestseller;
  final bool isNew;
  final bool isCrashCourse;
  final String? categoryName;
  final int? categoryId;
  final String? instructorName;
  final double rating;
  final int reviewCount;
  final List<CourseCurriculumSection> curriculum;
  final List<CoursePaymentOption> paymentOptions;
  final List<String> outcomes;
  final List<String> requirements;
  final List<Map<String, String>> faqs;

  /// Resolved full thumbnail URL
  String? get fullThumbnailUrl => ApiConfig.resolveImageUrl(thumbnail);

  /// Resolved full hero banner URL
  String? get fullHeroBannerUrl => ApiConfig.resolveImageUrl(heroBanner);

  /// Returns title based on selected language ('en', 're', 'ur')
  String getTitle(String langCode) {
    if (langCode == 're' && titleRe != null && titleRe!.trim().isNotEmpty) {
      return titleRe!;
    }
    if (langCode == 'ur' && titleUr != null && titleUr!.trim().isNotEmpty) {
      return titleUr!;
    }
    return title;
  }

  /// Returns short description based on selected language ('en', 're', 'ur')
  String? getShortDescription(String langCode) {
    if (langCode == 're' && shortDescriptionRe != null && shortDescriptionRe!.trim().isNotEmpty) {
      return shortDescriptionRe;
    }
    if (langCode == 'ur' && shortDescriptionUr != null && shortDescriptionUr!.trim().isNotEmpty) {
      return shortDescriptionUr;
    }
    return shortDescription;
  }

  /// Returns full description based on selected language ('en', 're', 'ur')
  String? getDescription(String langCode) {
    if (langCode == 're' && descriptionRe != null && descriptionRe!.trim().isNotEmpty) {
      return descriptionRe;
    }
    if (langCode == 'ur' && descriptionUr != null && descriptionUr!.trim().isNotEmpty) {
      return descriptionUr;
    }
    return description ?? shortDescription;
  }

  /// Effective price considering discount
  double get effectivePrice => (discountPrice != null && discountPrice! > 0) ? discountPrice! : price;

  /// Whether the course is free
  bool get isFree => effectivePrice <= 0;

  /// Formatted effective price (e.g. "₹999")
  String get formattedPrice {
    final effective = effectivePrice;
    return '₹${effective.toInt()}';
  }

  /// Formatted original price (if discounted)
  String? get formattedOriginalPrice {
    if (discountPrice != null && discountPrice! > 0 && discountPrice! < price) {
      return '₹${price.toInt()}';
    }
    return null;
  }

  /// Discount percentage if on sale (e.g. 33, 40)
  int? get discountPercent {
    if (discountPrice != null && discountPrice! > 0 && price > discountPrice!) {
      return (((price - discountPrice!) / price) * 100).round();
    }
    return null;
  }

  /// Combined languages display string (e.g. "English, Urdu" or "Urdu" or "Arabic")
  String get languagesDisplay {
    if (languages.isNotEmpty) {
      return languages.join(', ');
    }
    return language.isNotEmpty ? language : 'English';
  }

  /// Monthly installment price display (e.g. "Starting from ₹250/month EMI")
  String get monthlyInstallmentText {
    for (final opt in paymentOptions) {
      if (opt.planType == 'monthly' && opt.installmentAmount != null && opt.installmentAmount! > 0) {
        return 'Starting from ₹${opt.installmentAmount!.toInt()}/month EMI';
      }
    }
    // Fallback estimate for paid courses >= 500
    final effective = effectivePrice;
    if (effective >= 500) {
      final est = (effective / 4).round();
      return 'Starting from ₹$est/month EMI';
    }
    return '';
  }

  /// Badge text if applicable (e.g. "Bestseller", "New", "Popular", "Featured")
  String? get badgeLabel {
    if (courseBadge != null && courseBadge!.isNotEmpty) return courseBadge;
    if (isBestseller) return 'Bestseller';
    if (isNew) return 'New';
    if (isPopular) return 'Popular';
    if (isFeatured) return 'Featured';
    return null;
  }

  /// Clean lessons count string e.g. "98 Lessons" or "1 Lesson"
  String get lessonsDisplay {
    if (totalLessons == 1) return '1 Lesson';
    if (totalLessons > 1) return '$totalLessons Lessons';
    return '1 Lesson';
  }

  /// Clean rating & reviews display e.g. "4.9" or "4.9 (0 students)"
  String get ratingDisplay {
    final rStr = rating.toStringAsFixed(1);
    if (reviewCount > 0) {
      return '$rStr ($reviewCount)';
    }
    return rStr;
  }

  factory CourseApiModel.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic v, double fallback) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    int parseInt(dynamic v, int fallback) {
      if (v == null) return fallback;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? fallback;
    }

    final curriculumList = <CourseCurriculumSection>[];
    if (json['curriculum'] is List) {
      for (final c in json['curriculum'] as List) {
        if (c is Map<String, dynamic>) {
          curriculumList.add(CourseCurriculumSection.fromJson(c));
        }
      }
    }

    final paymentOpts = <CoursePaymentOption>[];
    if (json['payment_plans'] is Map && json['payment_plans']['options'] is List) {
      for (final o in json['payment_plans']['options'] as List) {
        if (o is Map<String, dynamic>) {
          paymentOpts.add(CoursePaymentOption.fromJson(o));
        }
      }
    }

    final outcomesList = <String>[];
    if (json['outcomes'] is List) {
      for (final o in json['outcomes'] as List) {
        if (o != null) outcomesList.add(o.toString());
      }
    }

    final reqsList = <String>[];
    if (json['requirements'] is List) {
      for (final r in json['requirements'] as List) {
        if (r != null) reqsList.add(r.toString());
      }
    }

    final faqsList = <Map<String, String>>[];
    if (json['faqs'] is List) {
      for (final f in json['faqs'] as List) {
        if (f is Map) {
          faqsList.add({
            'question': f['question']?.toString() ?? '',
            'answer': f['answer']?.toString() ?? '',
          });
        }
      }
    }

    final languagesList = <String>[];
    if (json['languages'] is List) {
      for (final l in json['languages'] as List) {
        if (l != null && l.toString().trim().isNotEmpty) {
          languagesList.add(l.toString().trim());
        }
      }
    }

    return CourseApiModel(
      id: parseInt(json['id'], 0),
      title: json['title']?.toString() ?? '',
      titleRe: json['title_re']?.toString(),
      titleUr: json['title_ur']?.toString(),
      slug: json['slug']?.toString() ?? '',
      shortDescription: json['short_description']?.toString(),
      shortDescriptionRe: json['short_description_re']?.toString(),
      shortDescriptionUr: json['short_description_ur']?.toString(),
      description: json['description']?.toString(),
      descriptionRe: json['description_re']?.toString(),
      descriptionUr: json['description_ur']?.toString(),
      thumbnail: json['thumbnail']?.toString(),
      heroBanner: json['hero_banner']?.toString(),
      previewVideoUrl: json['preview_video_url']?.toString(),
      courseBadge: json['course_badge']?.toString(),
      level: json['level']?.toString() ?? 'Beginner',
      duration: json['duration']?.toString() ?? '6 months',
      courseType: json['course_type_label']?.toString() ?? json['course_type']?.toString() ?? 'Online Course',
      language: json['language']?.toString() ?? 'English',
      languages: languagesList,
      price: parseNum(json['price'], 0.0),
      discountPrice: json['discount_price'] != null ? parseNum(json['discount_price'], 0.0) : null,
      offerLabel: json['offer_label']?.toString(),
      currency: json['currency']?.toString() ?? 'INR',
      totalLessons: parseInt(json['total_lessons'], 0),
      hasCertificate: json['has_certificate'] == 1 || json['has_certificate'] == true,
      hasStudyMaterial: json['has_study_material'] == 1 || json['has_study_material'] == true,
      isFeatured: json['is_featured'] == 1 || json['is_featured'] == true,
      isPopular: json['is_popular'] == 1 || json['is_popular'] == true,
      isBestseller: json['is_bestseller'] == 1 || json['is_bestseller'] == true,
      isNew: json['is_new'] == 1 || json['is_new'] == true,
      isCrashCourse: json['is_crash_course'] == 1 || json['is_crash_course'] == true,
      categoryName: json['category_name']?.toString(),
      categoryId: json['category_id'] is int
          ? json['category_id'] as int
          : int.tryParse(json['category_id']?.toString() ?? ''),
      instructorName: json['instructor_name']?.toString(),
      rating: parseNum(json['rating'], 5.0),
      reviewCount: parseInt(json['review_count'], 0),
      curriculum: curriculumList,
      paymentOptions: paymentOpts,
      outcomes: outcomesList,
      requirements: reqsList,
      faqs: faqsList,
    );
  }
}
