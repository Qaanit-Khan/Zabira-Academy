import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_role.dart';

/// Zabira Academy — User Model
///
/// Represents a user document stored in Firestore at `users/{uid}`.
/// Supports all three roles: parent, student, teacher.
class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.createdAt,
    this.photoUrl,
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
  final bool isEmailVerified;

  // ─── Parent ───────────────────────────────────────────────────────────────
  /// IDs of linked student/child profiles
  final List<String> childIds;

  // ─── Student ──────────────────────────────────────────────────────────────
  /// ID of parent/guardian account
  final String? parentId;

  /// Age or grade level for child learners
  final int? ageOrGrade;

  // ─── Teacher ──────────────────────────────────────────────────────────────
  /// Whether teacher account has been verified by admin
  final bool isTeacherVerified;

  // ─── Serialization ────────────────────────────────────────────────────────
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
    String? displayName,
    String? photoUrl,
    bool? isEmailVerified,
    List<String>? childIds,
    String? parentId,
    int? ageOrGrade,
    bool? isTeacherVerified,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      role: role,
      createdAt: createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
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
