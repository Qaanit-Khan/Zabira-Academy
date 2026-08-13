import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

/// Zabira Academy — Assembled ThemeData
///
/// Centralizes all visual design tokens into a single MaterialApp theme.
/// Every screen must use Theme.of(context) rather than hard-coded values.
final class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildTheme();

  static ThemeData _buildTheme() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.gold,
      onPrimary: AppColors.navyText,
      primaryContainer: AppColors.goldLight,
      onPrimaryContainer: AppColors.navyText,
      secondary: AppColors.navyDark,
      onSecondary: AppColors.textWhite,
      secondaryContainer: AppColors.navyDark,
      onSecondaryContainer: AppColors.textWhite,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: AppColors.textWhite,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: AppTypography.textTheme,

      // ─── Scaffold ─────────────────────────────────────────────────────────
      scaffoldBackgroundColor: AppColors.surfaceLight,

      // ─── AppBar ───────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.navyDark,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.titleLarge.copyWith(color: AppColors.textWhite),
      ),

      // ─── ElevatedButton ───────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.navyText,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          textStyle: AppTypography.labelLarge,
          elevation: 0,
        ),
      ),

      // ─── OutlinedButton ───────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          side: const BorderSide(color: AppColors.borderLight, width: 1.5),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // ─── TextButton ───────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold,
          textStyle: AppTypography.labelMedium.copyWith(
            color: AppColors.gold,
            decoration: TextDecoration.none,
          ),
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),

      // ─── InputDecoration ──────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBackground,
        hintStyle: AppTypography.inputHint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle: AppTypography.bodySmall.copyWith(color: AppColors.error),
      ),

      // ─── CheckboxTheme ────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.gold;
          return AppColors.surfaceWhite;
        }),
        checkColor: WidgetStateProperty.all(AppColors.navyText),
        side: const BorderSide(color: AppColors.borderLight, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // ─── SnackBar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.navyDark,
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),

      // ─── Divider ──────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(color: AppColors.borderMedium, thickness: 1, space: 1),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
