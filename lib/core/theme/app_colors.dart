import 'package:flutter/material.dart';

/// Zabira Academy Design System — Color Palette
///
/// Extracted directly from the official Zabira Academy Login Page design reference.
/// All colors match the PDF-extracted hex values from the website design system.
abstract final class AppColors {
  // ─── Brand Primary ────────────────────────────────────────────────────────
  /// Deep navy — primary dark background, Teacher button fill
  static const Color navyDark = Color(0xFF0A1628);

  /// Navy text — headings and dark text on light backgrounds
  static const Color navyText = Color(0xFF0B1628);

  // ─── Gold / Amber Accent ──────────────────────────────────────────────────
  /// Primary gold — CTA buttons, stat numbers, Forgot Password link, Create account link
  static const Color gold = Color(0xFFC9A84C);

  /// Gold variant — hover / lighter contexts
  static const Color goldLight = Color(0xFFCAA74D);

  // ─── Surfaces ─────────────────────────────────────────────────────────────
  /// Light gray — right panel / form area background
  static const Color surfaceLight = Color(0xFFF5F5F7);

  /// Pure white — cards, inputs, panels
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  /// Soft cream — feature icon container background
  static const Color softCream = Color(0xFFFAF7F2);

  /// Off-white — text field fill
  static const Color inputBackground = Color(0xFFFAFAFB);

  // ─── Borders / Dividers ───────────────────────────────────────────────────
  /// Input border color
  static const Color borderLight = Color(0xFFE7ECF1);

  /// Divider / separator color
  static const Color borderMedium = Color(0xFFE3E8F0);

  // ─── Text ─────────────────────────────────────────────────────────────────
  /// Dark heading text (on light backgrounds)
  static const Color textPrimary = Color(0xFF0B1628);

  /// Muted / subtitle text — placeholders, helper text, inactive tabs
  static const Color textSecondary = Color(0xFF6B7A99);

  /// White text (on dark/navy backgrounds)
  static const Color textWhite = Color(0xFFFFFFFF);

  /// Gold accent text — links, emphasis on dark backgrounds
  static const Color textGold = Color(0xFFC9A84C);

  // ─── Semantic / Feedback ──────────────────────────────────────────────────
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFB300);

  // ─── Card on dark background ──────────────────────────────────────────────
  /// Feature card border on navy background
  static const Color cardBorderOnDark = Color(0x33FFFFFF); // white 20%

  /// Feature card background on navy background
  static const Color cardBgOnDark = Color(0x1AFFFFFF); // white 10%

  // ─── Overlay ──────────────────────────────────────────────────────────────
  static const Color scrim = Color(0xAA000000);

  // ─── Transparent ──────────────────────────────────────────────────────────
  static const Color transparent = Colors.transparent;
}
