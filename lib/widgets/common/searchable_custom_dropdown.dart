import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Reusable, keyboard-aware Searchable Dropdown with Custom Entry Support
///
/// Features:
/// 1. FormField integration for native form validation.
/// 2. Tap to open full-featured searchable modal bottom sheet.
/// 3. Real-time substring search filtering.
/// 4. "+ Add Custom Value" action when typed query doesn't match predefined options.
/// 5. Case-insensitive deduplication and whitespace trimming.
/// 6. Custom validation and normalization support (e.g. for height formats).
/// 7. Keyboard-safe bottom sheet (prevents keyboard clipping and overflow).
class SearchableCustomDropdown extends FormField<String> {
  final String label;
  final String? currentValue;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final IconData? prefixIcon;
  final String? hint;
  final String? searchHint;
  final bool isRequired;
  final String? Function(String?)? customValidator;
  final String? Function(String)? customNormalizer;

  SearchableCustomDropdown({
    super.key,
    required this.label,
    required this.currentValue,
    required this.options,
    required this.onSelected,
    this.prefixIcon,
    this.hint,
    this.searchHint,
    this.isRequired = true,
    this.customValidator,
    this.customNormalizer,
    super.onSaved,
  }) : super(
          initialValue: currentValue,
          validator: (val) {
            if (isRequired && (val == null || val.trim().isEmpty)) {
              return 'Please select or enter $label';
            }
            if (customValidator != null) {
              return customValidator(val);
            }
            return null;
          },
          builder: (FormFieldState<String> state) {
            return _SearchableCustomDropdownField(
              label: label,
              currentValue: state.value,
              options: options,
              prefixIcon: prefixIcon,
              hint: hint,
              searchHint: searchHint,
              isRequired: isRequired,
              errorText: state.errorText,
              customValidator: customValidator,
              customNormalizer: customNormalizer,
              onChanged: (newVal) {
                state.didChange(newVal);
                onSelected(newVal);
              },
            );
          },
        );
}

class _SearchableCustomDropdownField extends StatelessWidget {
  final String label;
  final String? currentValue;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final IconData? prefixIcon;
  final String? hint;
  final String? searchHint;
  final bool isRequired;
  final String? errorText;
  final String? Function(String?)? customValidator;
  final String? Function(String)? customNormalizer;

  const _SearchableCustomDropdownField({
    required this.label,
    required this.currentValue,
    required this.options,
    required this.onChanged,
    this.prefixIcon,
    this.hint,
    this.searchHint,
    this.isRequired = true,
    this.errorText,
    this.customValidator,
    this.customNormalizer,
  });

  void _openSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SearchableDropdownModal(
        label: label,
        currentValue: currentValue,
        options: options,
        searchHint: searchHint,
        customValidator: customValidator,
        customNormalizer: customNormalizer,
        onSelected: (val) {
          Navigator.pop(ctx);
          onChanged(val);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = currentValue != null && currentValue!.trim().isNotEmpty;
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => _openSearchModal(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF9F6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasError
                    ? Colors.red.shade400
                    : AppTheme.cardBorder,
                width: hasError ? 1.4 : 1.0,
              ),
            ),
            child: Row(
              children: [
                if (prefixIcon != null) ...[
                  Icon(
                    prefixIcon,
                    color: hasValue ? AppTheme.burgundy : AppTheme.textMuted,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: hasError
                              ? Colors.red.shade700
                              : AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hasValue ? currentValue! : (hint ?? 'Tap to select or enter custom...'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                          color: hasValue ? AppTheme.textPrimary : AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down_rounded,
                  color: AppTheme.textSecondary,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 4),
            child: Text(
              errorText!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

class _SearchableDropdownModal extends StatefulWidget {
  final String label;
  final String? currentValue;
  final List<String> options;
  final String? searchHint;
  final ValueChanged<String> onSelected;
  final String? Function(String?)? customValidator;
  final String? Function(String)? customNormalizer;

  const _SearchableDropdownModal({
    required this.label,
    required this.currentValue,
    required this.options,
    this.searchHint,
    required this.onSelected,
    this.customValidator,
    this.customNormalizer,
  });

  @override
  State<_SearchableDropdownModal> createState() =>
      _SearchableDropdownModalState();
}

class _SearchableDropdownModalState extends State<_SearchableDropdownModal> {
  late final TextEditingController _searchController;
  late List<String> _filteredOptions;
  String? _customError;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredOptions = List.from(widget.options);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final clean = query.trim().toLowerCase();
    setState(() {
      _customError = null;
      if (clean.isEmpty) {
        _filteredOptions = List.from(widget.options);
      } else {
        _filteredOptions = widget.options
            .where((opt) => opt.toLowerCase().contains(clean))
            .toList();
      }
    });
  }

  void _confirmCustomValue(String rawInput) {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) return;

    // Check custom validator if specified
    if (widget.customValidator != null) {
      final err = widget.customValidator!(trimmed);
      if (err != null) {
        setState(() => _customError = err);
        return;
      }
    }

    // Check custom normalizer if specified
    String finalValue = trimmed;
    if (widget.customNormalizer != null) {
      final normalized = widget.customNormalizer!(trimmed);
      if (normalized != null) {
        finalValue = normalized;
      } else {
        setState(() => _customError = 'Invalid ${widget.label.replaceAll('*', '').trim()} format.');
        return;
      }
    }

    widget.onSelected(finalValue);
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();
    // Check if query exactly matches an existing option (case-insensitive)
    final bool exactMatchExists = widget.options.any(
      (opt) => opt.toLowerCase() == query.toLowerCase(),
    );
    final bool canAddCustom = query.isNotEmpty && !exactMatchExists;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Header title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select ${widget.label.replaceAll('*', '').trim()}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.burgundy,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search text field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                onSubmitted: (val) {
                  if (canAddCustom) {
                    _confirmCustomValue(val);
                  }
                },
                decoration: InputDecoration(
                  hintText: widget.searchHint ?? 'Search or type custom...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.burgundy),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF8F9FA),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.burgundy, width: 1.5),
                  ),
                ),
              ),
            ),

            // Custom error message if validation failed
            if (_customError != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _customError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

            // Pinned "+ Add Custom Value" Tile if query is new
            if (canAddCustom)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.roseLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.burgundy.withValues(alpha: 0.3)),
                ),
                child: ListTile(
                  dense: true,
                  leading: const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.burgundy,
                    child: Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  ),
                  title: Text(
                    'Add "$query"',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.burgundy,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    'Use "$query" as custom value',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  trailing: const Icon(Icons.arrow_forward_rounded, size: 18, color: AppTheme.burgundy),
                  onTap: () => _confirmCustomValue(query),
                ),
              ),

            // Scrollable suggestions list
            Expanded(
              child: _filteredOptions.isEmpty && !canAddCustom
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFFCBD5E1)),
                          const SizedBox(height: 10),
                          Text(
                            query.isEmpty
                                ? 'No suggestions available'
                                : 'No matching suggestions for "$query"',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredOptions.length,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      itemBuilder: (context, index) {
                        final option = _filteredOptions[index];
                        final isSelected = widget.currentValue != null &&
                            widget.currentValue!.toLowerCase() == option.toLowerCase();

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.roseLight : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                            title: Text(
                              option,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? AppTheme.burgundy : AppTheme.textPrimary,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle_rounded, color: AppTheme.burgundy, size: 20)
                                : null,
                            onTap: () => widget.onSelected(option),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
