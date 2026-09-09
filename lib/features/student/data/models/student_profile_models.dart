import '../../../../core/constants/api_config.dart';

/// Complete Student Profile model matching `6 - profile my profile 6.pdf` & `11 - profile settings 11.pdf`
class StudentProfileData {
  StudentProfileData({
    this.id = 0,
    this.studentId = 'ZAB-STU-000044',
    this.email = '',
    this.phone = '',
    this.isEmailVerified = true,
    this.isPhoneVerified = true,
    this.registrationDate = '11/08/2026',
    this.firstName = '',
    this.lastName = '',
    this.displayName = '',
    this.dateOfBirth = '',
    this.gender = 'Male',
    this.country = 'India',
    this.state = 'Maharashtra',
    this.city = 'Amravati',
    this.postalCode = '',
    this.address = '',
    this.preferredLanguage = 'English',
    this.timeZone = 'Asia/Kolkata',
    this.qualification = '',
    this.occupation = '',
    this.institution = '',
    this.bio = '',
    this.emergencyName = '',
    this.emergencyPhone = '',
    this.parentName = '',
    this.parentPhone = '',
    this.website = '',
    this.linkedin = '',
    this.twitter = '',
    this.instagram = '',
    this.youtube = '',
    this.photoUrl,
    // Notification & Channel Preferences
    this.emailNotifications = true,
    this.whatsappNotifications = true,
    this.pushNotifications = false,
    this.marketingEmails = false,
    this.assignmentReminders = true,
    this.liveClassReminders = true,
    this.eventNotifications = true,
    this.courseUpdates = true,
    this.paymentUpdates = true,
    this.certificateAlerts = true,
    // Settings Preferences
    this.theme = 'System',
    this.dateFormat = 'DD/MM/YYYY',
  });

  final int id;
  final String studentId;
  final String email;
  final String phone;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final String registrationDate;
  final String firstName;
  final String lastName;
  final String displayName;
  final String dateOfBirth;
  final String gender;
  final String country;
  final String state;
  final String city;
  final String postalCode;
  final String address;
  final String preferredLanguage;
  final String timeZone;
  final String qualification;
  final String occupation;
  final String institution;
  final String bio;
  final String emergencyName;
  final String emergencyPhone;
  final String parentName;
  final String parentPhone;
  final String website;
  final String linkedin;
  final String twitter;
  final String instagram;
  final String youtube;
  final String? photoUrl;

  final bool emailNotifications;
  final bool whatsappNotifications;
  final bool pushNotifications;
  final bool marketingEmails;
  final bool assignmentReminders;
  final bool liveClassReminders;
  final bool eventNotifications;
  final bool courseUpdates;
  final bool paymentUpdates;
  final bool certificateAlerts;

  final String theme;
  final String dateFormat;

  factory StudentProfileData.fromJson(Map<String, dynamic> json, {String? defaultEmail, String? defaultName, String? defaultPhoto}) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
    final user = data['user'] is Map<String, dynamic> ? data['user'] as Map<String, dynamic> : data;
    final student = data['student'] is Map<String, dynamic> ? data['student'] as Map<String, dynamic> : user;

    final fullName = (student['name'] ?? user['name'] ?? student['display_name'] ?? defaultName ?? '').toString().trim();
    final nameParts = fullName.split(' ');
    final first = student['first_name']?.toString() ?? (nameParts.isNotEmpty ? nameParts.first : '');
    final last = student['last_name']?.toString() ?? (nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '');

    final notifs = (student['notification_preferences'] is Map<String, dynamic>
            ? student['notification_preferences'] as Map<String, dynamic>
            : (student['notifications'] is Map<String, dynamic> ? student['notifications'] as Map<String, dynamic> : null)) ??
        {};

    final prefs = (student['preferences'] is Map<String, dynamic>
            ? student['preferences'] as Map<String, dynamic>
            : (student['settings'] is Map<String, dynamic> ? student['settings'] as Map<String, dynamic> : null)) ??
        {};

    return StudentProfileData(
      id: int.tryParse((student['id'] ?? user['id'] ?? 0).toString()) ?? 0,
      studentId: student['student_id']?.toString() ?? student['code']?.toString() ?? 'ZAB-STU-000044',
      email: student['email']?.toString() ?? user['email']?.toString() ?? defaultEmail ?? '',
      phone: student['phone']?.toString() ?? student['mobile']?.toString() ?? user['phone']?.toString() ?? user['mobile']?.toString() ?? '',
      isEmailVerified: student['is_email_verified'] != false && user['email_verified'] != false,
      isPhoneVerified: student['is_phone_verified'] != false && user['phone_verified'] != false,
      registrationDate: student['registration_date']?.toString() ?? student['created_at']?.toString() ?? '11/08/2026',
      firstName: first,
      lastName: last,
      displayName: fullName.isNotEmpty ? fullName : (first.isNotEmpty ? '$first $last'.trim() : 'Student'),
      dateOfBirth: student['date_of_birth']?.toString() ?? student['dob']?.toString() ?? '',
      gender: student['gender']?.toString() ?? 'Male',
      country: student['country']?.toString() ?? 'India',
      state: student['state']?.toString() ?? 'Maharashtra',
      city: student['city']?.toString() ?? 'Amravati',
      postalCode: student['postal_code']?.toString() ?? student['zip']?.toString() ?? '',
      address: student['address']?.toString() ?? '',
      preferredLanguage: prefs['language']?.toString() ?? student['preferred_language']?.toString() ?? 'English',
      timeZone: prefs['time_zone']?.toString() ?? student['time_zone']?.toString() ?? 'Asia/Kolkata',
      qualification: student['education_qualification']?.toString() ?? student['qualification']?.toString() ?? '',
      occupation: student['occupation']?.toString() ?? '',
      institution: student['institution']?.toString() ?? student['organization']?.toString() ?? '',
      bio: student['bio']?.toString() ?? student['about']?.toString() ?? '',
      emergencyName: student['emergency_name']?.toString() ?? '',
      emergencyPhone: student['emergency_phone']?.toString() ?? '',
      parentName: student['parent_name']?.toString() ?? student['guardian_name']?.toString() ?? '',
      parentPhone: student['parent_phone']?.toString() ?? student['guardian_contact']?.toString() ?? '',
      website: student['website']?.toString() ?? '',
      linkedin: student['linkedin']?.toString() ?? '',
      twitter: student['twitter']?.toString() ?? student['x']?.toString() ?? '',
      instagram: student['instagram']?.toString() ?? '',
      youtube: student['youtube']?.toString() ?? '',
      photoUrl: ApiConfig.resolveImageUrl(student['photo_url']?.toString() ?? student['avatar']?.toString() ?? defaultPhoto),
      emailNotifications: notifs['email'] != false,
      whatsappNotifications: notifs['whatsapp'] != false,
      pushNotifications: notifs['push'] == true,
      marketingEmails: notifs['marketing'] == true,
      assignmentReminders: notifs['assignment_reminders'] != false,
      liveClassReminders: notifs['live_class_reminders'] != false,
      eventNotifications: notifs['event_notifications'] != false,
      courseUpdates: notifs['course_updates'] != false,
      paymentUpdates: notifs['payment_updates'] != false,
      certificateAlerts: notifs['certificate_alerts'] != false,
      theme: prefs['theme']?.toString() ?? 'System',
      dateFormat: prefs['date_format']?.toString() ?? 'DD/MM/YYYY',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'display_name': displayName,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'country': country,
      'state': state,
      'city': city,
      'postal_code': postalCode,
      'address': address,
      'preferred_language': preferredLanguage,
      'time_zone': timeZone,
      'qualification': qualification,
      'occupation': occupation,
      'institution': institution,
      'bio': bio,
      'emergency_name': emergencyName,
      'emergency_phone': emergencyPhone,
      'parent_name': parentName,
      'parent_phone': parentPhone,
      'website': website,
      'linkedin': linkedin,
      'twitter': twitter,
      'instagram': instagram,
      'youtube': youtube,
      'notification_preferences': {
        'email': emailNotifications,
        'whatsapp': whatsappNotifications,
        'push': pushNotifications,
        'marketing': marketingEmails,
        'assignment_reminders': assignmentReminders,
        'live_class_reminders': liveClassReminders,
        'event_notifications': eventNotifications,
        'course_updates': courseUpdates,
        'payment_updates': paymentUpdates,
        'certificate_alerts': certificateAlerts,
      },
      'preferences': {
        'theme': theme,
        'date_format': dateFormat,
        'language': preferredLanguage,
        'time_zone': timeZone,
      }
    };
  }

  StudentProfileData copyWith({
    int? id,
    String? studentId,
    String? email,
    String? phone,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    String? registrationDate,
    String? firstName,
    String? lastName,
    String? displayName,
    String? dateOfBirth,
    String? gender,
    String? country,
    String? state,
    String? city,
    String? postalCode,
    String? address,
    String? preferredLanguage,
    String? timeZone,
    String? qualification,
    String? occupation,
    String? institution,
    String? bio,
    String? emergencyName,
    String? emergencyPhone,
    String? parentName,
    String? parentPhone,
    String? website,
    String? linkedin,
    String? twitter,
    String? instagram,
    String? youtube,
    String? photoUrl,
    bool? emailNotifications,
    bool? whatsappNotifications,
    bool? pushNotifications,
    bool? marketingEmails,
    bool? assignmentReminders,
    bool? liveClassReminders,
    bool? eventNotifications,
    bool? courseUpdates,
    bool? paymentUpdates,
    bool? certificateAlerts,
    String? theme,
    String? dateFormat,
  }) {
    return StudentProfileData(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      registrationDate: registrationDate ?? this.registrationDate,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      displayName: displayName ?? this.displayName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      address: address ?? this.address,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      timeZone: timeZone ?? this.timeZone,
      qualification: qualification ?? this.qualification,
      occupation: occupation ?? this.occupation,
      institution: institution ?? this.institution,
      bio: bio ?? this.bio,
      emergencyName: emergencyName ?? this.emergencyName,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      website: website ?? this.website,
      linkedin: linkedin ?? this.linkedin,
      twitter: twitter ?? this.twitter,
      instagram: instagram ?? this.instagram,
      youtube: youtube ?? this.youtube,
      photoUrl: photoUrl ?? this.photoUrl,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      whatsappNotifications: whatsappNotifications ?? this.whatsappNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      marketingEmails: marketingEmails ?? this.marketingEmails,
      assignmentReminders: assignmentReminders ?? this.assignmentReminders,
      liveClassReminders: liveClassReminders ?? this.liveClassReminders,
      eventNotifications: eventNotifications ?? this.eventNotifications,
      courseUpdates: courseUpdates ?? this.courseUpdates,
      paymentUpdates: paymentUpdates ?? this.paymentUpdates,
      certificateAlerts: certificateAlerts ?? this.certificateAlerts,
      theme: theme ?? this.theme,
      dateFormat: dateFormat ?? this.dateFormat,
    );
  }
}

/// Detailed Order Item for `7 - profile my product 7.pdf`
class StudentOrderItem {
  const StudentOrderItem({
    required this.id,
    required this.title,
    this.orderCode = '',
    this.invoiceCode = '',
    this.productType = 'COURSE',
    this.status = 'PENDING PAYMENT',
    this.fulfillmentStatus = 'PENDING',
    this.shipmentStatus = 'NONE',
    this.amount = 0.0,
    this.currency = '₹',
    this.dateStr = '',
    this.cashfreeOrderId = '',
    this.paymentId = '',
    this.paymentMethod = '',
    this.receiptCode = '',
    this.thumbnailUrl,
    this.courseId,
    this.invoiceUrl,
    this.receiptUrl,
  });

  final int id;
  final String title;
  final String orderCode;
  final String invoiceCode;
  final String productType; // COURSE, LIBRARY, STORE, EVENTS, SCHOLARSHIPS
  final String status; // PENDING PAYMENT, PAYMENT SUCCESSFUL, FAILED, CANCELLED, REFUNDED
  final String fulfillmentStatus; // PENDING, COMPLETED
  final String shipmentStatus; // NONE, SHIPPED, DELIVERED
  final double amount;
  final String currency;
  final String dateStr;
  final String cashfreeOrderId;
  final String paymentId;
  final String paymentMethod;
  final String receiptCode;
  final String? thumbnailUrl;
  final int? courseId;
  final String? invoiceUrl;
  final String? receiptUrl;

  bool get isSuccessful =>
      status.toUpperCase().contains('SUCCESS') || status.toUpperCase().contains('COMPLETED') || status.toUpperCase().contains('PAID');

  bool get isPending => status.toUpperCase().contains('PENDING');

  factory StudentOrderItem.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['total_amount'] ?? json['amount'] ?? json['price'] ?? 0;
    final parsedAmount = double.tryParse(rawAmount.toString()) ?? 0.0;

    final rawStatus = json['status']?.toString() ?? json['payment_status']?.toString() ?? 'pending';
    String normStatus;
    if (rawStatus.toLowerCase() == 'completed' || rawStatus.toLowerCase() == 'paid' || rawStatus.toLowerCase() == 'success') {
      normStatus = 'PAYMENT SUCCESSFUL';
    } else if (rawStatus.toLowerCase() == 'cancelled') {
      normStatus = 'CANCELLED';
    } else if (rawStatus.toLowerCase() == 'failed') {
      normStatus = 'FAILED';
    } else if (rawStatus.toLowerCase() == 'refunded') {
      normStatus = 'REFUNDED';
    } else {
      normStatus = 'PENDING PAYMENT';
    }

    final createdAt = json['created_at']?.toString() ?? json['date']?.toString() ?? '';

    return StudentOrderItem(
      id: int.tryParse(json['id']?.toString() ?? json['order_id']?.toString() ?? '0') ?? 0,
      title: json['item_name']?.toString() ?? json['title']?.toString() ?? json['course_title']?.toString() ?? 'Course Enrollment',
      orderCode: json['order_number']?.toString() ?? json['code']?.toString() ?? (json['id'] != null ? 'ZA-2026-0000${json['id']}' : 'ZA-2026-000001'),
      invoiceCode: json['invoice_number']?.toString() ?? json['invoice_code']?.toString() ?? '',
      productType: (json['product_type']?.toString() ?? json['type']?.toString() ?? 'COURSE').toUpperCase(),
      status: normStatus,
      fulfillmentStatus: (json['fulfillment_status']?.toString() ?? (normStatus == 'PAYMENT SUCCESSFUL' ? 'COMPLETED' : 'PENDING')).toUpperCase(),
      shipmentStatus: (json['shipment_status']?.toString() ?? 'NONE').toUpperCase(),
      amount: parsedAmount,
      currency: json['currency']?.toString() == 'USD' ? '\$' : '₹',
      dateStr: createdAt,
      cashfreeOrderId: json['cashfree_order_id']?.toString() ?? json['gateway_order_id']?.toString() ?? '',
      paymentId: json['payment_id']?.toString() ?? json['transaction_id']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? json['method']?.toString() ?? 'upi',
      receiptCode: json['receipt_number']?.toString() ?? json['receipt_code']?.toString() ?? '',
      thumbnailUrl: ApiConfig.resolveImageUrl(json['image_url']?.toString() ?? json['thumbnail']?.toString() ?? json['course_image']?.toString()),
      courseId: int.tryParse(json['course_id']?.toString() ?? ''),
      invoiceUrl: json['invoice_url']?.toString() ?? json['invoice_pdf']?.toString(),
      receiptUrl: json['receipt_url']?.toString() ?? json['receipt_pdf']?.toString(),
    );
  }
}

/// Purchased Book Item for `3 - profile my book 3.pdf`
class StudentBookItem {
  const StudentBookItem({
    required this.id,
    required this.title,
    this.author = '',
    this.coverImage,
    this.pdfUrl,
    this.purchasedAt,
    this.format = 'PDF eBook',
  });

  final int id;
  final String title;
  final String author;
  final String? coverImage;
  final String? pdfUrl;
  final DateTime? purchasedAt;
  final String format;

  factory StudentBookItem.fromJson(Map<String, dynamic> json) {
    return StudentBookItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'Islamic Book',
      author: json['author']?.toString() ?? json['writer']?.toString() ?? 'Zabira Academy',
      coverImage: ApiConfig.resolveImageUrl(json['cover_image']?.toString() ?? json['image']?.toString()),
      pdfUrl: json['pdf_url']?.toString() ?? json['file_url']?.toString(),
      purchasedAt: DateTime.tryParse(json['purchased_at']?.toString() ?? json['created_at']?.toString() ?? ''),
      format: json['format']?.toString() ?? 'PDF eBook',
    );
  }
}

/// Wishlist Item for `8 - profile whishlist 8.pdf`
class StudentWishlistItem {
  const StudentWishlistItem({
    required this.id,
    required this.courseId,
    required this.title,
    this.category = 'Quran Studies',
    this.thumbnailUrl,
    this.price = 0.0,
    this.discountPrice = 0.0,
    this.rating = 5.0,
    this.duration = '6 months',
  });

  final int id;
  final int courseId;
  final String title;
  final String category;
  final String? thumbnailUrl;
  final double price;
  final double discountPrice;
  final double rating;
  final String duration;

  factory StudentWishlistItem.fromJson(Map<String, dynamic> json) {
    return StudentWishlistItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      courseId: int.tryParse((json['course_id'] ?? json['id'] ?? 0).toString()) ?? 0,
      title: json['title']?.toString() ?? json['course_name']?.toString() ?? 'Course',
      category: json['category_name']?.toString() ?? json['category']?.toString() ?? 'Quran Studies',
      thumbnailUrl: ApiConfig.resolveImageUrl(json['thumbnail']?.toString() ?? json['image_url']?.toString()),
      price: double.tryParse((json['price'] ?? 0).toString()) ?? 0.0,
      discountPrice: double.tryParse((json['discount_price'] ?? json['price'] ?? 0).toString()) ?? 0.0,
      rating: double.tryParse((json['rating'] ?? 5.0).toString()) ?? 5.0,
      duration: json['duration']?.toString() ?? '6 months',
    );
  }
}
