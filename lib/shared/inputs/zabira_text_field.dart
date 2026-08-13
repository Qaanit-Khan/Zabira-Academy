import 'package:flutter/material.dart';
import 'package:zabira_academy/core/theme/app_colors.dart';
import 'package:zabira_academy/core/theme/app_typography.dart';
import 'package:zabira_academy/core/theme/app_spacing.dart';

/// Zabira Academy Branded Text Input Field
///
/// Matches the design reference exactly:
/// - Off-white fill (#FAFAFB)
/// - Light gray border (#E7ECF1)
/// - Gold focused border
/// - Prefix icon in muted color
/// - Password visibility toggle
class ZabiraTextField extends StatefulWidget {
  const ZabiraTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.isPassword = false,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.keyboardType,
    this.onFieldSubmitted,
    this.focusNode,
    this.autofillHints,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData? prefixIcon;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onFieldSubmitted;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;
  final bool enabled;

  @override
  State<ZabiraTextField> createState() => _ZabiraTextFieldState();
}

class _ZabiraTextFieldState extends State<ZabiraTextField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: widget.isPassword ? _obscured : false,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      keyboardType: widget.keyboardType,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofillHints: widget.autofillHints,
      enabled: widget.enabled,
      style: AppTypography.inputText,
      cursorColor: AppColors.gold,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: AppTypography.inputHint,
        prefixIcon: widget.prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Icon(widget.prefixIcon, color: AppColors.textSecondary, size: 20),
              )
            : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        suffixIcon: widget.isPassword
            ? GestureDetector(
                onTap: () => setState(() => _obscured = !_obscured),
                child: Icon(
                  _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              )
            : null,
      ),
    );
  }
}
