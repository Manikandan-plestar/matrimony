import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../providers/search_filter_provider.dart';

/// Matrimonial Multi-Filter Bottom Sheet
class SearchFilterSheet extends StatefulWidget {
  const SearchFilterSheet({super.key});

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  late String? _selectedCity;
  late String? _selectedReligion;
  late String? _selectedMaritalStatus;
  late String? _selectedEducation;
  late RangeValues _ageRange;

  @override
  void initState() {
    super.initState();
    final filter = Provider.of<SearchFilterProvider>(context, listen: false);
    _selectedCity = filter.selectedCity;
    _selectedReligion = filter.selectedReligion;
    _selectedMaritalStatus = filter.selectedMaritalStatus;
    _selectedEducation = filter.selectedEducation;
    _ageRange = filter.ageRange;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header & Drag bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Profiles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCity = null;
                        _selectedReligion = null;
                        _selectedMaritalStatus = null;
                        _selectedEducation = null;
                        _ageRange = const RangeValues(21, 40);
                      });
                      context.read<SearchFilterProvider>().clearAllFilters();
                    },
                    child: const Text('Clear All', style: TextStyle(color: AppTheme.rose)),
                  ),
                ],
              ),
              const Divider(color: AppTheme.dividerColor),

              // 1. Age Range Slider
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Age Range',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    '${_ageRange.start.round()} - ${_ageRange.end.round()} yrs',
                    style: const TextStyle(
                      color: AppTheme.burgundy,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              RangeSlider(
                values: _ageRange,
                min: 20,
                max: 50,
                divisions: 30,
                activeColor: AppTheme.burgundy,
                inactiveColor: AppTheme.cardBorder,
                labels: RangeLabels(
                  '${_ageRange.start.round()}',
                  '${_ageRange.end.round()}',
                ),
                onChanged: (values) {
                  setState(() {
                    _ageRange = values;
                  });
                },
              ),

              // 2. City / Location Selector
              const SizedBox(height: 12),
              const Text('Location / City', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.popularCities.map((city) {
                  final isSelected = (_selectedCity == city) || (_selectedCity == null && city == 'All Locations');
                  return ChoiceChip(
                    label: Text(city),
                    selected: isSelected,
                    selectedColor: AppTheme.roseLight,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.burgundy : AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? AppTheme.burgundy : AppTheme.dividerColor,
                      ),
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedCity = city == 'All Locations' ? null : city;
                      });
                    },
                  );
                }).toList(),
              ),

              // 3. Religion Selector
              const SizedBox(height: 16),
              const Text('Religion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.religionOptions.take(5).map((rel) {
                  final isSelected = _selectedReligion == rel;
                  return ChoiceChip(
                    label: Text(rel),
                    selected: isSelected,
                    selectedColor: AppTheme.roseLight,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.burgundy : AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? AppTheme.burgundy : AppTheme.dividerColor,
                      ),
                    ),
                    onSelected: (val) {
                      setState(() {
                        _selectedReligion = val ? rel : null;
                      });
                    },
                  );
                }).toList(),
              ),

              // 4. Marital Status
              const SizedBox(height: 16),
              const Text('Marital Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.maritalStatusOptions.map((status) {
                  final isSelected = _selectedMaritalStatus == status;
                  return ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    selectedColor: AppTheme.roseLight,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.burgundy : AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? AppTheme.burgundy : AppTheme.dividerColor,
                      ),
                    ),
                    onSelected: (val) {
                      setState(() {
                        _selectedMaritalStatus = val ? status : null;
                      });
                    },
                  );
                }).toList(),
              ),

              // Apply Action Button
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<SearchFilterProvider>().updateFilters(
                          city: _selectedCity,
                          religion: _selectedReligion,
                          maritalStatus: _selectedMaritalStatus,
                          education: _selectedEducation,
                          ageRange: _ageRange,
                        );
                    Navigator.pop(context);
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
