import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Zabira Academy Design System — Typography
///
/// Primary font: Poppins (as used on the Zabira Academy website).
/// Weights used: Regular (400), Medium (500), SemiBold (600), Bold (700).
abstract final class AppTypography {
  // ─── Font Family ──────────────────────────────────────────────────────────
  static const String fontFamily = 'Poppins';

  // ─── Display ──────────────────────────────────────────────────────────────
  /// Hero heading — "Knowledge that elevates every journey"
  static TextStyle get displayLarge => GoogleFonts.poppins(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: AppColors.textWhite,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle get displayMedium => GoogleFonts.poppins(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textWhite,
    height: 1.25,
  );

  // ─── Headline ─────────────────────────────────────────────────────────────
  /// "Welcome back" heading on the form panel
  static TextStyle get headlineLarge => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get headlineMedium => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get headlineSmall =>
      GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  // ─── Title ────────────────────────────────────────────────────────────────
  static TextStyle get titleLarge =>
      GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  static TextStyle get titleMedium =>
      GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  static TextStyle get titleSmall =>
      GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary);

  // ─── Body ─────────────────────────────────────────────────────────────────
  /// Subtitles, descriptions, supporting text
  static TextStyle get bodyLarge => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.outfit(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // ─── Label ────────────────────────────────────────────────────────────────
  /// Button labels, navigation labels
  static TextStyle get labelLarge => GoogleFonts.outfit(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.2,
  );

  static TextStyle get labelMedium =>
      GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  /// "LEARNING PORTAL" badge text — uppercase tracking
  static TextStyle get labelSmall => GoogleFonts.outfit(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textGold,
    letterSpacing: 1.5,
  );

  // ─── Input ────────────────────────────────────────────────────────────────
  static TextStyle get inputText =>
      GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary);

  static TextStyle get inputHint => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // ─── Stat numbers (10k+, 200+, 50+) ────────────────────────────────────
  static TextStyle get statNumber =>
      GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.gold);

  static TextStyle get statLabel => GoogleFonts.outfit(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textWhite.withAlpha(180),
  );

  // ─── TextTheme for MaterialApp ────────────────────────────────────────────
  static TextTheme get textTheme => TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}
