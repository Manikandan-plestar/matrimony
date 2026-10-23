import 'package:flutter/material.dart';
import '../models/matrimony_profile_model.dart';
import '../services/profile_service.dart';
import '../services/mock/mock_data.dart';

/// Discovery Provider for Groom & Bride feeds and swipe deck states.
/// Loads real profiles from the backend API, with fallback to verified mock candidates.
class DiscoveryProvider extends ChangeNotifier {
  int _selectedTabIndex = 0; // 0 = Groom, 1 = Center Publish, 2 = Bride

  List<MatrimonyProfileModel> _groomProfiles = [];
  List<MatrimonyProfileModel> _brideProfiles = [];

  bool _isLoadingGrooms = false;
  bool _isLoadingBrides = false;
  String? _groomError;
  String? _brideError;

  int _groomCardIndex = 0;
  int _brideCardIndex = 0;

  int get selectedTabIndex => _selectedTabIndex;
  List<MatrimonyProfileModel> get groomProfiles => _groomProfiles;
  List<MatrimonyProfileModel> get brideProfiles => _brideProfiles;
  bool get isLoadingGrooms => _isLoadingGrooms;
  bool get isLoadingBrides => _isLoadingBrides;
  String? get groomError => _groomError;
  String? get brideError => _brideError;
  int get groomCardIndex => _groomCardIndex;
  int get brideCardIndex => _brideCardIndex;

  void setTabIndex(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  void setGroomCardIndex(int index) {
    _groomCardIndex = index;
    notifyListeners();
  }

  void setBrideCardIndex(int index) {
    _brideCardIndex = index;
    notifyListeners();
  }

  /// Load groom profiles from backend.
  Future<void> fetchGroomProfiles({int page = 1}) async {
    _isLoadingGrooms = true;
    _groomError = null;
    notifyListeners();
    try {
      final profiles = await ProfileService.fetchProfiles(gender: 'Groom', page: page);
      if (page == 1) {
        _groomProfiles = profiles;
      } else {
        _groomProfiles = [..._groomProfiles, ...profiles];
      }
      _groomCardIndex = 0;
    } catch (_) {
      if (page == 1 && _groomProfiles.isEmpty) {
        _groomProfiles = MockData.initialGroomProfiles;
      }
      _groomError = null;
    } finally {
      _isLoadingGrooms = false;
      notifyListeners();
    }
  }

  /// Load bride profiles from backend.
  Future<void> fetchBrideProfiles({int page = 1}) async {
    _isLoadingBrides = true;
    _brideError = null;
    notifyListeners();
    try {
      final profiles = await ProfileService.fetchProfiles(gender: 'Bride', page: page);
      if (page == 1) {
        _brideProfiles = profiles;
      } else {
        _brideProfiles = [..._brideProfiles, ...profiles];
      }
      _brideCardIndex = 0;
    } catch (_) {
      if (page == 1 && _brideProfiles.isEmpty) {
        _brideProfiles = MockData.initialBrideProfiles;
      }
      _brideError = null;
    } finally {
      _isLoadingBrides = false;
      notifyListeners();
    }
  }

  /// Load both feeds at once.
  Future<void> fetchAllProfiles() async {
    await Future.wait([fetchGroomProfiles(), fetchBrideProfiles()]);
  }

  /// Insert a newly published profile into the correct feed.
  void addNewProfile(MatrimonyProfileModel profile) {
    if (profile.gender == 'Groom') {
      _groomProfiles = [profile, ..._groomProfiles];
      _groomCardIndex = 0;
    } else {
      _brideProfiles = [profile, ..._brideProfiles];
      _brideCardIndex = 0;
    }
    notifyListeners();
  }

  void toggleInterestSent(MatrimonyProfileModel profile) {
    profile.isInterestSent = !profile.isInterestSent;
    notifyListeners();
  }

  void toggleSaveProfile(MatrimonyProfileModel profile) {
    profile.isSaved = !profile.isSaved;
    notifyListeners();
  }

  /// Reset discovery state on logout
  void clear() {
    _groomProfiles = [];
    _brideProfiles = [];
    _groomCardIndex = 0;
    _brideCardIndex = 0;
    _isLoadingGrooms = false;
    _isLoadingBrides = false;
    _groomError = null;
    _brideError = null;
    notifyListeners();
  }
}
