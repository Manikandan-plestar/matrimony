import 'package:flutter/material.dart';
import 'searchable_custom_dropdown.dart';

/// Adapter forwarding CustomDropdownWithManual to the enhanced SearchableCustomDropdown
class CustomDropdownWithManual extends StatelessWidget {
  final String label;
  final String? currentValue;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final String manualHint;
  final IconData? prefixIcon;
  final bool isRequired;
  final String? Function(String?)? customManualValidator;
  final String? Function(String)? customNormalizer;

  const CustomDropdownWithManual({
    super.key,
    required this.label,
    required this.currentValue,
    required this.options,
    required this.onChanged,
    this.manualHint = 'Enter custom value...',
    this.prefixIcon,
    this.isRequired = true,
    this.customManualValidator,
    this.customNormalizer,
  });

  @override
  Widget build(BuildContext context) {
    return SearchableCustomDropdown(
      label: label,
      currentValue: currentValue,
      options: options,
      onSelected: onChanged,
      prefixIcon: prefixIcon,
      hint: manualHint,
      isRequired: isRequired,
      customValidator: customManualValidator,
      customNormalizer: customNormalizer,
    );
  }
}
