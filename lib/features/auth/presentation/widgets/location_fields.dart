import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

const List<String> zabiraCountryOptions = [
  'India',
  'United States',
  'United Kingdom',
  'Canada',
  'Australia',
  'United Arab Emirates',
  'Saudi Arabia',
  'Qatar',
  'Kuwait',
  'Oman',
  'Bahrain',
  'Pakistan',
  'Bangladesh',
  'Malaysia',
  'Singapore',
  'South Africa',
];

class CountrySelectionField extends StatefulWidget {
  const CountrySelectionField({
    super.key,
    required this.controller,
    this.onSelected,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onSelected;

  @override
  State<CountrySelectionField> createState() => _CountrySelectionFieldState();
}

class _CountrySelectionFieldState extends State<CountrySelectionField> {
  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: widget.controller.text),
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return zabiraCountryOptions;
        return zabiraCountryOptions.where(
          (country) => country.toLowerCase().contains(query),
        );
      },
      onSelected: (value) {
        widget.controller.text = value;
        widget.onSelected?.call(value);
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          style: AppTypography.inputText,
          decoration: const InputDecoration(
            hintText: 'Type country',
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: AppSpacing.sm),
              child: Icon(
                Icons.public_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            prefixIconConstraints: BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          onChanged: (value) => widget.controller.text = value,
          validator: (value) {
            final country = value?.trim() ?? '';
            if (country.isEmpty) return 'Please select a country.';
            final selected = zabiraCountryOptions.any(
              (option) => option.toLowerCase() == country.toLowerCase(),
            );
            return selected ? null : 'Please select a country.';
          },
        );
      },
    );
  }
}

class DependentLocationField extends StatelessWidget {
  const DependentLocationField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    required this.enabled,
    required this.disabledMessage,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool enabled;
  final String disabledMessage;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      style: AppTypography.inputText,
      decoration: InputDecoration(
        hintText: enabled ? hintText : disabledMessage,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.sm),
          child: Icon(prefixIcon, color: AppColors.textSecondary, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
      ),
      onChanged: onChanged,
      validator: (value) {
        if (!enabled) return disabledMessage;
        return (value == null || value.trim().isEmpty) ? 'Required' : null;
      },
    );
  }
}
