import '../../../../core/constants/api_config.dart';

/// Event model from Zabira Academy API
class EventItemModel {
  const EventItemModel({
    required this.id,
    required this.title,
    required this.slug,
    this.shortDescription = '',
    this.featuredImage,
    this.bannerImage,
    this.eventType = 'offline',
    this.category = 'Competition',
    this.categories = const [],
    this.venue = 'Zabira Academy Campus',
    this.address = '',
    this.eventDate = '',
    this.eventEndDate,
    this.startTime,
    this.endTime,
    this.registrationFee = 0.0,
    this.maxParticipants = 100,
    this.registrationCount = 0,
    this.seatsLeft = 100,
    this.ageGroup = '',
    this.grade = '',
    this.language = 'English',
    this.organizer = 'Zabira Academy',
    this.instructor = '',
    this.registrationStatus = 'open',
    this.status = 'published',
    this.isFeatured = false,
    this.isPast = false,
    this.isUpcoming = true,
    this.registrationOpen = true,
    this.allowsPublicRegistration = true,
  });

  final int id;
  final String title;
  final String slug;
  final String shortDescription;
  final String? featuredImage;
  final String? bannerImage;
  final String eventType;
  final String category;
  final List<String> categories;
  final String venue;
  final String address;
  final String eventDate;
  final String? eventEndDate;
  final String? startTime;
  final String? endTime;
  final double registrationFee;
  final int maxParticipants;
  final int registrationCount;
  final int seatsLeft;
  final String ageGroup;
  final String grade;
  final String language;
  final String organizer;
  final String instructor;
  final String registrationStatus;
  final String status;
  final bool isFeatured;
  final bool isPast;
  final bool isUpcoming;
  final bool registrationOpen;
  final bool allowsPublicRegistration;

  /// Resolved featured/banner image URLs
  String? get resolvedFeaturedImage => ApiConfig.resolveImageUrl(featuredImage ?? bannerImage);
  String? get resolvedBannerImage => ApiConfig.resolveImageUrl(bannerImage ?? featuredImage);

  /// Day and Month extraction for Date Badge (e.g. "20 JUN")
  String get dateDay {
    if (eventDate.isEmpty) return '20';
    try {
      final dt = DateTime.parse(eventDate);
      return dt.day.toString();
    } catch (_) {
      final parts = eventDate.split('-');
      if (parts.length >= 3) return parts[2];
      return '20';
    }
  }

  String get dateMonth {
    if (eventDate.isEmpty) return 'JUN';
    try {
      final dt = DateTime.parse(eventDate);
      const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
      return months[dt.month - 1];
    } catch (_) {
      return 'JUN';
    }
  }

  /// Formatted date string (e.g. "20 Jun 2026")
  String get formattedDate {
    if (eventDate.isEmpty) return 'Date TBA';
    try {
      final dt = DateTime.parse(eventDate);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return eventDate;
    }
  }

  /// Formatted time string (e.g. "10:00 AM")
  String get formattedTime {
    if (startTime == null || startTime!.isEmpty) return '10:00 AM';
    final parts = startTime!.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]) ?? 10;
      final m = parts[1];
      final period = h >= 12 ? 'PM' : 'AM';
      final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return '$h12:$m $period';
    }
    return startTime!;
  }

  /// Formatted location
  String get formattedLocation {
    if (eventType.toLowerCase() == 'online') return 'Online';
    if (venue.isNotEmpty) return venue;
    if (address.isNotEmpty) return address;
    return 'Hyderabad';
  }

  factory EventItemModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    }

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    bool parseBool(dynamic val) {
      if (val == null) return false;
      if (val is bool) return val;
      if (val is num) return val == 1;
      return val.toString() == '1' || val.toString().toLowerCase() == 'true';
    }

    final catList = <String>[];
    if (json['categories'] is List) {
      for (final c in json['categories'] as List) {
        if (c != null) catList.add(c.toString());
      }
    }

    return EventItemModel(
      id: parseInt(json['id']),
      title: json['title']?.toString() ?? 'Zabira Event',
      slug: json['slug']?.toString() ?? '',
      shortDescription: json['short_description']?.toString() ?? json['description']?.toString() ?? '',
      featuredImage: json['featured_image']?.toString(),
      bannerImage: json['banner_image']?.toString(),
      eventType: json['event_type']?.toString() ?? 'offline',
      category: json['category']?.toString() ?? 'General',
      categories: catList,
      venue: json['venue']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      eventDate: json['event_date']?.toString() ?? '',
      eventEndDate: json['event_end_date']?.toString(),
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      registrationFee: parseDouble(json['registration_fee']),
      maxParticipants: parseInt(json['max_participants']),
      registrationCount: parseInt(json['registration_count']),
      seatsLeft: parseInt(json['seats_left']),
      ageGroup: json['age_group']?.toString() ?? '',
      grade: json['grade']?.toString() ?? '',
      language: json['language']?.toString() ?? 'English',
      organizer: json['organizer']?.toString() ?? 'Zabira Academy',
      instructor: json['instructor']?.toString() ?? '',
      registrationStatus: json['registration_status']?.toString() ?? 'open',
      status: json['status']?.toString() ?? 'published',
      isFeatured: parseBool(json['is_featured'] ?? json['featured']),
      isPast: parseBool(json['is_past']),
      isUpcoming: parseBool(json['is_upcoming'] ?? true),
      registrationOpen: parseBool(json['registration_open'] ?? true),
      allowsPublicRegistration: parseBool(json['allows_public_registration'] ?? true),
    );
  }
}
