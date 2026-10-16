import 'package:flutter/material.dart';
import '../models/matrimony_profile_model.dart';
import '../services/profile_service.dart';

/// Provider for User's Matrimonial Profile and Multi-Phase Publishing Wizard
///
/// On load this provider fetches the real profile from the backend.
/// Mock data is only used as a safe fallback during transition/offline.
class ProfileProvider extends ChangeNotifier {
  MatrimonyProfileModel? _myProfile;
  bool _isLoadingProfile = false;
  String? _profileError;

  // Publishing Wizard Draft State (Phase 1 → Phase 2 → Phase 3)
  int _wizardCurrentPhase = 1; // 1, 2, or 3

  // Phase 1 Draft fields
  String draftCreatedFor = 'Self';
  String draftFullName = '';
  String draftGender = 'Groom';
  DateTime? draftDateOfBirth;
  int draftAge = 28;
  String draftMaritalStatus = 'Never Married';
  String draftHeight = '5\' 10\" (178 cm)';
  String draftMotherTongue = 'English';
  String draftReligion = 'Hindu';
  String draftCommunity = '';
  String draftDietaryPreference = 'Vegetarian';
  String draftPhotoUrl = '';
  String draftCountryCode = '+91';
  String draftPhone = '';
  String draftAddress = '';

  // Phase 2 Draft fields
  String draftHighestEducation = 'B.E / B.Tech';
  String draftOccupation = 'Software Engineer / IT Professional';
  String draftCompany = '';
  String draftAnnualIncome = '₹15 - 25 Lakhs';
  String draftCountry = '';
  String draftState = '';
  String draftCity = '';
  String draftLocality = '';
  String draftFamilyType = 'Nuclear Family';
  String draftFamilyBackground = '';
  String draftFamilyValues = 'Moderate';

  // Phase 3 Draft fields
  int draftPrefAgeMin = 24;
  int draftPrefAgeMax = 28;
  String draftPrefMaritalStatus = 'Never Married';
  String draftPrefLocation = 'Any Worldwide Location';
  String draftPrefEducation = 'B.E / B.Tech / Masters';
  String draftPrefOccupation = 'Working Professional';
  String draftPrefIncome = '₹10 Lakhs & above';
  String draftPartnerExpectations = '';
  String draftBio = '';

  bool _isPublishing = false;

  MatrimonyProfileModel? get myProfile => _myProfile;
  bool get hasProfile => _myProfile != null;
  bool get isLoadingProfile => _isLoadingProfile;
  String? get profileError => _profileError;
  int get wizardCurrentPhase => _wizardCurrentPhase;
  bool get isPublishing => _isPublishing;

  /// Load the profile from backend. Called after login and on screen open.
  Future<void> fetchMyProfile() async {
    _isLoadingProfile = true;
    _profileError = null;
    notifyListeners();
    try {
      final profile = await ProfileService.fetchMyProfile();
      _myProfile = profile;
    } catch (e) {
      _profileError = 'Could not load profile. Please check your connection.';
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  /// Called from AuthProvider after login to seed the profile.
  void seedProfileFromApi(MatrimonyProfileModel? profile) {
    _myProfile = profile;
    notifyListeners();
  }

  void setWizardPhase(int phase) {
    _wizardCurrentPhase = phase;
    notifyListeners();
  }

  void resetWizard() {
    _wizardCurrentPhase = 1;
    draftCreatedFor = 'Self';
    draftFullName = '';
    draftGender = 'Groom';
    draftDateOfBirth = null;
    draftAge = 28;
    draftMaritalStatus = 'Never Married';
    draftHeight = '5\' 10\" (178 cm)';
    draftMotherTongue = 'English';
    draftReligion = 'Hindu';
    draftCommunity = '';
    draftDietaryPreference = 'Vegetarian';
    draftPhotoUrl = '';
    draftCountryCode = '+91';
    draftPhone = '';
    draftAddress = '';
    draftHighestEducation = 'B.E / B.Tech';
    draftOccupation = 'Software Engineer / IT Professional';
    draftCompany = '';
    draftAnnualIncome = '₹15 - 25 Lakhs';
    draftCountry = '';
    draftState = '';
    draftCity = '';
    draftLocality = '';
    draftFamilyType = 'Nuclear Family';
    draftFamilyBackground = '';
    draftFamilyValues = 'Moderate';
    draftPrefAgeMin = 24;
    draftPrefAgeMax = 28;
    draftPrefMaritalStatus = 'Never Married';
    draftPrefLocation = 'Any Worldwide Location';
    draftPrefEducation = 'B.E / B.Tech / Masters';
    draftPrefOccupation = 'Working Professional';
    draftPrefIncome = '₹10 Lakhs & above';
    draftPartnerExpectations = '';
    draftBio = '';
    _isPublishing = false;
    notifyListeners();
  }

  /// If user already has a profile, pre-fill the wizard draft fields for editing.
  void prefillWizardFromProfile() {
    if (_myProfile == null) return;
    final p = _myProfile!;
    draftCreatedFor = p.createdFor;
    draftFullName = p.fullName;
    draftGender = p.gender;
    draftDateOfBirth = p.dateOfBirth;
    draftAge = p.age;
    draftMaritalStatus = p.maritalStatus;
    draftHeight = p.height;
    draftMotherTongue = p.motherTongue;
    draftReligion = p.religion;
    draftCommunity = p.community;
    draftDietaryPreference = p.dietaryPreference;
    draftPhotoUrl = p.profilePhotoUrl;
    draftCountryCode = p.countryCode;
    draftPhone = p.phone;
    draftAddress = p.address;
    draftHighestEducation = p.highestEducation;
    draftOccupation = p.occupation;
    draftCompany = p.company;
    draftAnnualIncome = p.annualIncome;
    draftCountry = p.country;
    draftState = p.state;
    draftCity = p.city;
    draftLocality = p.locality;
    draftFamilyType = p.familyType;
    draftFamilyBackground = p.familyBackground;
    draftFamilyValues = p.familyValues;
    draftPrefAgeMin = p.prefAgeMin;
    draftPrefAgeMax = p.prefAgeMax;
    draftPrefMaritalStatus = p.prefMaritalStatus;
    draftPrefLocation = p.prefLocation;
    draftPrefEducation = p.prefEducation;
    draftPrefOccupation = p.prefOccupation;
    draftPrefIncome = p.prefIncome;
    draftPartnerExpectations = p.partnerExpectations;
    draftBio = p.bio;
    notifyListeners();
  }

  void updateMyProfile(MatrimonyProfileModel updated) {
    _myProfile = updated;
    notifyListeners();
  }

  /// Publishes the wizard draft to the real backend and returns the saved profile.
  Future<MatrimonyProfileModel?> publishWizardProfile() async {
    _isPublishing = true;
    notifyListeners();

    try {
      final profileData = {
        'createdFor': draftCreatedFor,
        'fullName': draftFullName,
        'gender': draftGender,
        'dateOfBirth': draftDateOfBirth?.toIso8601String().substring(0, 10) ?? '1997-01-01',
        'age': draftAge,
        'maritalStatus': draftMaritalStatus,
        'height': draftHeight,
        'motherTongue': draftMotherTongue,
        'religion': draftReligion,
        'community': draftCommunity,
        'dietaryPreference': draftDietaryPreference,
        'profilePhotoUrl': draftPhotoUrl,
        'countryCode': draftCountryCode,
        'phone': draftPhone,
        'address': draftAddress,
        'highestEducation': draftHighestEducation,
        'occupation': draftOccupation,
        'company': draftCompany,
        'annualIncome': draftAnnualIncome,
        'country': draftCountry,
        'state': draftState,
        'city': draftCity,
        'locality': draftLocality,
        'familyType': draftFamilyType,
        'familyBackground': draftFamilyBackground,
        'familyValues': draftFamilyValues,
        'prefAgeMin': draftPrefAgeMin,
        'prefAgeMax': draftPrefAgeMax,
        'prefMaritalStatus': draftPrefMaritalStatus,
        'prefLocation': draftPrefLocation,
        'prefEducation': draftPrefEducation,
        'prefOccupation': draftPrefOccupation,
        'prefIncome': draftPrefIncome,
        'partnerExpectations': draftPartnerExpectations,
        'bio': draftBio,
        'status': 'published',
      };

      final result = await ProfileService.saveProfile(profileData);
      if (result.success && result.profile != null) {
        _myProfile = result.profile;
        resetWizard();
        notifyListeners();
        return result.profile;
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      _isPublishing = false;
      notifyListeners();
    }
  }

  /// Reset all profile state on logout
  void clear() {
    _myProfile = null;
    _isLoadingProfile = false;
    _profileError = null;
    resetWizard();
    notifyListeners();
  }
}
