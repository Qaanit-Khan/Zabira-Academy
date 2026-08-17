import '../../../courses/data/models/enrolled_course_model.dart';

/// Zabira Academy — Student Dashboard Model
/// Maps backend data for the authenticated Student Dashboard.
class StudentDashboardModel {
  const StudentDashboardModel({
    this.studentName = '',
    this.email = '',
    this.photoUrl,
    this.myOrdersCount = 0,
    this.myCoursesCount = 0,
    this.inProgressCount = 0,
    this.progressPercent = 0.0,
    this.certificatesCount = 0,
    this.wishlistCount = 0,
    this.liveClassesCount = 0,
    this.continueLearningCourses = const [],
    this.notifications = const [],
    this.recentCertificates = const [],
    this.upcomingLiveClass,
    this.weeklyGoalCurrent = 0,
    this.weeklyGoalTarget = 5,
    this.averageCourseCompletion = 0.0,
    this.quote = 'The ink of the scholar is more sacred than the blood of the martyr.',
  });

  final String studentName;
  final String email;
  final String? photoUrl;
  final int myOrdersCount;
  final int myCoursesCount;
  final int inProgressCount;
  final double progressPercent;
  final int certificatesCount;
  final int wishlistCount;
  final int liveClassesCount;
  final List<EnrolledCourseModel> continueLearningCourses;
  final List<StudentNotificationItem> notifications;
  final List<StudentCertificateItem> recentCertificates;
  final UpcomingLiveClassItem? upcomingLiveClass;
  final int weeklyGoalCurrent;
  final int weeklyGoalTarget;
  final double averageCourseCompletion;
  final String quote;

  factory StudentDashboardModel.fromJson(
    Map<String, dynamic> json, {
    String? defaultName,
    String? defaultEmail,
    String? defaultPhoto,
    int? fallbackOrdersCount,
    int? fallbackWishlistCount,
  }) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;

    final stats = data['stats'] is Map<String, dynamic> ? data['stats'] as Map<String, dynamic> : data;

    final ordersCount = int.tryParse((stats['orders_count'] ?? stats['my_orders'] ?? stats['orders'] ?? fallbackOrdersCount ?? 0).toString()) ?? (fallbackOrdersCount ?? 0);
    final coursesCount = int.tryParse((stats['courses_count'] ?? stats['my_courses'] ?? stats['enrolled_courses'] ?? 0).toString()) ?? 0;
    final inProgress = int.tryParse((stats['in_progress_count'] ?? stats['in_progress'] ?? 0).toString()) ?? 0;
    final progress = double.tryParse((stats['progress_percent'] ?? stats['overall_progress'] ?? stats['progress'] ?? 0).toString()) ?? 0.0;
    final certCount = int.tryParse((stats['certificates_count'] ?? stats['certificates'] ?? 0).toString()) ?? 0;
    final wishCount = int.tryParse((stats['wishlist_count'] ?? stats['wishlist'] ?? fallbackWishlistCount ?? 0).toString()) ?? (fallbackWishlistCount ?? 0);
    final liveCount = int.tryParse((stats['live_classes_count'] ?? stats['live_classes'] ?? stats['trials_count'] ?? 0).toString()) ?? 0;

    // Courses in progress / enrolled courses
    final dynamic rawCoursesData = data['continue_learning'] ?? data['courses'] ?? data['enrolled_courses'] ?? data['items'] ?? json['courses'] ?? json['enrollments'];
    List? rawCourses;
    if (rawCoursesData is List) {
      rawCourses = rawCoursesData;
    } else if (rawCoursesData is Map) {
      rawCourses = (rawCoursesData['courses'] ?? rawCoursesData['items'] ?? rawCoursesData['enrollments'] ?? rawCoursesData['data']) as List?;
    }

    List<EnrolledCourseModel> continueCourses = [];
    if (rawCourses != null) {
      continueCourses = rawCourses
          .whereType<Map<String, dynamic>>()
          .map((c) => EnrolledCourseModel.fromJson(c))
          .where((c) => c.courseId > 0 || c.id > 0)
          .toList();
    }

    // Notifications
    final dynamic rawNotifsData = data['notifications'] ?? data['recent_notifications'];
    List? rawNotifs = rawNotifsData is List ? rawNotifsData : (rawNotifsData is Map ? rawNotifsData['notifications'] as List? : null);
    List<StudentNotificationItem> notifs = [];
    if (rawNotifs is List) {
      notifs = rawNotifs
          .whereType<Map<String, dynamic>>()
          .map((n) => StudentNotificationItem.fromJson(n))
          .toList();
    }

    // Certificates
    final rawCerts = data['recent_certificates'] ?? data['certificates_list'] ?? [];
    List<StudentCertificateItem> certs = [];
    if (rawCerts is List) {
      certs = rawCerts
          .whereType<Map<String, dynamic>>()
          .map((c) => StudentCertificateItem.fromJson(c))
          .toList();
    }

    // Live Class
    UpcomingLiveClassItem? upcomingClass;
    if (data['upcoming_live_class'] is Map<String, dynamic>) {
      upcomingClass = UpcomingLiveClassItem.fromJson(data['upcoming_live_class'] as Map<String, dynamic>);
    }

    return StudentDashboardModel(
      studentName: data['name']?.toString() ?? data['full_name']?.toString() ?? defaultName ?? '',
      email: data['email']?.toString() ?? defaultEmail ?? '',
      photoUrl: data['photo_url']?.toString() ?? data['avatar']?.toString() ?? defaultPhoto,
      myOrdersCount: ordersCount,
      myCoursesCount: coursesCount > 0 ? coursesCount : continueCourses.length,
      inProgressCount: inProgress > 0 ? inProgress : continueCourses.where((c) => c.progressPercent > 0 && c.progressPercent < 100).length,
      progressPercent: progress,
      certificatesCount: certCount,
      wishlistCount: wishCount,
      liveClassesCount: liveCount,
      continueLearningCourses: continueCourses,
      notifications: notifs,
      recentCertificates: certs,
      upcomingLiveClass: upcomingClass,
      weeklyGoalCurrent: int.tryParse(data['weekly_goal_current']?.toString() ?? '0') ?? 0,
      weeklyGoalTarget: int.tryParse(data['weekly_goal_target']?.toString() ?? '5') ?? 5,
      averageCourseCompletion: double.tryParse(data['average_course_completion']?.toString() ?? '0') ?? 0.0,
      quote: data['quote']?.toString() ?? 'The ink of the scholar is more sacred than the blood of the martyr.',
    );
  }

  StudentDashboardModel copyWith({
    String? studentName,
    String? email,
    String? photoUrl,
    int? myOrdersCount,
    int? myCoursesCount,
    int? inProgressCount,
    double? progressPercent,
    int? certificatesCount,
    int? wishlistCount,
    int? liveClassesCount,
    List<EnrolledCourseModel>? continueLearningCourses,
    List<StudentNotificationItem>? notifications,
    List<StudentCertificateItem>? recentCertificates,
    UpcomingLiveClassItem? upcomingLiveClass,
    int? weeklyGoalCurrent,
    int? weeklyGoalTarget,
    double? averageCourseCompletion,
    String? quote,
  }) {
    return StudentDashboardModel(
      studentName: studentName ?? this.studentName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      myOrdersCount: myOrdersCount ?? this.myOrdersCount,
      myCoursesCount: myCoursesCount ?? this.myCoursesCount,
      inProgressCount: inProgressCount ?? this.inProgressCount,
      progressPercent: progressPercent ?? this.progressPercent,
      certificatesCount: certificatesCount ?? this.certificatesCount,
      wishlistCount: wishlistCount ?? this.wishlistCount,
      liveClassesCount: liveClassesCount ?? this.liveClassesCount,
      continueLearningCourses: continueLearningCourses ?? this.continueLearningCourses,
      notifications: notifications ?? this.notifications,
      recentCertificates: recentCertificates ?? this.recentCertificates,
      upcomingLiveClass: upcomingLiveClass ?? this.upcomingLiveClass,
      weeklyGoalCurrent: weeklyGoalCurrent ?? this.weeklyGoalCurrent,
      weeklyGoalTarget: weeklyGoalTarget ?? this.weeklyGoalTarget,
      averageCourseCompletion: averageCourseCompletion ?? this.averageCourseCompletion,
      quote: quote ?? this.quote,
    );
  }
}

class StudentNotificationItem {
  const StudentNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    this.type = 'info',
    this.createdAt,
    this.isRead = false,
  });

  final int id;
  final String title;
  final String message;
  final String type;
  final DateTime? createdAt;
  final bool isRead;

  factory StudentNotificationItem.fromJson(Map<String, dynamic> json) {
    return StudentNotificationItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? 'info',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      isRead: json['is_read'] == true || json['is_read'] == 1 || json['read_at'] != null,
    );
  }
}

class StudentCertificateItem {
  const StudentCertificateItem({
    required this.id,
    required this.courseTitle,
    this.certificateCode,
    this.issuedAt,
    this.pdfUrl,
  });

  final int id;
  final String courseTitle;
  final String? certificateCode;
  final DateTime? issuedAt;
  final String? pdfUrl;

  factory StudentCertificateItem.fromJson(Map<String, dynamic> json) {
    return StudentCertificateItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      courseTitle: json['course_title']?.toString() ?? json['title']?.toString() ?? 'Course Certificate',
      certificateCode: json['certificate_code']?.toString() ?? json['code']?.toString(),
      issuedAt: DateTime.tryParse(json['issued_at']?.toString() ?? json['created_at']?.toString() ?? ''),
      pdfUrl: json['pdf_url']?.toString() ?? json['file_url']?.toString(),
    );
  }
}

class UpcomingLiveClassItem {
  const UpcomingLiveClassItem({
    required this.id,
    required this.title,
    required this.scheduledAt,
    this.joinUrl,
    this.teacherName,
  });

  final int id;
  final String title;
  final DateTime scheduledAt;
  final String? joinUrl;
  final String? teacherName;

  factory UpcomingLiveClassItem.fromJson(Map<String, dynamic> json) {
    return UpcomingLiveClassItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? json['course_title']?.toString() ?? 'Live Session',
      scheduledAt: DateTime.tryParse(json['scheduled_at']?.toString() ?? '') ?? DateTime.now(),
      joinUrl: json['join_url']?.toString() ?? json['meeting_url']?.toString(),
      teacherName: json['teacher_name']?.toString(),
    );
  }
}
