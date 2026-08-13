import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// BuildContext extension utilities for Zabira Academy
extension ContextExtensions on BuildContext {
  // ─── Theme Shortcuts ──────────────────────────────────────────────────────
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  // ─── Screen Size ──────────────────────────────────────────────────────────
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  double get topPadding => MediaQuery.of(this).padding.top;
  double get bottomPadding => MediaQuery.of(this).padding.bottom;
  double get keyboardHeight => MediaQuery.of(this).viewInsets.bottom;
  bool get isKeyboardVisible => MediaQuery.of(this).viewInsets.bottom > 0;

  // ─── Navigation ───────────────────────────────────────────────────────────
  NavigatorState get navigator => Navigator.of(this);

  void pop<T>([T? result]) => Navigator.of(this).pop(result);

  // ─── SnackBar ─────────────────────────────────────────────────────────────
  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite),
          ),
          backgroundColor: AppColors.error,
        ),
      );
  }

  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite),
          ),
          backgroundColor: AppColors.success,
        ),
      );
  }

  void showInfoSnackBar(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite),
          ),
          backgroundColor: AppColors.navyDark,
        ),
      );
  }
}
