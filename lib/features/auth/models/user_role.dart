/// Zabira Academy — User Role
///
/// Drives role-based routing throughout the application.
enum UserRole {
  parent('parent'),
  student('student'),
  teacher('teacher');

  const UserRole(this.value);

  /// The string value stored in Firestore
  final String value;

  /// Create from Firestore string value
  static UserRole fromString(String value) {
    return UserRole.values.firstWhere((r) => r.value == value, orElse: () => UserRole.student);
  }
}
