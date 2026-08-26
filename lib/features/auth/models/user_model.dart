import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/api_config.dart';
import 'user_role.dart';

/// Zabira Academy — User Model
///
/// Represents an authenticated user profile.
/// Supports REST API responses (`/auth/profile`, `/student/profile`) as well as Firestore documents.
class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.createdAt,
    this.photoUrl,
    this.phone,
    this.mobile,
    this.gender,
    this.dateOfBirth,
    this.country,
    this.state,
    this.city,
    this.studentId,
    this.registrationDate,
    this.isEmailVerified = false,
    // Parent-specific
    this.childIds = const [],
    // Student-specific
    this.parentId,
    this.ageOrGrade,
    // Teacher-specific
    this.isTeacherVerified = false,
  });

  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final DateTime createdAt;
  final String? photoUrl;
  final String? phone;
  final String? mobile;
  final String? gender;
  final String? dateOfBirth;
  final String? country;
  final String? state;
  final String? city;
  final int? studentId;
  final String? registrationDate;
  final bool isEmailVerified;

  // ─── Parent ───────────────────────────────────────────────────────────────
  final List<String> childIds;

  // ─── Student ──────────────────────────────────────────────────────────────
  final String? parentId;
  final int? ageOrGrade;

  // ─── Teacher ──────────────────────────────────────────────────────────────
  final bool isTeacherVerified;

  String? get resolvedPhotoUrl => ApiConfig.resolveImageUrl(photoUrl);

  String get formattedPhone => phone ?? mobile ?? '';

  String get formattedLocation {
    final parts = [city, state, country].where((e) => e != null && e.trim().isNotEmpty).toList();
    return parts.join(', ');
  }

  // ─── API JSON Serialization ───────────────────────────────────────────────
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role']?.toString() ?? 'student';
    final name = json['full_name']?.toString() ??
        json['name']?.toString() ??
        json['displayName']?.toString() ??
        json['username']?.toString() ??
        json['email']?.toString().split('@').first ??
        'Student';

    final photo = json['photo_url']?.toString() ??
        json['photo_path']?.toString() ??
        json['avatar']?.toString() ??
        json['photoUrl']?.toString();

    return UserModel(
      uid: json['id']?.toString() ?? json['uid']?.toString() ?? json['user_id']?.toString() ?? '1',
      email: json['email']?.toString() ?? '',
      displayName: name,
      role: UserRole.fromString(roleStr),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? json['registration_date']?.toString() ?? '') ?? DateTime.now(),
      photoUrl: photo,
      phone: json['phone']?.toString() ?? json['contact_number']?.toString(),
      mobile: json['mobile']?.toString() ?? json['whatsapp']?.toString(),
      gender: json['gender']?.toString(),
      dateOfBirth: json['date_of_birth']?.toString() ?? json['dateOfBirth']?.toString(),
      country: json['country']?.toString(),
      state: json['state']?.toString(),
      city: json['city']?.toString(),
      studentId: json['student_id'] != null ? int.tryParse(json['student_id'].toString()) : null,
      registrationDate: json['registration_date']?.toString(),
      isEmailVerified: json['is_email_verified'] == true || json['email_verified'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'id': uid,
    'email': email,
    'displayName': displayName,
    'full_name': displayName,
    'role': role.value,
    'createdAt': createdAt.toIso8601String(),
    'photoUrl': photoUrl,
    'photo_url': photoUrl,
    'phone': phone,
    'mobile': mobile,
    'gender': gender,
    'date_of_birth': dateOfBirth,
    'country': country,
    'state': state,
    'city': city,
    'student_id': studentId,
    'registration_date': registrationDate,
    'isEmailVerified': isEmailVerified,
  };

  // ─── Firestore Serialization (Backward Compatibility) ─────────────────────
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String? ?? 'student'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photoUrl: data['photoUrl'] as String?,
      isEmailVerified: data['isEmailVerified'] as bool? ?? false,
      childIds: List<String>.from(data['childIds'] as List? ?? []),
      parentId: data['parentId'] as String?,
      ageOrGrade: data['ageOrGrade'] as int?,
      isTeacherVerified: data['isTeacherVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'email': email,
    'displayName': displayName,
    'role': role.value,
    'createdAt': Timestamp.fromDate(createdAt),
    'photoUrl': photoUrl,
    'isEmailVerified': isEmailVerified,
    'childIds': childIds,
    'parentId': parentId,
    'ageOrGrade': ageOrGrade,
    'isTeacherVerified': isTeacherVerified,
  };

  UserModel copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    String? phone,
    String? mobile,
    String? gender,
    String? dateOfBirth,
    String? country,
    String? state,
    String? city,
    int? studentId,
    String? registrationDate,
    bool? isEmailVerified,
    List<String>? childIds,
    String? parentId,
    int? ageOrGrade,
    bool? isTeacherVerified,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role,
      createdAt: createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      studentId: studentId ?? this.studentId,
      registrationDate: registrationDate ?? this.registrationDate,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      childIds: childIds ?? this.childIds,
      parentId: parentId ?? this.parentId,
      ageOrGrade: ageOrGrade ?? this.ageOrGrade,
      isTeacherVerified: isTeacherVerified ?? this.isTeacherVerified,
    );
  }

  @override
  String toString() => 'UserModel(uid: $uid, email: $email, role: ${role.value})';
}
