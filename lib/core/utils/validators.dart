import 'package:zabira_academy/core/constants/app_strings.dart';

/// Zabira Academy — Form Validators
abstract final class Validators {
  Validators._();

  /// Validates email address
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    final emailRegex = RegExp(r'^[\w\-\.+]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return AppStrings.invalidEmail;
    return null;
  }

  /// Validates login password (just non-empty check for login)
  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) return AppStrings.fieldRequired;
    return null;
  }

  /// Validates new password (min 8 chars)
  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return AppStrings.fieldRequired;
    if (value.length < 8) return AppStrings.passwordTooShort;
    return null;
  }

  /// Validates password confirmation
  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) return AppStrings.fieldRequired;
      if (value != password) return AppStrings.passwordMismatch;
      return null;
    };
  }

  /// Validates display name
  static String? displayName(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    if (value.trim().length < 2) return AppStrings.nameTooShort;
    return null;
  }

  /// Generic required field
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    return null;
  }
}
