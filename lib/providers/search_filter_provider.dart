import 'package:flutter/material.dart';
import '../models/matrimony_profile_model.dart';

/// Provider for Matrimonial Search & Multi-Filter Query Engine
class SearchFilterProvider extends ChangeNotifier {
  String _searchQuery = '';
  String? _selectedCity;
  String? _selectedReligion;
  String? _selectedMaritalStatus;
  String? _selectedEducation;
  RangeValues _ageRange = const RangeValues(21, 40);

  String get searchQuery => _searchQuery;
  String? get selectedCity => _selectedCity;
  String? get selectedReligion => _selectedReligion;
  String? get selectedMaritalStatus => _selectedMaritalStatus;
  String? get selectedEducation => _selectedEducation;
  RangeValues get ageRange => _ageRange;

  int get activeFilterCount {
    int count = 0;
    if (_searchQuery.trim().isNotEmpty) count++;
    if (_selectedCity != null && _selectedCity != 'All Locations') count++;
    if (_selectedReligion != null) count++;
    if (_selectedMaritalStatus != null) count++;
    if (_selectedEducation != null) count++;
    if (_ageRange.start > 21 || _ageRange.end < 40) count++;
    return count;
  }

  bool get hasActiveFilters => activeFilterCount > 0;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void updateFilters({
    String? city,
    String? religion,
    String? maritalStatus,
    String? education,
    RangeValues? ageRange,
  }) {
    _selectedCity = city;
    _selectedReligion = religion;
    _selectedMaritalStatus = maritalStatus;
    _selectedEducation = education;
    if (ageRange != null) _ageRange = ageRange;
    notifyListeners();
  }

  void clearAllFilters() {
    _searchQuery = '';
    _selectedCity = null;
    _selectedReligion = null;
    _selectedMaritalStatus = null;
    _selectedEducation = null;
    _ageRange = const RangeValues(21, 40);
    notifyListeners();
  }

  /// Filters given list of profiles according to active criteria
  List<MatrimonyProfileModel> filterProfiles(List<MatrimonyProfileModel> list) {
    return list.where((p) {
      // 1. Text Query
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final match = p.fullName.toLowerCase().contains(q) ||
            p.occupation.toLowerCase().contains(q) ||
            p.city.toLowerCase().contains(q) ||
            p.highestEducation.toLowerCase().contains(q) ||
            p.community.toLowerCase().contains(q) ||
            p.profileId.toLowerCase().contains(q);
        if (!match) return false;
      }

      // 2. City
      if (_selectedCity != null && _selectedCity != 'All Locations') {
        if (!p.city.toLowerCase().contains(_selectedCity!.toLowerCase())) return false;
      }

      // 3. Religion
      if (_selectedReligion != null && _selectedReligion!.isNotEmpty) {
        if (!p.religion.toLowerCase().contains(_selectedReligion!.toLowerCase())) return false;
      }

      // 4. Marital Status
      if (_selectedMaritalStatus != null && _selectedMaritalStatus!.isNotEmpty) {
        if (p.maritalStatus != _selectedMaritalStatus) return false;
      }

      // 5. Education
      if (_selectedEducation != null && _selectedEducation!.isNotEmpty) {
        if (!p.highestEducation.toLowerCase().contains(_selectedEducation!.toLowerCase())) return false;
      }

      // 6. Age Range
      if (p.age < _ageRange.start.round() || p.age > _ageRange.end.round()) {
        return false;
      }

      return true;
    }).toList();
  }
}
